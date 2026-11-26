/// A cluster of the layered graph (#530): a group of nodes and clusters the
/// layout keeps together in a box.
library;

import 'package:niman/src/diagrams/layered_node.dart';

/// A group of nodes and clusters, itself in one cluster at most.
///
/// A cluster has no size of its own: its box is read from its members
/// and from its [borderTop] and [borderBottom] once the layout is done.
final class LayeredCluster {
  /// Creates a cluster; a [LayeredGraph](layered_graph.dart) makes them,
  /// with the two border nodes it passes in.
  new({
    required this.id,
    required this.index,
    required this.depth,
    this.parent,
  });

  /// The caller's name for it, unique in the graph (nodes included).
  final String id;

  /// Its place in the graph's cluster list: the order it was added in.
  final int index;

  /// How many clusters it is inside: 0 at the top level.
  final int depth;

  /// The cluster it is inside, or null at the top level.
  final LayeredCluster? parent;

  /// The nodes the caller put in it directly, in the order they were added.
  /// The layout's own stand-ins and border nodes are not listed.
  final List<LayeredNode> nodes = [];

  /// The clusters it holds directly, in the order they were added.
  final List<LayeredCluster> clusters = [];

  /// The node that stands for its top: every member lies below it.
  late final LayeredNode borderTop;

  /// The node that stands for its bottom: every member lies above it.
  late final LayeredNode borderBottom;

  /// The node on its left side in each rank of its box, from [minRank] on:
  /// the one in rank `r` is `borderLeft[r - minRank]`. Empty until the layout
  /// adds them.
  final List<LayeredNode> borderLeft = [];

  /// The node on its right side in each rank of its box, from [minRank] on.
  final List<LayeredNode> borderRight = [];

  /// The first rank of its box, once ranked: the rank of [borderTop].
  int minRank = 0;

  /// The last rank of its box, once ranked: the rank of [borderBottom].
  int maxRank = 0;

  /// Whether it holds nothing, neither a node nor a cluster.
  bool get isEmpty => nodes.isEmpty && clusters.isEmpty;

  /// Whether [other] is this cluster or one of those it is inside.
  bool isWithin(LayeredCluster other) {
    for (LayeredCluster? at = this; at != null; at = at.parent) {
      if (at == other) return true;
    }
    return false;
  }

  @override
  String toString() => 'LayeredCluster($id)';
}
