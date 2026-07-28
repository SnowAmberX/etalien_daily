import 'package:flutter/material.dart';

import '../endfield.dart';

/// Endfield 细线进度条：1px 轨道 + 黄色填充 + 右端 wedge 尖角。
class EfProgress extends StatelessWidget {
  const EfProgress({
    super.key,
    required this.current,
    required this.total,
    this.color = Ef.signal,
    this.trackColor,
    this.height = 3,
  });

  final int current;
  final int total;
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * pct;
        return SizedBox(
          height: height + 2,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 1,
                child: Container(
                  height: height,
                  color: trackColor ?? Ef.ink.withValues(alpha: 0.12),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: 0,
                top: 1,
                width: w,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(height: height, color: color),
                    ),
                    // wedge 尖角
                    if (pct > 0)
                      CustomPaint(
                        size: Size(height + 2, height),
                        painter: _WedgePainter(color),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WedgePainter extends CustomPainter {
  const _WedgePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WedgePainter oldDelegate) =>
      oldDelegate.color != color;
}
