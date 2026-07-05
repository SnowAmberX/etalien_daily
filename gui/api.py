"""Flask REST API 服务器。

GUI 后端的 HTTP API，封装 db.py / client.py / service.py 的功能。
所有响应为 JSON 格式，账号返回时过滤敏感字段。
"""

import logging
import os
import socket
import subprocess
import sys
import threading
import time

from flask import Flask, jsonify, request, send_from_directory

from etalien.client import ApiClient
from etalien.db import (
    Account,
    add_account,
    add_claim_event,
    delete_account,
    get_account,
    get_accounts,
    get_claim_events,
    get_claim_history,
    get_settings,
    get_week_start_ts,
    init_db,
    update_account,
    update_account_token,
    update_settings,
)
from etalien.service import get_ad_progress_from_config, run_concurrent_claim
from gui import claim_manager

logger = logging.getLogger(__name__)

# ── 静态文件路径 ─────────────────────────────────────────────────

def _get_static_dir() -> str:
    """获取静态文件目录（兼容 PyInstaller 打包）。"""
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, "gui", "static")
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")


# ── 临时客户端缓存 ──────────────────────────────────────────────

_pending_clients: dict[str, ApiClient] = {}


def _normalize_phone(phone: str) -> str:
    """标准化手机号：11 位国内号码自动加 +86 前缀。"""
    phone = phone.strip()
    if not phone.startswith("+") and len(phone) == 11 and phone.isdigit():
        return "+86" + phone
    return phone


def _get_client(phone: str) -> ApiClient:
    if phone not in _pending_clients:
        acc = get_account(phone)
        device_id = acc.device_id if acc else ""
        _pending_clients[phone] = ApiClient(device_id=device_id)
    return _pending_clients[phone]


# ── 账号敏感字段过滤 ────────────────────────────────────────────

_ACCOUNT_PUBLIC_FIELDS = {
    "id", "phone", "name", "remark", "enabled",
    "user_id", "device_id", "created_at", "updated_at", "has_password",
}


def _account_public(acc: Account) -> dict:
    """返回不含 token 等敏感字段的账号 dict。"""
    d = acc.to_dict()
    return {k: v for k, v in d.items() if k in _ACCOUNT_PUBLIC_FIELDS}


# ── Flask App ────────────────────────────────────────────────────

