import 'package:flutter/material.dart';

import '../../core/database.dart';
import '../endfield.dart';
import 'ef_button.dart';
import 'ef_dialog.dart';

/// 领取历史弹窗：本周记录（service 结果）+ 过程事件（gui）。
Future<void> showHistoryDialog(BuildContext context) {
  return showEfDialog<void>(
    context,
    title: '领取历史',
    en: 'HISTORY',
    width: 520,
    child: const _HistoryList(),
  );
}

class _HistoryList extends StatefulWidget {
  const _HistoryList();

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  var _tab = 0; // 0=结果记录 1=过程事件
  List<Map<String, Object?>> _records = [];
  List<Map<String, Object?>> _events = [];
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weekStart = getWeekStartTs();
    final records = await getClaimHistory(weekStart: weekStart, limit: 100);
    final events = await getClaimEvents(weekStart: weekStart, limit: 100);
    if (mounted) {
      setState(() {
        _records = records;
        _events = events;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('加载中…')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _tabChip(0, '结果记录'),
            const SizedBox(width: 6),
            _tabChip(1, '过程事件'),
            const Spacer(),
            Text('本周', style: Ef.micro(size: 9)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 320,
          child: _tab == 0 ? _recordList() : _eventList(),
        ),
        EfDialogActions(
          children: [
            EfButton(
              label: '关闭',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabChip(int index, String label) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Ef.ink : Colors.transparent,
          border: Border.all(color: Ef.ink.withValues(alpha: 0.75)),
        ),
        child: Text(
          label,
          style: Ef.body(
            size: 12,
            weight: FontWeight.w600,
            color: active ? Colors.white : Ef.ink,
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) => Center(
        child: Text(text, style: Ef.body(size: 12, color: Ef.muted)),
      );

  static String _fmtTime(num ts) {
    final d = DateTime.fromMillisecondsSinceEpoch((ts * 1000).round());
    return '${d.month}-${d.day} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _fmtDuration(int s) {
    if (s <= 0) return '-';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return '${h}h${m.toString().padLeft(2, '0')}m';
  }

  Widget _recordList() {
    if (_records.isEmpty) return _empty('本周暂无领取记录');
    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (_, _) => Container(height: 1, color: Ef.paperEdge),
      itemBuilder: (context, i) {
        final r = _records[i];
        final status = r['status'] as String? ?? '';
        final vipBefore = (r['vip_before'] as num?)?.toInt() ?? 0;
        final vipAfter = (r['vip_after'] as num?)?.toInt() ?? 0;
        final gained = vipAfter - vipBefore;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 30,
                color: status == 'ok' || status == 'already_done'
                    ? Ef.stateOk
                    : Ef.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r['phone']} · ${_statusLabel(status)}',
                      style: Ef.body(size: 12, weight: FontWeight.w600),
                    ),
                    Text(
                      '${r['detail'] ?? ''}',
                      style: Ef.body(size: 10, color: Ef.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (gained > 0)
                    Text('+${_fmtDuration(gained)}',
                        style: Ef.num(size: 12, weight: FontWeight.w700)),
                  Text(
                    _fmtTime(r['claimed_at'] as num? ?? 0),
                    style: Ef.num(size: 9, color: Ef.muted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _eventList() {
    if (_events.isEmpty) return _empty('本周暂无过程事件');
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (_, _) => Container(height: 1, color: Ef.paperEdge),
      itemBuilder: (context, i) {
        final e = _events[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  _fmtTime(e['event_at'] as num? ?? 0),
                  style: Ef.num(size: 9, color: Ef.muted),
                ),
              ),
              Expanded(
                child: Text(
                  '${e['phone']} · ${e['step']} · ${e['detail']}',
                  style: Ef.body(size: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _statusLabel(String s) => switch (s) {
        'ok' => '成功',
        'already_done' => '已完成',
        'auth_error' => '认证失败',
        'need_login' => '需登录',
        'error' => '错误',
        _ => s,
      };
}
