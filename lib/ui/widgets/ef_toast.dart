import 'package:flutter/material.dart';

import '../endfield.dart';

enum EfToastType { info, ok, warn, error }

/// Endfield Toast：charcoal 底 + 黄左条，顶部右侧滑入，3s 消失。
class EfToast {
  EfToast._();

  static void show(
    BuildContext context,
    String msg, {
    EfToastType type = EfToastType.info,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        msg: msg,
        type: type,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.msg,
    required this.type,
    required this.onDismiss,
  });

  final String msg;
  final EfToastType type;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _barColor => switch (widget.type) {
        EfToastType.ok => Ef.stateOk,
        EfToastType.warn => Ef.signal,
        EfToastType.error => Ef.error,
        EfToastType.info => Ef.signal,
      };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: EfTitleBarSafeArea.top + 12,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: const BoxDecoration(color: Ef.panel),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 40, color: _barColor),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      widget.msg,
                      style: Ef.body(color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 标题栏高度占位常量（Toast 避让）。
class EfTitleBarSafeArea {
  static const double top = 48;
}
