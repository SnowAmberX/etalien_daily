"""Windows Service 包装器（纯 ctypes，零外部依赖）。

作为 Windows 服务运行，每日在 schedule_time 自动执行 CLI 领取。
用 ``sc create`` 安装、``sc delete`` 卸载，或通过 GUI 设置页管理。

入口：
    etalien-daily.exe --service       启动为 Windows 服务
"""

import ctypes
import logging
import sys
from ctypes import wintypes
from datetime import datetime, date

logger = logging.getLogger(__name__)

# ── Win32 常量 ──────────────────────────────────────────────────────

SERVICE_WIN32_OWN_PROCESS = 0x00000010
SERVICE_ACCEPT_STOP = 0x00000001
SERVICE_ACCEPT_SHUTDOWN = 0x00000004
SERVICE_RUNNING = 0x00000004
SERVICE_STOPPED = 0x00000001
SERVICE_START_PENDING = 0x00000002
SERVICE_STOP_PENDING = 0x00000003

SERVICE_CONTROL_STOP = 0x00000001
SERVICE_CONTROL_SHUTDOWN = 0x00000005
SERVICE_CONTROL_INTERROGATE = 0x00000004

NO_ERROR = 0
WAIT_OBJECT_0 = 0x00000000
INFINITE = 0xFFFFFFFF

# ── Win32 API 类型声明（argtypes + restype）───────────────────────
# 必须显式声明 restype，否则 ctypes 默认返回 c_int (32-bit)，
# 在 64 位 Windows 上会截断 SERVICE_STATUS_HANDLE → SetServiceStatus 失
# 效

_advapi32 = ctypes.windll.advapi32
_kernel32 = ctypes.windll.kernel32

# StartServiceCtrlDispatcherW
_advapi32.StartServiceCtrlDispatcherW.argtypes = [ctypes.c_void_p]
_advapi32.StartServiceCtrlDispatcherW.restype = wintypes.BOOL

# RegisterServiceCtrlHandlerExW
_advapi32.RegisterServiceCtrlHandlerExW.argtypes = [
    wintypes.LPCWSTR,
    ctypes.c_void_p,   # LPHANDLER_FUNCTION_EX
    wintypes.LPVOID,
]
_advapi32.RegisterServiceCtrlHandlerExW.restype = wintypes.HANDLE
# ↑ 关键：restype 必须是 HANDLE，否则 64 位句柄被截断为 32 位

# SetServiceStatus
_advapi32.SetServiceStatus.argtypes = [
    wintypes.HANDLE,
    ctypes.c_void_p,   # LPSERVICE_STATUS
]
_advapi32.SetServiceStatus.restype = wintypes.BOOL

# CreateEventW
_kernel32.CreateEventW.argtypes = [
    wintypes.LPVOID,   # lpEventAttributes
    wintypes.BOOL,     # bManualReset
    wintypes.BOOL,     # bInitialState
    wintypes.LPCWSTR,  # lpName
]
_kernel32.CreateEventW.restype = wintypes.HANDLE

# SetEvent
_kernel32.SetEvent.argtypes = [wintypes.HANDLE]
_kernel32.SetEvent.restype = wintypes.BOOL

# WaitForSingleObject
_kernel32.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
_kernel32.WaitForSingleObject.restype = wintypes.DWORD

# GetLastError
_kernel32.GetLastError.argtypes = []
_kernel32.GetLastError.restype = wintypes.DWORD


# ── 结构体 ──────────────────────────────────────────────────────────


class SERVICE_STATUS(ctypes.Structure):
    _fields_ = [
        ("dwServiceType", wintypes.DWORD),
        ("dwCurrentState", wintypes.DWORD),
        ("dwControlsAccepted", wintypes.DWORD),
        ("dwWin32ExitCode", wintypes.DWORD),
        ("dwServiceSpecificExitCode", wintypes.DWORD),
        ("dwCheckPoint", wintypes.DWORD),
        ("dwWaitHint", wintypes.DWORD),
    ]


class SERVICE_TABLE_ENTRYW(ctypes.Structure):
    _fields_ = [
        ("lpServiceName", wintypes.LPWSTR),
        ("lpServiceProc", ctypes.c_void_p),
    ]


# 回调类型
HandlerExProc = ctypes.WINFUNCTYPE(
    wintypes.DWORD,      # return
    wintypes.DWORD,      # dwControl
    wintypes.DWORD,      # dwEventType
    wintypes.LPVOID,     # lpEventData
    wintypes.LPVOID,     # lpContext
)

ServiceMainProc = ctypes.WINFUNCTYPE(
    None,
    wintypes.DWORD,                       # dwNumServicesArgs
    ctypes.POINTER(wintypes.LPWSTR),      # lpServiceArgVectors
)

# ── 全局状态 ────────────────────────────────────────────────────────

_status_handle: int = 0      # SERVICE_STATUS_HANDLE
_stop_event: int = 0         # Win32 event handle
_service_status: SERVICE_STATUS | None = None


def _report_status(
    current_state: int,
    exit_code: int = NO_ERROR,
    wait_hint: int = 0,
) -> bool:
    """向 SCM 上报服务状态。返回 True 表示成功。"""
    global _service_status

    if _service_status is None:
        _service_status = SERVICE_STATUS()
        _service_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS

    _service_status.dwCurrentState = current_state
    _service_status.dwWin32ExitCode = exit_code

    # checkpoint / waithint 规则：
    #   START_PENDING / STOP_PENDING → 递增 checkpoint，设置 waithint
    #   RUNNING / STOPPED           → checkpoint=0, waithint=0
    if current_state in (SERVICE_START_PENDING, SERVICE_STOP_PENDING):
        _service_status.dwCheckPoint += 1
        _service_status.dwWaitHint = wait_hint
    else:
        _service_status.dwCheckPoint = 0
        _service_status.dwWaitHint = 0

    if current_state == SERVICE_RUNNING:
        _service_status.dwControlsAccepted = (
            SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN
        )
    else:
        _service_status.dwControlsAccepted = 0

    if not _status_handle:
        logger.error("SetServiceStatus 调用时 _status_handle 为 0 (当前状态=%d)", current_state)
        return False

    ok = _advapi32.SetServiceStatus(
        wintypes.HANDLE(_status_handle),
        ctypes.byref(_service_status),
    )
    if not ok:
        err = _kernel32.GetLastError()
        logger.error("SetServiceStatus 失败 (状态=%d, 错误码=%d)", current_state, err)

    return bool(ok)


