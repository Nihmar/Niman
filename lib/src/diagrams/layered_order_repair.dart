/// Keeping the edges that pass a cluster out of it (#530).
///
/// The sweeps decide the order rank by rank, and the constraints they keep
/// stop two sibling clusters swapping sides, but nothing in them keeps an edge
/// from changing sides of a cluster: two edges that leave one cluster may go
/// round another on its two sides, and the cluster they leave is only on one.
/// An edge that is left of a cluster in one rank and right of it in the next,
/// both of which the cluster spans, is drawn through its box.
///
/// This puts that right once the order is chosen: the stand-ins of such an
/// edge are moved to the side the edge keeps in the ranks the cluster spans,
/// each to the place beside the cluster's border. They stay at the level of
/// the cluster tree they were at, so no other cluster's members are parted.
/// Constraining the sweeps instead was tried: it left as many edges through
/// clusters, and cost crossings.
library;

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// How many times every edge is gone over: moving a stand-in beside one
/// cluster can take it across another.
const int _passes = 4;

/// Moves the stand-ins of [graph]'s long edges, whose [LayeredNode.order]
/// is set, so that no edge changes sides of a cluster between two ranks the
/// cluster spans, where it can: a stand-in inside some other cluster is not
/// moved out of it.
void keepEdgesOutOfClusters(LayeredGraph graph) {
  if (graph.clusters.isEmpty) return;
  var last = 0;
  for (final node in graph.nodes) {
    if (node.rank > last) last = node.rank;
  }
  final ranks = [for (var r = 0; r <= last; r++) <LayeredNode>[]];
  for (final node in graph.nodes) {
    ranks[node.rank].add(node);
  }
  for (final rank in ranks) {
    rank.sort((a, b) => a.order - b.order);
  }
  for (var pass = 0; pass < _passes; pass++) {
    var moved = false;
    for (final edge in graph.edges) {
      if (edge.chain.length < 2) continue;
      for (final cluster in graph.clusters) {
        if (_keep(edge, cluster, ranks)) moved = true;
      }
    }
    if (!moved) break;
  }
}

/// Puts the stand-ins of [edge] that are beside [cluster], in the ranks it
/// spans, on one side of it. One inside a cluster of the same level, which is
/// not moved out of it, shows which side: the first of those, or if there is
/// none, the side the first stand-in is on. Whether any was moved.
bool _keep(
  LayeredEdge edge,
  LayeredCluster cluster,
  List<List<LayeredNode>> ranks,
) {
  final first = edge.from.rank + 1;
  final from = (cluster.minRank - first).clamp(0, edge.chain.length);
  final to = (cluster.maxRank - first + 1).clamp(0, edge.chain.length);
  // Which side of the cluster each stand-in of the stretch is on, and
  // whether it can be moved: -1 left, 1 right, 0 not at its level.
  var side = 0;
  var fixedSide = 0;
  final movable = <LayeredNode>[];
  for (var i = from; i < to; i++) {
    final stand = edge.chain[i];
    final at = stand.rank - cluster.minRank;
    if (stand.parent == cluster.parent) {
      movable.add(stand);
      if (side == 0) side = stand.order < cluster.borderLeft[at].order ? -1 : 1;
      continue;
    }
    // Inside a cluster beside this one: where that is.
    var beside = stand.parent;
    while (beside != null && beside.parent != cluster.parent) {
      beside = beside.parent;
    }
    if (beside == null || beside == cluster) continue;
    final there =
        beside.borderLeft[stand.rank - beside.minRank].order <
            cluster.borderLeft[at].order
        ? -1
        : 1;
    if (fixedSide == 0) fixedSide = there;
  }
  if (fixedSide != 0) side = fixedSide;
  var moved = false;
  for (final stand in movable) {
    final at = stand.rank - cluster.minRank;
    final now = stand.order < cluster.borderLeft[at].order ? -1 : 1;
    if (now == side) continue;
    final rank = ranks[stand.rank]..remove(stand);
    final border = side < 0 ? cluster.borderLeft[at] : cluster.borderRight[at];
    final index = rank.indexOf(border);
    rank.insert(side < 0 ? index : index + 1, stand);
    for (var k = 0; k < rank.length; k++) {
      rank[k].order = k;
    }
    moved = true;
  }
  return moved;
}
