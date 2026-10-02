/// The one drawing of an xy chart (#530): its grid, axes and their texts,
/// the bars and lines of its series, its legend and title.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/xy_chart_layout.dart';

/// Draws an [XyLayout] through a [DiagramTarget].
final class XyChartRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final XyLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  Color _colour(int series) => series < _palette.series.length
      ? _palette.series[series]
      : _palette.nodeStroke;

  /// Paints the grid behind, the series on it, the axes and every text.
  void paint(DiagramTarget target) {
    for (final line in layout.grid) {
      target.line(
        line.from,
        line.to,
        color: _palette.subgraphStroke,
        dashed: true,
      );
    }
    for (final bar in layout.bars) {
      target.polygon(
        DiagramShapes.polygonFor(FlowNodeShape.rect, bar.rect),
        fill: _colour(bar.series),
      );
    }
    for (final line in layout.lines) {
      final colour = _colour(line.series);
      for (var i = 0; i + 1 < line.points.length; i++) {
        target.line(
          line.points[i],
          line.points[i + 1],
          color: colour,
          strokeWidth: 2,
        );
      }
      for (final point in line.points) {
        target.polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.circle,
            Rect.fromCircle(center: point, radius: 4),
          ),
          fill: colour,
          stroke: _palette.edgeLabelBackground,
          strokeWidth: 1.5,
        );
      }
    }
    final plot = layout.plot;
    // The axes: the value axis's line where the categories start, and the
    // category axis's along the values' start.
    target
      ..line(plot.bottomLeft, plot.bottomRight, color: _palette.edge)
      ..line(plot.topLeft, plot.bottomLeft, color: _palette.edge);
    for (final text in [
      ...layout.valueLabels,
      ...layout.categoryLabels,
      ...layout.axisTitles,
    ]) {
      _text(target, text);
    }
    for (final entry in layout.legend) {
      target.polygon(
        DiagramShapes.polygonFor(FlowNodeShape.round, entry.swatch, radius: 3),
        fill: _colour(entry.series),
      );
      _text(target, entry.name, left: true);
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

  void _text(DiagramTarget target, XyText text, {bool left = false}) =>
      target.text(
        [text.text],
        text.box,
        color: _palette.nodeText,
        fontSize: style.fontSize,
        alignLeft: left,
      );
}
