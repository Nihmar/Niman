// What ranking a large graph costs (#530): the first stage of the compound
// layout runs inside the 60 ms the whole layout of a 3000-node chain or a
// 2000-node cycle is held to (`diagram_layout_perf_test.dart`), so it has to
// be close to linear on them, and not collapse on a graph with clusters.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/layered_rank_perf_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_rank.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The best of [runs] timings of ranking what [build] makes, in
/// milliseconds; building is not timed.
double _best(int runs, LayeredGraph Function() build) {
  var best = double.infinity;
  for (var run = 0; run < runs; run++) {
    final graph = build();
    final clock = Stopwatch()..start();
    rankLayered(graph);
    clock.stop();
    best = math.min(best, clock.elapsedMicroseconds / 1000);
  }
  return best;
}

/// [count] nodes in a chain, closed into a cycle when [cycle].
LayeredGraph _chain(int count, {required bool cycle}) {
  final graph = LayeredGraph();
  for (var i = 0; i < count; i++) {
    graph.addNode('n$i');
  }
  for (var i = 1; i < count; i++) {
    graph.addEdge('n${i - 1}', 'n$i');
  }
  if (cycle) graph.addEdge('n${count - 1}', 'n0');
  return graph;
}

/// [clusters] clusters of [size] nodes in a chain each, the clusters joined
/// in a chain too, and a few edges across.
LayeredGraph _clustered(int clusters, int size) {
  final random = math.Random(5);
  final graph = LayeredGraph();
  for (var c = 0; c < clusters; c++) {
    graph.addCluster('c$c');
    for (var i = 0; i < size; i++) {
      graph.addNode('c${c}n$i', parent: 'c$c');
    }
    for (var i = 1; i < size; i++) {
      graph.addEdge('c${c}n${i - 1}', 'c${c}n$i');
    }
    if (c > 0) graph.addEdge('c${c - 1}n${size - 1}', 'c${c}n0');
  }
  for (var i = 0; i < clusters; i++) {
    graph.addEdge(
      'c${random.nextInt(clusters)}n${random.nextInt(size)}',
      'c${random.nextInt(clusters)}n${random.nextInt(size)}',
    );
  }
  return graph;
}

/// [count] nodes with about twice as many edges, at random.
LayeredGraph _random(int count) {
  final random = math.Random(9);
  final graph = LayeredGraph();
  for (var i = 0; i < count; i++) {
    graph.addNode('n$i');
  }
  for (var i = 0; i < 2 * count; i++) {
    graph.addEdge('n${random.nextInt(count)}', 'n${random.nextInt(count)}');
  }
  return graph;
}

void main() {
  void check(String name, double ceiling, LayeredGraph Function() build) {
    test(name, () {
      final ms = _best(3, build);
      const backstop = 400.0;
      final bar = _referenceHost ? ceiling : backstop;
      print('$name: ${ms.toStringAsFixed(1)} ms (held to $bar ms)');
      expect(ms, lessThan(bar));
    });
  }

  check('ranking a 3000-node chain', 15, () => _chain(3000, cycle: false));
  check('ranking a 2000-node cycle', 15, () => _chain(2000, cycle: true));
  check('ranking 40 clusters of 25 nodes', 60, () => _clustered(40, 25));
  check('ranking 2000 nodes at random', 150, () => _random(2000));
}
