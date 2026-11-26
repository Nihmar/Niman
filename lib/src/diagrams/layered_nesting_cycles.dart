/// Rings the nesting graph closes (#530).
///
/// [breakCycles](layered_acyclic.dart) opens the rings among the caller's
/// edges, but an edge that names a cluster is also tied to the cluster's
/// top or bottom, and those are tied to its members: `b --> a` and
/// `a --> S` with `b` inside `S` is a ring through `S`'s top, and only the
/// nesting graph shows it. Such a ring always holds an edge that names a
/// cluster, so that edge is the one given up: turned round, and if that
/// closes a ring again, set aside.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// Opens every ring left in [graph] once its nesting graph is added.
///
/// A walk finds a ring and the edge that names a cluster on it is
/// turned or set aside; the walk starts again until none is left. A graph
/// that no edge names a cluster in has none to find, and costs nothing.
void breakNestingCycles(LayeredGraph graph) {
  if (!graph.edges.any((edge) => edge.clusterEnd)) return;
  List<LayeredEdge>? ring;
  while ((ring = _findRing(graph)) != null) {
    final named = ring!.where((edge) => edge.clusterEnd).toList();
    if (named.isEmpty) {
      throw StateError('A ring of edges none of which names a cluster.');
    }
    final edge = named.firstWhere(
      (edge) => !edge.reversed,
      orElse: () => named.first,
    );
    if (edge.reversed) {
      edge.flow = LayeredEdgeFlow.free;
    } else {
      graph.reverse(edge);
    }
  }
}

/// The edges of one ring in [graph], or null if it has none.
List<LayeredEdge>? _findRing(LayeredGraph graph) {
  const onPath = 1;
  const done = 2;
  final state = Uint8List(graph.nodes.length);
  final cursor = Int32List(graph.nodes.length);
  final path = <LayeredNode>[];
  final entered = <LayeredEdge?>[];
  for (final root in graph.nodes) {
    if (state[root.index] != 0) continue;
    state[root.index] = onPath;
    path.add(root);
    entered.add(null);
    while (path.isNotEmpty) {
      final node = path.last;
      final out = graph.outEdges(node);
      if (cursor[node.index] == out.length) {
        state[node.index] = done;
        path.removeLast();
        entered.removeLast();
        continue;
      }
      final edge = out[cursor[node.index]++];
      if (!edge.ranked) continue;
      final next = state[edge.to.index];
      if (next == 0) {
        state[edge.to.index] = onPath;
        path.add(edge.to);
        entered.add(edge);
      } else if (next == onPath) {
        final start = path.indexOf(edge.to);
        return [
          edge,
          for (var i = start + 1; i < path.length; i++) entered[i]!,
        ];
      }
    }
  }
  return null;
}
