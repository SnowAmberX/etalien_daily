import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../endfield.dart';
import 'history_dialog.dart';
import 'settings_dialog.dart';

/// Endfield charcoal 标题栏：左侧产品标识，右侧窗口控制，中部可拖拽。
class EfTitleBar extends StatelessWidget {
  const EfTitleBar({super.key});

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Ef.ink,
      child: Row(
        children: [
          // 拖拽区 + 产品标识
          Expanded(
            child: EfDragArea(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const _DragGrip(),
                    const SizedBox(width: 12),
                    Container(width: 10, height: 10, color: Ef.signal),
                    const SizedBox(width: 10),
                    Text(
                      'ETALIEN//DAILY CLAIM',
                      style: Ef.micro(color: Colors.white, size: 11),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '免广告领时长',
                      style: Ef.body(
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 功能入口
          _WinButton(
            icon: Icons.settings_outlined,
            onTap: () => showSettingsDialog(context),
            tooltip: '设置',
          ),
          _WinButton(
            icon: Icons.history,
            onTap: () => showHistoryDialog(context),
            tooltip: '历史',
          ),
          // 窗口控制
          _WinButton(
            icon: Icons.remove,
            onTap: () => windowManager.minimize(),
          ),
          _WinButton(
            icon: Icons.crop_square,
            iconSize: 14,
            onTap: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WinButton(
            icon: Icons.close,
            hoverColor: const Color(0xFFE81123),
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

/// 可拖拽区域：move 光标；拖拽与双击最大化由 [DragToMoveArea] 提供。
class EfDragArea extends StatelessWidget {
  const EfDragArea({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: SizedBox(
        height: height,
        child: child,
      ),
    );
  }
}

/// 3×2 六点拖拽把手（endfield field-code 提示）。
class _DragGrip extends StatelessWidget {
  const _DragGrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < 2; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < 3; c++)
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    color: Ef.signal.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WinButton extends StatefulWidget {
  const _WinButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 16,
    this.hoverColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final Color? hoverColor;
  final String? tooltip;

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: Container(
            width: 46,
            height: EfTitleBar.height,
            color: _hover
                ? (widget.hoverColor ?? Colors.white.withValues(alpha: 0.12))
                : Colors.transparent,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: Colors.white.withValues(alpha: _hover ? 1 : 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
