/// An edge of the layered graph (#530).
library;

import 'package:niman/src/diagrams/layered_node.dart';

/// A point of the layout.
typedef LayeredPoint = ({double x, double y});

/// How the ranking treats an edge.
enum LayeredEdgeFlow {
  /// As the caller gave it: it points from a lower rank to a higher one.
  forward,

  /// Against the caller's direction, to break a cycle: the drawing turns
  /// its points back.
  reversed,

  /// A self loop: it takes no part in the ranking, and is drawn beside its
  /// node.
  loop,

  /// An edge no rank can honour, because it ties a cluster to a node
  /// inside it or closes a ring of such ties: it takes no part in the
  /// ranking.
  free,
}

/// One edge between two nodes — or between a node and a cluster, which
/// ties it to the cluster's top as a target and to its bottom as a source.
final class LayeredEdge {
  /// Creates an edge; a [LayeredGraph](layered_graph.dart) makes them.
  new({
    required this.index,
    required this.fromId,
    required this.toId,
    required this.from,
    required this.to,
    required this.minlen,
    required this.weight,
    this.labelWidth = 0,
    this.labelHeight = 0,
    this.tailRoom = 0,
    this.headRoom = 0,
    this.source = -1,
    this.clusterEnd = false,
    this.nesting = false,
  });

  /// Its place in the graph's edge list: the order it was added in.
  final int index;

  /// The id of the node or cluster the caller drew it from.
  final String fromId;

  /// The id of the node or cluster the caller drew it to.
  final String toId;

  /// The node it leaves from in the ranking: the caller's own, or the
  /// other end's once [LayeredEdgeFlow.reversed].
  LayeredNode from;

  /// The node it arrives at in the ranking.
  LayeredNode to;

  /// The fewest ranks between its ends, 0 or more.
  final int minlen;

  /// How much it matters that it is short.
  final double weight;

  /// The width of its label, 0 if it has none.
  final double labelWidth;

  /// The height of its label, 0 if it has none.
  final double labelHeight;

  /// The room along the edge it needs next to its tail: for an arrow cap
  /// or a text at that end.
  final double tailRoom;

  /// The room along the edge it needs next to its head.
  final double headRoom;

  /// The caller's index for it, or -1 if it is the layout's own.
  final int source;

  /// Whether an end of it is a cluster.
  final bool clusterEnd;

  /// Whether the nesting graph made it, to hold a cluster together.
  final bool nesting;

  /// How the ranking treats it.
  LayeredEdgeFlow flow = LayeredEdgeFlow.forward;

  /// Whether it has a label.
  bool get hasLabel => labelWidth > 0 || labelHeight > 0;

  /// The stand-ins on it, one in each rank between its ends, from the one
  /// below [from] to the one above [to]. Empty if it spans one rank or none.
  /// Set when the edges are normalised.
  final List<LayeredNode> chain = [];

  /// The rank its label sits in, strictly between its ends, or -1 if it has
  /// no label or has not been ranked.
  int labelRank = -1;

  /// The stand-in that holds the room for its label, once it is normalised.
  LayeredNode? labelNode;

  /// Where it goes once the layout is done: its tail's anchor, each stand-in's
  /// centre, its head's anchor, running as the caller drew it whichever way
  /// it was ranked. An end that is a cluster is anchored on the outline of
  /// the cluster's box. Empty for a self loop, a flat edge or one no rank
  /// could honour: they are the caller's to draw.
  List<LayeredPoint> points = const [];

  /// The centre of its label's stand-in, or null if it has no label.
  LayeredPoint? labelCenter;

  /// Whether it is turned against the caller's direction.
  bool get reversed => flow == LayeredEdgeFlow.reversed;

  /// Whether the ranking has to honour it.
  bool get ranked =>
      flow == LayeredEdgeFlow.forward || flow == LayeredEdgeFlow.reversed;

  @override
  String toString() => 'LayeredEdge($fromId -> $toId)';
}
