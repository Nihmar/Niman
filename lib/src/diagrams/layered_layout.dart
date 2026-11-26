/// The compound layered layout (#530), as far as it goes: the pipeline the
/// stages run in.
///
/// Ranks, then stand-ins for long edges, each in the cluster its edge is
/// in, then the sides of every cluster, then the order within each rank, then
/// the places: down the ranks, across them, the clusters' boxes and the
/// edges' points.
library;

import 'package:niman/src/diagrams/layered_border_segments.dart';
import 'package:niman/src/diagrams/layered_box.dart';
import 'package:niman/src/diagrams/layered_cluster.dart' show LayeredCluster;
import 'package:niman/src/diagrams/layered_edge.dart' show LayeredEdge;
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart' show LayeredNode;
import 'package:niman/src/diagrams/layered_normalize.dart';
import 'package:niman/src/diagrams/layered_options.dart';
import 'package:niman/src/diagrams/layered_order.dart';
import 'package:niman/src/diagrams/layered_parent_chains.dart';
import 'package:niman/src/diagrams/layered_position.dart';
import 'package:niman/src/diagrams/layered_rank.dart';

/// Lays out [graph], in canonical space — ranks run down, the order runs
/// right — and returns the box round the real nodes, the clusters and the
/// labels.
///
/// Afterwards every node has a [LayeredNode.rank], [LayeredNode.order] and a
/// centre ([LayeredNode.x], [LayeredNode.y]), every cluster a
/// [LayeredCluster.minRank], [LayeredCluster.maxRank] and a
/// [LayeredCluster.box], and every edge that could be ranked its
/// [LayeredEdge.points] and, if it has a label, a [LayeredEdge.labelCenter].
/// Self loops, flat edges and edges no rank can honour have no points: they
/// are the caller's to draw. Nothing is translated.
LayeredBox layOutLayered(
  LayeredGraph graph, [
  LayeredOptions options = const LayeredOptions(),
]) {
  if (graph.nodes.isEmpty) return LayeredBox.zero;
  rankLayered(graph);
  normalizeEdges(graph);
  parentDummyChains(graph);
  addBorderSegments(graph);
  orderLayered(graph);
  return positionLayered(graph, options);
}
