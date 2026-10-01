/// The painter of a laid-out diagram (#530).
library;

import 'package:flutter/rendering.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_style.dart';

/// Paints a [DiagramLayout] with a [DiagramStyle].
final class DiagramPainter extends CustomPainter {
  /// Creates the painter.
  const new({required this.layout, required this.style});

  /// The drawing.
  final DiagramLayout layout;

  /// Its sizes and colours.
  final DiagramStyle style;

  @override
  void paint(Canvas canvas, Size size) => DiagramRenderer(
    layout: layout,
    style: style,
  ).paint(CanvasDiagramTarget(canvas, fontFamily: style.fontFamily));

  @override
  bool shouldRepaint(DiagramPainter oldDelegate) =>
      !identical(oldDelegate.layout, layout) ||
      oldDelegate.style.cacheKey != style.cacheKey;
}
