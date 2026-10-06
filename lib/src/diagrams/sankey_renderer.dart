/// The one drawing of a Sankey diagram (#530): its bands, its nodes' bars
/// and their labels.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture. A band is its
/// source's colour, see-through, so the bands it crosses show beneath.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/sankey_layout.dart';

/// How much of a band's colour covers what lies under it.
const double _bandOpacity = 0.45;

/// Draws a [SankeyLayout] through a [DiagramTarget].
final class SankeyRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final SankeyLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  Color _colour(int? slot) =>
      slot == null ? _palette.nodeStroke : _palette.series[slot];

  /// Paints the bands behind, then the bars and their labels.
  void paint(DiagramTarget target) {
    for (final band in layout.bands) {
      target.polygon(
        band.outline,
        fill: _colour(band.colour).withValues(alpha: _bandOpacity),
      );
    }
    for (final node in layout.nodes) {
      target
        ..polygon(
          DiagramShapes.polygonFor(FlowNodeShape.rect, node.rect),
          fill: _colour(node.colour),
        )
        ..text(
          [node.label],
          node.labelBox,
          color: _palette.nodeText,
          fontSize: style.fontSize,
          alignLeft: true,
        );
    }
  }
}
