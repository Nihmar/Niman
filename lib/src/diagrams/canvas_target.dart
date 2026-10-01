/// The [DiagramTarget] that draws with a Flutter [Canvas] (#530).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_target.dart';

/// Paints a diagram onto a canvas.
final class CanvasDiagramTarget implements DiagramTarget {
  /// Creates a target onto [canvas].
  new(this.canvas, {this.fontFamily});

  /// The canvas to draw onto.
  final Canvas canvas;

  /// The typeface labels are drawn in, or null for the ambient one.
  final String? fontFamily;

  @override
  void polygon(
    List<Offset> points, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 1,
  }) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    if (fill != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
    }
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  void cubic(
    Offset from,
    Offset control1,
    Offset control2,
    Offset to, {
    required Color color,
    double strokeWidth = 1,
    bool dashed = false,
  }) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        to.dx,
        to.dy,
      );
    _stroke(path, color, strokeWidth, dashed);
  }

  @override
  void line(
    Offset from,
    Offset to, {
    required Color color,
    double strokeWidth = 1,
    bool dashed = false,
  }) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
    _stroke(path, color, strokeWidth, dashed);
  }

  @override
  void text(
    List<String> lines,
    Rect box, {
    required Color color,
    required double fontSize,
    bool alignLeft = false,
    FontWeight weight = FontWeight.normal,
  }) {
    if (lines.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: lines.join('\n'),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: fontFamily,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignLeft ? TextAlign.left : TextAlign.center,
    )..layout(maxWidth: box.width);
    painter.paint(canvas, Offset(box.left, box.center.dy - painter.height / 2));
  }

  void _stroke(Path path, Color color, double width, bool dashed) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dashed ? _dashed(path) : path, paint);
  }

  Path _dashed(Path source) {
    const on = 6.0;
    const off = 4.0;
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + on;
        result.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + off;
      }
    }
    return result;
  }
}