# ── 控制处理器 ─────────────────────────────────────────────────────


@HandlerExProc
def _handler(control: int, _event_type: int, _event_data, _context) -> int:
    if control in (SERVICE_CONTROL_STOP, SERVICE_CONTROL_SHUTDOWN):
        logger.info("收到服务停止信号 (control=%d)", control)
        _report_status(SERVICE_STOP_PENDING, wait_hint=3000)
        _kernel32.SetEvent(wintypes.HANDLE(_stop_event))
        return NO_ERROR
    elif control == SERVICE_CONTROL_INTERROGATE:
        return NO_ERROR
    # ERROR_CALL_NOT_IMPLEMENTED
    return 0x00000000


# ── 服务主循环 ─────────────────────────────────────────────────────


def _service_worker() -> None:
    """服务主循环：每日定时执行领取。"""
    from etalien.db import get_db_path, init_db
    from etalien.db import get_accounts as db_get_accounts
    from etalien.db import get_settings as db_get_settings
    from etalien.service import run_concurrent_claim

    init_db()
    db_path = get_db_path()
    last_claim_date: date | None = None

    logger.info("定时领取服务已启动")

    while True:
        ret = _kernel32.WaitForSingleObject(
            wintypes.HANDLE(_stop_event),
            60000,  # 60 秒
        )
        if ret == WAIT_OBJECT_0:
            logger.info("服务正在停止")
            break

        try:
            settings = db_get_settings(db_path=db_path)
            if not settings.get("schedule_enabled", False):
                continue
            if settings.get("schedule_method", "schtasks") != "service":
                continue

            schedule_time = settings.get("schedule_time", "08:00")
            now = datetime.now()
            today = now.date()

            if last_claim_date == today:
                continue

            try:
                hour, minute = map(int, schedule_time.split(":"))
            except (ValueError, TypeError):
                continue

            scheduled_dt = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
            if abs((now - scheduled_dt).total_seconds()) > 60:
                continue

            logger.info("到达定时时间 %s，开始执行领取", schedule_time)

            accounts = db_get_accounts(enabled_only=True, db_path=db_path)
            if not accounts:
                logger.warning("没有启用的账号，跳过")
                last_claim_date = today
                continue

            results = run_concurrent_claim(accounts, settings)
            ok = sum(1 for r in results if r["status"] in ("ok", "already_done"))
            fail = len(results) - ok
            logger.info("领取完成: %d 成功, %d 失败", ok, fail)
            last_claim_date = today

        except Exception:
            logger.exception("定时领取执行异常")

    _report_status(SERVICE_STOPPED)


# ── ServiceMain ────────────────────────────────────────────────────


@ServiceMainProc
def _service_main(_argc: int, _argv) -> None:
    global _status_handle, _stop_event

    # 步骤 1：先注册控制处理器，拿到 _status_handle
    _status_handle = _advapi32.RegisterServiceCtrlHandlerExW(
        "EtAlienDaily",
        _handler,
        None,
    )
    if not _status_handle:
        logger.error(
            "RegisterServiceCtrlHandlerExW 失败 (错误码=%d)",
            _kernel32.GetLastError(),
        )
        return

    # 步骤 2：拿到句柄后再上报 START_PENDING（之前上报无效）
    _report_status(SERVICE_START_PENDING, wait_hint=3000)

    # 步骤 3：创建停止事件
    _stop_event = _kernel32.CreateEventW(None, True, False, None)
    if not _stop_event:
        logger.error(
            "CreateEventW 失败 (错误码=%d)",
            _kernel32.GetLastError(),
        )
        _report_status(SERVICE_STOPPED, exit_code=1)
        return

    # 步骤 4：报告运行中，然后进入主循环
    _report_status(SERVICE_RUNNING)

    _service_worker()


# ── 入口 ────────────────────────────────────────────────────────────


def run_service() -> None:
    """启动 Windows 服务调度器。

    调用 StartServiceCtrlDispatcherW，阻塞直到服务停止。
    仅在作为 Windows 服务启动时调用（sc start）。
    """
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.FileHandler(
                _get_service_log_path(),
                encoding="utf-8",
            ),
        ],
    )

    svc_name = "EtAlienDaily"

    entry = SERVICE_TABLE_ENTRYW()
    entry.lpServiceName = svc_name
    entry.lpServiceProc = ctypes.cast(_service_main, ctypes.c_void_p).value

    term = SERVICE_TABLE_ENTRYW()
    term.lpServiceName = None
    term.lpServiceProc = 0

    table = (SERVICE_TABLE_ENTRYW * 2)(entry, term)

    if not _advapi32.StartServiceCtrlDispatcherW(table):
        err = _kernel32.GetLastError()
        logger.error("StartServiceCtrlDispatcherW 失败 (错误码: %d)", err)
        sys.exit(1)


def _get_service_log_path() -> str:
    """服务日志文件路径，放在 config 目录下。"""
    import os
    from etalien.db import get_db_path
    config_dir = os.path.dirname(get_db_path())
    return os.path.join(config_dir, "service.log")
