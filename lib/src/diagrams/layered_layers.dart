/// The ranks of a layered graph as the ordering sees them (#530): each with
/// its nodes, and the clusters that cross it holding theirs.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// For every rank, what is in it and how it nests.
///
/// A rank holds nodes, and the clusters whose box spans it, which hold their
/// own nodes in that rank and the clusters inside them. In the lists a node
/// is its index, and a cluster is the graph's node count plus its index.
/// Each list is in the order things were added to the graph, a cluster
/// standing where its top node does, so that is the order ties between them
/// are broken in.
final class LayeredLayers {
  new _(
    this.nodeCount,
    this.rankOf,
    this.nodeParent,
    this.clusterParent,
    this.nodesAt,
    this.top,
    this.inside,
  );

  /// Sorts the nodes and clusters of [graph], which must have its nodes
  /// ranked, its edges normalised and its border segments added.
  factory of(LayeredGraph graph) {
    var last = 0;
    for (final node in graph.nodes) {
      if (node.rank > last) last = node.rank;
    }
    final count = graph.nodes.length;
    final nodesAt = [for (var r = 0; r <= last; r++) <int>[]];
    final top = [for (var r = 0; r <= last; r++) <int>[]];
    final inside = [
      for (final cluster in graph.clusters)
        [for (var r = cluster.minRank; r <= cluster.maxRank; r++) <int>[]],
    ];
    List<int> holder(LayeredCluster? cluster, int rank) {
      return cluster == null
          ? top[rank]
          : inside[cluster.index][rank - cluster.minRank];
    }

    final rankOf = Int32List(count);
    final nodeParent = Int32List(count);
    final clusterParent = Int32List(graph.clusters.length);
    for (final cluster in graph.clusters) {
      clusterParent[cluster.index] = cluster.parent?.index ?? -1;
    }
    for (final node in graph.nodes) {
      rankOf[node.index] = node.rank;
      nodeParent[node.index] = node.parent?.index ?? -1;
      if (node.side == LayeredBorder.top && node.parent != null) {
        final cluster = node.parent!;
        for (var r = cluster.minRank; r <= cluster.maxRank; r++) {
          holder(cluster.parent, r).add(count + cluster.index);
        }
      }
      nodesAt[node.rank].add(node.index);
      holder(node.parent, node.rank).add(node.index);
    }
    return LayeredLayers._(
      count,
      rankOf,
      nodeParent,
      clusterParent,
      nodesAt,
      top,
      inside,
    );
  }

  /// How many nodes the graph has: the number a cluster's index is added to.
  final int nodeCount;

  /// The rank of every node.
  final Int32List rankOf;

  /// The index of the cluster each node is in, or -1 outside every cluster.
  final Int32List nodeParent;

  /// The index of the cluster each cluster is in, or -1 outside every other.
  final Int32List clusterParent;

  /// Every node in each rank, in the order they were added.
  final List<List<int>> nodesAt;

  /// What is in each rank outside every cluster.
  final List<List<int>> top;

  /// What each cluster holds in each of its ranks: `inside[cluster][r -
  /// minRank]` for the rank `r`, its left and right border nodes among it.
  final List<List<List<int>>> inside;

  /// How many ranks there are.
  int get rankCount => nodesAt.length;
}
