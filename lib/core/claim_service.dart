/// 业务逻辑层（对照 v1 service.py）。
///
/// 编排完整的领取流程：
/// - 单账号领取: claimForAccount()
/// - 并发领取: runConcurrentClaim()
/// - 防死循环 + 认证错误检测 + 进度回调
library;

import 'dart:async';
import 'dart:math';

import 'api_client.dart';
import 'database.dart';
import 'proto/apiv2.pb.dart';

// ── 常量 ──────────────────────────────────────────────────────────

const String kAdId = '103334281'; // 固定广告 ID（PC）
const List<int> kBusinessTypes = [1, 2, 3]; // 三种广告业务类型
const int kMaxStalledRounds = 3; // 连续无进展最大轮数（防死循环）
const Duration kBusinessSleep = Duration(seconds: 3); // 业务类型切换间隔

// 手机端常量
const String kMobileAdId = '102815305';
const int kMobileBusiness = 2;

// 翻译端常量
const String kTranslateAdId = '103579416';
const int kTranslateBusiness = 3;

/// 手机端领取间隔（3 天，秒）。
const double kMobileClaimInterval = 259200;

// ── 结果状态 ──────────────────────────────────────────────────────

const String statusOk = 'ok';
const String statusAlreadyDone = 'already_done';
const String statusAuthError = 'auth_error';
const String statusNeedLogin = 'need_login';
const String statusError = 'error';
const String statusSkipped = 'skipped';

/// 当前按钮目标是否匹配账号勾选的 PC 范围。
bool shouldRunPc(Account account, String target) =>
    account.claimPc && (target == 'all' || target == 'pc');

/// 当前按钮目标是否匹配账号勾选的手机范围。
bool shouldRunMobile(Account account, String target) =>
    account.claimMobile && (target == 'all' || target == 'mobile');

/// 当前按钮目标是否匹配账号勾选的翻译范围。
bool shouldRunTranslate(Account account, String target) =>
    account.claimTranslate && (target == 'all' || target == 'translate');

/// 计算 callback 间等待时长：基础间隔 ±1 秒，最低为 0。
Duration jitteredCallbackDelay(Duration base, Random random) {
  final jitterMs = random.nextInt(2001) - 1000;
  return Duration(milliseconds: max(0, base.inMilliseconds + jitterMs));
}

/// 日志输出（可替换；默认 print）。
void Function(String message) logger = print;

void _log(String msg) {
  try {
    logger(msg);
  } catch (_) {}
}

// ── 数据类型 ──────────────────────────────────────────────────────

/// 单账号领取结果。
class ClaimResult {
  ClaimResult({
    required this.phone,
    this.status = statusError,
    this.vipBefore = 0,
    this.vipAfter = 0,
    this.claimed = 0,
    this.failed = 0,
    this.errorMsg,
  });

  String phone;
  String status;
  int vipBefore;
  int vipAfter;
  int claimed;
  int failed;
  String? errorMsg;

  Map<String, Object?> toMap() => {
        'phone': phone,
        'status': status,
        'vip_before': vipBefore,
        'vip_after': vipAfter,
        'claimed': claimed,
        'failed': failed,
        'error_msg': errorMsg,
      };
}

/// 进度事件。
class ProgressEvent {
  const ProgressEvent({
    required this.phone,
    required this.step,
    required this.detail,
    this.current,
    this.total,
    this.vipBefore,
    this.vipAfter,
  });

  final String phone;
  final String step;
  final String detail;
  final int? current;
  final int? total;
  final int? vipBefore;
  final int? vipAfter;
}

typedef ProgressCallback = void Function(ProgressEvent event);

void _report(
  ProgressCallback? callback,
  String phone,
  String step,
  String detail, {
  int? current,
  int? total,
  int? vipBefore,
  int? vipAfter,
}) {
  if (callback == null) return;
  try {
    callback(ProgressEvent(
      phone: phone,
      step: step,
      detail: detail,
      current: current,
      total: total,
      vipBefore: vipBefore,
      vipAfter: vipAfter,
    ));
  } catch (e) {
    _log('进度回调异常: $e');
  }
}

// ── 客户端初始化 ──────────────────────────────────────────────────

