/// A node of the layered graph (#530): the unit the compound layout ranks,
/// orders and places.
library;

import 'package:niman/src/diagrams/layered_cluster.dart';

/// What a node stands for.
enum LayeredNodeKind {
  /// A box the caller asked for.
  real,

  /// A stand-in the layout adds on a long edge, one per rank it crosses.
  dummy,

  /// The top or the bottom of a cluster: it holds the cluster's first and
  /// last rank, and an edge that names the cluster ends on it.
  border,

  /// The node the nesting graph hangs everything on while ranking; it
  /// leaves the graph again before the ranks are read.
  nestingRoot,
}

/// One node: a size, a place in the cluster tree, and the rank the layout
/// gives it.
final class LayeredNode {
  /// Creates a node; a [LayeredGraph](layered_graph.dart) makes them.
  new({
    required this.id,
    required this.index,
    required this.width,
    required this.height,
    required this.kind,
    this.parent,
  });

  /// The caller's name for it, unique in the graph (clusters included).
  final String id;

  /// Its place in the graph's node list: the order it was added in.
  final int index;

  /// How wide it is, in logical pixels.
  final double width;

  /// How tall it is, in logical pixels.
  final double height;

  /// What it stands for.
  final LayeredNodeKind kind;

  /// The cluster it sits in, or null at the top level. A border node sits
  /// in the cluster it bounds, though that cluster does not list it as a
  /// member.
  final LayeredCluster? parent;

  /// Its rank: the row it is in, counted from 0 at the top. Set by the
  /// ranking.
  int rank = 0;

  @override
  String toString() => 'LayeredNode($id, rank $rank)';
}
