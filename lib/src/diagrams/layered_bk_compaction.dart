/// One alignment of Brandes and Köpf's coordinate assignment (#530): the
/// nodes of each rank joined into straight blocks with a neighbour in the
/// rank before, then the blocks pushed together as far as their separations
/// allow.
///
/// After Brandes and Köpf, "Fast and Simple Horizontal Coordinate
/// Assignment", with the compaction of dagre's version: a graph of blocks
/// with an edge between blocks that are neighbours in a rank, weighted by
/// their separation, and two passes over it — the first puts every block as
/// far left as it can go, the second moves a block right again, up to its
/// right neighbours, so no space is left that nothing needs. A block that is
/// the right side of a cluster is not moved by the second pass, so the side
/// stays against what the cluster holds.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_bk_conflicts.dart';
import 'package:niman/src/diagrams/layered_segments.dart';
import 'package:niman/src/diagrams/layered_separation.dart';

/// What every alignment shares.
final class LayeredAlignmentContext {
  /// Collects what an alignment reads.
  new({
    required this.segments,
    required this.conflicts,
    required this.separation,
    required this.sideOf,
  });

  /// The segments of the graph.
  final LayeredSegments segments;

  /// The segments the alignment must not join.
  final LayeredConflicts conflicts;

  /// How far apart neighbours must be.
  final LayeredSeparation separation;

  /// For each node, which side of a cluster it is on: 0 for none, 1 for a
  /// left border, 2 for a right border.
  final Uint8List sideOf;
}

/// The x of every node in one alignment.
///
/// [layers] are the ranks in the order they are walked, and each rank in the
/// order its nodes are: [up] says whether a node is joined to a neighbour in
/// the rank before it in the graph (the walk goes down) or after it (the walk
/// goes up), and [mirrored] whether each rank is walked right to left. The
/// result is in the walk's own space: for a mirrored walk, left is right.
Float64List alignAndCompact(
  LayeredAlignmentContext context,
  List<Int32List> layers,
  int nodeCount, {
  required bool up,
  required bool mirrored,
}) {
  final root = Int32List(nodeCount);
  final align = Int32List(nodeCount);
  final position = Int32List(nodeCount);
  for (var i = 0; i < nodeCount; i++) {
    root[i] = i;
    align[i] = i;
  }
  for (final layer in layers) {
    for (var i = 0; i < layer.length; i++) {
      root[layer[i]] = layer[i];
      align[layer[i]] = layer[i];
      position[layer[i]] = i;
    }
  }
  _alignVertically(context, layers, root, align, position, up: up);
  return _compact(context, layers, root, nodeCount, mirrored: mirrored);
}

/// Joins each node to one of its median neighbours, left to right.
///
/// A cluster's side is joined whole, first: each of its border nodes to the
/// one before it in the walk, so the side is one straight block however the
/// ordering left the edges that cross it. The other nodes are then joined
/// as Brandes and Köpf have it, but never across a side: a node left of a
/// side's node is joined only to a neighbour left of the one that side is
/// joined to, and one right of it only to one right of it. Cluster boxes
/// are therefore exactly the rectangles they are drawn as.
void _alignVertically(
  LayeredAlignmentContext context,
  List<Int32List> layers,
  Int32List root,
  Int32List align,
  Int32List position, {
  required bool up,
}) {
  final segments = context.segments;
  final start = up ? segments.upStart : segments.downStart;
  final others = up ? segments.upNodes : segments.downNodes;
  final sideOf = context.sideOf;
  for (final layer in layers) {
    for (final node in layer) {
      if (sideOf[node] != 0 && start[node] < start[node + 1]) {
        final other = others[start[node]];
        align[other] = node;
        root[node] = root[other];
        align[node] = root[other];
      }
    }
  }
  final neighbours = <int>[];
  var limit = Int32List(0);
  for (final layer in layers) {
    if (limit.length < layer.length) limit = Int32List(layer.length);
    // How far right a node may be joined: short of the neighbour of the
    // next side's node, if there is one.
    var bound = 1 << 30;
    for (var i = layer.length - 1; i >= 0; i--) {
      final node = layer[i];
      if (sideOf[node] != 0 && start[node] < start[node + 1]) {
        bound = position[others[start[node]]];
      }
      limit[i] = bound;
    }
    // The place of the last neighbour a node has been joined to: a node
    // later in the rank may not be joined to one before it.
    var joined = -1;
    for (var i = 0; i < layer.length; i++) {
      final node = layer[i];
      if (sideOf[node] != 0 && start[node] < start[node + 1]) {
        joined = position[others[start[node]]];
        continue;
      }
      neighbours.clear();
      for (var s = start[node]; s < start[node + 1]; s++) {
        neighbours.add(others[s]);
      }
      if (neighbours.isEmpty) continue;
      if (neighbours.length > 1) {
        neighbours.sort((a, b) => position[a] - position[b]);
      }
      final low = (neighbours.length - 1) >> 1;
      final high = neighbours.length >> 1;
      for (var k = low; k <= high; k++) {
        final other = neighbours[k];
        if (align[node] == node &&
            joined < position[other] &&
            position[other] < limit[i] &&
            !context.conflicts.has(node, other)) {
          align[other] = node;
          root[node] = root[other];
          align[node] = root[other];
          joined = position[other];
        }
      }
    }
  }
}

