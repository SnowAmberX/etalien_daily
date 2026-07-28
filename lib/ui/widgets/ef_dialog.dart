import 'package:flutter/material.dart';

import '../endfield.dart';
import 'ef_button.dart';

/// Endfield 模态对话框：paper 面板 + charcoal 标题条（黄 wedge + 双语标题）。
///
/// 用法：
/// ```dart
/// showEfDialog(context, title: '设置', en: 'SETTINGS', child: ...);
/// ```
Future<T?> showEfDialog<T>(
  BuildContext context, {
  required String title,
  required String en,
  required Widget child,
  double width = 420,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => EfDialog(title: title, en: en, width: width, child: child),
  );
}

class EfDialog extends StatelessWidget {
  const EfDialog({
    super.key,
    required this.title,
    required this.en,
    required this.child,
    this.width = 420,
  });

  final String title;
  final String en;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          color: Ef.paper,
          border: Border.all(color: Ef.ink),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // charcoal 标题条
            Container(
              height: 38,
              color: Ef.ink,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(width: 8, height: 8, color: Ef.signal),
                  const SizedBox(width: 8),
                  Text(en, style: Ef.micro(color: Colors.white, size: 10)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Ef.body(
                      color: Colors.white.withValues(alpha: 0.75),
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 方形输入框（focus 黄色 1px outline）。
class EfTextField extends StatefulWidget {
  const EfTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLength;

  @override
  State<EfTextField> createState() => _EfTextFieldState();
}

class _EfTextFieldState extends State<EfTextField> {
  final _focus = FocusNode();
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Ef.micro(size: 9)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(
                color: _focused ? Ef.ink : Ef.paperEdge,
              ),
              boxShadow: _focused
                  ? const [BoxShadow(color: Ef.signal, spreadRadius: 1)]
                  : null,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              style: Ef.num(size: 13),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: Ef.body(size: 12, color: Ef.muted),
                border: InputBorder.none,
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹窗底部按钮行。
class EfDialogActions extends StatelessWidget {
  const EfDialogActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 确认弹窗。返回 true=确认。
Future<bool> showEfConfirm(
  BuildContext context,
  String message, {
  String title = '确认',
  String en = 'CONFIRM',
  String okLabel = '确认',
}) async {
  final result = await showEfDialog<bool>(
    context,
    title: title,
    en: en,
    width: 320,
    child: Builder(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Ef.body(size: 13)),
          EfDialogActions(
            children: [
              EfButton(
                label: okLabel,
                primary: true,
                compact: true,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              EfButton(
                label: '取消',
                compact: true,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
