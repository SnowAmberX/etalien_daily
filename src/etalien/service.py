"""业务逻辑层。

编排完整的领取流程：
- 单账号领取: claim_for_account()
- 并发领取: run_concurrent_claim()
- 防死循环 + 认证错误检测 + 进度回调
"""

import json
import logging
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Callable

from etalien.client import ApiClient
from etalien.db import (
    Account,
    add_claim_record,
    get_settings,
    update_account,
    update_account_token,
)

logger = logging.getLogger(__name__)

# ── 常量 ──────────────────────────────────────────────────────────

AD_ID = "103334281"            # 固定广告 ID（PC）
BUSINESS_TYPES = [1, 2, 3]     # 三种广告业务类型
MAX_STALLED_ROUNDS = 3         # 连续无进展最大轮数（防死循环）
BUSINESS_SLEEP = 3.0           # 业务类型切换间隔（秒）

# 手机端常量
MOBILE_AD_ID = "102815305"     # 手机端广告 ID
MOBILE_BUSINESS = 2            # 手机端业务类型

# 翻译端常量
TRANSLATE_AD_ID = "103579416"  # 翻译广告 ID
TRANSLATE_BUSINESS = 3          # 翻译业务类型


# ── 结果状态 ──────────────────────────────────────────────────────

STATUS_OK = "ok"
STATUS_ALREADY_DONE = "already_done"
STATUS_AUTH_ERROR = "auth_error"
STATUS_NEED_LOGIN = "need_login"
STATUS_ERROR = "error"


# ── 客户端初始化 ──────────────────────────────────────────────────

def init_client(account: Account) -> ApiClient | None:
    """为账号初始化 ApiClient。

    - 如果账号有 token，验证其有效性
    - 如果 token 有效，返回带 token 的 client
    - 如果 token 过期或无 token，尝试用已存密码自动登录

    Returns:
        ApiClient 实例，异常时返回 None。
    """
    try:
        client = ApiClient(
            device_id=account.device_id,
            auth_token=account.auth_token,
        )
    except Exception as e:
        logger.error("初始化 ApiClient 失败 (%s): %s", account.phone, e)
        return None

    # 如果有 token，验证有效性
    if account.auth_token:
        if client.check_token_valid():
            logger.debug("Token 有效: %s", account.phone)
            return client
        else:
            logger.info("Token 已过期: %s", account.phone)
            client.clear_auth_token()

    # Token 无效或无 token，尝试密码自动登录
    if account.password:
        logger.info("尝试密码自动登录: %s", account.phone)
        result = client.login_by_password(account.phone, account.password)
        if result.get("_error"):
            logger.warning("密码自动登录失败 (%s): %s", account.phone, result.get("msg"))
        else:
            logger.info("密码自动登录成功 (%s), user_id=%s", account.phone, result.get("user_id"))
            update_account_token(account.phone, result["authorization"], result["user_id"])
            return client

    return client


# ── 单账号领取 ────────────────────────────────────────────────────

