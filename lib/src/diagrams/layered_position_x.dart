/// Placing the nodes of each rank across the page (#530).
///
/// Brandes and Köpf's "Fast and Simple Horizontal Coordinate Assignment":
/// four alignments — joined to the neighbours above or below, packed to the
/// left or to the right — each giving every node an x. Long edges and
/// cluster sides come out straight in each, and balancing the four, by the
/// mean of the two in the middle, centres a node between its neighbours.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_bk_compaction.dart';
import 'package:niman/src/diagrams/layered_bk_conflicts.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_options.dart';
import 'package:niman/src/diagrams/layered_segments.dart';
import 'package:niman/src/diagrams/layered_separation.dart';

/// Whether [node] floats: the top or the bottom of a cluster's box, which
/// an edge that names the cluster ends at. It is not aligned with that edge,
/// or the cluster's sides would be dragged out to where the edge goes; its x
/// is the caller's to choose within the box, once the box is known.
bool floatsInCluster(LayeredNode node) =>
    node.kind == LayeredNodeKind.border &&
    (node.side == LayeredBorder.top || node.side == LayeredBorder.bottom);

/// Sets the [LayeredNode.x] of every node of [graph] that does not float,
/// whose nodes must be ranked and ordered and whose edges normalised.
void positionAcross(LayeredGraph graph, LayeredOptions options) {
  final segments = LayeredSegments.of(graph, skip: floatsInCluster);
  final count = graph.nodes.length;
  final layers = _layers(graph);
  // Where each node is in its rank once the floating ones are not counted.
  final order = Int32List(count);
  for (final layer in layers) {
    for (var i = 0; i < layer.length; i++) {
      order[layer[i]] = i;
    }
  }
  final isStand = Uint8List(count);
  final isBorder = Uint8List(count);
  final sideOf = Uint8List(count);
  final floats = Uint8List(count);
  for (final node in graph.nodes) {
    if (node.kind != LayeredNodeKind.real) isStand[node.index] = 1;
    if (node.kind == LayeredNodeKind.border) isBorder[node.index] = 1;
    if (floatsInCluster(node)) floats[node.index] = 1;
    sideOf[node.index] = switch (node.side) {
      LayeredBorder.left => 1,
      LayeredBorder.right => 2,
      _ => 0,
    };
  }
  final context = LayeredAlignmentContext(
    segments: segments,
    conflicts: findConflicts(layers, segments, isStand, isBorder, order),
    separation: LayeredSeparation(graph, options),
    sideOf: sideOf,
  );
  final upward = layers.reversed.toList();
  final alignments = <Float64List>[];
  for (final (rows, up) in [(layers, true), (upward, false)]) {
    for (final mirrored in [false, true]) {
      final walked = mirrored ? [for (final row in rows) _reversed(row)] : rows;
      final x = alignAndCompact(
        context,
        walked,
        count,
        up: up,
        mirrored: mirrored,
      );
      if (mirrored) {
        for (var i = 0; i < count; i++) {
          x[i] = -x[i];
        }
      }
      alignments.add(x);
    }
  }
  _alignTo(graph, alignments, floats);
  for (final node in graph.nodes) {
    final i = node.index;
    if (floats[i] == 1) continue;
    final around = [for (final x in alignments) x[i]]..sort();
    node.x = (around[1] + around[2]) / 2;
  }
}

/// The nodes of each rank that do not float, left to right.
List<Int32List> _layers(LayeredGraph graph) {
  var last = 0;
  for (final node in graph.nodes) {
    last = math.max(last, node.rank);
  }
  final ranks = [for (var r = 0; r <= last; r++) <LayeredNode>[]];
  for (final node in graph.nodes) {
    if (!floatsInCluster(node)) ranks[node.rank].add(node);
  }
  return [
    for (final rank in ranks)
      Int32List.fromList([
        for (final node in rank..sort((a, b) => a.order - b.order)) node.index,
      ]),
  ];
}

Int32List _reversed(Int32List row) {
  final out = Int32List(row.length);
  for (var i = 0; i < row.length; i++) {
    out[i] = row[row.length - 1 - i];
  }
  return out;
}

/// Moves the alignments, which are in the order up-left, up-right, down-left,
/// down-right, so the left ones have their lowest x where the narrowest has
/// its lowest and the right ones their highest where its highest is.
void _alignTo(
  LayeredGraph graph,
  List<Float64List> alignments,
  Uint8List floats,
) {
  var narrowest = alignments.first;
  var narrowestWidth = double.infinity;
  for (final x in alignments) {
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (final node in graph.nodes) {
      if (floats[node.index] == 1) continue;
      final half = node.width / 2;
      low = math.min(low, x[node.index] - half);
      high = math.max(high, x[node.index] + half);
    }
    if (high - low < narrowestWidth) {
      narrowestWidth = high - low;
      narrowest = x;
    }
  }
  final (anchorLow, anchorHigh) = _range(narrowest, floats);
  for (var k = 0; k < alignments.length; k++) {
    final x = alignments[k];
    if (identical(x, narrowest)) continue;
    final (low, high) = _range(x, floats);
    final delta = k.isEven ? anchorLow - low : anchorHigh - high;
    if (delta != 0) {
      for (var i = 0; i < x.length; i++) {
        x[i] += delta;
      }
    }
  }
}

(double, double) _range(Float64List x, Uint8List floats) {
  var low = double.infinity;
  var high = double.negativeInfinity;
  for (var i = 0; i < x.length; i++) {
    if (floats[i] == 1) continue;
    low = math.min(low, x[i]);
    high = math.max(high, x[i]);
  }
  return (low, high);
}
