/// The first answer of the network simplex (#530): a spanning tree of tight
/// edges.
///
/// After Gansner, Koutsofios, North and Vo, "A Technique for Drawing
/// Directed Graphs". An edge is tight when it is no longer than it has to
/// be. A tree of tight edges that reaches every node fixes the ranks
/// relative to each other, and the simplex then only has to trade one tree
/// edge for another.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_min_heap.dart';
import 'package:niman/src/diagrams/layered_rank_network.dart';

/// Grows a tree of tight edges over every node of [network], moving ranks
/// as it goes so that each edge it takes in is tight and none is shorter
/// than it must be. Returns which edges are in the tree.
///
/// The network must be connected, and its ranks must already honour every
/// minimum length. The tree starts at the first node and takes in, each
/// time, the edge to a node outside it that has the least slack: if that is
/// none, the tree as a whole moves until it is. Moving the whole tree is
/// one number, not a pass over its nodes, and the edges to choose among
/// wait in two heaps, so it is all O(E log E).
Uint8List feasibleTree(RankNetwork network) {
  final inTree = Uint8List(network.nodeCount);
  final inTreeEdge = Uint8List(network.edgeCount);
  final rank = network.rank;
  // How far the tree has moved: a node in it is at its rank plus this.
  var moved = 0;
  var size = 0;
  // Edges that leave a node in the tree for one outside it, by the slack
  // they have before the tree moves, and edges that arrive at one in it.
  final leaving = LayeredMinHeap();
  final arriving = LayeredMinHeap();

  void join(int node) {
    // From here its rank is kept as what it is before the tree moves.
    rank[node] -= moved;
    inTree[node] = 1;
    size++;
    for (var i = network.incStart[node]; i < network.outEnd[node]; i++) {
      final edge = network.incEdges[i];
      final to = network.head[edge];
      if (inTree[to] == 0) {
        leaving.push(rank[to] - rank[node] - network.minlen[edge], edge);
      }
    }
    for (var i = network.outEnd[node]; i < network.incStart[node + 1]; i++) {
      final edge = network.incEdges[i];
      final from = network.tail[edge];
      if (inTree[from] == 0) {
        arriving.push(rank[node] - rank[from] - network.minlen[edge], edge);
      }
    }
  }

  // An edge whose far end has since joined the tree by another way is of no
  // use: its heap entry is dropped when it comes to the top.
  void dropStale() {
    while (!leaving.isEmpty && inTree[network.head[leaving.topValue]] == 1) {
      leaving.pop();
    }
    while (!arriving.isEmpty && inTree[network.tail[arriving.topValue]] == 1) {
      arriving.pop();
    }
  }

  join(0);
  while (size < network.nodeCount) {
    dropStale();
    if (leaving.isEmpty && arriving.isEmpty) {
      throw StateError('The network is not connected.');
    }
    final fromLeaving =
        arriving.isEmpty ||
        (!leaving.isEmpty &&
            (leaving.topKey - moved < arriving.topKey + moved ||
                (leaving.topKey - moved == arriving.topKey + moved &&
                    leaving.topValue < arriving.topValue)));
    if (fromLeaving) {
      // The tree is the edge's tail: moving it down closes the gap.
      moved = leaving.topKey;
      final edge = leaving.topValue;
      leaving.pop();
      inTreeEdge[edge] = 1;
      join(network.head[edge]);
    } else {
      // The tree is the edge's head: moving it up closes the gap.
      moved = -arriving.topKey;
      final edge = arriving.topValue;
      arriving.pop();
      inTreeEdge[edge] = 1;
      join(network.tail[edge]);
    }
  }
  for (var node = 0; node < network.nodeCount; node++) {
    rank[node] += moved;
  }
  return inTreeEdge;
}
