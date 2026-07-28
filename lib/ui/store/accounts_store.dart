/// 账号状态管理（对照 v1 /api/accounts + /api/status）。
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/claim_service.dart';
import '../../core/database.dart';

/// 单个账号的展示状态（对照 v1 _fetch_status 返回字段）。
class AccountStatus {
  AccountStatus({required this.account});

  final Account account;

  bool loggedIn = false;
  bool tokenValid = false;
  bool tokenExpired = false;
  String status = 'need_login'; // ok / all_done / error / need_login
  int vipDuration = 0;
  int freeDuration = 0;
  int current = 0;
  int total = 0;
  int mobileDuration = 0;
  int mobileCurrent = 0;
  int mobileTotal = 0;
  bool mobileError = false;
  int translateCurrent = 0;
  int translateTotal = 0;
  int translateCount = 0;
  bool translateError = false;

  String get phone => account.phone;
  String get name => account.name;
  bool get enabled => account.enabled;
  bool get needsLogin => !loggedIn || !tokenValid;

  double get pcPct => total > 0 ? current / total : 0;
}

class AccountsStore extends ChangeNotifier {
  final List<AccountStatus> accounts = [];
  bool loading = false;
  bool refreshing = false;

  int get totalCount => accounts.length;
  int get enabledCount => accounts.where((a) => a.enabled).length;

  /// 总进度（所有启用账号 PC 进度的平均百分比）。
  int get overallProgress {
    final active =
        accounts.where((a) => a.enabled && a.tokenValid && a.total > 0);
    if (active.isEmpty) return 0;
    final sum = active.fold<double>(0, (s, a) => s + a.pcPct);
    return (sum / active.length * 100).round();
  }

  /// 加载账号列表（仅数据库，无远程状态）。
  Future<void> load() async {
    loading = true;
    notifyListeners();
    final rows = await getAccounts(enabledOnly: false);
    accounts
      ..clear()
      ..addAll(rows.map((a) => AccountStatus(account: a)));
    loading = false;
    notifyListeners();
  }

  /// 并发刷新所有账号的远程状态（对照 v1 /api/status）。
  Future<void> refreshStatus() async {
    if (refreshing) return;
    refreshing = true;
    notifyListeners();

    final list = List<AccountStatus>.of(accounts);
    final maxWorkers = min(list.length, 10);
    var index = 0;
    final workers = List.generate(maxWorkers, (_) async {
      while (index < list.length) {
        final s = list[index++];
        await _fetchStatus(s);
      }
    });
    await Future.wait(workers);

    refreshing = false;
    notifyListeners();
  }

  Future<void> _fetchStatus(AccountStatus s) async {
    final acc = s.account;
    final client = ApiClient(deviceId: acc.deviceId, authToken: acc.authToken);

    s.loggedIn = acc.authToken != null && acc.authToken!.isNotEmpty;
    if (!s.loggedIn) {
      s
        ..tokenValid = false
        ..tokenExpired = false
        ..status = 'need_login';
      notifyListeners();
      return;
    }

    if (!await client.checkTokenValid()) {
      s
        ..tokenValid = false
        ..tokenExpired = true
        ..status = 'need_login';
      notifyListeners();
      return;
    }

    final dur = await client.fetchPcDuration();
    final config = await client.fetchPcAdConfig();

    s
      ..tokenValid = true
      ..tokenExpired = false
      ..vipDuration = dur.data?.vipDurationSecond.toInt() ?? 0
      ..freeDuration = dur.data?.freeDurationSecond.toInt() ?? 0;

    if (config.isError || config.data == null || dur.isError) {
      s.status = 'error';
    } else {
      final (watched, total) = getAdProgress(config.data!);
      s
        ..current = watched
        ..total = total
        ..status = total > 0 && watched >= total ? 'all_done' : 'ok';
    }
    notifyListeners();

    // 手机端（失败不影响主状态）
    try {
      final activity = await client.fetchMobileAdActivity();
      if (!activity.isError && activity.data != null) {
        final bar = activity.data!.videoBar;
        final total = bar.where((t) => t.hasAward).length;
        final pending =
            bar.where((t) => t.hasAward && !t.isGet).length;
        s
          ..mobileTotal = total
          ..mobileCurrent = total - pending;
      } else {
        s.mobileError = true;
      }
    } catch (_) {
      s.mobileError = true;
    }
    try {
      final profile = await client.fetchMyProfile();
      if (!profile.isError && profile.data != null) {
        final data = profile.data!;
        final expire = data.hasMember() ? data.member.expireTime.toInt() : 0;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        s.mobileDuration = max(0, expire - now);
      } else {
        s.mobileError = true;
      }
    } catch (_) {
      s.mobileError = true;
    }
    notifyListeners();

    // 翻译（静默）
    try {
      final tconfig = await client.fetchTranslateAdConfig();
      if (!tconfig.isError && tconfig.data != null) {
        final (tw, tt) = getAdProgress(tconfig.data!);
        s
          ..translateCurrent = tw
          ..translateTotal = tt;
      }
      final product = await client.fetchTranslateProduct();
      if (!product.isError && product.data != null) {
        s.translateCount = max(0, product.data!.expireTime.toInt());
      } else {
        s.translateError = true;
      }
    } catch (_) {
      s.translateError = true;
    }
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────

  /// 添加账号。手机号已存在时抛 [StateError]。
  Future<void> add(String phone, String name, String remark) async {
    if (await getAccount(phone) != null) {
      throw StateError('账号已存在');
    }
    await addAccount(phone, name: name, remark: remark);
    await load();
  }

  Future<void> edit(
      String oldPhone, String phone, String name, String remark) async {
    if (oldPhone != phone) {
      // 变更手机号：清空凭证重建（v1 PUT /api/accounts/<phone> 行为）。
      await deleteAccount(oldPhone);
      await addAccount(phone, name: name, remark: remark);
    } else {
      await updateAccount(oldPhone, name: name, remark: remark);
    }
    await load();
  }

  Future<void> remove(String phone) async {
    await deleteAccount(phone);
    await load();
  }

  Future<void> toggle(String phone, bool enabled) async {
    await updateAccount(phone, enabled: enabled);
    await load();
  }
}
