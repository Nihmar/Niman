/// The sides of a cluster, rank by rank (#530).
///
/// After dagre's `addBorderSegments`. A cluster has a node on its left and
/// one on its right in every rank its box spans. The ordering keeps every
/// member of the cluster between them, which is what keeps a cluster's box
/// from running through the nodes of another, and the placing reads the
/// box's sides from their positions.
library;

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// Adds a left and a right border node to every cluster of [graph] in each
/// rank from its [LayeredCluster.minRank] to its [LayeredCluster.maxRank],
/// kept in [LayeredCluster.borderLeft] and [LayeredCluster.borderRight].
/// The clusters must have been ranked.
void addBorderSegments(LayeredGraph graph) {
  for (final cluster in graph.clusters) {
    if (cluster.borderLeft.isNotEmpty) continue;
    for (var rank = cluster.minRank; rank <= cluster.maxRank; rank++) {
      cluster.borderLeft.add(_border(graph, cluster, LayeredBorder.left, rank));
      cluster.borderRight.add(
        _border(graph, cluster, LayeredBorder.right, rank),
      );
    }
  }
}

LayeredNode _border(
  LayeredGraph graph,
  LayeredCluster cluster,
  LayeredBorder side,
  int rank,
) =>
    graph.addAuxiliary(LayeredNodeKind.border, parent: cluster, side: side)
      ..rank = rank;
