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
import 'package:niman/src/diagrams/layered_layout.dart';
import 'package:niman/src/diagrams/layered_rank.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The best of [runs] timings of running [stage] on what [build] makes, in
/// milliseconds; building is not timed.
double _best(
  int runs,
  LayeredGraph Function() build,
  void Function(LayeredGraph) stage,
) {
  var best = double.infinity;
  for (var run = 0; run < runs; run++) {
    final graph = build();
    final clock = Stopwatch()..start();
    stage(graph);
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

/// [count] nodes, each with edges to two of the next few, and now and then
/// one back: the shape of a real chart, not a tangle that is a hundred ranks
/// deep.
LayeredGraph _random(int count) {
  final random = math.Random(9);
  final graph = LayeredGraph();
  for (var i = 0; i < count; i++) {
    graph.addNode('n$i');
  }
  for (var i = 0; i < count - 8; i++) {
    for (var k = 0; k < 2; k++) {
      graph.addEdge('n$i', 'n${i + 1 + random.nextInt(8)}');
    }
    if (random.nextInt(200) == 0) {
      graph.addEdge('n$i', 'n${random.nextInt(i + 1)}');
    }
  }
  return graph;
}

void main() {
  void check(
    String name,
    double ceiling,
    LayeredGraph Function() build,
    void Function(LayeredGraph) stage,
  ) {
    test(name, () {
      final ms = _best(3, build, stage);
      const backstop = 400.0;
      final bar = _referenceHost ? ceiling : backstop;
      print('$name: ${ms.toStringAsFixed(1)} ms (held to $bar ms)');
      expect(ms, lessThan(bar));
    });
  }

  // The whole layout of a 3000-node chain or a 2000-node cycle is held to
  // 60 ms; the stages before the placing have their share of it. Laying out
  // is the whole engine: ranking, stand-ins, border nodes, ordering, places.
  check(
    'ranking a 3000-node chain',
    15,
    () => _chain(3000, cycle: false),
    rankLayered,
  );
  check(
    'ranking a 2000-node cycle',
    15,
    () => _chain(2000, cycle: true),
    rankLayered,
  );
  check(
    'ranking 40 clusters of 25 nodes',
    60,
    () => _clustered(40, 25),
    rankLayered,
  );
  check(
    'ranking 2000 nodes of a wide chart',
    150,
    () => _random(2000),
    rankLayered,
  );
  check(
    'laying out a 3000-node chain',
    30,
    () => _chain(3000, cycle: false),
    layOutLayered,
  );
  check(
    'laying out a 2000-node cycle',
    30,
    () => _chain(2000, cycle: true),
    layOutLayered,
  );
  check(
    'laying out 40 clusters of 25 nodes',
    150,
    () => _clustered(40, 25),
    layOutLayered,
  );
  check(
    'laying out 2000 nodes of a wide chart',
    500,
    () => _random(2000),
    layOutLayered,
  );
}
