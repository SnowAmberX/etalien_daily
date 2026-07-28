import 'package:flutter/material.dart';

import '../endfield.dart';

/// Endfield 方形按钮：直角、1px 描边、左侧 yellow wedge（主按钮）、
/// hover 反色、按压下沉 1px。
class EfButton extends StatefulWidget {
  const EfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool enabled;
  final bool compact;

  @override
  State<EfButton> createState() => _EfButtonState();
}

class _EfButtonState extends State<EfButton> {
  var _hover = false;
  var _pressed = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    Color bg;
    Color fg;
    Border border;
    if (!_active) {
      bg = Colors.transparent;
      fg = Ef.muted;
      border = Border.all(color: Ef.muted.withValues(alpha: 0.5));
    } else if (primary) {
      bg = _pressed
          ? Ef.signal
          : _hover
              ? const Color(0xFF2A2A2A)
              : Ef.ink;
      fg = _pressed ? Ef.ink : Colors.white;
      border = Border.all(color: Ef.ink);
    } else {
      bg = _pressed
          ? Ef.ink.withValues(alpha: 0.12)
          : _hover
              ? Ef.ink
              : Colors.transparent;
      fg = _hover && !_pressed ? Colors.white : Ef.ink;
      border = Border.all(color: Ef.ink.withValues(alpha: 0.75));
    }

    final height = widget.compact ? 30.0 : 36.0;

    return MouseRegion(
      cursor: _active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: _active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _active
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed!();
              }
            : null,
        onTapCancel: _active ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: height,
          transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(Ef.radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (primary)
                Container(
                  width: 4,
                  height: height,
                  color: _pressed ? Ef.ink : Ef.signal,
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 10 : 14,
                ),
                child: Text(
                  widget.label,
                  style: Ef.body(
                    color: fg,
                    size: widget.compact ? 12 : 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
