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

/// Gives every node of [graph] an x and a y, every cluster a box and every
/// edge its points, and returns the box that holds the real nodes, the
/// clusters and the labels. The graph must be ranked and ordered.
///
/// Nothing is translated: the coordinates are where the layout put them,
/// and the first rank's top is at y 0.
LayeredBox positionLayered(LayeredGraph graph, LayeredOptions options) {
  positionRanks(graph, options);
  positionAcross(graph, options);
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
    // The top and the bottom float: they are where an edge to the cluster
    // ends, which is anchored on the outline in _route, and the middle is
    // as good a place as any for what is read from them otherwise.
    final middle = (cluster.box.left + cluster.box.right) / 2;
    cluster.borderTop.x = middle;
    cluster.borderBottom.x = middle;
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
  final nodes = [edge.from, ...edge.chain, edge.to];
  final points = <LayeredPoint>[
    for (final node in nodes) (x: node.x, y: node.y),
  ];
  // An end that names a cluster is anchored on the cluster's outline, as
  // near the edge's next point as the box allows, so the edge arrives
  // straight where it can instead of at a spot the box was no part in.
  if (floatsInCluster(edge.from)) {
    points[0] = _anchored(edge.from, points[1].x);
  }
  if (floatsInCluster(edge.to)) {
    points[points.length - 1] = _anchored(edge.to, points[points.length - 2].x);
  }
  edge.points = edge.reversed ? points.reversed.toList() : points;
}

/// The point on the outline of the cluster that [border], its top or its
/// bottom, belongs to: [x] if that is inside the box less its pads, else the
/// nearest that is.
LayeredPoint _anchored(LayeredNode border, double x) {
  final cluster = border.parent!;
  final low = cluster.box.left + cluster.padLeft;
  final high = cluster.box.right - cluster.padRight;
  if (low > high) return (x: border.x, y: border.y);
  return (x: x.clamp(low, high), y: border.y);
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
