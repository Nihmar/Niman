/// The one drawing of a quadrant chart (#530): the four quadrants, their
/// names, the axes' ends, the points and their names.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/quadrant_layout.dart';

/// Draws a [QuadrantLayout] through a [DiagramTarget].
final class QuadrantRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final QuadrantLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints the quadrants — opposite ones alike — and the lines between,
  /// then the points, their names, the axes' ends and the title.
  void paint(DiagramTarget target) {
    for (final (q, quadrant) in layout.quadrants.indexed) {
      target.polygon(
        DiagramShapes.polygonFor(FlowNodeShape.rect, quadrant.rect),
        fill: q.isEven ? _palette.nodeFill : _palette.subgraphFill,
      );
      final name = quadrant.name;
      final box = quadrant.nameBox;
      if (name != null && box != null) {
        target.text(
          [name],
          box,
          color: _palette.nodeText,
          fontSize: style.fontSize,
          weight: FontWeight.w600,
        );
      }
    }
    final plot = layout.plot;
    target
      ..polygon(
        DiagramShapes.polygonFor(FlowNodeShape.rect, plot),
        stroke: _palette.nodeStroke,
        strokeWidth: 1.5,
      )
      ..line(
        Offset(plot.center.dx, plot.top),
        Offset(plot.center.dx, plot.bottom),
        color: _palette.nodeStroke,
      )
      ..line(
        Offset(plot.left, plot.center.dy),
        Offset(plot.right, plot.center.dy),
        color: _palette.nodeStroke,
      );
    for (final dot in layout.dots) {
      target
        ..polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.circle,
            Rect.fromCircle(center: dot.centre, radius: dot.radius),
          ),
          fill: _palette.series.first,
          stroke: _palette.edgeLabelBackground,
          strokeWidth: 1.5,
        )
        ..text(
          [dot.label],
          dot.labelBox,
          color: _palette.nodeText,
          fontSize: style.fontSize,
        );
    }
    for (final label in layout.axisLabels) {
      target.text(
        [label.text],
        label.box,
        color: _palette.nodeText,
        fontSize: style.fontSize,
      );
    }
    final title = layout.title;
    final box = layout.titleBox;
    if (title != null && box != null) {
      target.text(
        [title],
        box,
        color: _palette.nodeText,
        fontSize: style.fontSize * 1.2,
        weight: FontWeight.w600,
      );
    }
  }
}
