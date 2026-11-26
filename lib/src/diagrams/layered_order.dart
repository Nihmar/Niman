/// Ordering the nodes within each rank (#530): the second stage's heart,
/// where the crossings of a drawing are cut.
///
/// After dagre's `order`. A first order from a walk down the graph is
/// improved by sweeps, each sorting the ranks one after the other against
/// the rank before it (a sweep down) or after it (a sweep up), the clusters
/// kept whole; after each the weighted crossings are counted, and the best
/// order seen is the one kept. A cluster stays one run of nodes between its
/// border nodes, and sibling clusters keep their sides from rank to rank.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_cross_count.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_layer_sort.dart';
import 'package:niman/src/diagrams/layered_layers.dart';
import 'package:niman/src/diagrams/layered_node.dart' show LayeredNode;
import 'package:niman/src/diagrams/layered_order_init.dart';
import 'package:niman/src/diagrams/layered_segments.dart';

/// How many sweeps in a row may fail to cut a crossing before the ordering
/// stops.
const int _patience = 4;

/// The most sweeps, however well they go: a drawing's crossings fall
/// quickly, and the rest is a long tail.
const int _mostSweeps = 40;

/// Sets the [LayeredNode.order] of every node of [graph].
///
/// The graph's edges must be normalised, its clusters ranked and given their
/// border nodes. Afterwards in every rank the nodes of a cluster, those of
/// the clusters inside it included, are one run with the cluster's left
/// border node first and its right one last, and if a cluster is left of
/// another in one rank they share, it is in every rank they share.
void orderLayered(LayeredGraph graph) {
  if (graph.nodes.isEmpty) return;
  final layers = LayeredLayers.of(graph);
  final segments = LayeredSegments.of(graph);
  final order = initialOrder(layers, segments);
  final sorter = LayerSorter(layers, segments, graph.clusters, order);
  var best = Int32List.fromList(order);
  var bestCrossings = double.infinity;
  var stale = 0;
  // The first sweep is up, so every rank, the last included, is sorted
  // whole once before any is counted.
  for (var sweep = 0; sweep < _mostSweeps && stale < _patience; sweep++) {
    _sweep(sorter, layers, order, graph.clusters.isNotEmpty, sweep);
    final crossings = countCrossings(layers, segments, order);
    if (crossings < bestCrossings) {
      stale = 0;
      bestCrossings = crossings;
      best = Int32List.fromList(order);
    } else {
      stale++;
      if (crossings == bestCrossings) best = Int32List.fromList(order);
    }
    if (crossings == 0) break;
  }
  for (final node in graph.nodes) {
    node.order = best[node.index];
  }
}

/// One sweep over the ranks, in [order]: up on an even [sweep], down on an
/// odd one, and the side that gets the ties changes with every other pair.
void _sweep(
  LayerSorter sorter,
  LayeredLayers layers,
  Int32List order,
  bool hasClusters,
  int sweep,
) {
  final down = sweep.isOdd;
  final switchBias = sweep % 4 >= 2;
  sorter
    ..down = down
    ..biasRight = true
    ..constraints.clear();
  final last = layers.rankCount - 1;
  if (down && hasClusters) {
    // The rank a sweep down starts from is not sorted by it: its order is
    // what the ranks after it have to keep to.
    final nodes = layers.nodesAt[0].toList()
      ..sort((a, b) => order[a] - order[b]);
    sorter.record(nodes);
  }
  for (var step = 0; step < last + (down ? 0 : 1); step++) {
    final rank = down ? step + 1 : last - step;
    final sorted = sorter.sort(rank);
    if (sorted.nodes.length != layers.nodesAt[rank].length) {
      throw StateError('Rank $rank lost nodes in the sort.');
    }
    for (var i = 0; i < sorted.nodes.length; i++) {
      order[sorted.nodes[i]] = i;
    }
    if (hasClusters) sorter.record(sorted.nodes);
    if (switchBias && sorted.tied) sorter.biasRight = !sorter.biasRight;
  }
}
