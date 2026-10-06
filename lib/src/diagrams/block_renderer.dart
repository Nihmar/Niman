/// The one drawing of a block diagram (#530): its groups, its edges, its
/// blocks and the edges' labels, stacked in that order.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture. An edge goes under
/// the blocks, so one passing a block it does not join is hidden by it
/// rather than drawn across its text; a label goes over everything.
library;

import 'package:niman/src/diagrams/block_geometry.dart';
import 'package:niman/src/diagrams/block_layout.dart';
import 'package:niman/src/diagrams/diagram_caps.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// Draws a [BlockLayout] through a [DiagramTarget].
final class BlockRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final BlockLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints every part.
  void paint(DiagramTarget target) {
    for (final group in layout.groups) {
      target.polygon(
        DiagramShapes.polygonFor(
          FlowNodeShape.round,
          group,
          radius: style.cornerRadius,
        ),
        fill: _palette.subgraphFill,
        stroke: _palette.subgraphStroke,
      );
    }
    for (final edge in layout.edges) {
      target.line(
        edge.start,
        edge.end,
        color: _palette.edge,
        strokeWidth: edge.edge.style.width,
        dashed: edge.edge.style == FlowEdgeStyle.dotted,
      );
      paintEdgeCap(target, edge.start, edge.end, edge.edge.start, _palette);
      paintEdgeCap(target, edge.end, edge.start, edge.edge.end, _palette);
    }
    for (final block in layout.blocks) {
      _block(target, block);
    }
    for (final edge in layout.edges) {
      final box = edge.labelBox;
      final label = edge.edge.label;
      if (box == null || label == null) continue;
      target
        ..polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.round,
            box,
            radius: style.cornerRadius,
          ),
          fill: _palette.edgeLabelBackground,
        )
        ..text(
          DiagramMetrics.lines(label),
          box,
          color: _palette.edge,
          fontSize: style.fontSize,
        );
    }
  }

  void _block(DiagramTarget target, BlockBox block) {
    final node = block.node;
    final arrow = node.arrow;
    final rect = block.rect;
    target.polygon(
      arrow == null
          ? DiagramShapes.polygonFor(
              node.shape,
              rect,
              radius: style.cornerRadius,
            )
          : blockArrowOutline(rect, arrow),
      fill: _palette.nodeFill,
      stroke: _palette.nodeStroke,
      strokeWidth: style.nodeStrokeWidth,
    );
    if (arrow == null && node.shape == FlowNodeShape.subroutine) {
      for (final (a, b) in DiagramShapes.subroutineBars(rect)) {
        target.line(
          a,
          b,
          color: _palette.nodeStroke,
          strokeWidth: style.nodeStrokeWidth,
        );
      }
    }
    target.text(
      block.lines,
      arrow == null ? rect : blockArrowTextBox(rect, arrow),
      color: _palette.nodeText,
      fontSize: style.fontSize,
    );
  }
}
