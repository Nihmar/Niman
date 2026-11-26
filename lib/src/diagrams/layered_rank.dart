/// Ranking the layered graph (#530): the first stage of the compound
/// layout, in canonical space — ranks run downwards.
///
/// The pipeline is dagre's: open the rings, add the nesting graph, rank by
/// network simplex, drop the ranks nothing needs, take the nesting graph
/// away again. What it leaves is a `rank` on every node, and a
/// `minRank`/`maxRank` on every cluster — the ranks of its two borders —
/// so a cluster is one band, and clusters tied by an edge stand one above
/// the other rather than side by side.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_acyclic.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_nesting.dart';
import 'package:niman/src/diagrams/layered_nesting_cycles.dart';
import 'package:niman/src/diagrams/layered_network_simplex.dart';
import 'package:niman/src/diagrams/layered_rank_network.dart';

/// Gives every node of [graph] a rank, from 0, and every cluster the first
/// and last rank of its box.
///
/// An edge ends at least its `minlen` ranks below where it starts, once any
/// that closes a ring is turned round ([breakCycles]); the ranks are
/// otherwise the ones that make the edges, weighted, shortest. A cluster's
/// border nodes keep ranks of their own: every member is below the top and
/// above the bottom.
void rankLayered(LayeredGraph graph) {
  if (graph.nodes.isEmpty) return;
  breakCycles(graph);
  final nesting = LayeredNesting.add(graph);
  breakNestingCycles(graph);
  final network = RankNetwork.of(graph, nesting.nodeRankFactor);
  networkSimplex(network);
  _normalize(network.rank);
  for (final node in graph.nodes) {
    node.rank = network.rank[node.index];
  }
  _removeEmptyRanks(graph, nesting.nodeRankFactor);
  nesting.cleanup();
  _startAtZero(graph);
  for (final cluster in graph.clusters) {
    cluster.minRank = cluster.borderTop.rank;
    cluster.maxRank = cluster.borderBottom.rank;
  }
}

/// Moves [ranks] so the lowest is 0.
void _normalize(Int32List ranks) {
  var lowest = ranks[0];
  for (final rank in ranks) {
    if (rank < lowest) lowest = rank;
  }
  for (var i = 0; i < ranks.length; i++) {
    ranks[i] -= lowest;
  }
}

/// Drops the ranks no node is on, except the multiples of [factor]: those
/// are the rows of nodes, and a long edge has a stand-in on each of them
/// even where no box is. The rest were room for borders that did not come.
void _removeEmptyRanks(LayeredGraph graph, int factor) {
  var last = 0;
  for (final node in graph.nodes) {
    if (node.rank > last) last = node.rank;
  }
  final used = Uint8List(last + 1);
  for (final node in graph.nodes) {
    used[node.rank] = 1;
  }
  // How many ranks have gone by each rank.
  final gone = Int32List(last + 1);
  var removed = 0;
  for (var rank = 0; rank <= last; rank++) {
    if (used[rank] == 0 && rank % factor != 0) removed++;
    gone[rank] = removed;
  }
  for (final node in graph.nodes) {
    node.rank -= gone[node.rank];
  }
}

/// Moves the ranks of [graph]'s nodes so the lowest is 0.
void _startAtZero(LayeredGraph graph) {
  var lowest = graph.nodes.first.rank;
  for (final node in graph.nodes) {
    if (node.rank < lowest) lowest = node.rank;
  }
  for (final node in graph.nodes) {
    node.rank -= lowest;
  }
}
