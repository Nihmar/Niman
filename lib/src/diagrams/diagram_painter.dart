/// The painter of a laid-out diagram (#530).
library;

import 'package:flutter/rendering.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/pie_renderer.dart';
import 'package:niman/src/diagrams/sequence_renderer.dart';

/// Paints a [DiagramDrawing] with a [DiagramStyle], whatever its kind.
final class DiagramPainter extends CustomPainter {
  /// Creates the painter.
  const new({required this.drawing, required this.style});

  /// The drawing.
  final DiagramDrawing drawing;

  /// Its sizes and colours.
  final DiagramStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final target = CanvasDiagramTarget(canvas, fontFamily: style.fontFamily);
    switch (drawing) {
      case FlowDrawing(:final layout):
        DiagramRenderer(layout: layout, style: style).paint(target);
      case SequenceDrawing(:final layout):
        SequenceRenderer(layout: layout, style: style).paint(target);
      case PieDrawing(:final layout):
        PieRenderer(layout: layout, style: style).paint(target);
    }
  }

  @override
  bool shouldRepaint(DiagramPainter oldDelegate) =>
      !identical(oldDelegate.drawing, drawing) ||
      oldDelegate.style.cacheKey != style.cacheKey;
}
