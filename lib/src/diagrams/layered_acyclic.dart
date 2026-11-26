/// Making the layered graph acyclic (#530): a rank is a direction, so a
/// ring of edges has to be opened before anything can be ranked.
///
/// A walk in the order the nodes were added, following each node's edges in
/// the order they were added, finds the ring: an edge back to a node still
/// on the walk's path closes one, and that edge is turned round. So the
/// node written first stays on top of its ring, as the flowchart layout
/// has always had it. A turned edge is kept in the graph and marked, so a
/// later stage draws it the way the caller gave it.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// Opens every ring in [graph]'s edges.
///
/// Self loops are set aside ([LayeredEdgeFlow.loop]), and so is an edge
/// that ties a cluster to a node inside it, or to itself: no rank can
/// honour it ([LayeredEdgeFlow.free]). The rest that closes a ring is
/// turned round ([LayeredEdgeFlow.reversed]). Linear in the graph.
void breakCycles(LayeredGraph graph) {
  for (final edge in graph.edges) {
    if (edge.clusterEnd && _tiesClusterToItself(graph, edge)) {
      edge.flow = LayeredEdgeFlow.free;
    }
  }
  _closingEdges(graph).forEach(graph.reverse);
}

/// Whether [edge] joins a cluster to a node or a cluster that is inside it
/// (or to itself): its ends cannot be a top above everything and a bottom
/// below everything at once.
bool _tiesClusterToItself(LayeredGraph graph, LayeredEdge edge) {
  final from = graph.cluster(edge.fromId);
  final to = graph.cluster(edge.toId);
  return (from != null && _isInside(graph, edge.toId, from)) ||
      (to != null && _isInside(graph, edge.fromId, to));
}

/// Whether the node or cluster [id] is [cluster], or inside it.
bool _isInside(LayeredGraph graph, String id, LayeredCluster cluster) {
  final inner = graph.cluster(id) ?? graph.node(id)?.parent;
  return inner != null && inner.isWithin(cluster);
}

/// The edges that close a ring on a walk through [graph].
List<LayeredEdge> _closingEdges(LayeredGraph graph) {
  const onPath = 1;
  const done = 2;
  final state = Uint8List(graph.nodes.length);
  final cursor = Int32List(graph.nodes.length);
  final closing = <LayeredEdge>[];
  final stack = <LayeredNode>[];
  for (final root in graph.nodes) {
    if (state[root.index] != 0) continue;
    state[root.index] = onPath;
    stack.add(root);
    while (stack.isNotEmpty) {
      final node = stack.last;
      final out = graph.outEdges(node);
      if (cursor[node.index] == out.length) {
        state[node.index] = done;
        stack.removeLast();
        continue;
      }
      final edge = out[cursor[node.index]++];
      if (!edge.ranked) continue;
      final next = state[edge.to.index];
      if (next == onPath) {
        closing.add(edge);
      } else if (next == 0) {
        state[edge.to.index] = onPath;
        stack.add(edge.to);
      }
    }
  }
  return closing;
}