/// 为账号初始化 ApiClient。
///
/// - 如果账号有 token，验证其有效性
/// - 如果 token 过期或无 token，尝试用已存密码自动登录
///
/// 返回 ApiClient 实例；其 token 可能为空（调用方需检查）。
Future<ApiClient> initClient(Account account) async {
  final client = ApiClient(
    deviceId: account.deviceId,
    authToken: account.authToken,
  );

  // 如果有 token，验证有效性
  if (account.authToken != null && account.authToken!.isNotEmpty) {
    if (await client.checkTokenValid()) {
      _log('Token 有效: ${account.phone}');
      return client;
    }
    _log('Token 已过期: ${account.phone}');
    client.clearAuthToken();
  }

  // Token 无效或无 token，尝试密码自动登录
  if (account.password.isNotEmpty) {
    _log('尝试密码自动登录: ${account.phone}');
    final result = await client.loginByPassword(account.phone, account.password);
    final data = result.data;
    if (result.isError || data == null) {
      _log('密码自动登录失败 (${account.phone}): ${result.msg}');
    } else {
      _log('密码自动登录成功 (${account.phone}), user_id=${data.userId}');
      await updateAccountToken(
        account.phone,
        data.authorization,
        data.userId.toInt(),
      );
      return client;
    }
  }

  return client;
}

// ── 单账号领取 ────────────────────────────────────────────────────

/// 对单个账号执行完整领取流程。
///
/// [target] 领取目标："all" 按账号勾选范围，或 "pc" / "mobile" / "translate" 快捷过滤。
/// [source] 来源标识（"service" 或 "gui"），影响数据库记录的 source 字段。
Future<ClaimResult> claimForAccount(
  Account account, {
  Settings? settings,
  ProgressCallback? progressCallback,
  String source = 'service',
  String target = 'all',
}) async {
  final s = settings ?? await getSettings();
  final phone = account.phone;
  final result = ClaimResult(phone: phone);

  final runPc = shouldRunPc(account, target);
  final runMobile = shouldRunMobile(account, target);
  final runTranslate = shouldRunTranslate(account, target);
  if (!runPc && !runMobile && !runTranslate) {
    result
      ..status = statusSkipped
      ..errorMsg = '未配置该领取范围';
    return result;
  }

  // 1. 初始化客户端
  _report(progressCallback, phone, 'init', '初始化客户端');
  final client = await initClient(account);

  if (client.authToken == null || client.authToken!.isEmpty) {
    result.status = statusNeedLogin;
    result.errorMsg = '未登录或 token 已过期';
    return result;
  }

  var totalClaimed = 0;
  var totalFailed = 0;
  var total = 0;

  // ── PC 端领取 ──
  if (runPc) {
    // 2. 查询领取前 VIP 时长
    _report(progressCallback, phone, 'before', '查询当前时长');
    final before = await client.fetchPcDuration();
    if (before.isError || before.data == null) {
      if (before.isAuthError) {
        result.status = statusAuthError;
        result.errorMsg = 'token 已过期';
        return result;
      }
      result.errorMsg = '查询时长失败: ${before.msg}';
      return result;
    }
    result.vipBefore = before.data!.vipDurationSecond.toInt();

    // 3. 获取广告任务列表
    _report(progressCallback, phone, 'config', '获取广告任务');
    final config = await client.fetchPcAdConfig();
    if (config.isError || config.data == null) {
      result.errorMsg = '获取任务列表失败: ${config.msg}';
      return result;
    }

    // 上报初始广告进度
    final (watched, totalCount) = getAdProgress(config.data!);
    total = totalCount;
    _report(
      progressCallback,
      phone,
      'config',
      '获取广告任务 ($watched/$total)',
      current: watched,
      total: total,
    );

    // 检查是否全部已完成
    if (getUnwatchedCount(config.data!) == 0) {
      _report(
        progressCallback,
        phone,
        'done',
        '所有广告已观看完毕',
        current: total,
        total: total,
        vipBefore: result.vipBefore,
        vipAfter: result.vipBefore,
      );
      result.status = statusAlreadyDone;
      result.vipAfter = result.vipBefore;
      await _saveClaimRecord(account.id, result, source);
      return result;
    }

    // 4. 对每种 business 逐一领取
    for (var idx = 0; idx < kBusinessTypes.length; idx++) {
      final business = kBusinessTypes[idx];
      if (idx > 0) {
        await Future<void>.delayed(kBusinessSleep);
      }

      _report(
        progressCallback,
        phone,
        'business_$business',
        '领取 business=$business',
      );

      final (claimed, failed) = await _claimBusinessPhase(
        client,
        business,
        s,
        phone,
        progressCallback,
      );

      totalClaimed += claimed;
      totalFailed += failed;
    }

    result.claimed = totalClaimed;
    result.failed = totalFailed;

    // 5. 查询领取后 VIP 时长
    _report(progressCallback, phone, 'after', '查询领取后时长');
    final after = await client.fetchPcDuration();
    if (after.isError) {
      if (after.isAuthError) {
        result.status = statusAuthError;
        result.errorMsg = '领取后 token 过期';
        await _saveClaimRecord(account.id, result, source);
        return result;
      }
    } else if (after.data != null) {
      result.vipAfter = after.data!.vipDurationSecond.toInt();
    }
  }

  // ── 手机端领取 ──
  if (runMobile) {
    // 每 3 天执行一次
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (account.lastMobileClaim > 0 &&
        (now - account.lastMobileClaim) < kMobileClaimInterval) {
      _log('[$phone] 距上次手机领取不足3天，跳过');
      _report(progressCallback, phone, 'mobile_skip', '手机端距上次不足3天，跳过');
    } else {
      _report(progressCallback, phone, 'mobile', '开始手机端领取');
      final (claimed, failed) = await _claimMobilePhase(
        client,
        s,
        phone,
        progressCallback,
      );
      totalClaimed += claimed;
      totalFailed += failed;
      result.claimed = totalClaimed;
      result.failed = totalFailed;
      // 记录手机领取时间
      await updateAccount(phone, lastMobileClaim: now);
    }
  }

  // ── 翻译领取 ──
  if (runTranslate) {
    final now2 = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _report(progressCallback, phone, 'translate', '开始翻译领取');
    final (claimed, failed) = await _claimTranslatePhase(
      client,
      s,
      phone,
      progressCallback,
    );
    totalClaimed += claimed;
    totalFailed += failed;
    result.claimed = totalClaimed;
    result.failed = totalFailed;
    await updateAccount(phone, lastTranslateClaim: now2);
  }

  // 判断最终状态
  if (totalFailed > 0 && totalClaimed == 0) {
    result.status = statusError;
    result.errorMsg = result.errorMsg ?? '所有回调均失败';
  } else {
    result.status = statusOk;
  }

  // 最终进度上报
  _report(
    progressCallback,
    phone,
    'done',
    '领取完成',
    current: total,
    total: total,
    vipBefore: result.vipBefore,
    vipAfter: result.vipAfter,
  );

  await _saveClaimRecord(account.id, result, source);
  return result;
}