/// Places the blocks, and every node at its block's x.
Float64List _compact(
  LayeredAlignmentContext context,
  List<Int32List> layers,
  Int32List root,
  int nodeCount, {
  required bool mirrored,
}) {
  // The block graph: an edge from a block to the one after it in a rank.
  var pairs = 0;
  for (final layer in layers) {
    if (layer.length > 1) pairs += layer.length - 1;
  }
  final tail = Int32List(pairs);
  final head = Int32List(pairs);
  final weight = Float64List(pairs);
  var edge = 0;
  for (final layer in layers) {
    for (var i = 1; i < layer.length; i++) {
      final before = layer[i - 1];
      final after = layer[i];
      tail[edge] = root[before];
      head[edge] = root[after];
      // In a mirrored walk the one walked first is the one on the right.
      weight[edge] = mirrored
          ? context.separation.between(after, before)
          : context.separation.between(before, after);
      edge++;
    }
  }
  final outStart = Int32List(nodeCount + 1);
  final inCount = Int32List(nodeCount);
  for (var e = 0; e < pairs; e++) {
    outStart[tail[e] + 1]++;
    inCount[head[e]]++;
  }
  for (var i = 0; i < nodeCount; i++) {
    outStart[i + 1] += outStart[i];
  }
  final outAt = Int32List.fromList(outStart);
  final outEdges = Int32List(pairs);
  for (var e = 0; e < pairs; e++) {
    outEdges[outAt[tail[e]]++] = e;
  }
  // The blocks in an order that has each after the blocks before it.
  final order = <int>[];
  final remaining = Int32List.fromList(inCount);
  for (var v = 0; v < nodeCount; v++) {
    if (root[v] == v && remaining[v] == 0) order.add(v);
  }
  for (var i = 0; i < order.length; i++) {
    final block = order[i];
    for (var k = outStart[block]; k < outStart[block + 1]; k++) {
      final next = head[outEdges[k]];
      if (--remaining[next] == 0) order.add(next);
    }
  }
  // Blocks that could not be put in order, which only a ring would cause,
  // are placed last, as they are.
  if (order.length < _blockCount(root)) {
    for (var v = 0; v < nodeCount; v++) {
      if (root[v] == v && remaining[v] > 0) order.add(v);
    }
  }
  final x = Float64List(nodeCount);
  for (final block in order) {
    for (var k = outStart[block]; k < outStart[block + 1]; k++) {
      final e = outEdges[k];
      final reach = x[block] + weight[e];
      if (reach > x[head[e]]) x[head[e]] = reach;
    }
  }
  // The side a block must not be pulled from: the far one in this walk.
  final fixedSide = mirrored ? 1 : 2;
  for (var i = order.length - 1; i >= 0; i--) {
    final block = order[i];
    if (outStart[block] == outStart[block + 1]) continue;
    var limit = double.infinity;
    for (var k = outStart[block]; k < outStart[block + 1]; k++) {
      final e = outEdges[k];
      final room = x[head[e]] - weight[e];
      if (room < limit) limit = room;
    }
    if (context.sideOf[block] != fixedSide && limit > x[block]) {
      x[block] = limit;
    }
  }
  for (var v = 0; v < nodeCount; v++) {
    x[v] = x[root[v]];
  }
  return x;
}

int _blockCount(Int32List root) {
  var count = 0;
  for (var v = 0; v < root.length; v++) {
    if (root[v] == v) count++;
  }
  return count;
}
