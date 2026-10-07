/// The one drawing of a diagram (#530).
///
/// Given a laid-out chart and a style, it walks the layout once and calls a
/// [DiagramTarget]: the Flutter canvas for the screen and live mode, the SVG
/// target for an export. Nothing here knows which one it is drawing on, so
/// the two cannot drift apart.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_caps.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_size.dart';

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
    _endLabels(target);
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
      if (edge.edge.style == FlowEdgeStyle.invisible) continue;
      target.cubic(
        edge.start,
        edge.control1,
        edge.control2,
        edge.end,
        color: style.palette.edge,
        strokeWidth: edge.edge.style.width,
        dashed: edge.edge.style == FlowEdgeStyle.dotted,
      );
      paintEdgeCap(
        target,
        edge.start,
        edge.control1,
        edge.edge.start,
        style.palette,
      );
      paintEdgeCap(
        target,
        edge.end,
        edge.control2,
        edge.edge.end,
        style.palette,
      );
    }
  }

  void _edgeLabels(DiagramTarget target) {
    for (final edge in layout.edges) {
      if (edge.edge.style == FlowEdgeStyle.invisible) continue;
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

  /// The texts at an edge's ends: a class relation's cardinalities.
  void _endLabels(DiagramTarget target) {
    for (final edge in layout.edges) {
      for (final (text, box) in [
        (edge.edge.startLabel, edge.startLabelBox),
        (edge.edge.endLabel, edge.endLabelBox),
      ]) {
        if (text == null || box == null) continue;
        target.text(
          [text],
          box,
          color: style.palette.edge,
          fontSize: style.fontSize,
        );
      }
    }
  }

  void _nodes(DiagramTarget target) {
    for (final node in layout.nodes) {
      switch (node.node.shape) {
        case FlowNodeShape.start:
          target.polygon(_outline(node), fill: style.palette.edge);
        case FlowNodeShape.end:
          target
            ..polygon(
              _outline(node),
              fill: style.palette.edgeLabelBackground,
              stroke: style.palette.edge,
              strokeWidth: 1.5,
            )
            ..polygon(
              DiagramShapes.polygonFor(
                FlowNodeShape.circle,
                node.rect.deflate(node.rect.width * 0.22),
              ),
              fill: style.palette.edge,
            );
        case FlowNodeShape.bar:
          target.polygon(_outline(node), fill: style.palette.edge);
        case FlowNodeShape.classBox:
          _classBox(target, node);
        case FlowNodeShape.note:
          target
            ..polygon(
              _outline(node),
              fill: style.palette.subgraphFill,
              stroke: style.palette.subgraphStroke,
            )
            ..text(
              layout.lines[node.node.id] ?? [node.node.label],
              node.rect,
              color: style.palette.subgraphTitle,
              fontSize: style.fontSize,
            );
        case _:
          _box(target, node);
      }
    }
  }

  /// A flowchart's own node: its outline and its label.
  void _box(DiagramTarget target, LaidOutNode node) {
    target.polygon(
      _outline(node),
      fill: style.palette.nodeFill,
      stroke: style.palette.nodeStroke,
      strokeWidth: style.nodeStrokeWidth,
    );
    if (node.node.shape == FlowNodeShape.doubleCircle) {
      target.polygon(
        DiagramShapes.polygonFor(
          FlowNodeShape.circle,
          node.rect.deflate(doubleCircleGap),
        ),
        stroke: style.palette.nodeStroke,
        strokeWidth: style.nodeStrokeWidth,
      );
    }
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
    if (node.node.sections.isNotEmpty) return _card(target, node);
    target.text(
      layout.lines[node.node.id] ?? [node.node.label],
      node.rect,
      color: style.palette.nodeText,
      fontSize: style.fontSize,
    );
  }

  /// A card's sections stacked and centred in its box, the middle one —
  /// the name — bold.
  void _card(DiagramTarget target, LaidOutNode node) {
    final sections = node.node.sections;
    final line = style.fontSize * style.lineHeight;
    final total = node.node.stackedLines.length * line;
    var y = node.rect.center.dy - total / 2;
    for (var i = 0; i < sections.length; i++) {
      final height = sections[i].length * line;
      if (height > 0) {
        target.text(
          sections[i],
          Rect.fromLTWH(node.rect.left, y, node.rect.width, height),
          color: style.palette.nodeText,
          fontSize: style.fontSize,
          weight: i == 1 ? FontWeight.w600 : FontWeight.normal,
        );
      }
      y += height;
    }
  }

  /// A class: its box, a rule between compartments, its name centred and
  /// its members from the left.
  void _classBox(DiagramTarget target, LaidOutNode node) {
    final rect = node.rect;
    target.polygon(
      _outline(node),
      fill: style.palette.nodeFill,
      stroke: style.palette.nodeStroke,
      strokeWidth: style.nodeStrokeWidth,
    );
    final heights = classSectionHeights(node.node, style);
    final inset = style.nodePadding.left;
    var y = rect.top;
    for (var i = 0; i < node.node.sections.length; i++) {
      final section = node.node.sections[i];
      if (i > 0) {
        target.line(
          Offset(rect.left, y),
          Offset(rect.right, y),
          color: style.palette.nodeStroke,
          strokeWidth: style.nodeStrokeWidth,
        );
      }
      if (section.isNotEmpty) {
        target.text(
          section,
          i == 0
              ? Rect.fromLTWH(rect.left, y, rect.width, heights[i])
              : Rect.fromLTWH(
                  rect.left + inset,
                  y,
                  rect.width - 2 * inset,
                  heights[i],
                ),
          color: style.palette.nodeText,
          fontSize: style.fontSize,
          alignLeft: i > 0,
          weight: i == 0 ? FontWeight.w600 : FontWeight.normal,
        );
      }
      y += heights[i];
    }
  }

  List<Offset> _outline(LaidOutNode node) => DiagramShapes.polygonFor(
    node.node.shape,
    node.rect,
    radius: style.cornerRadius,
  );
}