def claim_for_account(
    account: Account,
    settings: dict[str, Any] | None = None,
    progress_callback: Callable | None = None,
    source: str = "service",
    target: str = "all",
) -> dict[str, Any]:
    """对单个账号执行完整领取流程。

    Args:
        account: 账号对象（含 token 和 device_id）。
        settings: 设置 dict，为 None 时自动加载。
        progress_callback: 进度回调，签名为 callback(phone, step, detail, **extra)。
        source: 来源标识（"service" 或 "gui"），影响数据库记录的 source 字段。
        target: 领取目标（"all" / "pc" / "mobile"）。

    Returns:
        {
            "phone": str,
            "status": str,       # ok / already_done / auth_error / need_login / error
            "vip_before": int,
            "vip_after": int,
            "claimed": int,
            "failed": int,
            "error_msg": str | None,
        }
    """
    if settings is None:
        settings = get_settings()

    phone = account.phone
    base_result = {
        "phone": phone,
        "status": STATUS_ERROR,
        "vip_before": 0,
        "vip_after": 0,
        "claimed": 0,
        "failed": 0,
        "error_msg": None,
    }

    # 1. 初始化客户端
    _report(progress_callback, phone, "init", "初始化客户端")
    client = init_client(account)
    if client is None:
        base_result["status"] = STATUS_ERROR
        base_result["error_msg"] = "初始化客户端失败"
        return base_result

    if not client.get_auth_token():
        base_result["status"] = STATUS_NEED_LOGIN
        base_result["error_msg"] = "未登录或 token 已过期"
        return base_result

    total_claimed = 0
    total_failed = 0
    total = 0
    vip_before = 0
    vip_after = 0
    run_pc = target in ("all", "pc")
    run_mobile = target in ("all", "mobile")
    run_translate = target in ("all", "translate")

    # ── PC 端领取 ──
    if run_pc:
        # 2. 查询领取前 VIP 时长
        _report(progress_callback, phone, "before", "查询当前时长")
        before = client.fetch_pc_duration()
        if before.get("_error"):
            if _is_auth_error(before):
                base_result["status"] = STATUS_AUTH_ERROR
                base_result["error_msg"] = "token 已过期"
                return base_result
            base_result["error_msg"] = f"查询时长失败: {before.get('msg')}"
            return base_result
        vip_before = int(before.get("vip_duration_second", 0))
        base_result["vip_before"] = vip_before

        # 3. 获取广告任务列表
        _report(progress_callback, phone, "config", "获取广告任务")
        config = client.fetch_pc_ad_config()
        if config.get("_error"):
            base_result["error_msg"] = f"获取任务列表失败: {config.get('msg')}"
            return base_result

        # 上报初始广告进度
        watched, total = get_ad_progress_from_config(config)
        _report(progress_callback, phone, "config", f"获取广告任务 ({watched}/{total})",
                current=watched, total=total)

        # 检查是否全部已完成
        if _all_ads_watched(config):
            _report(progress_callback, phone, "done", "所有广告已观看完毕",
                    current=total, total=total, vip_before=vip_before, vip_after=vip_before)
            base_result["status"] = STATUS_ALREADY_DONE
            base_result["vip_after"] = vip_before
            _save_claim_record(account.id, base_result, source=source)
            return base_result

        # 4. 对每种 business 逐一领取
        total_claimed = 0
        total_failed = 0

        for idx, business in enumerate(BUSINESS_TYPES):
            if idx > 0:
                time.sleep(BUSINESS_SLEEP)

            _report(progress_callback, phone, f"business_{business}", f"领取 business={business}")

            claimed, failed = _claim_business_phase(
                client, business, settings, phone, progress_callback,
            )

            total_claimed += claimed
            total_failed += failed

            if failed > 0 and not client.get_auth_token():
                pass

        base_result["claimed"] = total_claimed
        base_result["failed"] = total_failed

        # 5. 查询领取后 VIP 时长
        _report(progress_callback, phone, "after", "查询领取后时长")
        after = client.fetch_pc_duration()
        if after.get("_error"):
            if _is_auth_error(after):
                base_result["status"] = STATUS_AUTH_ERROR
                base_result["error_msg"] = "领取后 token 过期"
                _save_claim_record(account.id, base_result, source=source)
                return base_result

        vip_after = int(after.get("vip_duration_second", vip_before))
        base_result["vip_after"] = vip_after

    # ── 手机端领取 ──
    if run_mobile:
        # 每 3 天执行一次
        now = time.time()
        if account.last_mobile_claim > 0 and (now - account.last_mobile_claim) < 259200:
            logger.info("[%s] 距上次手机领取不足3天，跳过", phone)
            _report(progress_callback, phone, "mobile_skip", "手机端距上次不足3天，跳过")
        else:
            _report(progress_callback, phone, "mobile", "开始手机端领取")
            mobile_claimed, mobile_failed = _claim_mobile_phase(
                client, settings, phone, progress_callback,
            )
            total_claimed += mobile_claimed
            total_failed += mobile_failed
            base_result["claimed"] = total_claimed
            base_result["failed"] = total_failed
            # 记录手机领取时间
            update_account(phone, last_mobile_claim=now)

    # ── 翻译领取 ──
    if run_translate:
        logger.info("[%s] 进入翻译领取检查 (last_translate_claim=%.0f, now=%.0f, diff=%.0f)", 
                    phone, account.last_translate_claim, time.time(), time.time() - account.last_translate_claim)
        now2 = time.time()
        _report(progress_callback, phone, "translate", "开始翻译领取")
        translate_claimed, translate_failed = _claim_translate_phase(
            client, settings, phone, progress_callback,
        )
        total_claimed += translate_claimed
        total_failed += translate_failed
        base_result["claimed"] = total_claimed
        base_result["failed"] = total_failed
        update_account(phone, last_translate_claim=now2)

    # 判断最终状态
    if total_failed > 0 and total_claimed == 0:
        base_result["status"] = STATUS_ERROR
        base_result["error_msg"] = base_result["error_msg"] or "所有回调均失败"
    else:
        base_result["status"] = STATUS_OK

    # 最终进度上报
    _report(progress_callback, phone, "done", "领取完成",
            current=total, total=total,
            vip_before=vip_before, vip_after=vip_after)

    _save_claim_record(account.id, base_result, source=source)
    return base_result