def create_app() -> Flask:
    app = Flask(__name__)
    static_dir = _get_static_dir()

    # ── 请求校验 ────────────────────────────────────────────

    @app.before_request
    def check_json():
        if request.method in ("POST", "PUT"):
            if request.content_length and not request.is_json:
                if request.path.startswith("/api/"):
                    return jsonify({"error": "请求体需为 JSON"}), 400

    # ── 前端页面 ────────────────────────────────────────────

    @app.route("/")
    def index():
        return send_from_directory(static_dir, "index.html")

    @app.route("/<path:path>")
    def static_files(path):
        return send_from_directory(static_dir, path)

    # ── 账号管理 ────────────────────────────────────────────

    @app.route("/api/accounts", methods=["GET"])
    def list_accounts():
        accounts = get_accounts(enabled_only=False)
        return jsonify([_account_public(acc) for acc in accounts])

    @app.route("/api/accounts/<phone>", methods=["GET"])
    def get_account_api(phone):
        acc = get_account(phone)
        if not acc:
            return jsonify({"error": "账号不存在"}), 404
        return jsonify(_account_public(acc))

    @app.route("/api/accounts", methods=["POST"])
    def create_account():
        data = request.get_json(silent=True) or {}
        phone = data.get("phone", "").strip()
        if not phone:
            return jsonify({"error": "手机号不能为空"}), 400
        if get_account(phone):
            return jsonify({"error": "账号已存在"}), 409
        acc = add_account(
            phone=phone,
            name=data.get("name", ""),
            remark=data.get("remark", ""),
        )
        return jsonify(_account_public(acc)), 201

    @app.route("/api/accounts/<phone>", methods=["PUT"])
    def update_account_api(phone):
        data = request.get_json(silent=True) or {}
        allowed = {"name", "remark", "enabled"}
        fields = {k: v for k, v in data.items() if k in allowed}

        # 如果修改手机号，清空旧凭证
        new_phone = data.get("phone", "").strip()
        if new_phone and new_phone != phone:
            delete_account(phone)
            acc = add_account(phone=new_phone, name=data.get("name", ""), remark=data.get("remark", ""))
            return jsonify(_account_public(acc))

        if not fields:
            return jsonify({"error": "没有可更新的字段"}), 400
        ok = update_account(phone, **fields)
        if not ok:
            return jsonify({"error": "账号不存在"}), 404
        acc = get_account(phone)
        return jsonify(_account_public(acc) if acc else {})

    @app.route("/api/accounts/<phone>", methods=["DELETE"])
    def delete_account_api(phone):
        ok = delete_account(phone)
        if not ok:
            return jsonify({"error": "账号不存在"}), 404
        return jsonify({"ok": True})

    # ── 登录 ────────────────────────────────────────────────

    @app.route("/api/login/<phone>", methods=["POST"])
    def send_code(phone):
        acc = get_account(phone)
        if not acc:
            return jsonify({"error": "账号不存在"}), 404
        client = _get_client(phone)
        result = client.get_verification_code(phone_number=_normalize_phone(phone))
        if result.get("_error"):
            code = result.get("code", 0)
            # 60/1000 表示冷却期，但验证码可能已发送
            if code in (60, 1000):
                return jsonify({"ok": True, "msg": "验证码冷却中，请检查短信"})
            return jsonify({"error": result.get("msg", "发送失败")}), 500
        return jsonify({"ok": True, "msg": "验证码已发送"})

    @app.route("/api/login/<phone>/verify", methods=["POST"])
    def verify_code(phone):
        data = request.get_json(silent=True) or {}
        code = data.get("code", "").strip()
        if not code:
            return jsonify({"error": "验证码不能为空"}), 400
        client = _get_client(phone)
        result = client.login(phone_number=_normalize_phone(phone), verification_code=code)
        if result.get("_error"):
            return jsonify({"error": result.get("msg", "登录失败")}), 401
        token = result.get("authorization", "")
        user_id = result.get("user_id", 0)
        update_account_token(phone, token, user_id)
        _pending_clients.pop(phone, None)

        # 获取用户昵称，如果备注名为空则自动设置
        try:
            profile = client.fetch_my_profile()
            nickname = profile.get("nickname", "")
            if nickname:
                acc = get_account(phone)
                if acc and not acc.name:
                    update_account(phone, name=nickname)
        except Exception:
            pass

        return jsonify({"ok": True, "user_id": user_id})

    @app.route("/api/login/<phone>/password", methods=["POST"])
    def password_login(phone):
        data = request.get_json(silent=True) or {}
        password = data.get("password", "").strip()
        if not password:
            return jsonify({"error": "密码不能为空"}), 400

        acc = get_account(phone)
        if not acc:
            return jsonify({"error": "账号不存在"}), 404

        client = _get_client(phone)
        result = client.login_by_password(
            phone_number=_normalize_phone(phone),
            password=password,
        )
        if result.get("_error"):
            return jsonify({"error": result.get("msg", "登录失败")}), 401

        token = result.get("authorization", "")
        user_id = result.get("user_id", 0)
        update_account_token(phone, token, user_id)
        # 保存密码到数据库
        update_account(phone, password=password)
        _pending_clients.pop(phone, None)

        # 获取用户昵称
        try:
            profile = client.fetch_my_profile()
            nickname = profile.get("nickname", "")
            if nickname:
                acc2 = get_account(phone)
                if acc2 and not acc2.name:
                    update_account(phone, name=nickname)
        except Exception:
            pass

        return jsonify({"ok": True, "user_id": user_id})

    # ── 状态 ────────────────────────────────────────────────

    @app.route("/api/status", methods=["GET"])
    def account_status():
        """获取所有账号状态（VIP 时长、广告进度、Token 状态等）。"""
        accounts = get_accounts(enabled_only=False)
        if not accounts:
            return jsonify([])

        from concurrent.futures import ThreadPoolExecutor, as_completed

        def _fetch_status(acc):
            client = ApiClient(device_id=acc.device_id, auth_token=acc.auth_token)
            base = {
                "phone": acc.phone,
                "name": acc.name,
                "remark": acc.remark,
                "enabled": acc.enabled,
            }

            if not acc.auth_token:
                return {
                    **base,
                    "logged_in": False,
                    "token_valid": False,
                    "token_expired": False,
                    "status": "need_login",
                    "vip_duration": 0,
                    "free_duration": 0,
                    "progress": "-/-",
                    "current": 0,
                    "total": 0,
                    "mobile_duration": 0,
                    "mobile_progress": "-/-",
                    "mobile_current": 0,
                    "mobile_total": 0,
                    "mobile_error": False,
                }

            if not client.check_token_valid():
                return {
                    **base,
                    "logged_in": True,
                    "token_valid": False,
                    "token_expired": True,
                    "status": "need_login",
                    "vip_duration": 0,
                    "free_duration": 0,
                    "progress": "-/-",
                    "current": 0,
                    "total": 0,
                    "mobile_duration": 0,
                    "mobile_progress": "-/-",
                    "mobile_current": 0,
                    "mobile_total": 0,
                    "mobile_error": False,
                }

            dur = client.fetch_pc_duration()
            config = client.fetch_pc_ad_config()

            vip = int(dur.get("vip_duration_second", 0))
            free = int(dur.get("free_duration_second", 0))

            if config.get("_error") or dur.get("_error"):
                return {
                    **base,
                    "logged_in": True,
                    "token_valid": True,
                    "token_expired": False,
                    "status": "error",
                    "vip_duration": vip,
                    "free_duration": free,
                    "progress": "-/-",
                    "current": 0,
                    "total": 0,
                    "mobile_duration": 0,
                    "mobile_progress": "-/-",
                    "mobile_current": 0,
                    "mobile_total": 0,
                    "mobile_error": False,
                }

            watched, total = get_ad_progress_from_config(config)
            progress_str = f"{watched}/{total}"
            status = "all_done" if total > 0 and watched >= total else "ok"

            # 手机端数据
            mobile_current = 0
            mobile_total = 0
            mobile_progress = "-/-"
            mobile_duration = 0
            mobile_error = False
            # 手机端广告任务
            try:
                activity = client.fetch_mobile_ad_activity()
                if not activity.get("_error"):
                    video_bar = activity.get("video_bar", [])
                    # 待领取 = has_award=true 且 is_get=false
                    pending = [t for t in video_bar if t.get("has_award") and not t.get("is_get")]
                    mobile_total = len([t for t in video_bar if t.get("has_award")])
                    mobile_current = mobile_total - len(pending)
                    mobile_progress = f"{mobile_current}/{mobile_total}" if mobile_total > 0 else "-/-"
                else:
                    mobile_error = True
                    logger.warning("[status] %s 手机端 activity 查询失败: %s",
                                   acc.phone, activity.get("msg", "unknown"))
            except Exception:
                mobile_error = True
                logger.exception("[status] %s 手机端 activity 查询异常", acc.phone)
            # 手机端加速时长（独立 try，activity 失败不影响 profile）
            try:
                profile = client.fetch_my_profile()
                if not profile.get("_error"):
                    mobile_duration = int(profile.get("remaining_seconds", 0))
                else:
                    mobile_error = True
                    logger.warning("[status] %s 手机端 profile 查询失败: %s",
                                   acc.phone, profile.get("msg", "unknown"))
            except Exception:
                mobile_error = True
                logger.exception("[status] %s 手机端 profile 查询异常", acc.phone)

            # 翻译任务进度（静默获取）
            translate_current = 0
            translate_total = 0
            translate_progress = "-/-"
            translate_count = 0
            try:
                config = client.fetch_translate_ad_config()
                if not config.get("_error"):
                    tw, tt = get_ad_progress_from_config(config)
                    translate_current = tw
                    translate_total = tt
                    translate_progress = f"{tw}/{tt}" if tt > 0 else "-/-"
                product = client.fetch_translate_product()
                logger.info("[status] 翻译次数 product=%s",
                           {k: v for k, v in product.items() if not k.startswith("_")})
                if not product.get("_error"):
                    translate_count = int(product.get("expire_time") or product.get("expireTime") or 0)
            except Exception:
                pass

            return {
                **base,
                "logged_in": True,
                "token_valid": True,
                "token_expired": False,
                "status": status,
                "vip_duration": vip,
                "free_duration": free,
                "progress": progress_str,
                "current": watched,
                "total": total,
                "mobile_progress": mobile_progress,
                "mobile_current": mobile_current,
                "mobile_total": mobile_total,
                "mobile_duration": mobile_duration,
                "mobile_error": mobile_error,
                "translate_progress": translate_progress,
                "translate_current": translate_current,
                "translate_total": translate_total,
                "translate_count": translate_count,
            }

        with ThreadPoolExecutor(max_workers=min(len(accounts), 10)) as executor:
            futures = {executor.submit(_fetch_status, acc): acc for acc in accounts}
            results = []
            for future in as_completed(futures):
                try:
                    results.append(future.result())
                except Exception as e:
                    acc = futures[future]
                    logger.error("获取状态异常 (%s): %s", acc.phone, e)
                    results.append({
                        "phone": acc.phone,
                        "name": acc.name or "",
                        "remark": acc.remark or "",
                        "enabled": acc.enabled,
                        "logged_in": bool(acc.auth_token),
                        "token_valid": False,
                        "token_expired": False,
                        "status": "error",
                        "vip_duration": 0,
                        "free_duration": 0,
                        "progress": "-/-",
                        "current": 0,
                        "total": 0,
                        "mobile_duration": 0,
                        "mobile_progress": "-/-",
                        "mobile_current": 0,
                        "mobile_total": 0,
                        "mobile_error": False,
                    })

        results.sort(key=lambda r: r["phone"])
        return jsonify(results)

    # ── 领取 ────────────────────────────────────────────────

    @app.route("/api/claim", methods=["POST"])
    def start_claim():
        data = request.get_json(silent=True) or {}
        target = data.get("target", "all")
        if target not in ("all", "pc", "mobile", "translate"):
            target = "all"

        run_id = claim_manager.start()
        if not run_id:
            return jsonify({"error": "领取任务已在运行中"}), 409

        accounts = get_accounts(enabled_only=True)
        if not accounts:
            claim_manager.finish()
            return jsonify({"error": "没有启用的账号"}), 400

        settings = get_settings()
        account_map = {acc.phone: acc for acc in accounts}
        logger.info("开始领取任务 target=%s account_count=%d run_id=%s", target, len(accounts), run_id)

        # 为每个账号添加初始进度条目
        for acc in accounts:
            claim_manager.add_progress_entry({
                "phone": acc.phone,
                "status": "running",
                "current": 0,
                "total": 0,
                "vip_before": 0,
                "vip_after": 0,
                "error": None,
            })

        def _progress_callback(phone, step, detail, **extra):
            """将 service 的回调转为进度条目更新 + DB 事件记录。"""
            updates = {}
            if step == "done" or step == "after":
                updates["status"] = "done"
            elif step == "already_done":
                updates["status"] = "already_done"
            elif step == "error":
                updates["status"] = "error"
                updates["error"] = detail
            elif step == "auth_error":
                updates["status"] = "need_login"
                updates["error"] = detail
            elif step.startswith("b"):
                updates["detail"] = detail

            # 从 extra 中提取进度数值
            if "current" in extra:
                updates["current"] = extra["current"]
            if "total" in extra:
                updates["total"] = extra["total"]
            if "vip_before" in extra:
                updates["vip_before"] = extra["vip_before"]
            if "vip_after" in extra:
                updates["vip_after"] = extra["vip_after"]

            logger.info("[%s] 领取进度 step=%s detail=%s extra=%s", phone, step, detail, extra)
            claim_manager.update_progress_entry(phone, updates)

            # 写入领取事件到数据库
            try:
                acc = account_map.get(phone)
                if acc:
                    add_claim_event(
                        run_id=run_id,
                        account_id=acc.id,
                        phone=phone,
                        status=updates.get("status", "running"),
                        step=step,
                        detail=detail,
                        current=extra.get("current", 0),
                        total=extra.get("total", 0),
                        vip_before=extra.get("vip_before", 0),
                        vip_after=extra.get("vip_after", 0),
                        error=updates.get("error", ""),
                        source="gui",
                    )
            except Exception as e:
                logger.warning("保存领取事件失败: %s", e)

        def _run():
            try:
                results = run_concurrent_claim(
                    accounts, settings,
                    progress_callback=_progress_callback,
                    source="gui",
                    target=target,
                )
                # 用最终结果更新进度
                for r in results:
                    claim_manager.update_progress_entry(r["phone"], {
                        "status": r["status"],
                        "vip_before": r.get("vip_before", 0),
                        "vip_after": r.get("vip_after", 0),
                        "current": r.get("claimed", 0),
                        "total": r.get("claimed", 0) + r.get("failed", 0),
                        "error": r.get("error_msg"),
                    })
                logger.info("领取任务完成 run_id=%s result_count=%d", run_id, len(results))
            except Exception as e:
                logger.error("领取异常: %s", e)
            finally:
                claim_manager.finish()

        t = threading.Thread(target=_run, daemon=True)
        t.start()
        return jsonify({"ok": True, "account_count": len(accounts)})

    @app.route("/api/claim/progress", methods=["GET"])
    def claim_progress():
        return jsonify(claim_manager.get_progress())

    # ── 设置 ────────────────────────────────────────────────

    @app.route("/api/settings", methods=["GET"])
    def settings_get():
        return jsonify(get_settings())

    @app.route("/api/settings", methods=["PUT"])
    def settings_update():
        data = request.get_json(silent=True) or {}
        allowed = {"max_concurrent", "request_interval", "max_rounds", "mobile_max_rounds", "translate_retry_limit", "schedule_time",
                   "schedule_enabled", "schedule_method"}
        fields = {k: v for k, v in data.items() if k in allowed}
        if not fields:
            return jsonify({"error": "没有可更新的字段"}), 400
        update_settings(**fields)

        # 保存后同步定时机制
        settings = get_settings()
        if settings.get("schedule_enabled") and settings.get("schedule_method") == "schtasks":
            _ensure_schtask(settings.get("schedule_time", "08:00"))
        elif not settings.get("schedule_enabled"):
            _remove_schtask()

        return jsonify(settings)

    # ── 定时任务 ────────────────────────────────────────────

    TASK_NAME = "EtAlienAuto_DailyClaim"

    def _get_exe_path() -> str:
        if getattr(sys, "frozen", False):
            return sys.executable
        return sys.executable  # Python 解释器路径

    def _get_schtask_cmd() -> str:
        """构建 schtasks 要执行的命令行。"""
        exe_path = _get_exe_path()
        if getattr(sys, "frozen", False):
            return f'"{exe_path}" --cli --scheduled'
        else:
            main_py = os.path.join(
                os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                "src", "etalien", "main.py",
            )
            return f'"{sys.executable}" "{main_py}" --scheduled'

    def _ensure_schtask(schedule_time: str) -> None:
        """创建或更新 Windows 计划任务。"""
        try:
            cmd = _get_schtask_cmd()
            _sc_run([
                "schtasks", "/create", "/tn", TASK_NAME,
                "/tr", cmd,
                "/sc", "daily", "/st", schedule_time, "/f",
            ], check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass

    def _remove_schtask() -> None:
        """删除 Windows 计划任务。"""
        try:
            _sc_run(["schtasks", "/delete", "/tn", TASK_NAME, "/f"])
        except FileNotFoundError:
            pass

    @app.route("/api/schedule", methods=["GET"])
    def schedule_get():
        try:
            result = subprocess.run(
                ["schtasks", "/query", "/tn", TASK_NAME],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                return jsonify({"enabled": False})
            # 简单解析
            return jsonify({"enabled": True, "detail": result.stdout.strip()})
        except FileNotFoundError:
            return jsonify({"enabled": False, "error": "schtasks 不可用"})

    @app.route("/api/schedule", methods=["POST"])
    def schedule_create():
        data = request.get_json(silent=True) or {}
        schedule_time = data.get("schedule_time") or data.get("time", "08:00")

        try:
            cmd = _get_schtask_cmd()
            subprocess.run([
                "schtasks", "/create", "/tn", TASK_NAME,
                "/tr", cmd,
                "/sc", "daily", "/st", schedule_time, "/f",
            ], capture_output=True, text=True, check=True)
            return jsonify({"ok": True, "time": schedule_time})
        except subprocess.CalledProcessError as e:
            return jsonify({"error": e.stderr.strip()}), 500
        except FileNotFoundError:
            return jsonify({"error": "schtasks 不可用（非 Windows 系统）"}), 500

    @app.route("/api/schedule", methods=["DELETE"])
    def schedule_delete():
        try:
            subprocess.run(
                ["schtasks", "/delete", "/tn", TASK_NAME, "/f"],
                capture_output=True, text=True, check=True,
            )
            return jsonify({"ok": True})
        except subprocess.CalledProcessError as e:
            return jsonify({"error": e.stderr.strip()}), 500
        except FileNotFoundError:
            return jsonify({"ok": True})

    # ── 定时服务状态 ─────────────────────────────────────

    SERVICE_NAME = "EtAlienDaily"

    @app.route("/api/schedule/status", methods=["GET"])
    def schedule_status():
        """综合查询定时任务状态（schtasks + Windows Service）。"""
        result = {
            "schtasks": False,
            "service_installed": False,
            "service_running": False,
        }

        # 检查 schtasks
        try:
            r = _sc_run(["schtasks", "/query", "/tn", TASK_NAME])
            result["schtasks"] = r.returncode == 0
        except FileNotFoundError:
            pass

        # 检查 Windows Service
        try:
            r = _sc_run(["sc", "query", SERVICE_NAME])
            if r.returncode == 0:
                result["service_installed"] = True
                result["service_running"] = "RUNNING" in r.stdout
        except FileNotFoundError:
            pass

        return jsonify(result)

    # ── Windows Service 安装/卸载 ──────────────────────────

    def _sc_run(args: list, timeout: int = 30, check: bool = False) -> subprocess.CompletedProcess:
        """执行外部命令，Windows 下隐藏窗口。"""
        kwargs = dict(capture_output=True, text=True, timeout=timeout)
        if sys.platform == "win32":
            kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW
        if check:
            return subprocess.run(args, **kwargs, check=True)
        return subprocess.run(args, **kwargs)

    @app.route("/api/schedule/install-service", methods=["POST"])
    def install_service():
        """安装 Windows 服务（需要管理员权限）。"""
        exe_path = _get_exe_path()
        if not getattr(sys, "frozen", False):
            return jsonify({
                "error": "请先打包为 EXE 后再安装服务",
                "hint": "运行 uv run python build.py 打包",
            }), 400

        try:
            # 先检查是否已安装，若是则停止并删除旧服务
            r = _sc_run(["sc", "query", SERVICE_NAME])
            if r.returncode == 0:
                _sc_run(["sc", "stop", SERVICE_NAME])
                r_del = _sc_run(["sc", "delete", SERVICE_NAME])
                if r_del.returncode != 0:
                    return jsonify({"error": "删除旧服务失败: " + r_del.stderr.strip()}), 500
                import time
                time.sleep(1)

            # 创建服务
            r_create = _sc_run([
                "sc", "create", SERVICE_NAME,
                "binPath=", f'"{exe_path}" --service',
                "start=", "auto",
                "DisplayName=", "ET Alien Daily Claim Service",
            ])
            if r_create.returncode != 0:
                err = r_create.stderr.strip() or r_create.stdout.strip() or "未知错误"
                return jsonify({"error": "服务创建失败: " + err}), 500

            # 启动服务
            r_start = _sc_run(["sc", "start", SERVICE_NAME])
            if r_start.returncode != 0:
                err = r_start.stderr.strip() or r_start.stdout.strip() or "未知错误"
                return jsonify({"error": "服务启动失败: " + err}), 500

            # 同步设置：启用定时 + 服务模式
            settings = get_settings()
            update_settings(
                schedule_enabled=True,
                schedule_method="service",
                schedule_time=settings.get("schedule_time", "08:00"),
            )
            # 删除旧的 schtasks 避免重复执行
            _remove_schtask()

            return jsonify({"ok": True})
        except subprocess.TimeoutExpired:
            return jsonify({"error": "服务操作超时"}), 500
        except FileNotFoundError:
            return jsonify({"error": "sc 不可用（非 Windows 系统）"}), 500

    @app.route("/api/schedule/uninstall-service", methods=["DELETE"])
    def uninstall_service():
        """卸载 Windows 服务。"""
        try:
            _sc_run(["sc", "stop", SERVICE_NAME])
            r_del = _sc_run(["sc", "delete", SERVICE_NAME])
            if r_del.returncode != 0:
                err = r_del.stderr.strip() or r_del.stdout.strip() or "未知错误"
                # 如果服务本来就不存在，也算成功
                if "1060" in err or "not exist" in err.lower():
                    pass
                else:
                    return jsonify({"error": "服务删除失败: " + err}), 500

            # 重置设置：回退到 schtasks 模式
            update_settings(schedule_enabled=False, schedule_method="schtasks")

            return jsonify({"ok": True})
        except FileNotFoundError:
            return jsonify({"ok": True})

    # ── 历史 ────────────────────────────────────────────────

    @app.route("/api/history", methods=["GET"])
    def claim_history():
        limit = request.args.get("limit", 50, type=int)
        week_start = request.args.get("week_start", None, type=float)
        source = request.args.get("source", None, type=str)

        if week_start is None:
            week_start = get_week_start_ts(time.time())

        # 获取 service 最终记录
        service_records = get_claim_history(
            limit=limit,
            week_start=week_start,
            source=("service" if not source or source == "service" else source),
        )

        # 获取 GUI 过程事件
        gui_events = []
        if not source or source == "gui":
            gui_events = get_claim_events(
                week_start=week_start,
                limit=limit,
            )

        return jsonify({
            "week_start": week_start,
            "service": service_records,
            "gui": gui_events,
        })

    return app


# ── 端口扫描 ────────────────────────────────────────────────────

PORT_START = 52137
PORT_END = 52200


def find_free_port() -> int:
    for port in range(PORT_START, PORT_END + 1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) != 0:
                return port
    raise RuntimeError(f"端口范围 {PORT_START}-{PORT_END} 均已占用")

