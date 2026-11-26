/// The one-rank pieces of a normalised layered graph (#530), in flat arrays:
/// what the ordering counts crossings over and the placing aligns along.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_graph.dart';

/// Every segment between two nodes in neighbouring ranks, read off a
/// graph whose edges are normalised and whose clusters have border nodes.
///
/// A segment is a piece of an edge — the edge itself if it spans one rank,
/// else the stretch between two stand-ins or between a stand-in and an end —
/// or a stretch of a cluster's left or right side from one rank to the
/// next, which counts for 1. Edges that span no rank, self loops and edges
/// no rank can honour are not segments.
///
/// For each node there are its segments up, to the rank above, and down, to
/// the rank below, in the order they were added; the other end of each, and
/// its weight, are in the arrays at the node's run.
final class LayeredSegments {
  new _(
    this.upStart,
    this.upNodes,
    this.upWeights,
    this.downStart,
    this.downNodes,
    this.downWeights,
  );

  /// Reads the segments of [graph].
  factory of(LayeredGraph graph) {
    final from = <int>[];
    final to = <int>[];
    final weight = <double>[];
    void add(int upper, int lower, double w) {
      from.add(upper);
      to.add(lower);
      weight.add(w);
    }

    for (final edge in graph.edges) {
      if (!edge.ranked) continue;
      final span = edge.to.rank - edge.from.rank;
      if (span < 1) continue;
      if (edge.chain.length != span - 1) {
        throw StateError('${edge.fromId} > ${edge.toId} is not normalised.');
      }
      var upper = edge.from;
      for (final stand in edge.chain) {
        add(upper.index, stand.index, edge.weight);
        upper = stand;
      }
      add(upper.index, edge.to.index, edge.weight);
    }
    for (final cluster in graph.clusters) {
      for (var i = 1; i < cluster.borderLeft.length; i++) {
        add(cluster.borderLeft[i - 1].index, cluster.borderLeft[i].index, 1);
        add(cluster.borderRight[i - 1].index, cluster.borderRight[i].index, 1);
      }
    }
    final count = graph.nodes.length;
    final (downStart, downNodes, downWeights) = _index(count, from, to, weight);
    final (upStart, upNodes, upWeights) = _index(count, to, from, weight);
    return LayeredSegments._(
      upStart,
      upNodes,
      upWeights,
      downStart,
      downNodes,
      downWeights,
    );
  }

  /// Where each node's segments up start in [upNodes]; one more than there
  /// are nodes, so a node's run ends where the next begins.
  final Int32List upStart;

  /// The node at the other end of each segment up.
  final Int32List upNodes;

  /// The weight of each segment up.
  final Float64List upWeights;

  /// Where each node's segments down start in [downNodes].
  final Int32List downStart;

  /// The node at the other end of each segment down.
  final Int32List downNodes;

  /// The weight of each segment down.
  final Float64List downWeights;

  /// Groups the pairs by their first node, keeping their order.
  static (Int32List, Int32List, Float64List) _index(
    int count,
    List<int> near,
    List<int> far,
    List<double> weight,
  ) {
    final start = Int32List(count + 1);
    for (final node in near) {
      start[node + 1]++;
    }
    for (var i = 0; i < count; i++) {
      start[i + 1] += start[i];
    }
    final at = Int32List.fromList(start);
    final nodes = Int32List(near.length);
    final weights = Float64List(near.length);
    for (var i = 0; i < near.length; i++) {
      final slot = at[near[i]]++;
      nodes[slot] = far[i];
      weights[slot] = weight[i];
    }
    return (start, nodes, weights);
  }
}