# ── 单 business 领取阶段 ──────────────────────────────────────────

def _claim_business_phase(
    client: ApiClient,
    business: int,
    settings: dict,
    phone: str,
    progress_callback: Callable | None = None,
) -> tuple[int, int]:
    """对单个 business 类型执行回调循环。

    与 etalien-auto 对齐：基于全局未观看广告数量判断进度，不再将 business 与 level 绑定。

    循环逻辑:
    1. fetch_pc_ad_config() → 统计全局 unwatched_before
    2. unwatched_before == 0 → 全部完成，退出
    3. pc_ad_callback_backup(AD_ID, business) → 仅用 business 作为请求参数
    4. sleep(request_interval)
    5. 再次 fetch_pc_ad_config() → 统计 unwatched_after
    6. unwatched_after < unwatched_before → 有进展，重置 stalled_rounds
    7. unwatched_after == unwatched_before → stalled_rounds += 1
    8. 连续 MAX_STALLED_ROUNDS 轮无进展 → 退出（防死循环）

    Returns:
        (claimed 成功次数, failed 失败次数)
    """
    claimed = 0
    failed = 0
    stalled_rounds = 0
    round_num = 0
    request_interval = settings.get("request_interval", 1.0)
    max_rounds = settings.get("max_rounds", 21)

    while round_num < max_rounds:
        # 检查 token
        if not client.get_auth_token():
            logger.warning("[%s] Token 无效，停止领取 business=%d", phone, business)
            break

        # 查任务 → 统计全局未观看数量
        config = client.fetch_pc_ad_config()
        if config.get("_error"):
            logger.warning("[%s] 获取任务列表失败 business=%d: %s", phone, business, config.get("msg"))
            failed += 1
            continue

        tasks = config.get("list", [])
        unwatched_before = get_unwatched_count(tasks)

        # 全局所有广告都已观看，退出
        if unwatched_before == 0:
            logger.info("[%s] business=%d 全局广告已全部观看，退出", phone, business)
            break

        round_num += 1

        # 发送回调 — business 仅作为请求参数
        logger.info(
            "[%s] business=%d round=%d unwatched_before=%d stalled=%d → 发送回调",
            phone, business, round_num, unwatched_before, stalled_rounds,
        )
        _report(progress_callback, phone, f"b{business}_r{round_num}",
                f"business={business} 第{round_num}轮 (unwatched={unwatched_before})")

        result = client.pc_ad_callback_backup(AD_ID, business)
        is_verify = bool(result.get("is_verify", False))

        if result.get("_error"):
            if _is_auth_error(result):
                client.clear_auth_token()
                failed += 1
                logger.warning("[%s] business=%d 认证错误，退出", phone, business)
                break
            logger.warning("[%s] 回调失败 business=%d round=%d: %s", phone, business, round_num, result.get("msg"))
            failed += 1
        elif is_verify:
            claimed += 1
            logger.info("[%s] business=%d round=%d is_verify=True claimed=%d", phone, business, round_num, claimed)
        else:
            failed += 1
            logger.info("[%s] business=%d round=%d is_verify=False failed=%d", phone, business, round_num, failed)

        # 等待间隔
        time.sleep(request_interval)

        # 再查任务 → 比较全局未观看数量变化
        config2 = client.fetch_pc_ad_config()
        if config2.get("_error"):
            logger.warning("[%s] 获取任务列表失败 business=%d (after callback)", phone, business)
            continue

        tasks2 = config2.get("list", [])
        unwatched_after = get_unwatched_count(tasks2)

        logger.info(
            "[%s] business=%d round=%d unwatched_before=%d unwatched_after=%d is_verify=%s stalled=%d",
            phone, business, round_num, unwatched_before, unwatched_after, is_verify, stalled_rounds,
        )

        if unwatched_after < unwatched_before:
            stalled_rounds = 0  # 有进展，重置
        else:
            stalled_rounds += 1
            logger.info(
                "[%s] business=%d round=%d 无进展 stalled=%d/%d",
                phone, business, round_num, stalled_rounds, MAX_STALLED_ROUNDS,
            )
            if stalled_rounds >= MAX_STALLED_ROUNDS:
                _report(progress_callback, phone, f"b{business}",
                        f"business={business} 连续{MAX_STALLED_ROUNDS}轮无进展，停止")
                logger.info("[%s] business=%d 连续%d轮无进展，停止", phone, business, MAX_STALLED_ROUNDS)
                break

    return claimed, failed


