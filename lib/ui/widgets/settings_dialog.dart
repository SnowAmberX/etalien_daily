import 'package:flutter/material.dart';

import '../../core/database.dart';
import '../../platform/scheduler.dart';
import '../../platform/service_installer.dart';
import '../endfield.dart';
import 'ef_button.dart';
import 'ef_dialog.dart';
import 'ef_toast.dart';

/// 设置弹窗：运行参数 + 定时调度 + Windows Service 管理。
Future<void> showSettingsDialog(BuildContext context) {
  return showEfDialog<void>(
    context,
    title: '设置',
    en: 'SETTINGS',
    width: 460,
    child: const _SettingsForm(),
  );
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm();

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _maxConcurrent = TextEditingController();
  final _requestInterval = TextEditingController();
  final _maxRounds = TextEditingController();
  final _mobileMaxRounds = TextEditingController();
  final _translateRetryLimit = TextEditingController();
  final _translateMaxRounds = TextEditingController();
  final _scheduleTime = TextEditingController();

  bool _scheduleEnabled = false;
  String _scheduleMethod = 'schtasks';
  ScheduleStatus? _status;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await getSettings();
    _maxConcurrent.text = '${s.maxConcurrent}';
    _requestInterval.text = '${s.requestInterval}';
    _maxRounds.text = '${s.maxRounds}';
    _mobileMaxRounds.text = '${s.mobileMaxRounds}';
    _translateRetryLimit.text = '${s.translateRetryLimit}';
    _translateMaxRounds.text = '${s.translateMaxRounds}';
    _scheduleTime.text = s.scheduleTime;
    _scheduleEnabled = s.scheduleEnabled;
    _scheduleMethod = s.scheduleMethod;
    await _refreshStatus();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _refreshStatus() async {
    final st = await queryScheduleStatus();
    if (mounted) setState(() => _status = st);
  }

  @override
  void dispose() {
    for (final c in [
      _maxConcurrent,
      _requestInterval,
      _maxRounds,
      _mobileMaxRounds,
      _translateRetryLimit,
      _translateMaxRounds,
      _scheduleTime,
    ]) {
      c.dispose();
    }
    super.dispose();
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
        // ── 运行参数 ──
        _groupLabel('RUN', '运行参数'),
        Row(
          children: [
            Expanded(child: _numField('并发数', _maxConcurrent, '1-50')),
            const SizedBox(width: 10),
            Expanded(child: _numField('请求间隔(s)', _requestInterval, '0.1-30')),
          ],
        ),
        Row(
          children: [
            Expanded(child: _numField('PC 轮数', _maxRounds, '1-200')),
            const SizedBox(width: 10),
            Expanded(child: _numField('手机轮数', _mobileMaxRounds, '1-200')),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: _numField('翻译重试', _translateRetryLimit, '1-100')),
            const SizedBox(width: 10),
            Expanded(
                child: _numField('翻译轮数', _translateMaxRounds, '1-200')),
          ],
        ),
        const SizedBox(height: 6),

        // ── 定时调度 ──
        _groupLabel('SCHEDULE', '定时调度'),
        Row(
          children: [
            Expanded(child: _timeField()),
            const SizedBox(width: 10),
            Expanded(child: _methodField()),
          ],
        ),
        const SizedBox(height: 4),
        _enabledRow(),
        const SizedBox(height: 8),
        _serviceBlock(),
        const SizedBox(height: 10),

        EfDialogActions(
          children: [
            EfButton(
              label: _busy ? '保存中…' : '保存',
              primary: true,
              onPressed: _busy ? null : _save,
            ),
            EfButton(
              label: '关闭',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _groupLabel(String en, String zh) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, color: Ef.signal),
          const SizedBox(width: 6),
          Text(en, style: Ef.micro(size: 9, color: Ef.ink)),
          const SizedBox(width: 6),
          Text(zh, style: Ef.body(size: 11, weight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: Ef.paperEdge)),
        ],
      ),
    );
  }

  Widget _numField(
      String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Ef.micro(size: 9)),
          const SizedBox(height: 4),
          _input(ctrl, hint: hint),
        ],
      ),
    );
  }

  Widget _timeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('每日时间', style: Ef.micro(size: 9)),
        const SizedBox(height: 4),
        _input(_scheduleTime, hint: 'HH:MM'),
      ],
    );
  }

  Widget _methodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('方式', style: Ef.micro(size: 9)),
        const SizedBox(height: 4),
        Row(
          children: [
            _methodChip('schtasks', 'Schtasks'),
            const SizedBox(width: 6),
            _methodChip('service', 'Service'),
          ],
        ),
      ],
    );
  }

  Widget _methodChip(String value, String label) {
    final active = _scheduleMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _scheduleMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _enabledRow() {
    return GestureDetector(
      onTap: () => setState(() => _scheduleEnabled = !_scheduleEnabled),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _scheduleEnabled ? Ef.signal : Colors.transparent,
              border: Border.all(color: Ef.ink),
            ),
            child: _scheduleEnabled
                ? const Icon(Icons.check, size: 12, color: Ef.ink)
                : null,
          ),
          const SizedBox(width: 8),
          Text('启用每日定时领取', style: Ef.body(size: 12)),
        ],
      ),
    );
  }

  Widget _serviceBlock() {
    final st = _status;
    final installed = st?.serviceInstalled ?? false;
    final running = st?.serviceRunning ?? false;
    final schtasks = st?.schtasks ?? false;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Ef.paperEdge),
        color: Colors.white.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SERVICE', style: Ef.micro(size: 8)),
                const SizedBox(height: 3),
                Text(
                  '服务 ${installed ? (running ? '运行中' : '已停止') : '未安装'}'
                  ' · 任务计划 ${schtasks ? '已配置' : '未配置'}',
                  style: Ef.body(size: 11, color: Ef.muted),
                ),
              ],
            ),
          ),
          if (installed)
            EfButton(
              label: '卸载服务',
              compact: true,
              onPressed: _busy ? null : _uninstallService,
            )
          else
            EfButton(
              label: '安装服务',
              compact: true,
              onPressed: _busy ? null : _installService,
            ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController ctrl, {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: Ef.paperEdge),
      ),
      child: TextField(
        controller: ctrl,
        style: Ef.num(size: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Ef.body(size: 11, color: Ef.muted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await updateSettings(
        maxConcurrent: int.tryParse(_maxConcurrent.text),
        requestInterval: double.tryParse(_requestInterval.text),
        maxRounds: int.tryParse(_maxRounds.text),
        mobileMaxRounds: int.tryParse(_mobileMaxRounds.text),
        translateRetryLimit: int.tryParse(_translateRetryLimit.text),
        translateMaxRounds: int.tryParse(_translateMaxRounds.text),
        scheduleTime: _scheduleTime.text.trim(),
        scheduleEnabled: _scheduleEnabled,
        scheduleMethod: _scheduleMethod,
      );
      String? err;
      if (_scheduleMethod == 'schtasks') {
        err = await applySchtasksSchedule();
      } else {
        // service 模式：ini 同步由安装流程负责，这里同步一次即可
        err = await applySchtasksSchedule();
      }
      if (!mounted) return;
      if (err != null) {
        EfToast.show(context, '保存成功，但调度应用失败: $err',
            type: EfToastType.warn);
      } else {
        EfToast.show(context, '设置已保存', type: EfToastType.ok);
      }
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _installService() async {
    setState(() => _busy = true);
    try {
      final err = await installService();
      if (!mounted) return;
      if (err != null) {
        EfToast.show(context, err, type: EfToastType.error);
      } else {
        EfToast.show(context, '服务已安装并启动', type: EfToastType.ok);
        setState(() {
          _scheduleMethod = 'service';
          _scheduleEnabled = true;
        });
      }
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uninstallService() async {
    setState(() => _busy = true);
    try {
      final err = await uninstallService();
      if (!mounted) return;
      if (err != null) {
        EfToast.show(context, err, type: EfToastType.error);
      } else {
        EfToast.show(context, '服务已卸载', type: EfToastType.ok);
        setState(() {
          _scheduleMethod = 'schtasks';
          _scheduleEnabled = false;
        });
      }
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
