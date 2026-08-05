#include "win_service.h"

#include <windows.h>

#include <cstdio>
#include <ctime>
#include <fstream>
#include <string>

namespace {

constexpr wchar_t kServiceName[] = L"EtAlienDaily";

// headless 程序位于 exe 同级 bin\ 子目录（dart build cli bundle 结构：
// bin\etalien_headless.exe + lib\sqlite3.dll，dll 按 exe 相对路径 ..\lib 解析）。
constexpr wchar_t kHeadlessExe[] = L"bin\\etalien_headless.exe";
constexpr DWORD kPollIntervalMs = 60000;      // 主循环轮询间隔
constexpr int kTimeWindowSec = 60;            // 定时时间匹配窗口（±秒）

SERVICE_STATUS_HANDLE g_status_handle = nullptr;
HANDLE g_stop_event = nullptr;
DWORD g_check_point = 0;

std::wstring ExeDir() {
  wchar_t path[MAX_PATH] = {};
  GetModuleFileNameW(nullptr, path, MAX_PATH);
  std::wstring full(path);
  const auto pos = full.find_last_of(L"\\/");
  return pos == std::wstring::npos ? L"." : full.substr(0, pos);
}

std::wstring ConfigDir() {
  const std::wstring dir = ExeDir() + L"\\config";
  CreateDirectoryW(dir.c_str(), nullptr);  // 幂等
  return dir;
}

void Log(const std::wstring& msg) {
  std::wofstream f(ConfigDir() + L"\\service.log", std::ios::app);
  if (!f) return;
  const time_t now = time(nullptr);
  tm local = {};
  localtime_s(&local, &now);
  wchar_t ts[32] = {};
  wcsftime(ts, 32, L"%Y-%m-%d %H:%M:%S", &local);
  f << ts << L" " << msg << L"\n";
}

bool ReportStatus(DWORD state, DWORD exit_code = NO_ERROR, DWORD wait_hint = 0) {
  if (!g_status_handle) return false;
  SERVICE_STATUS status = {};
  status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
  status.dwCurrentState = state;
  status.dwWin32ExitCode = exit_code;
  if (state == SERVICE_START_PENDING || state == SERVICE_STOP_PENDING) {
    status.dwCheckPoint = ++g_check_point;
    status.dwWaitHint = wait_hint;
  } else {
    status.dwCheckPoint = 0;
    status.dwWaitHint = 0;
  }
  status.dwControlsAccepted =
      state == SERVICE_RUNNING ? (SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN) : 0;
  return SetServiceStatus(g_status_handle, &status) != 0;
}

DWORD WINAPI HandlerEx(DWORD control, DWORD, LPVOID, LPVOID) {
  if (control == SERVICE_CONTROL_STOP || control == SERVICE_CONTROL_SHUTDOWN) {
    Log(L"received stop control");
    ReportStatus(SERVICE_STOP_PENDING, NO_ERROR, 5000);
    if (g_stop_event) SetEvent(g_stop_event);
  }
  return NO_ERROR;
}

struct ScheduleConfig {
  bool enabled = false;
  std::wstring method = L"schtasks";
  std::wstring time = L"08:00";
};

ScheduleConfig ReadSchedule() {
  const std::wstring ini = ConfigDir() + L"\\schedule.ini";
  wchar_t buf[64] = {};
  ScheduleConfig cfg;
  GetPrivateProfileStringW(L"schedule", L"enabled", L"false", buf, 64, ini.c_str());
  cfg.enabled = _wcsicmp(buf, L"true") == 0;
  GetPrivateProfileStringW(L"schedule", L"method", L"schtasks", buf, 64, ini.c_str());
  cfg.method = buf;
  GetPrivateProfileStringW(L"schedule", L"time", L"08:00", buf, 64, ini.c_str());
  cfg.time = buf;
  return cfg;
}

void RunHeadlessClaim() {
  const std::wstring exe = ExeDir() + L"\\" + kHeadlessExe;
  std::wstring cmd = L"\"" + exe + L"\" --scheduled";

  STARTUPINFOW si = {};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_HIDE;
  PROCESS_INFORMATION pi = {};
  if (!CreateProcessW(nullptr, cmd.data(), nullptr, nullptr, FALSE,
                      CREATE_NO_WINDOW, nullptr, ExeDir().c_str(), &si, &pi)) {
    Log(L"CreateProcess(" + exe + L") failed, error=" +
        std::to_wstring(GetLastError()));
    return;
  }

  // 等待子进程退出；期间收到停止信号则终止子进程
  const HANDLE handles[2] = {pi.hProcess, g_stop_event};
  const DWORD ret = WaitForMultipleObjects(2, handles, FALSE, INFINITE);
  if (ret == WAIT_OBJECT_0 + 1) {
    Log(L"stop requested, terminating claim process");
    TerminateProcess(pi.hProcess, 1);
    WaitForSingleObject(pi.hProcess, 5000);
  } else {
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    Log(L"claim process exited, code=" + std::to_wstring(code));
  }
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
}

void ServiceWorker() {
  Log(L"service worker started");
  std::wstring last_claim_date;
  while (WaitForSingleObject(g_stop_event, kPollIntervalMs) == WAIT_TIMEOUT) {
    const ScheduleConfig cfg = ReadSchedule();
    if (!cfg.enabled || cfg.method != L"service") continue;

    int hh = 0, mm = 0;
    if (swscanf_s(cfg.time.c_str(), L"%d:%d", &hh, &mm) != 2) continue;

    const time_t now = time(nullptr);
    tm local = {};
    localtime_s(&local, &now);

    wchar_t today[16] = {};
    swprintf(today, 16, L"%04d-%02d-%02d", local.tm_year + 1900,
             local.tm_mon + 1, local.tm_mday);
    if (last_claim_date == today) continue;

    const int now_sec = local.tm_hour * 3600 + local.tm_min * 60 + local.tm_sec;
    const int sched_sec = hh * 3600 + mm * 60;
    if (abs(now_sec - sched_sec) > kTimeWindowSec) continue;

    Log(L"scheduled time " + cfg.time + L" reached, launching claim");
    RunHeadlessClaim();
    last_claim_date = today;
  }
  Log(L"service worker stopped");
}

void WINAPI ServiceMain(DWORD, LPWSTR*) {
  g_status_handle =
      RegisterServiceCtrlHandlerExW(kServiceName, HandlerEx, nullptr);
  if (!g_status_handle) return;

  ReportStatus(SERVICE_START_PENDING, NO_ERROR, 3000);

  g_stop_event = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!g_stop_event) {
    ReportStatus(SERVICE_STOPPED, 1);
    return;
  }

  ReportStatus(SERVICE_RUNNING);
  ServiceWorker();

  CloseHandle(g_stop_event);
  g_stop_event = nullptr;
  ReportStatus(SERVICE_STOPPED);
}

}  // namespace

int RunServiceIfRequested() {
  int argc = 0;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  bool is_service = false;
  for (int i = 1; argv && i < argc; i++) {
    if (_wcsicmp(argv[i], L"--service") == 0) {
      is_service = true;
      break;
    }
  }
  if (argv) LocalFree(argv);
  if (!is_service) return -1;

  SERVICE_TABLE_ENTRYW table[2] = {};
  table[0].lpServiceName = const_cast<LPWSTR>(kServiceName);
  table[0].lpServiceProc = ServiceMain;
  if (!StartServiceCtrlDispatcherW(table)) {
    return static_cast<int>(GetLastError());
  }
  return 0;
}