# ── 手机端领取阶段 ──────────────────────────────────────────────

def _claim_mobile_phase(
    client: ApiClient,
    settings: dict,
    phone: str,
    progress_callback: Callable | None = None,
) -> tuple[int, int]:
    """手机端广告领取阶段。

    与 PC 端独立：使用 MOBILE_AD_ID 和 MOBILE_BUSINESS，数据源为
    fetch_mobile_ad_activity() 而非 fetch_pc_ad_config()。

    循环逻辑:
    1. fetch_mobile_ad_activity() → video_bar
    2. 统计 has_award=True 且 is_get=False 的待领取任务数
    3. pending == 0 → 全部完成，退出
    4. 发送 pc_ad_callback_backup(MOBILE_AD_ID, MOBILE_BUSINESS)
    5. 等待后重新获取 activity，统计 pending_after
    6. pending_after < pending_before → 有进展，重置 stalled
    7. 连续 MAX_STALLED_ROUNDS 轮无进展 → 退出

    Returns:
        (claimed 成功次数, failed 失败次数)
    """
    claimed = 0
    failed = 0
    stalled_rounds = 0
    round_num = 0
    request_interval = settings.get("request_interval", 1.0)
    # 手机端最大轮数比 PC 端少（通常 7 个广告）
    mobile_max_rounds = settings.get("mobile_max_rounds", 21)

    while round_num < mobile_max_rounds:
        if not client.get_auth_token():
            logger.warning("[%s] Token 无效，停止手机端领取", phone)
            break

        # 查手机端广告任务
        activity = client.fetch_mobile_ad_activity()
        if activity.get("_error"):
            if _is_auth_error(activity):
                client.clear_auth_token()
                logger.warning("[%s] 手机端认证错误，退出", phone)
                break
            logger.warning("[%s] 获取手机端任务失败: %s", phone, activity.get("msg"))
            failed += 1
            continue

        video_bar = activity.get("video_bar", [])
        pending_before = len([t for t in video_bar if t.get("has_award") and not t.get("is_get")])

        if pending_before == 0:
            logger.info("[%s] 手机端广告已全部领取，退出", phone)
            _report(progress_callback, phone, "mobile_done", "手机端广告已全部领取")
            break

        round_num += 1
        logger.info(
            "[%s] mobile round=%d pending_before=%d stalled=%d → 发送回调",
            phone, round_num, pending_before, stalled_rounds,
        )
        _report(progress_callback, phone, f"m_r{round_num}",
                f"手机端第{round_num}轮 (pending={pending_before})")

        result = client.pc_ad_callback_backup(MOBILE_AD_ID, MOBILE_BUSINESS)
        is_verify = bool(result.get("is_verify", False))

        if result.get("_error"):
            if _is_auth_error(result):
                client.clear_auth_token()
                failed += 1
                logger.warning("[%s] 手机端认证错误，退出", phone)
                break
            logger.warning("[%s] 手机端回调失败 round=%d: %s", phone, round_num, result.get("msg"))
            failed += 1
        elif is_verify:
            claimed += 1
            logger.info("[%s] mobile round=%d is_verify=True claimed=%d", phone, round_num, claimed)
        else:
            failed += 1
            logger.info("[%s] mobile round=%d is_verify=False failed=%d", phone, round_num, failed)

        time.sleep(request_interval)

        # 再查手机端任务
        activity2 = client.fetch_mobile_ad_activity()
        if activity2.get("_error"):
            logger.warning("[%s] 获取手机端任务失败 round=%d", phone, round_num)
            continue

        video_bar2 = activity2.get("video_bar", [])
        pending_after = len([t for t in video_bar2 if t.get("has_award") and not t.get("is_get")])

        logger.info(
            "[%s] mobile round=%d pending_before=%d pending_after=%d is_verify=%s stalled=%d",
            phone, round_num, pending_before, pending_after, is_verify, stalled_rounds,
        )

        if pending_after < pending_before:
            stalled_rounds = 0
        else:
            stalled_rounds += 1
            logger.info(
                "[%s] mobile round=%d 无进展 stalled=%d/%d",
                phone, round_num, stalled_rounds, MAX_STALLED_ROUNDS,
            )
            if stalled_rounds >= MAX_STALLED_ROUNDS:
                _report(progress_callback, phone, "mobile_stalled",
                        f"手机端连续{MAX_STALLED_ROUNDS}轮无进展，停止")
                logger.info("[%s] 手机端连续%d轮无进展，停止", phone, MAX_STALLED_ROUNDS)
                break

    return claimed, failed


