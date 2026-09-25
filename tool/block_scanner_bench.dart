/// Measures the block scanner: the cold scan, and what one edit costs.
///
/// The claim it checks is the one the whole design rests on
/// (`docs/records/unified-surface.md` §8.5): a re-scan stops at the first line whose
/// state is what it was, so an edit costs O(change) lines rather than
/// O(document). It prints rather than asserts, as the repo's benchmarks do, and
/// debug mode inflates the absolutes — the ratios carry.
///
/// ```sh
/// dart run tool/block_scanner_bench.dart
/// dart run tool/block_scanner_bench.dart "Geometria 1.md"
/// ```
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:path/path.dart' as p;

/// The fixtures to measure, when no paths are given.
const List<String> _defaults = <String>[
  'test/fixtures/markdown/fixture-200kb.md',
  'test/fixtures/markdown/fixture-1mb.md',
];

/// The real worst case, measured when it is present.
const String _worstCase = 'Geometria 1.md';

void main(List<String> args) {
  final paths = args.isNotEmpty
      ? args
      : <String>[..._defaults, if (File(_worstCase).existsSync()) _worstCase];

  print('# block scanner, debug mode: ratios carry, absolutes do not');
  print('');
  print(
    '| fixture | lines | blocks | cold scan | keystroke | lines re-scanned | '
    'Enter | lines re-scanned |',
  );
  print('|---|---:|---:|---:|---:|---:|---:|---:|');

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      print('| ${p.basename(path)} | — | — | missing | | | | |');
      continue;
    }
    final text = file.readAsStringSync();
    final buffer = SourceBuffer.fromText(text);
    final scanner = BlockScanner(buffer);
    final blocks = scanner.index.blocks.length;

    final cold = _millis(
      _best(5, () => BlockScanner(SourceBuffer.fromText(text))),
    );

    // A keystroke in the middle: one character inside a line.
    final middle = buffer.offsetOfLine(buffer.lineCount ~/ 2);
    final keystroke = _edit(buffer, scanner, () => buffer.insert(middle, 'x'));
    // Enter: a terminator, which changes the line count.
    final enter = _edit(buffer, scanner, () => buffer.insert(middle, '\n'));

    print(
      '| ${p.basename(path)} | ${buffer.lineCount} | $blocks | $cold | '
      '${_micros(keystroke.$1)} | ${keystroke.$2} | ${_micros(enter.$1)} | '
      '${enter.$2} |',
    );
  }

  print('');
  print('`cold scan` is the whole document. `lines re-scanned` is what the');
  print('convergence rule saved: the number of lines whose state was computed');
  print('again, out of the document total.');
}

/// Runs [edit], re-scans, and reports the time and the lines re-scanned.
(double, int) _edit(
  SourceBuffer buffer,
  BlockScanner scanner,
  SourceEdit Function() edit,
) {
  var best = double.infinity;
  var lines = 0;
  for (var attempt = 0; attempt < 50; attempt++) {
    final before = scanner.scannedLineTotal;
    final watch = Stopwatch()..start();
    scanner.edited(edit());
    watch.stop();
    lines = scanner.scannedLineTotal - before;
    final micros = watch.elapsedMicroseconds.toDouble();
    if (micros < best) best = micros;
  }
  return (best, lines);
}

/// The best of [runs] calls, in microseconds.
double _best(int runs, void Function() body) {
  var best = double.infinity;
  for (var i = 0; i < runs; i++) {
    final watch = Stopwatch()..start();
    body();
    watch.stop();
    final micros = watch.elapsedMicroseconds.toDouble();
    if (micros < best) best = micros;
  }
  return best;
}

String _micros(double micros) => micros < 1000
    ? '${micros.toStringAsFixed(1)} µs'
    : '${(micros / 1000).toStringAsFixed(2)} ms';

String _millis(double micros) => '${(micros / 1000).toStringAsFixed(2)} ms';
