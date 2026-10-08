// What finding the article in a long page costs (#531): the Wikipedia page
// of upstream's test pages, 350 KB of HTML, parsed and read by the
// Readability port.
// The capture runs it off the UI isolate, but on a phone; and the port
// gathers a node's text again on every call, as upstream does — this is
// the test that says when caching it has become worth it.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/readability_perf_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/capture/readability/readability.dart';
import 'package:path/path.dart' as p;

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

void main() {
  test('the Wikipedia page', () {
    final source = File(
      p.join('test', 'fixtures', 'readability', 'wikipedia', 'source.html'),
    ).readAsStringSync();
    var best = double.infinity;
    for (var run = 0; run < 3; run++) {
      final clock = Stopwatch()..start();
      final article = readArticle(
        html.parse(source),
        documentUri: Uri.parse('https://en.wikipedia.org/wiki/Mozilla'),
      );
      clock.stop();
      expect(article, isNotNull);
      final ms = clock.elapsedMicroseconds / 1000;
      if (ms < best) best = ms;
    }
    const ceiling = 250.0;
    const backstop = 1500.0;
    final bar = _referenceHost ? ceiling : backstop;
    print(
      'the Wikipedia page: ${best.toStringAsFixed(1)} ms (held to $bar ms)',
    );
    expect(best, lessThan(bar));
  });
}
