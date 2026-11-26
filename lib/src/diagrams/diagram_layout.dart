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

/// One edge and the curve it is drawn along: a chain of cubic Béziers.
final class LaidOutEdge {
  /// Creates an edge drawn along one cubic from [start] to [end].
  new({
    required this.edge,
    required Offset start,
    required Offset control1,
    required Offset control2,
    required Offset end,
    this.label,
    this.labelBox,
    this.startLabelBox,
    this.endLabelBox,
  }) : path = [start, control1, control2, end];

  /// Creates an edge drawn along [path]: a poly-Bézier of 3k + 1 points,
  /// `[p0, c1, c2, p1, c1, c2, p2, ...]`, each piece running from one
  /// anchor to the next through its two control points.
  new along({
    required this.edge,
    required this.path,
    this.label,
    this.labelBox,
    this.startLabelBox,
    this.endLabelBox,
  }) : assert(
         path.length >= 4 && (path.length - 1) % 3 == 0,
         'a poly-Bézier has 3k + 1 points',
       );

  /// The model edge.
  final FlowEdge edge;

  /// The curve: anchors and control points, as [LaidOutEdge.along] says.
  final List<Offset> path;

  /// The tail's point, on the source node's outline.
  Offset get start => path.first;

  /// The control point the curve leaves its tail towards: the direction it
  /// leaves in.
  Offset get control1 => path[1];

  /// The control point the curve reaches its head from: the direction it
  /// arrives in.
  Offset get control2 => path[path.length - 2];

  /// The head's point, on the target node's outline.
  Offset get end => path.last;

  /// The label's text, or null.
  final String? label;

  /// The box the label sits in, or null.
  final Rect? labelBox;

  /// Where [FlowEdge.startLabel] sits, beside the tail, or null.
  final Rect? startLabelBox;

  /// Where [FlowEdge.endLabel] sits, beside the head, or null.
  final Rect? endLabelBox;

  /// The point [t] of the way along the curve, `t` from 0 at the start to 1
  /// at the end, each piece taking an equal share.
  Offset at(double t) {
    final pieces = (path.length - 1) ~/ 3;
    final scaled = t.clamp(0.0, 1.0) * pieces;
    final piece = scaled >= pieces ? pieces - 1 : scaled.floor();
    final s = scaled - piece;
    final u = 1 - s;
    final i = piece * 3;
    return path[i] * (u * u * u) +
        path[i + 1] * (3 * u * u * s) +
        path[i + 2] * (3 * u * s * s) +
        path[i + 3] * (s * s * s);
  }

  /// This edge moved by [by], its labels with it.
  LaidOutEdge shifted(Offset by) => LaidOutEdge.along(
    edge: edge,
    path: [for (final point in path) point + by],
    label: label,
    labelBox: labelBox?.shift(by),
    startLabelBox: startLabelBox?.shift(by),
    endLabelBox: endLabelBox?.shift(by),
  );

  /// This edge with its label put in [box].
  LaidOutEdge withLabelBox(Rect box) => LaidOutEdge.along(
    edge: edge,
    path: path,
    label: label,
    labelBox: box,
    startLabelBox: startLabelBox,
    endLabelBox: endLabelBox,
  );
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