// ── 单 business 领取阶段 ──────────────────────────────────────────

/// 对单个 business 类型执行回调循环。
///
/// 循环逻辑:
/// 1. fetchPcAdConfig() → 统计全局 unwatchedBefore
/// 2. unwatchedBefore == 0 → 全部完成，退出
/// 3. pcAdCallbackBackup(AD_ID, business) → 仅用 business 作为请求参数
/// 4. sleep(backupRequestInterval)
/// 5. 再次 fetchPcAdConfig() → 统计 unwatchedAfter
/// 6. unwatchedAfter < unwatchedBefore → 有进展，重置 stalledRounds
/// 7. 连续 kMaxStalledRounds 轮无进展 → 退出（防死循环）
Future<(int, int)> _claimBusinessPhase(
  ApiClient client,
  int business,
  Settings settings,
  String phone,
  ProgressCallback? progressCallback,
) async {
  var claimed = 0;
  var failed = 0;
  var stalledRounds = 0;
  var roundNum = 0;
  final backupRequestInterval =
      Duration(milliseconds: (settings.backupRequestInterval * 1000).round());
  final maxRounds = settings.maxRounds;
  final random = Random();

  while (roundNum < maxRounds) {
    // 检查 token
    if (client.authToken == null) {
      _log('[$phone] Token 无效，停止领取 business=$business');
      break;
    }

    // 查任务 → 统计全局未观看数量
    final config = await client.fetchPcAdConfig();
    if (config.isError || config.data == null) {
      _log('[$phone] 获取任务列表失败 business=$business: ${config.msg}');
      failed += 1;
      continue;
    }

    final unwatchedBefore = getUnwatchedCount(config.data!);

    // 全局所有广告都已观看，退出
    if (unwatchedBefore == 0) {
      _log('[$phone] business=$business 全局广告已全部观看，退出');
      break;
    }

    roundNum += 1;

    _log('[$phone] business=$business round=$roundNum '
        'unwatched_before=$unwatchedBefore stalled=$stalledRounds → 发送回调');
    _report(
      progressCallback,
      phone,
      'b${business}_r$roundNum',
      'business=$business 第$roundNum轮 (unwatched=$unwatchedBefore)',
    );

    final result = await client.pcAdCallbackBackup(kAdId, business);
    final isVerify = result.data?.isVerify ?? false;

    if (result.isError) {
      if (result.isAuthError) {
        client.clearAuthToken();
        failed += 1;
        _log('[$phone] business=$business 认证错误，退出');
        break;
      }
      _log('[$phone] 回调失败 business=$business round=$roundNum: ${result.msg}');
      failed += 1;
    } else if (isVerify) {
      claimed += 1;
    } else {
      failed += 1;
    }

    // 等待间隔
    await Future<void>.delayed(
      jitteredCallbackDelay(backupRequestInterval, random),
    );

    // 再查任务 → 比较全局未观看数量变化
    final config2 = await client.fetchPcAdConfig();
    if (config2.isError || config2.data == null) {
      _log('[$phone] 获取任务列表失败 business=$business (after callback)');
      continue;
    }

    final unwatchedAfter = getUnwatchedCount(config2.data!);

    if (unwatchedAfter < unwatchedBefore) {
      stalledRounds = 0; // 有进展，重置
    } else {
      stalledRounds += 1;
      if (stalledRounds >= kMaxStalledRounds) {
        _report(
          progressCallback,
          phone,
          'b$business',
          'business=$business 连续$kMaxStalledRounds轮无进展，停止',
        );
        _log('[$phone] business=$business 连续$kMaxStalledRounds轮无进展，停止');
        break;
      }
    }
  }

  return (claimed, failed);
}

