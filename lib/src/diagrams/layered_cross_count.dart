/// Counting the crossings of a layered drawing (#530).
///
/// After Barth, Jünger and Mutzel, "Simple and efficient bilayer cross
/// counting": the segments between two ranks are sorted by where they leave
/// the upper one, and the crossings are counted as the positions they arrive
/// at in the lower one are put in a tree of partial sums — O(E log V) for
/// the pair, not O(E²).
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_layers.dart';
import 'package:niman/src/diagrams/layered_segments.dart';

/// How many crossings the segments of [segments] make with the nodes of
/// every rank in the order [order] gives them, each crossing counting for
/// the product of its two segments' weights.
///
/// The ranks' nodes are in [layers]; [order] must number the nodes of each
/// rank from 0 without a gap.
double countCrossings(
  LayeredLayers layers,
  LayeredSegments segments,
  Int32List order,
) {
  final ranks = <Int32List>[];
  for (final nodes in layers.nodesAt) {
    final sorted = Int32List(nodes.length);
    for (final node in nodes) {
      sorted[order[node]] = node;
    }
    ranks.add(sorted);
  }
  var widest = 1;
  for (final rank in ranks) {
    if (rank.length > widest) widest = rank.length;
  }
  final tree = Float64List(4 * widest);
  var total = 0.0;
  for (var r = 1; r < ranks.length; r++) {
    total += _between(ranks[r - 1], ranks[r].length, segments, order, tree);
  }
  return total;
}

/// The crossings between [north] and the rank of [southCount] nodes under it.
double _between(
  Int32List north,
  int southCount,
  LayeredSegments segments,
  Int32List order,
  Float64List tree,
) {
  var first = 1;
  while (first < southCount) {
    first <<= 1;
  }
  tree.fillRange(0, 2 * first, 0);
  first -= 1;
  var crossings = 0.0;
  final positions = <int>[];
  final weights = <double>[];
  for (final node in north) {
    final from = segments.downStart[node];
    final to = segments.downStart[node + 1];
    if (from == to) continue;
    // Its segments in the order they arrive in, so that two from one node
    // do not count as crossing.
    positions.clear();
    weights.clear();
    for (var i = from; i < to; i++) {
      final position = order[segments.downNodes[i]];
      var at = positions.length;
      positions.add(position);
      weights.add(segments.downWeights[i]);
      while (at > 0 && positions[at - 1] > position) {
        positions[at] = positions[at - 1];
        weights[at] = weights[at - 1];
        at--;
      }
      positions[at] = position;
      weights[at] = segments.downWeights[i];
    }
    for (var k = 0; k < positions.length; k++) {
      var index = positions[k] + first;
      final weight = weights[k];
      tree[index] += weight;
      var rightOf = 0.0;
      while (index > 0) {
        if (index.isOdd) rightOf += tree[index + 1];
        index = (index - 1) >> 1;
        tree[index] += weight;
      }
      crossings += weight * rightOf;
    }
  }
  return crossings;
}
