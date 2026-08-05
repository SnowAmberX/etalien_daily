/// 无头领取程序（对照 v1 CLI 的领取路径）。
///
/// 由 Windows Service / schtasks 定时触发，或手动执行：
///   etalien_headless.exe [--scheduled] [--account <phone>] [--target all|pc|mobile|translate]
///   all 按账号配置的领取范围执行；pc/mobile/translate 按对应目标过滤。
///
/// 退出码（对照 v1 main.py）：
///   0 全部成功 / 1 部分成功 / 2 全部失败 / 3 需要登录 / 4 无启用账号 / 5 网络错误
library;

import 'dart:io';

import 'package:etalien_daily/core/claim_service.dart';
import 'package:etalien_daily/core/database.dart';

const int exitAllOk = 0;
const int exitPartial = 1;
const int exitAllFail = 2;
const int exitNeedLogin = 3;
const int exitNoEnabled = 4;
const int exitNetworkError = 5;

Future<void> main(List<String> args) async {
  final accountFilter = _argValue(args, '--account');
  final target = _argValue(args, '--target') ?? 'all';
  final startedAt = DateTime.now();

  // 静默参数当前仅作语义标记（无控制台窗口时 stdout 不可见，写日志文件由
  // 调用方重定向）；保留解析以与 v1 参数兼容。
  final silent = args.contains('--scheduled') || args.contains('--auto-close');
  if (silent) {
    // 预留：后续可切换为文件日志。
  }

  stdout.writeln('etalien-daily headless claim, target=$target'
      '${accountFilter != null ? ', account=$accountFilter' : ''}');

  await initDb();

  final List<Account> accounts;
  if (accountFilter != null) {
    final acc = await getAccount(accountFilter);
    accounts = [
      if (acc != null && acc.enabled) acc,
    ];
  } else {
    accounts = await getAccounts();
  }

  if (accounts.isEmpty) {
    stdout.writeln('没有启用的账号');
    await closeDb();
    exitCode = exitNoEnabled;
    return;
  }

  final results = await runConcurrentClaim(
    accounts,
    source: 'service',
    target: target,
    progressCallback: (e) {
      stdout.writeln('[${e.phone}] ${e.step}: ${e.detail}');
    },
  );

  await closeDb();

  final elapsed = DateTime.now().difference(startedAt).inSeconds;
  for (final r in results) {
    final gained = r.vipAfter - r.vipBefore;
    stdout.writeln(
      '${r.phone}  ${r.status}  '
      'claimed=${r.claimed} failed=${r.failed}  '
      'vip=${r.vipBefore}→${r.vipAfter}${gained > 0 ? ' (+$gained)' : ''}'
      '${r.errorMsg != null ? '  ${r.errorMsg}' : ''}',
    );
  }
  stdout.writeln('耗时 ${elapsed}s');

  exitCode = _determineExitCode(results);
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
  return null;
}

/// 退出码判定（对照 v1 _determine_exit_code）。
int _determineExitCode(List<ClaimResult> results) {
  if (results.isEmpty) return exitNoEnabled;
  final statuses = results.map((r) => r.status).toList();
  if (statuses.contains(statusNeedLogin)) return exitNeedLogin;

  final okCount =
      statuses.where((s) => s == statusOk || s == statusAlreadyDone).length;
  final failCount =
      statuses.where((s) => s == statusAuthError || s == statusError).length;

  if (failCount == results.length) {
    for (final r in results) {
      final msg = (r.errorMsg ?? '').toLowerCase();
      if (msg.contains('connection') ||
          msg.contains('timeout') ||
          msg.contains('network') ||
          msg.contains('max retries')) {
        return exitNetworkError;
      }
    }
    return exitAllFail;
  }
  if (okCount > 0 && failCount > 0) return exitPartial;
  return exitAllOk;
}
