/// Where a parsed diagram's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the drawing on canvas and the exported
/// SVG both read this, so they cannot disagree about where anything is.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// A diagram with every part placed.
final class DiagramLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.nodes,
    required this.edges,
    required this.subgraphs,
    required this.lines,
  });

  /// The drawing's size.
  final Size size;

  /// The nodes, in the chart's own order.
  final List<LaidOutNode> nodes;

  /// The edges, in the chart's own order.
  final List<LaidOutEdge> edges;

  /// The subgraph boxes, outermost first so a drawing can paint them in
  /// order.
  final List<LaidOutSubgraph> subgraphs;

  /// The text of each node's label, already broken into lines, by node id.
  final Map<String, List<String>> lines;

  /// The laid-out node for [id], or null.
  LaidOutNode? nodeOf(String id) {
    for (final node in nodes) {
      if (node.node.id == id) return node;
    }
    return null;
  }
}

/// One node and the rectangle it occupies.
final class LaidOutNode {
  /// Creates a placed node.
  const new({required this.node, required this.rect});

  /// The model node.
  final FlowNode node;

  /// Where it sits.
  final Rect rect;
}

/// One edge and the curve it is drawn along.
final class LaidOutEdge {
  /// Creates a placed edge.
  const new({
    required this.edge,
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
    this.label,
    this.labelBox,
    this.startLabelBox,
    this.endLabelBox,
  });

  /// The model edge.
  final FlowEdge edge;

  /// The tail's point, on the source node's outline.
  final Offset start;

  /// The first cubic control point.
  final Offset control1;

  /// The second cubic control point.
  final Offset control2;

  /// The head's point, on the target node's outline.
  final Offset end;

  /// The label's text, or null.
  final String? label;

  /// The box the label sits in, or null.
  final Rect? labelBox;

  /// Where [FlowEdge.startLabel] sits, beside the tail, or null.
  final Rect? startLabelBox;

  /// Where [FlowEdge.endLabel] sits, beside the head, or null.
  final Rect? endLabelBox;
}

/// One subgraph and the box drawn round it.
final class LaidOutSubgraph {
  /// Creates a placed subgraph.
  const new({
    required this.subgraph,
    required this.rect,
    required this.titleRect,
    required this.title,
  });

  /// The model subgraph.
  final FlowSubgraph subgraph;

  /// The box.
  final Rect rect;

  /// Where the title sits.
  final Rect titleRect;

  /// The title's text.
  final String title;
}
