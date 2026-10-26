// What the block scanner keeps of a note once it has scanned it (#1196,
// `docs/records/memory-usage.md`): the blocks, and the state every line
// enters in, for a million lines of three kinds of note.
//
// **How it is measured.** `ProcessInfo.currentRss` before the scan, and after
// it and a churn of the heap, is the memory the process holds on the scan's
// behalf: what the survey of the running app counted, and the only figure a
// test can read — the heap's own numbers need the VM service, which
// `flutter test` does not offer. The delta is retention only once the
// collector has freed the scan's garbage (a cold scan makes a `Block` per
// block before the list packs them, ~100 MB for the prose fixture), so each
// run churns the heap with large lists — what makes the collector run — and
// the figure is the **median of a few runs**. A run can read too much, when
// the collector has not come yet, and too little, when the scan fills pages
// the process already held: the lowest of the runs, which this file read
// first, was a negative number twice. Even the median is a bound and not a
// count: it reads 43–88 B a block of the packed storage from one run of the
// file to the next, where the heap holds 33–67 (measured through the VM
// service, `getAllocationProfile` with a collection before each reading),
// and 226–305 of the `Block` objects, where the heap held 143–164.
//
// So the backstop is the `Block` objects' lowest reading, and catches a return
// to an object per block anywhere; the bar is the packed storage's highest
// with the room of a slower runner, and is to be read with that spread in
// mind.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's bar is
// asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/block_memory_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Whether this run is the one that holds the design's bars.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The lines each fixture has.
const int _lines = 1000000;

/// How many times a fixture is scanned: the median reading is kept.
const int _runs = 5;

/// [lines] lines of [pattern] repeated, a `#` in a line standing for its
/// number so that no two lines are alike.
String _note(int lines, List<String> pattern) {
  final out = StringBuffer();
  for (var at = 0; at < lines; at++) {
    out.writeln(pattern[at % pattern.length].replaceAll('#', '$at'));
  }
  return out.toString();
}

/// Fills and drops large lists, which is what makes the collector run, and
/// gives it a moment to hand its pages back.
void _churn() {
  for (var round = 0; round < 20; round++) {
    List<int>.filled(4 << 20, 0);
  }
  sleep(const Duration(milliseconds: 300));
}

/// What a scan of [buffer] keeps, in bytes: the median of [_runs] readings,
/// and the last scanner, which is still alive.
(int, BlockScanner) _retained(SourceBuffer buffer) {
  final readings = <int>[];
  BlockScanner? scanner;
  for (var run = 0; run < _runs; run++) {
    // The last run's scanner goes before the next reading starts.
    scanner = null;
    _churn();
    final before = ProcessInfo.currentRss;
    scanner = BlockScanner(buffer);
    _churn();
    readings.add(ProcessInfo.currentRss - before);
  }
  readings.sort();
  return (readings[readings.length ~/ 2], scanner!);
}

void main() {
  // What a block costs, per fixture, in the readings of this file.
  final fixtures = <String, List<String>>{
    'prose': [
      '## Heading #',
      '',
      'A paragraph line # of prose.',
      'more prose #',
      '',
    ],
    'lists': [
      '- item #',
      '  - nested #',
      '    text #',
      '1. ordered #',
      '> quote #',
      '> - q list #',
      '',
    ],
    'code': ['```dart', 'code #', 'code #', '```', ''],
  };
  const ceiling = 120.0;
  const backstop = 225.0;
  for (final entry in fixtures.entries) {
    test('a million lines of ${entry.key}', () {
      final buffer = SourceBuffer.fromText(_note(_lines, entry.value));
      final (held, scanner) = _retained(buffer);
      final blocks = scanner.index.blocks.length;
      final perBlock = held / blocks;
      final bar = _referenceHost ? ceiling : backstop;
      print(
        '${entry.key}: ${buffer.lineCount} lines, $blocks blocks, '
        'kept ${(held / 1048576).toStringAsFixed(1)} MB = '
        '${perBlock.toStringAsFixed(0)} B/block, '
        '${(held / buffer.lineCount).toStringAsFixed(0)} B/line '
        '(held to ${bar.toStringAsFixed(0)} B/block)',
      );
      expect(blocks, greaterThan(_lines ~/ 10));
      expect(perBlock, lessThan(bar));
    });
  }
}