// ── 手机端领取阶段 ──────────────────────────────────────────────

/// 手机端广告领取阶段。
///
/// 与 PC 端独立：使用 kMobileAdId 和 kMobileBusiness，数据源为
/// fetchMobileAdActivity() 而非 fetchPcAdConfig()。
Future<(int, int)> _claimMobilePhase(
  ApiClient client,
  Settings settings,
  String phone,
  ProgressCallback? progressCallback,
) async {
  var claimed = 0;
  var failed = 0;
  var stalledRounds = 0;
  var roundNum = 0;
  final backupRequestInterval =
      Duration(milliseconds: (settings.backupRequestInterval * 1000).round());
  final mobileMaxRounds = settings.mobileMaxRounds;
  final random = Random();

  int countPending(AdActivityResponse activity) => activity.videoBar
      .where((t) => t.hasAward && !t.isGet)
      .length;

  while (roundNum < mobileMaxRounds) {
    if (client.authToken == null) {
      _log('[$phone] Token 无效，停止手机端领取');
      break;
    }

    // 查手机端广告任务
    final activity = await client.fetchMobileAdActivity();
    if (activity.isError || activity.data == null) {
      if (activity.isAuthError) {
        client.clearAuthToken();
        _log('[$phone] 手机端认证错误，退出');
        break;
      }
      _log('[$phone] 获取手机端任务失败: ${activity.msg}');
      failed += 1;
      continue;
    }

    final data = activity.data!;
    final pendingBefore = countPending(data);
    final mobileTotal = data.videoBar.where((t) => t.hasAward).length;
    final mobileCurrentBefore = mobileTotal - pendingBefore;

    if (pendingBefore == 0) {
      _log('[$phone] 手机端广告已全部领取，退出');
      _report(
        progressCallback,
        phone,
        'mobile_done',
        '手机端广告已全部领取',
        current: mobileCurrentBefore,
        total: mobileTotal,
      );
      break;
    }

    roundNum += 1;
    _report(
      progressCallback,
      phone,
      'm_r$roundNum',
      '手机端第$roundNum轮 (pending=$pendingBefore)',
      current: mobileCurrentBefore,
      total: mobileTotal,
    );

    final result = await client.pcAdCallbackBackup(kMobileAdId, kMobileBusiness);
    final isVerify = result.data?.isVerify ?? false;

    if (result.isError) {
      if (result.isAuthError) {
        client.clearAuthToken();
        failed += 1;
        _log('[$phone] 手机端认证错误，退出');
        break;
      }
      _log('[$phone] 手机端回调失败 round=$roundNum: ${result.msg}');
      failed += 1;
    } else if (isVerify) {
      claimed += 1;
    } else {
      failed += 1;
    }

    await Future<void>.delayed(
      jitteredCallbackDelay(backupRequestInterval, random),
    );

    // 再查手机端任务
    final activity2 = await client.fetchMobileAdActivity();
    if (activity2.isError || activity2.data == null) {
      _log('[$phone] 获取手机端任务失败 round=$roundNum');
      continue;
    }

    final pendingAfter = countPending(activity2.data!);

    if (pendingAfter < pendingBefore) {
      stalledRounds = 0;
    } else {
      stalledRounds += 1;
      if (stalledRounds >= kMaxStalledRounds) {
        _report(
          progressCallback,
          phone,
          'mobile_stalled',
          '手机端连续$kMaxStalledRounds轮无进展，停止',
          current: mobileCurrentBefore,
          total: mobileTotal,
        );
        _log('[$phone] 手机端连续$kMaxStalledRounds轮无进展，停止');
        break;
      }
    }
  }

  return (claimed, failed);
}

