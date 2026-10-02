/// The one drawing of a packet diagram (#530): its boxes and their names,
/// the bit numbers over them and the title.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/packet_layout.dart';

/// Draws a [PacketLayout] through a [DiagramTarget].
final class PacketRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final PacketLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints every part.
  void paint(DiagramTarget target) {
    for (final box in layout.boxes) {
      target
        ..polygon(
          DiagramShapes.polygonFor(FlowNodeShape.rect, box.rect),
          fill: _palette.nodeFill,
          stroke: _palette.nodeStroke,
          strokeWidth: style.nodeStrokeWidth,
        )
        ..text(
          box.lines,
          box.rect,
          color: _palette.nodeText,
          fontSize: style.fontSize,
        );
    }
    for (final number in layout.numbers) {
      target.text(
        [number.text],
        number.box,
        color: _palette.nodeText,
        fontSize: numberFontSize(style),
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
