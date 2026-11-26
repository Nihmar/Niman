/// Placing the laid-out graph (#530): the last stage, in canonical space —
/// ranks run down, the order runs right.
///
/// The rows get their heights and their places down the page, the nodes
/// their places across it, and what the caller reads is made from them: a
/// box for each cluster, and a list of points for each edge.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/layered_box.dart';
import 'package:niman/src/diagrams/layered_cluster.dart';
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
  // Inside out, so a cluster can hug the boxes of the clusters in it.
  final labels = <LayeredCluster, List<LayeredNode>>{};
  for (final node in graph.nodes) {
    final parent = node.parent;
    if (node.kind == LayeredNodeKind.edgeLabel && parent != null) {
      (labels[parent] ??= []).add(node);
    }
  }
  final inside = [...graph.clusters]..sort((a, b) => b.depth - a.depth);
  for (final cluster in inside) {
    _box(cluster, labels[cluster] ?? const []);
  }
  graph.edges.forEach(_route);
  return _bounds(graph);
}

/// Gives [cluster] its box: from its left side to its right, and from the
/// top of what it holds less its pad to the bottom of it plus its pad. What it
/// holds is its boxes, the label stand-ins on its edges and the boxes of the
/// clusters in it — whose own boxes must be made. The stand-ins of other
/// edges, passing through, do not hold it open, so a cluster in a row that a
/// tall box outside it made tall is no taller than its own content. The box
/// is never taller than the band from the cluster's top rank to its bottom
/// rank, which is as it was when the box was drawn from them, and an empty
/// cluster keeps the band.
void _box(LayeredCluster cluster, List<LayeredNode> labels) {
  var left = double.infinity;
  var right = double.negativeInfinity;
  for (final node in cluster.borderLeft) {
    left = math.min(left, node.x);
  }
  for (final node in cluster.borderRight) {
    right = math.max(right, node.x);
  }
  var top = double.infinity;
  var bottom = double.negativeInfinity;
  void hold(double from, double to) {
    top = math.min(top, from);
    bottom = math.max(bottom, to);
  }

  for (final node in cluster.nodes) {
    hold(node.y - node.height / 2, node.y + node.height / 2);
  }
  for (final inner in cluster.clusters) {
    hold(inner.box.top, inner.box.bottom);
  }
  for (final node in labels) {
    hold(node.y - node.height / 2, node.y + node.height / 2);
  }
  final band = (top: cluster.borderTop.y, bottom: cluster.borderBottom.y);
  if (top.isFinite) {
    cluster.borderTop.y = math.max(band.top, top - cluster.padTop);
    cluster.borderBottom.y = math.min(band.bottom, bottom + cluster.padBottom);
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
  final middle = (left + right) / 2;
  cluster.borderTop.x = middle;
  cluster.borderBottom.x = middle;
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
