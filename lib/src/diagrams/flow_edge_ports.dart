/// Where on a node's side each edge leaves or reaches it (#530).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/layered_edge.dart';

/// Where the edges leave and reach their nodes, by index into the chart's
/// edges: the x of each end that shares its side with another.
typedef FlowPorts = ({Map<int, double> starts, Map<int, double> ends});

/// Where each edge leaves its tail's side and reaches its head's, by edge
/// index. An edge that runs down leaves the canonical bottom of its tail
/// and reaches the top of its head; one the layout turned back against the
/// chart, to break a cycle, leaves the top and reaches the bottom.
///
/// The edges sharing a side spread along its middle three fifths, each
/// where it comes from or goes to — the edge heading furthest left at the
/// leftmost point — so neither their lines nor the marks at their ends lie
/// on one another. An edge that goes both ways between two nodes has one
/// of each on a side, and the two are kept apart the same way. A side with
/// one edge keeps its middle (null). [rects] are the nodes', by id; an edge
/// to a subgraph's box has no port: it is anchored on the outline.
FlowPorts flowPorts(
  List<FlowEdge> edges,
  List<LayeredEdge?> routes,
  Map<String, Rect> rects,
) {
  final sides = <(String, bool), List<_Use>>{};
  for (var i = 0; i < edges.length; i++) {
    final route = routes[i];
    if (route == null || route.flow == LayeredEdgeFlow.free) continue;
    final points = route.points;
    if (points.length < 2) continue;
    final down = !route.reversed;
    final edge = edges[i];
    // Where an end heads: the next point of the way, or the other end.
    if (rects.containsKey(edge.from)) {
      (sides[(edge.from, down)] ??= []).add(
        _Use(i, tail: true, towards: points[1].x),
      );
    }
    if (rects.containsKey(edge.to)) {
      (sides[(edge.to, !down)] ??= []).add(
        _Use(i, tail: false, towards: points[points.length - 2].x),
      );
    }
  }
  final starts = <int, double>{};
  final ends = <int, double>{};
  for (final MapEntry(key: (id, _), value: uses) in sides.entries) {
    if (uses.length < 2) continue;
    uses.sort();
    final rect = rects[id]!;
    final span = rect.width * 0.6;
    for (var k = 0; k < uses.length; k++) {
      final x = rect.center.dx - span / 2 + span * k / (uses.length - 1);
      (uses[k].tail ? starts : ends)[uses[k].edge] = x;
    }
  }
  return (starts: starts, ends: ends);
}

/// An end of an edge on one side of a node.
final class _Use implements Comparable<_Use> {
  const new(this.edge, {required this.tail, required this.towards});

  final int edge;
  final bool tail;
  final double towards;

  @override
  int compareTo(_Use other) {
    final cmp = towards.compareTo(other.towards);
    if (cmp != 0) return cmp;
    final byEdge = edge.compareTo(other.edge);
    if (byEdge != 0) return byEdge;
    return tail == other.tail ? 0 : (tail ? -1 : 1);
  }
}
