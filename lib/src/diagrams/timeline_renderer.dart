/// The one drawing of a timeline (#530): the time line, the sections'
/// headers, the periods, their events and the dashed lines between.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/timeline_geometry.dart';

/// Ink on a light fill.
const Color _darkInk = Color(0xFF1F1F1F);

/// Ink on a dark fill.
const Color _lightInk = Color(0xFFFFFFFF);

/// Draws a [TimelineLayout] through a [DiagramTarget].
final class TimelineRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final TimelineLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints the time line and the connectors, then every box and the
  /// title.
  void paint(DiagramTarget target) {
    final (from, to) = layout.axis;
    // The line, its arrowhead saying time runs on.
    target
      ..line(from, to, color: _palette.edge, strokeWidth: 2)
      ..polygon([
        to,
        to + const Offset(-10, -5),
        to + const Offset(-10, 5),
      ], fill: _palette.edge);
    for (final (top, bottom) in layout.connectors) {
      target.line(top, bottom, color: _palette.edge, dashed: true);
    }
    for (final box in [...layout.sections, ...layout.boxes]) {
      _box(target, box);
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

  /// A box: a period or a header filled with its section's colour, an
  /// event outlined in it on the neutral fill; neutral without a colour.
  void _box(DiagramTarget target, LaidOutTimelineBox box) {
    final slot = box.colour;
    final colour = slot == null ? null : _palette.series[slot];
    final fill = colour == null || box.event ? _palette.nodeFill : colour;
    final ink = colour != null && !box.event
        ? (colour.computeLuminance() > 0.4 ? _darkInk : _lightInk)
        : _palette.nodeText;
    target
      ..polygon(
        DiagramShapes.polygonFor(
          FlowNodeShape.round,
          box.rect,
          radius: style.cornerRadius,
        ),
        fill: fill,
        stroke: colour ?? _palette.nodeStroke,
        strokeWidth: 1.5,
      )
      ..text(
        box.lines,
        box.rect,
        color: ink,
        fontSize: style.fontSize,
        weight: box.event ? FontWeight.normal : FontWeight.w600,
      );
  }
}