# ── 翻译领取阶段 ──────────────────────────────────────────────

def _claim_translate_phase(
    client: ApiClient,
    settings: dict,
    phone: str,
    progress_callback: Callable | None = None,
) -> tuple[int, int]:
    """翻译广告领取阶段。

    基于 translate/ad/config 的多阶段广告进度循环领取。
    翻译广告共 4 个阶段 (1+4+5+5=15)，每轮发一次 callback，
    通过 config 的 is_watch 统计全局进度决定是否继续。

    循环逻辑:
    1. fetch_translate_ad_config() → 统计 watched_before / total / unwatched_before
    2. unwatched_before == 0 → 全部完成，退出
    3. pc_ad_callback_backup(TRANSLATE_AD_ID, TRANSLATE_BUSINESS)
    4. sleep(request_interval)
    5. 再次 fetch_translate_ad_config() → 统计 watched_after
    6. watched_after > watched_before → 有进展，重置 stalled_rounds
    7. watched_after == watched_before → stalled_rounds += 1
    8. 连续 translate_retry_limit 轮无进展 → 退出（防死循环）

    Returns:
        (claimed 成功次数, failed 失败次数)
    """
    claimed = 0
    failed = 0
    stalled_rounds = 0
    round_num = 0
    request_interval = settings.get("request_interval", 1.0)
    translate_max_rounds = max(1, int(settings.get("translate_max_rounds", 20)))
    translate_retry_limit = max(1, int(settings.get("translate_retry_limit", 3)))
    logger.info("[%s] translate_max_rounds=%d translate_retry_limit=%d",
                phone, translate_max_rounds, translate_retry_limit)

    while round_num < translate_max_rounds:
        if not client.get_auth_token():
            logger.warning("[%s] Token 无效，停止翻译领取", phone)
            break

        # 1. 查询翻译广告配置 → 统计进度
        config = client.fetch_translate_ad_config()
        if config.get("_error"):
            if _is_auth_error(config):
                client.clear_auth_token()
                logger.warning("[%s] 翻译认证错误，退出", phone)
                break
            logger.warning("[%s] 获取翻译任务失败: %s", phone, config.get("msg"))
            failed += 1
            continue

        tasks = config.get("list", [])
        watched_before, total_items = get_ad_progress_from_config(config)
        unwatched_before = total_items - watched_before

        # 打印各阶段详情
        level_counts = [len(_get_level_items(lv)) for lv in tasks]
        level_watched = [
            sum(1 for it in _get_level_items(lv) if bool(it.get("is_watch", False)))
            for lv in tasks
        ]
        logger.info(
            "[%s] translate levels=%d counts=%s watched=%s progress=%d/%d",
            phone, len(tasks), level_counts, level_watched, watched_before, total_items,
        )

        # 全部已观看，退出
        if unwatched_before == 0:
            logger.info("[%s] 翻译广告已全部观看 (%d/%d)，退出", phone, watched_before, total_items)
            _report(progress_callback, phone, "translate_done",
                    f"翻译广告已全部完成 ({watched_before}/{total_items})",
                    current=watched_before, total=total_items)
            break

        round_num += 1
        logger.info(
            "[%s] translate round=%d watched=%d/%d unwatched=%d stalled=%d → 发送回调",
            phone, round_num, watched_before, total_items, unwatched_before, stalled_rounds,
        )
        _report(progress_callback, phone, f"t_r{round_num}",
                f"翻译第{round_num}轮 (progress={watched_before}/{total_items})",
                current=watched_before, total=total_items)

        # 2. 发送回调
        result = client.pc_ad_callback_backup(TRANSLATE_AD_ID, TRANSLATE_BUSINESS)
        is_verify = bool(result.get("is_verify", False))
        logger.info("[%s] translate round=%d callback is_verify=%s", phone, round_num, is_verify)

        if result.get("_error"):
            if _is_auth_error(result):
                client.clear_auth_token()
                failed += 1
                logger.warning("[%s] 翻译认证错误，退出", phone)
                break
            logger.warning("[%s] 翻译回调失败 round=%d: %s", phone, round_num, result.get("msg"))
            failed += 1
        elif not is_verify:
            failed += 1
            logger.info("[%s] translate round=%d is_verify=False failed=%d", phone, round_num, failed)

        time.sleep(request_interval)

        # 3. 再次查询配置 → 比较进度变化
        config2 = client.fetch_translate_ad_config()
        if config2.get("_error"):
            logger.warning("[%s] 获取翻译任务失败 round=%d (after callback)", phone, round_num)
            continue

        watched_after, _ = get_ad_progress_from_config(config2)
        logger.info("[%s] translate round=%d watched_after=%d (before=%d)",
                   phone, round_num, watched_after, watched_before)

        if watched_after > watched_before:
            gained = watched_after - watched_before
            claimed += gained
            stalled_rounds = 0
            logger.info("[%s] translate round=%d 进展 +%d (%d→%d)",
                       phone, round_num, gained, watched_before, watched_after)
            _report(progress_callback, phone, f"t_r{round_num}",
                    f"翻译进展 +{gained} ({watched_before}→{watched_after})",
                    current=watched_after, total=total_items)
        else:
            stalled_rounds += 1
            logger.info("[%s] translate round=%d 无进展 stalled=%d/%d",
                       phone, round_num, stalled_rounds, translate_retry_limit)
            if stalled_rounds >= translate_retry_limit:
                _report(progress_callback, phone, "translate_stalled",
                        f"翻译连续{translate_retry_limit}轮无进展，停止")
                logger.info("[%s] 翻译连续%d轮无进展，停止", phone, translate_retry_limit)
                break

    # 最终校验：打印翻译次数
    try:
        final = client.fetch_translate_product()
        if not final.get("_error"):
            final_count = _safe_parse_translate_count(final)
            logger.info("[%s] translate final translate_count=%d", phone, final_count)
    except Exception:
        pass

    return claimed, failed

