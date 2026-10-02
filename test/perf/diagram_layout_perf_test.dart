// What laying a large flowchart out costs the UI isolate (#530): the read
// view resolves a diagram synchronously in build, so a long chain or a big
// cycle is a frame the note waits for.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/diagram_layout_perf_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_parser.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The best of [runs] timings of [body], in milliseconds.
double _best(int runs, void Function() body) {
  var best = double.infinity;
  for (var run = 0; run < runs; run++) {
    final clock = Stopwatch()..start();
    body();
    clock.stop();
    final ms = clock.elapsedMicroseconds / 1000;
    if (ms < best) best = ms;
  }
  return best;
}

/// A chart of [nodes] nodes in one chain, closed into a cycle when
/// [cycle].
String _chain(int nodes, {required bool cycle}) {
  final source = StringBuffer('flowchart TD\n');
  for (var at = 1; at < nodes; at++) {
    source.writeln('n${at - 1} --> n$at');
  }
  if (cycle) source.writeln('n${nodes - 1} --> n0');
  return source.toString();
}

void main() {
  for (final cycle in [false, true]) {
    final name = cycle ? 'a 2000-node cycle' : 'a 3000-node chain';
    test(name, () {
      final chart = parseFlowchart(_chain(cycle ? 2000 : 3000, cycle: cycle));
      final ms = _best(3, () => layoutFlowchart(chart, const DiagramStyle()));
      // Before ordering re-indexed every layer after each sort and cycles
      // were relaxed edge by edge: 1250 ms for the chain, 860 for the cycle.
      const ceiling = 60.0;
      const backstop = 400.0;
      final bar = _referenceHost ? ceiling : backstop;
      print('$name: ${ms.toStringAsFixed(1)} ms (held to $bar ms)');
      expect(ms, lessThan(bar));
    });
  }
}