// ── 翻译领取阶段 ──────────────────────────────────────────────

/// 翻译广告领取阶段。
///
/// 基于 translate/ad/config 的多阶段广告进度循环领取。
/// 翻译广告共 4 个阶段 (1+4+5+5=15)，每轮发一次 callback，
/// 通过 config 的 isWatch 统计全局进度决定是否继续。
Future<(int, int)> _claimTranslatePhase(
  ApiClient client,
  Settings settings,
  String phone,
  ProgressCallback? progressCallback,
) async {
  var claimed = 0;
  var failed = 0;
  var stalledRounds = 0;
  var roundNum = 0;
  final backupRequestInterval =
      Duration(milliseconds: (settings.backupRequestInterval * 1000).round());
  final translateMaxRounds = max(1, settings.translateMaxRounds);
  final translateRetryLimit = max(1, settings.translateRetryLimit);
  final random = Random();

  while (roundNum < translateMaxRounds) {
    if (client.authToken == null) {
      _log('[$phone] Token 无效，停止翻译领取');
      break;
    }

    // 1. 查询翻译广告配置 → 统计进度
    final config = await client.fetchTranslateAdConfig();
    if (config.isError || config.data == null) {
      if (config.isAuthError) {
        client.clearAuthToken();
        _log('[$phone] 翻译认证错误，退出');
        break;
      }
      _log('[$phone] 获取翻译任务失败: ${config.msg}');
      failed += 1;
      continue;
    }

    final (watchedBefore, totalItems) = getAdProgress(config.data!);
    final unwatchedBefore = totalItems - watchedBefore;

    // 全部已观看，退出
    if (unwatchedBefore == 0) {
      _log('[$phone] 翻译广告已全部观看 ($watchedBefore/$totalItems)，退出');
      _report(
        progressCallback,
        phone,
        'translate_done',
        '翻译广告已全部完成 ($watchedBefore/$totalItems)',
        current: watchedBefore,
        total: totalItems,
      );
      break;
    }

    roundNum += 1;
    _report(
      progressCallback,
      phone,
      't_r$roundNum',
      '翻译第$roundNum轮 (progress=$watchedBefore/$totalItems)',
      current: watchedBefore,
      total: totalItems,
    );

    // 2. 发送回调
    final result =
        await client.pcAdCallbackBackup(kTranslateAdId, kTranslateBusiness);
    final isVerify = result.data?.isVerify ?? false;

    if (result.isError) {
      if (result.isAuthError) {
        client.clearAuthToken();
        failed += 1;
        _log('[$phone] 翻译认证错误，退出');
        break;
      }
      _log('[$phone] 翻译回调失败 round=$roundNum: ${result.msg}');
      failed += 1;
    } else if (!isVerify) {
      failed += 1;
    }

    await Future<void>.delayed(
      jitteredCallbackDelay(backupRequestInterval, random),
    );

    // 3. 再次查询配置 → 比较进度变化
    final config2 = await client.fetchTranslateAdConfig();
    if (config2.isError || config2.data == null) {
      _log('[$phone] 获取翻译任务失败 round=$roundNum (after callback)');
      continue;
    }

    final (watchedAfter, _) = getAdProgress(config2.data!);

    if (watchedAfter > watchedBefore) {
      final gained = watchedAfter - watchedBefore;
      claimed += gained;
      stalledRounds = 0;
      _report(
        progressCallback,
        phone,
        't_r$roundNum',
        '翻译进展 +$gained ($watchedBefore→$watchedAfter)',
        current: watchedAfter,
        total: totalItems,
      );
    } else {
      stalledRounds += 1;
      if (stalledRounds >= translateRetryLimit) {
        _report(
          progressCallback,
          phone,
          'translate_stalled',
          '翻译连续$translateRetryLimit轮无进展，停止',
        );
        _log('[$phone] 翻译连续$translateRetryLimit轮无进展，停止');
        break;
      }
    }
  }

  // 最终校验：打印翻译次数
  try {
    final product = await client.fetchTranslateCount();
    if (!product.isError && product.data != null) {
      _log(
          '[$phone] translate final translate_count=${max(0, product.data!)}');
    }
  } catch (_) {}

  return (claimed, failed);
}

