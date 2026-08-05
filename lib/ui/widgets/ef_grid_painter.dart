import 'package:flutter/material.dart';

import '../endfield.dart';

/// Endfield 工程网格背景：低透明细线网格 + 边缘十字标记。
class EfGridPainter extends CustomPainter {
  const EfGridPainter({this.spacing = 44, this.opacity = 0.05});

  final double spacing;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Ef.ink.withValues(alpha: opacity)
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 网格交点十字标记（每 4 格）
    final cross = Paint()
      ..color = Ef.ink.withValues(alpha: opacity * 2.2)
      ..strokeWidth = 1;
    const arm = 3.0;
    for (var x = 0.0; x <= size.width; x += spacing * 4) {
      for (var y = 0.0; y <= size.height; y += spacing * 4) {
        canvas.drawLine(
            Offset(x - arm, y), Offset(x + arm, y), cross);
        canvas.drawLine(
            Offset(x, y - arm), Offset(x, y + arm), cross);
      }
    }
  }

  @override
  bool shouldRepaint(EfGridPainter oldDelegate) => false;
}
