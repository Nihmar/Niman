/// The one drawing of a diagram (#530).
///
/// Given a laid-out chart and a style, it walks the layout once and calls a
/// [DiagramTarget]: the Flutter canvas for the screen and live mode, the SVG
/// target for an export. Nothing here knows which one it is drawing on, so
/// the two cannot drift apart.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// Draws a [DiagramLayout] through a [DiagramTarget].
final class DiagramRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final DiagramLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  /// Paints everything, in the order that stacks subgraphs under edges
  /// under nodes.
  void paint(DiagramTarget target) {
    _subgraphs(target);
    _edges(target);
    _edgeLabels(target);
    _nodes(target);
  }

  void _subgraphs(DiagramTarget target) {
    for (final sub in layout.subgraphs) {
      target
        ..polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.round,
            sub.rect,
            radius: style.cornerRadius,
          ),
          fill: style.palette.subgraphFill,
          stroke: style.palette.subgraphStroke,
        )
        ..text(
          [sub.title],
          sub.titleRect,
          color: style.palette.subgraphTitle,
          fontSize: style.fontSize,
          alignLeft: true,
          weight: FontWeight.w600,
        );
    }
  }

  void _edges(DiagramTarget target) {
    for (final edge in layout.edges) {
      target.cubic(
        edge.start,
        edge.control1,
        edge.control2,
        edge.end,
        color: style.palette.edge,
        strokeWidth: edge.edge.style.width,
        dashed: edge.edge.style == FlowEdgeStyle.dotted,
      );
      _cap(target, edge.start, edge.control1, edge.edge.start);
      _cap(target, edge.end, edge.control2, edge.edge.end);
    }
  }

  void _cap(
    DiagramTarget target,
    Offset point,
    Offset towards,
    FlowEdgeEnd end,
  ) {
    if (!end.isMarked) return;
    final direction = _unit(point - towards);
    switch (end) {
      case FlowEdgeEnd.none:
        return;
      case FlowEdgeEnd.arrow:
        _arrow(target, point, direction);
      case FlowEdgeEnd.cross:
        _cross(target, point, direction);
      case FlowEdgeEnd.circle:
        _circle(target, point);
    }
  }

  void _arrow(DiagramTarget target, Offset tip, Offset direction) {
    const length = 11.0;
    const half = 5.0;
    final back = tip - direction * length;
    final normal = Offset(-direction.dy, direction.dx);
    target.polygon([
      tip,
      back + normal * half,
      back - normal * half,
    ], fill: style.palette.edge);
  }

  void _cross(DiagramTarget target, Offset at, Offset direction) {
    const s = 5.0;
    final normal = Offset(-direction.dy, direction.dx);
    final a = at - direction * s - normal * s;
    final b = at + direction * s + normal * s;
    final c = at - direction * s + normal * s;
    final d = at + direction * s - normal * s;
    target
      ..line(a, b, color: style.palette.edge, strokeWidth: 2)
      ..line(c, d, color: style.palette.edge, strokeWidth: 2);
  }

  void _circle(DiagramTarget target, Offset at) {
    const r = 5.0;
    final rect = Rect.fromCircle(center: at, radius: r);
    target.polygon(
      DiagramShapes.polygonFor(FlowNodeShape.circle, rect),
      fill: style.palette.edgeLabelBackground,
      stroke: style.palette.edge,
      strokeWidth: 2,
    );
  }

  void _edgeLabels(DiagramTarget target) {
    for (final edge in layout.edges) {
      final label = edge.label;
      final box = edge.labelBox;
      if (label == null || box == null) continue;
      final padded = box.inflate(style.edgeLabelPadding.left);
      target
        ..polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.round,
            padded,
            radius: style.cornerRadius,
          ),
          fill: style.palette.edgeLabelBackground,
        )
        ..text(
          [label],
          padded,
          color: style.palette.edge,
          fontSize: style.fontSize,
        );
    }
  }

  void _nodes(DiagramTarget target) {
    for (final node in layout.nodes) {
      target.polygon(
        DiagramShapes.polygonFor(
          node.node.shape,
          node.rect,
          radius: style.cornerRadius,
        ),
        fill: style.palette.nodeFill,
        stroke: node.node.shape.isClosed ? style.palette.nodeStroke : null,
        strokeWidth: style.nodeStrokeWidth,
      );
      if (node.node.shape == FlowNodeShape.subroutine) {
        for (final (a, b) in DiagramShapes.subroutineBars(node.rect)) {
          target.line(
            a,
            b,
            color: style.palette.nodeStroke,
            strokeWidth: style.nodeStrokeWidth,
          );
        }
      }
      target.text(
        layout.lines[node.node.id] ?? [node.node.label],
        node.rect,
        color: style.palette.nodeText,
        fontSize: style.fontSize,
      );
    }
  }

  static Offset _unit(Offset vector) {
    final length = math.sqrt(vector.dx * vector.dx + vector.dy * vector.dy);
    if (length == 0) return const Offset(0, 1);
    return Offset(vector.dx / length, vector.dy / length);
  }
}
