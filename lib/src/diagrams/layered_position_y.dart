/// Placing the ranks down the page (#530).
///
/// Every rank is a row as tall as the tallest box in it. Dagre gives every
/// rank the same gap below it, border ranks and empty ones included, which
/// is what makes its charts with clusters tall: a cluster's top and its
/// bottom are ranks of their own, each a full gap from what is next to it.
/// Here a gap is what is needed:
///
/// - a rank no box is in — only border nodes and the stand-ins of long edges
///   — has no height, and takes no gap of its own: a run of them costs the
///   one gap between the rows round it;
/// - a cluster's own pad is the room between its outline and what it holds,
///   so no gap is added where a cluster opens or closes — unless a box
///   outside it shares the border's row, and needs its gap as any box does;
/// - an edge that needs room at an end, for an arrow cap or a text, widens
///   the gap its first or last piece crosses.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_options.dart';

/// Sets the [LayeredNode.y] of every node of [graph], whose ranks must be
/// set and whose clusters must have their border nodes: the centre of the
/// row for a box, a stand-in or a side of a cluster, and the outline of the
/// box for a cluster's top or bottom. Returns where each rank starts and
/// where it ends.
(Float64List, Float64List) positionRanks(
  LayeredGraph graph,
  LayeredOptions options,
) {
  var last = 0;
  for (final node in graph.nodes) {
    last = math.max(last, node.rank);
  }
  final count = last + 1;
  final height = Float64List(count);
  final hasBox = Uint8List(count);
  final hasPad = Uint8List(count);
  for (final node in graph.nodes) {
    final rank = node.rank;
    switch (node.kind) {
      case LayeredNodeKind.real || LayeredNodeKind.edgeLabel:
        hasBox[rank] = 1;
        height[rank] = math.max(height[rank], node.height);
      case LayeredNodeKind.border:
        final pad = switch (node.side) {
          LayeredBorder.top => node.parent!.padTop,
          LayeredBorder.bottom => node.parent!.padBottom,
          _ => 0.0,
        };
        if (pad > 0) hasPad[rank] = 1;
        height[rank] = math.max(height[rank], pad);
      case LayeredNodeKind.dummy || LayeredNodeKind.nestingRoot:
        break;
    }
  }
  final opens = Uint8List(count);
  final closes = Uint8List(count);
  for (final cluster in graph.clusters) {
    opens[cluster.minRank] = 1;
    closes[cluster.maxRank] = 1;
  }
  final base = options.rankGap / graph.rankSpacing;
  final gap = Float64List(math.max(count - 1, 0));
  for (var r = 0; r + 1 < count; r++) {
    // A rank with a box or a pad takes half a gap on each side; one with
    // neither takes none.
    final share =
        (hasBox[r] + hasPad[r] > 0 ? base / 2 : 0.0) +
        (hasBox[r + 1] + hasPad[r + 1] > 0 ? base / 2 : 0.0);
    // Where a cluster opens or closes, its pad is the room between its
    // outline and what it holds — unless a box outside the cluster is in
    // the border's row too: then the row's own height is that box's, and
    // the box beside the cluster needs its gap from the row next to it.
    final padOnly =
        (opens[r] == 1 && hasBox[r] == 0) ||
        (closes[r + 1] == 1 && hasBox[r + 1] == 0);
    var between = padOnly ? 0.0 : share;
    // A row of no height still has to be told from its neighbours, or the
    // pieces of an edge through it would lie on one another.
    if (between < base / 10 && (height[r] == 0 || height[r + 1] == 0)) {
      between = base / 10;
    }
    gap[r] = between;
  }
  for (final edge in graph.edges) {
    final span = edge.to.rank - edge.from.rank;
    if (!edge.ranked || span < 1) continue;
    final upper = edge.reversed ? edge.headRoom : edge.tailRoom;
    final lower = edge.reversed ? edge.tailRoom : edge.headRoom;
    if (span == 1) {
      gap[edge.from.rank] = math.max(gap[edge.from.rank], upper + lower);
    } else {
      gap[edge.from.rank] = math.max(gap[edge.from.rank], upper);
      gap[edge.to.rank - 1] = math.max(gap[edge.to.rank - 1], lower);
    }
  }
  final top = Float64List(count);
  final bottom = Float64List(count);
  var at = 0.0;
  for (var r = 0; r < count; r++) {
    top[r] = at;
    bottom[r] = at + height[r];
    at = bottom[r] + (r < gap.length ? gap[r] : 0);
  }
  for (final node in graph.nodes) {
    final rank = node.rank;
    final mid = (top[rank] + bottom[rank]) / 2;
    node.y = node.kind == LayeredNodeKind.border
        ? switch (node.side) {
            LayeredBorder.top => bottom[rank] - node.parent!.padTop,
            LayeredBorder.bottom => top[rank] + node.parent!.padBottom,
            _ => mid,
          }
        : mid;
  }
  return (top, bottom);
}
