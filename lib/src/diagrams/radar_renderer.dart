/// The one drawing of a radar chart (#530): the scale's rings and spokes,
/// the curves over them, the axes' labels, the legend and the title.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture. A curve's fill is its
/// colour, see-through, so the curves under it still show; its outline is
/// the colour itself.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/radar_layout.dart';

/// How much of a curve's colour fills it.
const double _fillOpacity = 0.2;

/// How much of the edge colour the rings and spokes take: there to read
/// the curves against, not to compete with them.
const double _gridOpacity = 0.25;

/// Draws a [RadarLayout] through a [DiagramTarget].
final class RadarRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final RadarLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  Color _colour(int? slot) =>
      slot == null ? _palette.nodeStroke : _palette.series[slot];

  /// Paints every part.
  void paint(DiagramTarget target) {
    final grid = _palette.edge.withValues(alpha: _gridOpacity);
    for (final ring in layout.rings) {
      target.polygon(ring, stroke: grid);
    }
    for (final (from, to) in layout.spokes) {
      target.line(from, to, color: grid);
    }
    for (final curve in layout.curves) {
      final colour = _colour(curve.colour);
      target.polygon(
        curve.points,
        fill: colour.withValues(alpha: _fillOpacity),
        stroke: colour,
        strokeWidth: 2,
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
    for (final row in layout.legend) {
      target
        ..polygon([
          row.swatch.topLeft,
          row.swatch.topRight,
          row.swatch.bottomRight,
          row.swatch.bottomLeft,
        ], fill: _colour(row.colour))
        ..text(
          [row.label.text],
          row.label.box,
          color: _palette.nodeText,
          fontSize: style.fontSize,
          alignLeft: true,
        );
    }
    final title = layout.title;
    if (title != null) {
      target.text(
        [title.text],
        title.box,
        color: _palette.nodeText,
        fontSize: style.fontSize * 1.2,
        weight: FontWeight.w600,
      );
    }
  }
}