// ── 多账号并发领取 ────────────────────────────────────────────────

/// 并发领取多个账号（信号量限流，结果为提交顺序）。
Future<List<ClaimResult>> runConcurrentClaim(
  List<Account> accounts, {
  Settings? settings,
  ProgressCallback? progressCallback,
  String source = 'service',
  String target = 'all',
}) async {
  final s = settings ?? await getSettings();
  if (accounts.isEmpty) return [];

  final maxWorkers = min(s.maxConcurrent, accounts.length);
  final semaphore = _Semaphore(maxWorkers);

  final futures = accounts.map((acc) async {
    await semaphore.acquire();
    try {
      return await claimForAccount(
        acc,
        settings: s,
        progressCallback: progressCallback,
        source: source,
        target: target,
      );
    } catch (e) {
      _log('领取异常 (${acc.phone}): $e');
      return ClaimResult(
        phone: acc.phone,
        status: statusError,
        errorMsg: e.toString(),
      );
    } finally {
      semaphore.release();
    }
  });

  return Future.wait(futures);
}

/// 简单的异步信号量。
class _Semaphore {
  _Semaphore(this._count);

  int _count;
  final _queue = <Completer<void>>[];

  Future<void> acquire() {
    if (_count > 0) {
      _count--;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    } else {
      _count++;
    }
  }
}

// ── 辅助函数 ──────────────────────────────────────────────────────

/// 统计所有 level 中未观看广告的总数（全局计数）。
int getUnwatchedCount(PcAdConfigResponse config) => config.list
    .expand((level) => level.list)
    .where((item) => !item.isWatch)
    .length;

/// 从广告任务配置中提取 (已观看数, 总数)。
(int, int) getAdProgress(PcAdConfigResponse config) {
  var total = 0;
  var watched = 0;
  for (final level in config.list) {
    for (final item in level.list) {
      total += 1;
      if (item.isWatch) watched += 1;
    }
  }
  return (watched, total);
}

/// 保存领取记录到数据库。
Future<void> _saveClaimRecord(
  int accountId,
  ClaimResult result,
  String source,
) async {
  if (result.status == statusSkipped) return;
  try {
    var detail = result.errorMsg ?? '';
    if (result.status == statusOk) {
      detail = '成功${result.claimed}次,失败${result.failed}次';
    } else if (result.status == statusAlreadyDone) {
      detail = '所有广告已观看完毕';
    }
    await addClaimRecord(
      accountId,
      result.status,
      vipBefore: result.vipBefore,
      vipAfter: result.vipAfter,
      claimedCount: result.claimed,
      failedCount: result.failed,
      source: source,
      detail: detail,
    );
  } catch (e) {
    _log('保存领取记录失败: $e');
  }
}
