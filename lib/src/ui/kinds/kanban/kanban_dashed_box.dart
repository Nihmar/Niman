import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A rounded rectangle drawn with a dashed line, round [child] (#1167): the
/// outline of "+ Add a card" and "+ Add a column", which say the place is
/// empty and waiting.
final class KanbanDashedBox extends StatelessWidget {
  /// Draws [child] in a dashed box of [color].
  const new({
    required this.color,
    required this.child,
    this.radius = 10,
    super.key,
  });

  /// The dashes' colour.
  final Color color;

  /// The corner radius.
  final double radius;

  /// What the box holds.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(color: color, radius: radius),
      child: child,
    );
  }
}

final class _DashedPainter extends CustomPainter {
  const new({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.6),
      );
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = ui.clampDouble(at + _dash, 0, metric.length);
        canvas.drawPath(metric.extractPath(at, end), paint);
        at += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}
