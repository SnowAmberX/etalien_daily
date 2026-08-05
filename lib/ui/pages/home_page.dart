import 'dart:math';

import 'package:flutter/material.dart';

import '../endfield.dart';
import '../store/accounts_store.dart';
import '../store/claim_store.dart';
import '../store/stores.dart';
import '../widgets/account_dialog.dart';
import '../widgets/claim_scope_controls.dart';
import '../widgets/ef_button.dart';
import '../widgets/ef_dialog.dart';
import '../widgets/ef_grid_painter.dart';
import '../widgets/ef_progress.dart';
import '../widgets/ef_toast.dart';
import '../widgets/login_dialog.dart';
import '../widgets/title_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ef.paper,
      body: Column(
        children: [
          const EfTitleBar(),
          const _StatsDock(),
          const _ActionStrip(),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: EfGridPainter()),
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  children: const [
                    _AccountsSection(),
                    SizedBox(height: 14),
                    _ClaimSection(),
                  ],
                ),
              ],
            ),
          ),
          const _StatusBar(),
        ],
      ),
    );
  }
}

// ── 统计 dock ──────────────────────────────────────────────────

class _StatsDock extends StatelessWidget {
  const _StatsDock();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: accountsStore,
      builder: (context, _) {
        return Container(
          height: 44,
          color: Ef.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: EfDragArea(
            height: 44,
            child: Row(
              children: [
                _stat('ACCOUNTS', accountsStore.totalCount),
                _divider(),
                _stat('ENABLED', accountsStore.enabledCount),
                _divider(),
                _stat('PROGRESS', accountsStore.overallProgress, suffix: '%'),
                const Spacer(),
                if (accountsStore.refreshing)
                  Text('SYNCING…', style: Ef.micro(color: Ef.signal, size: 9)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, int value, {String suffix = ''}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$value$suffix',
          style: Ef.num(color: Colors.white, size: 18, weight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(label, style: Ef.micro(color: Ef.muted, size: 9)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        color: Colors.white.withValues(alpha: 0.16),
      );
}

// ── 操作条 ────────────────────────────────────────────────────

class _ActionStrip extends StatelessWidget {
  const _ActionStrip();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: claimStore,
      builder: (context, _) {
        final running = claimStore.running;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Ef.paperEdge)),
          ),
          child: Row(
            children: [
              EfButton(
                label: running ? '${claimStore.targetLabel}…' : '按配置领取',
                primary: true,
                onPressed: running ? null : () => _claim(context, 'all'),
              ),
              const SizedBox(width: 8),
              EfButton(
                label: '仅 PC',
                onPressed: running ? null : () => _claim(context, 'pc'),
              ),
              const SizedBox(width: 8),
              EfButton(
                label: '仅手机',
                onPressed: running ? null : () => _claim(context, 'mobile'),
              ),
              const SizedBox(width: 8),
              EfButton(
                label: '翻译',
                onPressed: running ? null : () => _claim(context, 'translate'),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: accountsStore,
                builder: (context, _) => EfButton(
                  label: '刷新状态',
                  onPressed: accountsStore.refreshing
                      ? null
                      : () => accountsStore.refreshStatus(),
                ),
              ),
              const SizedBox(width: 8),
              EfButton(
                label: '+ 添加账号',
                compact: true,
                onPressed: () => showAccountDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _claim(BuildContext context, String target) {
    if (accountsStore.enabledCount == 0) {
      EfToast.show(context, '没有启用的账号', type: EfToastType.warn);
      return;
    }
    claimStore.startClaim(target);
  }
}

// ── 区段标题（01/ACCOUNTS + 引导线）────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.index, this.en, this.zh);

  final String index;
  final String en;
  final String zh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            index,
            style: Ef.num(size: 15, weight: FontWeight.w700)
                .copyWith(color: Ef.ink),
          ),
          const SizedBox(width: 8),
          Text(en, style: Ef.micro(color: Ef.ink, size: 11)),
          const SizedBox(width: 8),
          Text(zh, style: Ef.body(size: 12, weight: FontWeight.w600)),
          const SizedBox(width: 14),
          Expanded(child: Container(height: 1, color: Ef.paperEdge)),
        ],
      ),
    );
  }
}

// ── 账号区 ────────────────────────────────────────────────────

class _AccountsSection extends StatefulWidget {
  const _AccountsSection();

  @override
  State<_AccountsSection> createState() => _AccountsSectionState();
}

class _AccountsSectionState extends State<_AccountsSection> {
  final Set<String> _flipped = {};
  final Set<String> _selected = {};
  final Map<String, ClaimScope> _drafts = {};
  bool _selectionMode = false;

  static const _defaultScope = (pc: true, mobile: true, translate: false);

  ClaimScope _scopeOf(AccountStatus status) => (
        pc: status.account.claimPc,
        mobile: status.account.claimMobile,
        translate: status.account.claimTranslate,
      );

  void _toggleFlip(String phone) {
    setState(() {
      if (!_flipped.add(phone)) _flipped.remove(phone);
    });
  }

  void _startSelection(String phone) {
    setState(() {
      _selectionMode = true;
      _selected.add(phone);
      _flipped.remove(phone);
    });
  }

  void _toggleSelection(String phone) {
    setState(() {
      if (!_selected.add(phone)) _selected.remove(phone);
      if (_selected.isEmpty) _selectionMode = false;
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(accountsStore.accounts.map((a) => a.phone));
    });
  }

  void _invertSelection() {
    setState(() {
      final allPhones = accountsStore.accounts.map((a) => a.phone).toSet();
      final inverted = allPhones.difference(_selected);
      _selected
        ..clear()
        ..addAll(inverted);
    });
  }

  void _updateScope(String phone, ClaimScope scope) {
    setState(() => _drafts[phone] = scope);
  }

  ClaimScope _draftScope(String phone) {
    final draft = _drafts[phone];
    if (draft != null) return draft;
    final status =
        accountsStore.accounts.where((a) => a.phone == phone).firstOrNull;
    return status == null ? _defaultScope : _scopeOf(status);
  }

  Future<void> _saveScope(String phone, BuildContext context) async {
    final scope = _draftScope(phone);
    await accountsStore.saveScope(
      phone,
      pc: scope.pc,
      mobile: scope.mobile,
      translate: scope.translate,
    );
    if (!context.mounted) return;
    setState(() {
      _flipped.remove(phone);
      _drafts.remove(phone);
    });
    EfToast.show(context, '已保存', type: EfToastType.ok);
  }

  Future<void> _saveAll(BuildContext context) async {
    final first = _flipped.isEmpty ? null : _flipped.first;
    if (first == null) return;
    final scope = _draftScope(first);
    await accountsStore.applyScopeToAll(
      pc: scope.pc,
      mobile: scope.mobile,
      translate: scope.translate,
    );
    if (!context.mounted) return;
    setState(() {
      _flipped.clear();
      _drafts.clear();
    });
    EfToast.show(context, '已应用到所有账号', type: EfToastType.ok);
  }

  Future<void> _openBatchDialog(BuildContext context) async {
    final firstPhone = _selected.first;
    final result = await _showBatchScopeDialog(
      context,
      _draftScope(firstPhone),
      _selected.length,
    );
    if (result == null || !mounted) return;
    await accountsStore.saveScopeForPhones(
      _selected,
      pc: result.pc,
      mobile: result.mobile,
      translate: result.translate,
    );
    if (!context.mounted) return;
    setState(() {
      _selectionMode = false;
      _selected.clear();
      _drafts.clear();
    });
    EfToast.show(context, '已应用', type: EfToastType.ok);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('01', 'ACCOUNTS', '账号'),
        if (_selectionMode) _selectionDock(context),
        ListenableBuilder(
          listenable: accountsStore,
          builder: (context, _) {
            if (accountsStore.loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('加载中…'),
              );
            }
            if (accountsStore.accounts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '暂无账号，点击「+ 添加账号」开始',
                  style: Ef.body(color: Ef.muted, size: 12),
                ),
              );
            }
            return SizedBox(
              // 背面固定控件（3 个 40px checkbox + 两个按钮）需要 248px。
              height: 248,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accountsStore.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final status = accountsStore.accounts[i];
                  final phone = status.phone;
                  return _AccountCard(
                    status: status,
                    flipped: _flipped.contains(phone),
                    scope: _draftScope(phone),
                    selectionMode: _selectionMode,
                    selected: _selected.contains(phone),
                    selectionIndex:
                        _selected.toList().indexOf(phone) + 1,
                    onTap: _selectionMode
                        ? () => _toggleSelection(phone)
                        : () => _toggleFlip(phone),
                    onLongPress: _selectionMode
                        ? () => _toggleSelection(phone)
                        : () => _startSelection(phone),
                    onScopeChanged: (scope) => _updateScope(phone, scope),
                    onSave: () => _saveScope(phone, context),
                    onSaveAll: () => _saveAll(context),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _selectionDock(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: Ef.ink,
      child: Row(
        children: [
          Text(
            'SELECT ${_selected.length}',
            style: Ef.micro(color: Ef.signal, size: 10),
          ),
          const Spacer(),
          _DockTextButton(label: '全选', onPressed: _selectAll),
          const SizedBox(width: 8),
          _DockTextButton(label: '反选', onPressed: _invertSelection),
          const SizedBox(width: 8),
          _DockTextButton(
            label: '批量设置',
            onPressed: _selected.isEmpty
                ? null
                : () => _openBatchDialog(context),
          ),
          const SizedBox(width: 8),
          _DockTextButton(label: '取消', onPressed: _exitSelection),
        ],
      ),
    );
  }
}

class _DockTextButton extends StatelessWidget {
  const _DockTextButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: onPressed == null ? Ef.muted : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: Ef.body(
          color: onPressed == null ? Ef.muted : Colors.white,
          size: 12,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.status,
    required this.flipped,
    required this.scope,
    required this.onTap,
    required this.onLongPress,
    required this.onScopeChanged,
    required this.onSave,
    required this.onSaveAll,
    this.selectionMode = false,
    this.selected = false,
    this.selectionIndex = 0,
  });

  final AccountStatus status;
  final bool flipped;
  final ClaimScope scope;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<ClaimScope> onScopeChanged;
  final VoidCallback onSave;
  final VoidCallback onSaveAll;
  final bool selectionMode;
  final bool selected;
  final int selectionIndex;

  static String _maskPhone(String p) =>
      p.length > 6 ? '${p.substring(0, 3)}****${p.substring(p.length - 4)}' : p;

  Color get _statusColor {
    if (!status.enabled) return Ef.muted;
    return switch (status.status) {
      'ok' || 'all_done' => Ef.stateOk,
      'error' => Ef.error,
      _ => Ef.signal,
    };
  }

  String get _statusLabel {
    if (!status.enabled) return '已禁用';
    return switch (status.status) {
      'ok' => '正常',
      'all_done' => '已完成',
      'error' => '错误',
      _ => '需登录',
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 220,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: flipped ? pi : 0),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          builder: (context, angle, _) {
            final frontOpacity = cos(angle).clamp(0.0, 1.0);
            final backOpacity = 1 - frontOpacity;
            return Stack(
              fit: StackFit.expand,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: frontOpacity,
                    child: IgnorePointer(
                      ignoring: frontOpacity == 0,
                      child: _buildFront(),
                    ),
                  ),
                ),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle + pi),
                  child: Opacity(
                    opacity: backOpacity,
                    child: IgnorePointer(
                      ignoring: backOpacity == 0,
                      child: _buildBack(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront() {
    final s = status;
    return Container(
      key: ValueKey('front-${s.phone}'),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: selected ? Ef.signal : Ef.paperEdge),
      ),
      child: Row(
        children: [
          Container(width: 4, color: selected ? Ef.signal : _statusColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (selectionMode) ...[
                        Container(
                          width: 18,
                          height: 18,
                          color: selected ? Ef.signal : Ef.ink,
                          child: Center(
                            child: Text(
                              selected ? '$selectionIndex' : '',
                              style: Ef.num(
                                color:
                                    selected ? Ef.ink : Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          _maskPhone(s.phone),
                          style: Ef.num(size: 13, weight: FontWeight.w700),
                        ),
                      ),
                      _CardActions(status: s),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.name.isEmpty ? '-' : s.name,
                          style: Ef.body(size: 11, color: Ef.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _statusLabel,
                        style: Ef.body(size: 10, color: Ef.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (s.tokenValid)
                    _DurationReadout(status: s)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('NEED AUTH', style: Ef.micro(size: 9)),
                    ),
                  const Spacer(),
                  _progressRow('PC', s.current, s.total),
                  const SizedBox(height: 3),
                  _progressRow('手机', s.mobileCurrent, s.mobileTotal),
                  const SizedBox(height: 3),
                  _progressRow('翻译', s.translateCurrent, s.translateTotal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final s = status;
    return Container(
      key: ValueKey('back-${s.phone}'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: selected ? Ef.signal : Ef.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _maskPhone(s.phone),
                  style: Ef.num(size: 12, weight: FontWeight.w700),
                ),
              ),
              Text('SCOPE', style: Ef.micro(size: 8)),
            ],
          ),
          const SizedBox(height: 2),
          Text('领取范围 CLAIM SCOPE', style: Ef.micro(size: 8)),
          const SizedBox(height: 4),
          ClaimScopeControls(
            scope: scope,
            onChanged: onScopeChanged,
          ),
          const Spacer(),
          EfButton(
            label: '保存',
            primary: true,
            compact: true,
            onPressed: onSave,
          ),
          const SizedBox(height: 6),
          EfButton(
            label: '应用到所有账号',
            compact: true,
            onPressed: onSaveAll,
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String label, int current, int total) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label, style: Ef.body(size: 9, color: Ef.muted)),
        ),
        Expanded(
          child: EfProgress(current: current, total: total),
        ),
        const SizedBox(width: 6),
        Text(
          '$current/$total',
          style: Ef.num(size: 9, color: Ef.muted),
        ),
      ],
    );
  }
}

Future<ClaimScope?> _showBatchScopeDialog(
  BuildContext context,
  ClaimScope initial,
  int count,
) {
  return showEfDialog<ClaimScope>(
    context,
    title: '批量配置',
    en: 'BATCH SCOPE',
    width: 340,
    child: Builder(
      builder: (ctx) {
        var scope = initial;
        return StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '应用到 $count 个账号',
                style: Ef.body(size: 12, color: Ef.muted),
              ),
              const SizedBox(height: 8),
              ClaimScopeControls(
                scope: scope,
                onChanged: (value) => setState(() => scope = value),
              ),
              EfDialogActions(
                children: [
                  EfButton(
                    label: '应用',
                    primary: true,
                    compact: true,
                    onPressed: () => Navigator.of(ctx).pop(scope),
                  ),
                  EfButton(
                    label: '取消',
                    compact: true,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// 账号卡片操作按钮：⋯ 菜单（登录/编辑/启停）+ × 删除。
class _CardActions extends StatelessWidget {
  const _CardActions({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          tooltip: '操作',
          padding: EdgeInsets.zero,
          iconSize: 16,
          icon: const Icon(Icons.more_horiz, size: 16, color: Ef.muted),
          color: Ef.ink,
          itemBuilder: (_) => [
            if (s.needsLogin)
              _menuItem('login', '登录'),
            _menuItem('edit', '编辑'),
            _menuItem('toggle', s.enabled ? '禁用' : '启用'),
          ],
          onSelected: (action) => _onAction(context, action),
        ),
        GestureDetector(
          onTap: () => _onAction(context, 'delete'),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.close, size: 14, color: Ef.muted),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 34,
      child: Text(
        label,
        style: Ef.body(size: 12, color: Colors.white),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    final s = status;
    switch (action) {
      case 'login':
        await showLoginDialog(context, s.phone);
      case 'edit':
        await showAccountDialog(context, phone: s.phone);
      case 'toggle':
        await accountsStore.toggle(s.phone, !s.enabled);
      case 'delete':
        if (!context.mounted) return;
        final ok = await showEfConfirm(
          context,
          '删除账号 ${_mask(s.phone)}？\n其领取历史将一并删除。',
          okLabel: '删除',
        );
        if (ok) {
          await accountsStore.remove(s.phone);
          if (context.mounted) {
            EfToast.show(context, '已删除', type: EfToastType.ok);
          }
        }
    }
  }

  static String _mask(String p) =>
      p.length > 6 ? '${p.substring(0, 3)}****${p.substring(p.length - 4)}' : p;
}

/// Endfield field-code 时长读数块：micro-label + 主读数 + 次读数层级。
class _DurationReadout extends StatelessWidget {
  const _DurationReadout({required this.status});

  final AccountStatus status;

  static String _fmt(int s) {
    if (s < 0) s = 0;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = status;
    final mobile = s.mobileError ? '--:--:--' : _fmt(s.mobileDuration);
    final trans = s.translateError ? '--' : '×${s.translateCount}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
      decoration: BoxDecoration(
        border: Border.all(color: Ef.paperEdge),
        color: Colors.white.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VIP', style: Ef.micro(size: 8)),
          const SizedBox(height: 1),
          Text(
            _fmt(s.vipDuration),
            style: Ef.num(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text('MOBILE ', style: Ef.micro(size: 8)),
              Text(mobile, style: Ef.num(size: 9, color: Ef.muted)),
              const SizedBox(width: 8),
              Text('TRANS ', style: Ef.micro(size: 8)),
              Text(trans, style: Ef.num(size: 9, color: Ef.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 领取区 ────────────────────────────────────────────────────

class _ClaimSection extends StatelessWidget {
  const _ClaimSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('02', 'CLAIM', '领取'),
        ListenableBuilder(
          listenable: claimStore,
          builder: (context, _) {
            if (claimStore.cards.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '点击上方按钮开始领取',
                  style: Ef.body(color: Ef.muted, size: 12),
                ),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final card in claimStore.cards.values)
                  _ClaimCard(state: card),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.state});

  final ClaimCardState state;

  Color get _statusColor => switch (state.status) {
        'running' => Ef.signal,
        'done' || 'already_done' => Ef.stateOk,
        'skipped' => Ef.muted,
        'error' || 'auth_error' => Ef.error,
        'need_login' => Ef.muted,
        _ => Ef.muted,
      };

  String get _statusLabel => switch (state.status) {
        'waiting' => '等待',
        'running' => '进行中',
        'done' => '完成',
        'already_done' => '已完成',
        'skipped' => '已跳过',
        'error' => '错误',
        'auth_error' => '认证失败',
        'need_login' => '需登录',
        _ => state.status,
      };

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: Ef.paperEdge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBar4(color: _statusColor, pulse: s.status == 'running'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.name.isEmpty ? s.phone : '${s.name} · ${s.phone}',
                          style: Ef.num(size: 12, weight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(_statusLabel,
                          style: Ef.body(size: 10, color: Ef.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  EfProgress(current: s.current, total: s.total),
                  const SizedBox(height: 4),
                  Text(
                    s.detail,
                    style: Ef.body(size: 10, color: Ef.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 左侧 4px 状态竖条（运行中时呼吸脉冲——全页唯一 attention loop）。
class _StatusBar4 extends StatefulWidget {
  const _StatusBar4({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_StatusBar4> createState() => _StatusBar4State();
}

class _StatusBar4State extends State<_StatusBar4>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusBar4 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && _ctrl == null) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat(reverse: true);
    } else if (!widget.pulse) {
      _ctrl?.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(width: 4, height: 74, color: widget.color);
    final ctrl = _ctrl;
    if (ctrl == null) return bar;
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(ctrl),
      child: bar,
    );
  }
}

// ── 底部状态条 ────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: Ef.ink,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('ETALIEN V2', style: Ef.micro(color: Ef.muted, size: 9)),
          const SizedBox(width: 16),
          ListenableBuilder(
            listenable: claimStore,
            builder: (context, _) => Text(
              claimStore.running
                  ? 'CLAIM RUNNING · ${claimStore.doneCount}/${claimStore.totalCount}'
                  : 'IDLE',
              style: Ef.micro(
                color: claimStore.running ? Ef.signal : Ef.muted,
                size: 9,
              ),
            ),
          ),
          const Spacer(),
          Text('FLUTTER WINDOWS', style: Ef.micro(color: Ef.muted, size: 9)),
        ],
      ),
    );
  }
}
