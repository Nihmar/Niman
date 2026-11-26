/// A node of the layered graph (#530): the unit the compound layout ranks,
/// orders and places.
library;

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_edge.dart';

/// What a node stands for.
enum LayeredNodeKind {
  /// A box the caller asked for.
  real,

  /// A stand-in the layout adds on a long edge, one per rank it crosses.
  dummy,

  /// The stand-in on a long edge that holds the room for its label.
  edgeLabel,

  /// The top or the bottom of a cluster: it holds the cluster's first and
  /// last rank, and an edge that names the cluster ends on it.
  border,

  /// The node the nesting graph hangs everything on while ranking; it
  /// leaves the graph again before the ranks are read.
  nestingRoot,
}

/// Which edge of a cluster's frame a border node is on.
enum LayeredBorder {
  /// The top: the node every member of the cluster is below.
  top,

  /// The bottom: the node every member of the cluster is above.
  bottom,

  /// The left side, in one rank.
  left,

  /// The right side, in one rank.
  right,
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
    this.side,
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

  /// Which edge of its cluster's frame it is on, for a border node.
  final LayeredBorder? side;

  /// The cluster it sits in, or null at the top level. A border node sits
  /// in the cluster it bounds, and a stand-in on an edge inside the cluster
  /// it crosses, though that cluster does not list either as a member.
  LayeredCluster? parent;

  /// Its rank: the row it is in, counted from 0 at the top. Set by the
  /// ranking.
  int rank = 0;

  /// Its place in its rank, counted from the left. Set by the ordering.
  int order = 0;

  /// The edge a stand-in is on, or null for any other node.
  LayeredEdge? edge;

  /// Where a stand-in is on its edge's chain: 0 for the one next to the
  /// edge's start.
  int chainIndex = -1;

  @override
  String toString() => 'LayeredNode($id, rank $rank)';
}
