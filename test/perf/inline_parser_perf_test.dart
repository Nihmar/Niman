// Our inline parser on the leaves of the fixtures (docs/dev/block-tree.md,
// "Speed"). It replaced the package's parse, masked: measured on this host
// 2026-10-06 (tool/inline_bench.dart), 5 ms against 52 on the 200 KB
// fixture and 50 against 608 on the worst note — the package is gone, and
// the bars it set stay.
//
// Every run holds it to ten times the bar, a backstop the hardware cannot
// fail; NIMAN_PERF=1 to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:path/path.dart' as p;

import '../../tool/inline_bench.dart' show leafTexts;

/// The fastest of five runs of [run], in microseconds.
int _best(void Function() run) {
  var best = 1 << 62;
  for (var round = 0; round < 5; round++) {
    final watch = Stopwatch()..start();
    run();
    if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
  }
  return best;
}

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  for (final (name, path, bar) in [
    (
      'the 200 KB fixture',
      p.join('test', 'fixtures', 'markdown', 'fixture-200kb.md'),
      15000,
    ),
    (
      'the worst note',
      p.join('test', 'fixtures', 'spec', 'worst-note.md'),
      120000,
    ),
  ]) {
    test('our inline parser reads $name within its bar', () {
      final texts = leafTexts(File(path).readAsStringSync());
      final ours = _best(() {
        for (final text in texts) {
          InlineParser(text).parse();
        }
      });
      print(
        '$name, ${texts.length} leaves: ${ours ~/ 1000} ms '
        '(bar ${bar ~/ 1000} ms${measured ? '' : ', held to ten times it'})',
      );
      expect(ours, lessThan(measured ? bar : bar * 10));
    });
  }
}
