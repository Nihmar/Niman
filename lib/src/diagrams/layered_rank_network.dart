/// The graph as the ranking reads it (#530): flat arrays, so a ranking of
/// thousands of nodes does not chase an object per edge.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_graph.dart';

/// The ranked edges of a [LayeredGraph], one per ordered pair of nodes, and
/// a rank for every node.
///
/// Edges between the same two nodes in the same direction are one: their
/// weights add and the longer minimum length holds, which ranks the same
/// and keeps the ranking short. Each node knows the edges at it in two
/// runs, the ones that leave it and then the ones that arrive.
final class RankNetwork {
  new _(this.nodeCount, this.tail, this.head, this.minlen, this.weight)
    : edgeCount = tail.length,
      rank = Int32List(nodeCount),
      incStart = Int32List(nodeCount + 1),
      outEnd = Int32List(nodeCount),
      incEdges = Int32List(2 * tail.length),
      surplus = Float64List(nodeCount) {
    _index();
  }

  /// Reads the ranked edges of [graph]. A caller's edge is [rankFactor]
  /// times [spacing] times as long as it asks to be, and at least [spacing]
  /// times [rankFactor] if it has a label, which needs a rank of its own;
  /// the nesting graph's own edges are as long as they are.
  factory of(LayeredGraph graph, int rankFactor, {int spacing = 1}) {
    final nodeCount = graph.nodes.length;
    final tail = <int>[];
    final head = <int>[];
    final minlen = <int>[];
    final weight = <double>[];
    final at = <int, int>{};
    for (final edge in graph.edges) {
      if (!edge.ranked) continue;
      final from = edge.from.index;
      final to = edge.to.index;
      final asked = edge.hasLabel && edge.minlen < 1 ? 1 : edge.minlen;
      final length = edge.nesting ? edge.minlen : asked * spacing * rankFactor;
      final merged = at[from * nodeCount + to];
      if (merged == null) {
        at[from * nodeCount + to] = tail.length;
        tail.add(from);
        head.add(to);
        minlen.add(length);
        weight.add(edge.weight);
      } else {
        weight[merged] += edge.weight;
        if (length > minlen[merged]) minlen[merged] = length;
      }
    }
    return RankNetwork._(
      nodeCount,
      Int32List.fromList(tail),
      Int32List.fromList(head),
      Int32List.fromList(minlen),
      Float64List.fromList(weight),
    );
  }

  /// How many nodes there are.
  final int nodeCount;

  /// How many edges there are.
  final int edgeCount;

  /// The node each edge leaves from.
  final Int32List tail;

  /// The node each edge arrives at.
  final Int32List head;

  /// The fewest ranks each edge spans.
  final Int32List minlen;

  /// How much each edge matters.
  final Float64List weight;

  /// Each node's rank: what the ranking works on.
  final Int32List rank;

  /// Where each node's edges start in [incEdges]; one more than there are
  /// nodes, so a node's run ends where the next begins.
  final Int32List incStart;

  /// Where the edges that arrive at each node start in its run.
  final Int32List outEnd;

  /// The edges at each node: the run of node `v` is [incStart]`[v]` up to
  /// [incStart]`[v + 1]`, its first part the edges that leave it, up to
  /// [outEnd]`[v]`, then the edges that arrive.
  final Int32List incEdges;

  /// How much more weight leaves each node than arrives at it.
  final Float64List surplus;

  /// How far [edge] is longer than it has to be.
  int slack(int edge) => rank[head[edge]] - rank[tail[edge]] - minlen[edge];

  /// Sets every rank to the shortest that keeps each edge as long as it has
  /// to be, a node no higher than the last of the edges that arrive at it
  /// asks. Throws if the edges close a ring.
  void rankByLongestPath() {
    final remaining = Int32List(nodeCount);
    final queue = Int32List(nodeCount);
    var tailAt = 0;
    for (var v = 0; v < nodeCount; v++) {
      remaining[v] = incStart[v + 1] - outEnd[v];
      rank[v] = 0;
      if (remaining[v] == 0) queue[tailAt++] = v;
    }
    for (var headAt = 0; headAt < tailAt; headAt++) {
      final v = queue[headAt];
      for (var i = incStart[v]; i < outEnd[v]; i++) {
        final edge = incEdges[i];
        final to = head[edge];
        final asked = rank[v] + minlen[edge];
        if (asked > rank[to]) rank[to] = asked;
        if (--remaining[to] == 0) queue[tailAt++] = to;
      }
    }
    if (tailAt < nodeCount) throw StateError('The edges close a ring.');
  }

  void _index() {
    final outCount = Int32List(nodeCount);
    final inCount = Int32List(nodeCount);
    for (var e = 0; e < edgeCount; e++) {
      outCount[tail[e]]++;
      inCount[head[e]]++;
      surplus[tail[e]] += weight[e];
      surplus[head[e]] -= weight[e];
    }
    for (var v = 0; v < nodeCount; v++) {
      incStart[v + 1] = incStart[v] + outCount[v] + inCount[v];
      outEnd[v] = incStart[v] + outCount[v];
    }
    final outAt = Int32List.fromList(incStart);
    final inAt = Int32List.fromList(outEnd);
    for (var e = 0; e < edgeCount; e++) {
      incEdges[outAt[tail[e]]++] = e;
      incEdges[inAt[head[e]]++] = e;
    }
  }
}
