/// The compound layered layout (#530), as far as it goes: the pipeline the
/// stages run in.
///
/// Ranks, then stand-ins for long edges, each in the cluster its edge is
/// in, then the sides of every cluster, then the order within each rank.
/// The placing, the boxes and the edges' points come after.
library;

import 'package:niman/src/diagrams/layered_border_segments.dart';
import 'package:niman/src/diagrams/layered_cluster.dart' show LayeredCluster;
import 'package:niman/src/diagrams/layered_edge.dart' show LayeredEdge;
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart' show LayeredNode;
import 'package:niman/src/diagrams/layered_normalize.dart';
import 'package:niman/src/diagrams/layered_order.dart';
import 'package:niman/src/diagrams/layered_parent_chains.dart';
import 'package:niman/src/diagrams/layered_rank.dart';

/// Lays out [graph] as far as its nodes' ranks and orders: afterwards every
/// node has a [LayeredNode.rank] and a [LayeredNode.order], every cluster a
/// [LayeredCluster.minRank] and [LayeredCluster.maxRank] and border nodes down
/// its sides, and every long edge a [LayeredEdge.chain] of stand-ins.
///
/// Self loops and edges no rank can honour take no part.
void layOutLayered(LayeredGraph graph) {
  if (graph.nodes.isEmpty) return;
  rankLayered(graph);
  normalizeEdges(graph);
  parentDummyChains(graph);
  addBorderSegments(graph);
  orderLayered(graph);
}
