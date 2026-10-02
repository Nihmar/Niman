/// The one drawing of an architecture diagram (#530): the groups' boxes
/// and titles, the edges and their arrows and labels, the services' icons
/// and titles and the junctions' dots.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/architecture_icons.dart';
import 'package:niman/src/diagrams/architecture_layout.dart';
import 'package:niman/src/diagrams/diagram_caps.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// Draws an [ArchitectureLayout] through a [DiagramTarget].
final class ArchitectureRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final ArchitectureLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints every part: groups under edges under services.
  void paint(DiagramTarget target) {
    for (final group in layout.groups) {
      target
        ..polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.round,
            group.rect,
            radius: style.cornerRadius,
          ),
          fill: _palette.subgraphFill,
          stroke: _palette.subgraphStroke,
        )
        ..text(
          [group.group.title],
          group.titleBox,
          color: _palette.subgraphTitle,
          fontSize: style.fontSize,
          alignLeft: true,
          weight: FontWeight.w600,
        );
      if (group.group.icon.isNotEmpty) {
        _icon(target, archIcon(group.group.icon, group.icon), 1.2);
      }
    }
    for (final edge in layout.edges) {
      final points = edge.points;
      for (var i = 0; i + 1 < points.length; i++) {
        target.line(
          points[i],
          points[i + 1],
          color: _palette.edge,
          strokeWidth: 2,
        );
      }
      if (points.length < 2) continue;
      if (edge.edge.arrowAtFrom) {
        paintEdgeCap(
          target,
          points.first,
          points[1],
          FlowEdgeEnd.arrow,
          _palette,
        );
      }
      if (edge.edge.arrowAtTo) {
        paintEdgeCap(
          target,
          points.last,
          points[points.length - 2],
          FlowEdgeEnd.arrow,
          _palette,
        );
      }
    }
    for (final node in layout.nodes) {
      if (node.service.isJunction) {
        target.polygon(
          DiagramShapes.polygonFor(FlowNodeShape.circle, node.icon),
          fill: _palette.edge,
        );
        continue;
      }
      target.polygon(
        DiagramShapes.polygonFor(
          FlowNodeShape.round,
          node.icon,
          radius: style.cornerRadius,
        ),
        fill: _palette.nodeFill,
        stroke: _palette.nodeStroke,
        strokeWidth: style.nodeStrokeWidth,
      );
      _icon(target, archIcon(node.service.icon, node.icon), 2);
      final box = node.titleBox;
      if (box != null) {
        target.text(
          node.lines,
          box,
          color: _palette.nodeText,
          fontSize: style.fontSize,
        );
      }
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
        ..text([label], box, color: _palette.edge, fontSize: style.fontSize);
    }
  }

  void _icon(DiagramTarget target, ArchIcon icon, double width) {
    for (final outline in icon.outlines) {
      target.polygon(outline, stroke: _palette.nodeStroke, strokeWidth: width);
    }
    for (final (a, b) in icon.lines) {
      target.line(a, b, color: _palette.nodeStroke, strokeWidth: width);
    }
    for (final dot in icon.dots) {
      target.polygon(
        DiagramShapes.polygonFor(FlowNodeShape.circle, dot),
        fill: _palette.nodeStroke,
      );
    }
  }
}