# ── 多账号并发领取 ────────────────────────────────────────────────

def run_concurrent_claim(
    accounts: list[Account],
    settings: dict[str, Any] | None = None,
    progress_callback: Callable | None = None,
    source: str = "service",
    target: str = "all",
) -> list[dict[str, Any]]:
    """并发领取多个账号。

    Args:
        accounts: 已启用的账号列表。
        settings: 设置 dict。
        progress_callback: 进度回调。
        source: 来源标识（"service" 或 "gui"），传递给 claim_for_account。
        target: 领取目标（"all" / "pc" / "mobile"）。

    Returns:
        结果列表（完成顺序，非提交顺序）。
    """
    if settings is None:
        settings = get_settings()

    max_workers = min(settings.get("max_concurrent", 10), len(accounts))
    results = []

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_account = {
            executor.submit(claim_for_account, acc, settings, progress_callback, source, target): acc
            for acc in accounts
        }
        for future in as_completed(future_to_account):
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                acc = future_to_account[future]
                logger.error("领取异常 (%s): %s", acc.phone, e)
                results.append({
                    "phone": acc.phone,
                    "status": STATUS_ERROR,
                    "vip_before": 0,
                    "vip_after": 0,
                    "claimed": 0,
                    "failed": 0,
                    "error_msg": str(e),
                })

    return results


