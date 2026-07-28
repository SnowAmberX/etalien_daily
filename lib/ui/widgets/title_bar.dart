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
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
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
