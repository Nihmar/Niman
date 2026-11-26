/// A first order for the ranks (#530).
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_layers.dart';
import 'package:niman/src/diagrams/layered_segments.dart';

/// Numbers each rank's nodes by a walk down from the first rank: each node
/// takes the next place in its rank as the walk reaches it, following the
/// segments down in the order they were added.
///
/// After Gansner, Koutsofios, North and Vo. It puts the nodes of a path
/// side by side and a fan's children in the order they were drawn, so the
/// sweeps start near a drawing with few crossings. It knows nothing of
/// clusters; the first sweep puts that right. Returns the order of every
/// node in its rank.
Int32List initialOrder(LayeredLayers layers, LayeredSegments segments) {
  final order = Int32List(layers.nodeCount);
  final placed = Uint8List(layers.nodeCount);
  final taken = Int32List(layers.rankCount);
  final cursor = Int32List(layers.nodeCount);
  final stack = <int>[];
  for (final nodes in layers.nodesAt) {
    for (final root in nodes) {
      if (placed[root] == 1) continue;
      stack.add(root);
      while (stack.isNotEmpty) {
        final node = stack.last;
        if (placed[node] == 0) {
          placed[node] = 1;
          cursor[node] = segments.downStart[node];
          order[node] = taken[layers.rankOf[node]]++;
        }
        if (cursor[node] == segments.downStart[node + 1]) {
          stack.removeLast();
          continue;
        }
        final next = segments.downNodes[cursor[node]++];
        if (placed[next] == 0) stack.add(next);
      }
    }
  }
  return order;
}
