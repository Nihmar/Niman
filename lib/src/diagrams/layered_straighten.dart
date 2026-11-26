/// Straightening the stand-ins of long edges (#530), once the nodes are
/// placed.
///
/// Brandes and Köpf's alignment joins a stand-in to a neighbour in the
/// next rank, but a node can be joined to one neighbour only: of two edges
/// between the same two nodes, one gets the joins and the other is left a
/// block of its own, which the compaction puts wherever the nearest
/// constraint is — out at the side of a cluster that a wide node in another
/// rank made broad. Here every stand-in is moved back towards the line
/// between its neighbours, as far as the nodes on either side of it allow.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_segments.dart';
import 'package:niman/src/diagrams/layered_separation.dart';

/// How many times the stand-ins are gone over, down and then up and then
/// down again: moving one changes where its neighbours want to be.
const int _passes = 3;

/// A move this small is not one.
const double _slight = 1e-9;

/// Moves the stand-ins of [layers], the nodes of each rank left to right,
/// in [x]: each to the mean x of its neighbours in the ranks above and below
/// — or the one it has — but never closer to the node on its left or on its
/// right than [separation] says. Nothing but a stand-in moves, and none
/// moves past another node, so the order and the separations hold.
void straightenStandIns(
  List<Int32List> layers,
  List<LayeredNode> nodes,
  LayeredSegments segments,
  LayeredSeparation separation,
  Float64List x,
) {
  bool isStand(int node) =>
      nodes[node].kind == LayeredNodeKind.dummy ||
      nodes[node].kind == LayeredNodeKind.edgeLabel;

  double? target(int node) {
    var sum = 0.0;
    var count = 0;
    for (var s = segments.upStart[node]; s < segments.upStart[node + 1]; s++) {
      sum += x[segments.upNodes[s]];
      count++;
    }
    for (
      var s = segments.downStart[node];
      s < segments.downStart[node + 1];
      s++
    ) {
      sum += x[segments.downNodes[s]];
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  void pass(Iterable<int> ranks) {
    for (final rank in ranks) {
      final layer = layers[rank];
      for (var i = 0; i < layer.length; i++) {
        final node = layer[i];
        if (!isStand(node)) continue;
        final wanted = target(node);
        if (wanted == null) continue;
        var low = double.negativeInfinity;
        var high = double.infinity;
        if (i > 0) {
          low = x[layer[i - 1]] + separation.between(layer[i - 1], node);
        }
        if (i + 1 < layer.length) {
          high = x[layer[i + 1]] - separation.between(node, layer[i + 1]);
        }
        if (low > high) continue;
        final placed = wanted < low ? low : (wanted > high ? high : wanted);
        if ((placed - x[node]).abs() > _slight) x[node] = placed;
      }
    }
  }

  for (var k = 0; k < _passes; k++) {
    pass(
      k.isEven
          ? Iterable<int>.generate(layers.length)
          : Iterable<int>.generate(layers.length, (i) => layers.length - 1 - i),
    );
  }
}
