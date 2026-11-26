/// Placing the laid-out graph (#530): the last stage, in canonical space —
/// ranks run down, the order runs right.
///
/// The rows get their heights and their places down the page, the nodes
/// their places across it, and what the caller reads is made from them: a
/// box for each cluster, and a list of points for each edge.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/layered_box.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_options.dart';
import 'package:niman/src/diagrams/layered_position_x.dart';
import 'package:niman/src/diagrams/layered_position_y.dart';
import 'package:niman/src/diagrams/layered_segments.dart';

/// Gives every node of [graph] an x and a y, every cluster a box and every
/// edge its points, and returns the box that holds the real nodes, the
/// clusters and the labels. The graph must be ranked and ordered.
///
/// Nothing is translated: the coordinates are where the layout put them,
/// and the first rank's top is at y 0.
LayeredBox positionLayered(LayeredGraph graph, LayeredOptions options) {
  positionRanks(graph, options);
  positionAcross(graph, LayeredSegments.of(graph), options);
  for (final cluster in graph.clusters) {
    var left = double.infinity;
    var right = double.negativeInfinity;
    for (final node in cluster.borderLeft) {
      left = math.min(left, node.x);
    }
    for (final node in cluster.borderRight) {
      right = math.max(right, node.x);
    }
    cluster.box = LayeredBox(
      left,
      cluster.borderTop.y,
      right,
      cluster.borderBottom.y,
    );
  }
  graph.edges.forEach(_route);
  return _bounds(graph);
}

/// Sets [edge]'s points and label centre.
void _route(LayeredEdge edge) {
  final label = edge.labelNode;
  edge.labelCenter = label == null ? null : (x: label.x, y: label.y);
  if (!edge.ranked || edge.to.rank - edge.from.rank < 1) {
    edge.points = const [];
    return;
  }
  final points = <LayeredPoint>[
    for (final node in [edge.from, ...edge.chain, edge.to])
      (x: node.x, y: node.y),
  ];
  edge.points = edge.reversed ? points.reversed.toList() : points;
}

/// The box round the real nodes, the clusters' boxes and the labels.
LayeredBox _bounds(LayeredGraph graph) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  void take(double l, double t, double r, double b) {
    left = math.min(left, l);
    top = math.min(top, t);
    right = math.max(right, r);
    bottom = math.max(bottom, b);
  }

  for (final node in graph.nodes) {
    if (node.kind != LayeredNodeKind.real &&
        node.kind != LayeredNodeKind.edgeLabel) {
      continue;
    }
    take(
      node.x - node.width / 2,
      node.y - node.height / 2,
      node.x + node.width / 2,
      node.y + node.height / 2,
    );
  }
  for (final cluster in graph.clusters) {
    final box = cluster.box;
    take(box.left, box.top, box.right, box.bottom);
  }
  return left.isFinite ? LayeredBox(left, top, right, bottom) : LayeredBox.zero;
}
