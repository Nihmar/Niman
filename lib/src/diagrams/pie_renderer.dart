/// The one drawing of a pie chart (#530): its slices, their shares, the
/// legend and the title.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/pie_geometry.dart';

/// Ink on a light slice.
const Color _darkInk = Color(0xFF1F1F1F);

/// Ink on a dark slice.
const Color _lightInk = Color(0xFFFFFFFF);

/// Draws a [PieLayout] through a [DiagramTarget].
final class PieRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final PieLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints the slices, then their shares, the legend and the title.
  void paint(DiagramTarget target) {
    for (final slice in layout.slices) {
      // A ring of the surface between two slices, so neither bleeds into
      // the other however close their colours.
      target.polygon(
        slice.outline,
        fill: _palette.series[slice.colour],
        stroke: _palette.edgeLabelBackground,
        strokeWidth: 2,
      );
    }
    for (final slice in layout.slices) {
      final percent = slice.percent;
      final at = slice.percentAt;
      if (percent == null || at == null) continue;
      final colour = _palette.series[slice.colour];
      final height = style.fontSize * style.lineHeight;
      target.text(
        [percent],
        Rect.fromCenter(center: at, width: height * 3, height: height),
        color: colour.computeLuminance() > 0.4 ? _darkInk : _lightInk,
        fontSize: style.fontSize,
        weight: FontWeight.w600,
      );
    }
    for (final row in layout.legend) {
      target
        ..polygon(
          DiagramShapes.polygonFor(FlowNodeShape.round, row.swatch, radius: 3),
          fill: _palette.series[row.colour],
        )
        ..text(
          [row.text],
          row.textBox,
          color: _palette.nodeText,
          fontSize: style.fontSize,
          alignLeft: true,
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
