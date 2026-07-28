import 'package:flutter/material.dart';

import '../endfield.dart';
import '../store/accounts_store.dart';
import '../store/claim_store.dart';
import '../store/stores.dart';
import '../widgets/account_dialog.dart';
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
                label: running ? '${claimStore.targetLabel}…' : '全部领取',
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

class _AccountsSection extends StatelessWidget {
  const _AccountsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('01', 'ACCOUNTS', '账号'),
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
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accountsStore.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) =>
                    _AccountCard(status: accountsStore.accounts[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.status});

  final AccountStatus status;

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
    final s = status;
    return Container(
      width: 208,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: Ef.paperEdge),
      ),
      child: Row(
        children: [
          Container(width: 4, color: _statusColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                      child: Text('NEED AUTH',
                          style: Ef.micro(size: 9)),
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
        'error' || 'auth_error' => Ef.error,
        'need_login' => Ef.muted,
        _ => Ef.muted,
      };

  String get _statusLabel => switch (state.status) {
        'waiting' => '等待',
        'running' => '进行中',
        'done' => '完成',
        'already_done' => '已完成',
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
