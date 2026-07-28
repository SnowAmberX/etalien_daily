/// 领取运行状态管理（对照 v1 gui/__init__.py ClaimManager + app.js 进度轮询）。
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/claim_service.dart';
import '../../core/database.dart';

/// 单个账号的领取卡片状态。
class ClaimCardState {
  ClaimCardState({required this.phone, this.name = ''});

  final String phone;
  String name;

  /// waiting / running / done / already_done / error / need_login
  String status = 'waiting';
  String step = '';
  String detail = '等待开始';
  int current = 0;
  int total = 0;
  int vipBefore = 0;
  int vipAfter = 0;
  int claimed = 0;
  int failed = 0;
  String? error;

  /// 日志行（状态变化时追加）。
  final List<({String text, bool isError})> logs = [];
}

class ClaimStore extends ChangeNotifier {
  /// 按账号顺序的卡片。
  final LinkedHashMap<String, ClaimCardState> cards = LinkedHashMap();

  bool running = false;
  String targetLabel = '';

  /// 最终结果（完成后保留展示）。
  List<ClaimResult> results = [];

  String _runId = '';

  int get doneCount =>
      cards.values.where((c) => c.status != 'waiting' && c.status != 'running').length;
  int get totalCount => cards.length;

  Future<void> startClaim(String target) async {
    if (running) return;

    final accounts = await getAccounts();
    if (accounts.isEmpty) return;

    results = [];
    cards
      ..clear()
      ..addEntries(accounts.map(
        (a) => MapEntry(a.phone, ClaimCardState(phone: a.phone, name: a.name)),
      ));

    running = true;
    targetLabel = switch (target) {
      'pc' => '仅 PC',
      'mobile' => '仅手机',
      'translate' => '翻译',
      _ => '全部领取',
    };
    _runId = _newRunId();
    notifyListeners();

    try {
      results = await runConcurrentClaim(
        accounts,
        source: 'gui',
        target: target,
        progressCallback: _onProgress,
      );
    } finally {
      // 结果写回卡片
      for (final r in results) {
        final card = cards[r.phone];
        if (card == null) continue;
        card
          ..status = r.status
          ..claimed = r.claimed
          ..failed = r.failed
          ..vipBefore = r.vipBefore
          ..vipAfter = r.vipAfter
          ..error = r.errorMsg
          ..detail = _resultDetail(r);
        _addLog(card, _resultLogText(r), isError: r.errorMsg != null);
      }
      running = false;
      notifyListeners();
    }
  }

  void _onProgress(ProgressEvent e) {
    final card = cards[e.phone];
    if (card == null) return;

    card
      ..status = 'running'
      ..step = e.step
      ..detail = e.detail;
    if (e.current != null) card.current = e.current!;
    if (e.total != null && e.total! > 0) card.total = e.total!;
    if (e.vipBefore != null) card.vipBefore = e.vipBefore!;
    if (e.vipAfter != null) card.vipAfter = e.vipAfter!;

    // 关键节点写日志
    if (e.step == 'done' ||
        e.step.endsWith('_stalled') ||
        e.step.endsWith('_skip')) {
      _addLog(card, e.detail, isError: e.step.endsWith('_stalled'));
    }

    // 过程事件持久化（对照 v1：GUI 事件写 claim_events 表）
    unawaited(addClaimEvent(
      _runId,
      null,
      e.phone,
      card.status,
      step: e.step,
      detail: e.detail,
      current: card.current,
      total: card.total,
      vipBefore: card.vipBefore,
      vipAfter: card.vipAfter,
    ));

    notifyListeners();
  }

  void _addLog(ClaimCardState card, String text, {bool isError = false}) {
    card.logs.add((text: text, isError: isError));
    notifyListeners();
  }

  String _resultDetail(ClaimResult r) => switch (r.status) {
        statusOk => '领取完成',
        statusAlreadyDone => '所有广告已观看完毕',
        statusNeedLogin => '需要登录',
        statusAuthError => '认证失败',
        _ => r.errorMsg ?? '错误',
      };

  String _resultLogText(ClaimResult r) {
    if (r.status == statusOk) {
      final gained = max(0, r.vipAfter - r.vipBefore);
      return '完成 +${_fmtDuration(gained)}';
    }
    if (r.status == statusAlreadyDone) return '已完成';
    if (r.status == statusNeedLogin) return '需要登录';
    return '错误: ${r.errorMsg ?? ''}';
  }

  static String _fmtDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  static String _newRunId() {
    final now = DateTime.now();
    final rand = Random().nextInt(0xFFFF);
    return 'run-${now.millisecondsSinceEpoch.toRadixString(36)}-${rand.toRadixString(36)}';
  }
}