# ── 辅助函数 ──────────────────────────────────────────────────────

def _report(callback: Callable | None, phone: str, step: str, detail: str, **extra) -> None:
    """调用进度回调（如果提供）。

    支持通过 **extra 传递额外的进度信息（current, total, vip_before 等），
    向下兼容仅接受 (phone, step, detail) 的回调函数。
    """
    if callback:
        try:
            callback(phone, step, detail, **extra)
        except TypeError:
            # 旧回调不接受 **extra，降级调用
            callback(phone, step, detail)
        except Exception as e:
            logger.warning("进度回调异常: %s", e)


def _get_level_items(level: dict) -> list:
    """获取 level 中的广告 item 列表，兼容 items 和 list 两种字段名。

    etalien-auto 的 client.py 手动构建 dict 时把 protobuf 的 list 字段重命名为 items；
    etalien_daily 的 client.py 使用 preserving_proto_field_name=True 保留原名字 list。
    此函数兼容两种格式。
    """
    return level.get("items") or level.get("list") or []


def get_unwatched_count(tasks: list) -> int:
    """统计所有 level 中未观看广告的总数（全局计数）。

    遍历所有 level 的所有 item，统计 is_watch 为 False 的数量。
    """
    return sum(
        1
        for level in tasks
        for item in _get_level_items(level)
        if not bool(item.get("is_watch", False))
    )


def get_ad_progress_from_config(config: dict) -> tuple[int, int]:
    """从广告任务配置中提取 (已观看数, 总数)。

    兼容 etalien-auto (level["items"]) 和 etalien-daily (level["list"]) 两种字段名，
    基于每条 item 的 is_watch 字段统计。
    """
    tasks = config.get("list", [])
    total = 0
    watched = 0
    for level in tasks:
        items = _get_level_items(level)
        total += len(items)
        watched += sum(1 for item in items if bool(item.get("is_watch", False)))
    return watched, total


def _safe_parse_translate_count(product: dict) -> int:
    """从翻译产品响应中安全解析 translate_count。

    MessageToDict 会将 protobuf int64 转为字符串（如 "7"），
    本函数处理字符串、int、缺失、空字符串、非法值等情况，
    始终返回 int，不抛异常。

    Args:
        product: fetch_translate_product() 的返回 dict

    Returns:
        翻译次数（int），解析失败返回 0
    """
    if not product or not isinstance(product, dict):
        return 0
    raw = product.get("expire_time", 0)
    try:
        count = int(raw)
    except (TypeError, ValueError):
        logger.warning("_safe_parse_translate_count: 无法解析 expire_time=%r，返回 0", raw)
        return 0
    return max(0, count)


def _is_auth_error(result: dict) -> bool:
    """判断响应是否为认证错误。"""
    if not result.get("_error"):
        return False
    return result.get("code") in (16, 401, 403)


def _all_ads_watched(config: dict) -> bool:
    """检查所有广告是否都已观看（基于全局 is_watch 字段）。"""
    return get_unwatched_count(config.get("list", [])) == 0


def _save_claim_record(account_id: int, result: dict, source: str = "service") -> None:
    """保存领取记录到数据库。"""
    try:
        detail = result.get("error_msg", "")
        if result["status"] == STATUS_OK:
            detail = f"成功{result.get('claimed', 0)}次,失败{result.get('failed', 0)}次"
        elif result["status"] == STATUS_ALREADY_DONE:
            detail = "所有广告已观看完毕"
        add_claim_record(
            account_id=account_id,
            status=result["status"],
            vip_before=result.get("vip_before", 0),
            vip_after=result.get("vip_after", 0),
            claimed_count=result.get("claimed", 0),
            failed_count=result.get("failed", 0),
            source=source,
            detail=detail,
        )
    except Exception as e:
        logger.warning("保存领取记录失败: %s", e)
