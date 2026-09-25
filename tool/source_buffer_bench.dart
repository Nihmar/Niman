/// Measures the source buffer, so its cost claims are numbers and not prose.
///
/// The design document says a content edit is O(log n) and a line-count change
/// is O(lines) in a flat loop with a small constant
/// (`docs/records/unified-surface.md` §8.2). This is what checks that.
///
/// ```sh
/// dart run tool/source_buffer_bench.dart                  # the fixtures
/// dart run tool/source_buffer_bench.dart "Geometria 1.md" # the worst case
/// ```
///
/// Follows the repo's convention for benchmarks: it *prints* rather than
/// asserts, so it stays green on any machine and the numbers are read from the
/// log. Debug mode, which inflates the absolute values; the ratios are the part
/// that carries.
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:niman/src/markdown/source_buffer.dart';
import 'package:path/path.dart' as p;

/// The fixtures to measure, when no paths are given.
const List<String> _defaults = <String>[
  'test/fixtures/markdown/fixture-10kb.md',
  'test/fixtures/markdown/fixture-200kb.md',
  'test/fixtures/markdown/fixture-1mb.md',
];

/// The real worst case, measured when it is present.
const String _worstCase = 'Geometria 1.md';

/// One measured operation, as it appears in the table.
final class _Operation {
  const new(this.name, this.what, this.body);

  final String name;
  final String what;
  final void Function(SourceBuffer) body;
}

/// The middle of the document, where an operation is neither first nor last.
int _middleOffset(SourceBuffer buffer) =>
    buffer.offsetOfLine(buffer.lineCount ~/ 2);

void main(List<String> args) {
  final paths = args.isNotEmpty
      ? args
      : <String>[..._defaults, if (File(_worstCase).existsSync()) _worstCase];

  var jump = 0;
  final operations = <_Operation>[
    // The app's keystroke shape: one character replaced in place.
    _Operation('content edit', 'one character replaced in place', (buffer) {
      final at = _middleOffset(buffer);
      buffer
        ..insert(at, 'x')
        ..delete(at, at + 1);
    }),
    // What Enter costs: the line count changes, so every index after it moves.
    _Operation('structural edit', 'a terminator added and taken away', (
      buffer,
    ) {
      final at = _middleOffset(buffer);
      buffer
        ..insert(at, '\n')
        ..delete(at, at + 1);
    }),
    _Operation('line delete', 'a whole line removed', (buffer) {
      final middle = buffer.lineCount ~/ 2;
      final start = buffer.offsetOfLine(middle);
      final end = buffer.offsetOfLine(middle + 1);
      buffer
        ..replaceRange(start, end, 'x')
        ..insert(start + 1, '\n');
    }),
    _Operation(
      'lineOf',
      'one offset to line lookup',
      (buffer) => buffer.lineOf(buffer.length ~/ 2),
    ),
    _Operation(
      'lineAt',
      'one line read',
      (buffer) => buffer.lineAt(buffer.lineCount ~/ 2),
    ),
    // A frame reads the lines it draws, far from the last read: the chunk
    // the line is in is searched for, not the one the last read landed in.
    _Operation('lineAt, jumping', 'one line read far from the last', (buffer) {
      jump = (jump + 7919) % buffer.lineCount;
      buffer.lineAt(jump);
    }),
    _Operation('substring', '64 characters read', (buffer) {
      final at = buffer.length ~/ 2;
      buffer.substring(at, at + 64 < buffer.length ? at + 64 : buffer.length);
    }),
    // What the read pane is handed, and what the editor's next keystroke
    // pays for it: the chunk it lands in is copied before it is written.
    _Operation('snapshot', 'a copy the edits do not reach', (buffer) {
      buffer.snapshot();
    }),
    _Operation('snapshot + keystroke', 'a copy, then a character typed', (
      buffer,
    ) {
      buffer.snapshot();
      final at = _middleOffset(buffer);
      buffer
        ..insert(at, 'x')
        ..delete(at, at + 1);
    }),
  ];

  print('# source buffer, debug mode: ratios carry, absolutes do not');
  print('');
  print(
    '| fixture | lines | chars | load | '
    '${operations.map((operation) => operation.name).join(' | ')} | text |',
  );
  print('|---|---|---:|---:${'---:|' * operations.length}---:|');

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      final empty = ' |' * operations.length;
      print('| ${p.basename(path)} | — | — | missing |$empty |');
      continue;
    }
    final text = file.readAsStringSync();
    final lines = '\n'.allMatches(text).length + 1;
    final buffer = SourceBuffer.fromText(text);

    final load = _millis(_perOperation(() => SourceBuffer.fromText(text)));
    final timings = <String>[
      for (final operation in operations)
        _micros(_perOperation(() => operation.body(buffer))),
    ];
    final whole = _millis(_perOperation(() => buffer.text));

    print(
      '| ${p.basename(path)} | $lines | ${text.length} | $load | '
      '${timings.join(' | ')} | $whole |',
    );
  }

  print('');
  for (final operation in operations) {
    print('- **${operation.name}** — ${operation.what}.');
  }
  print('');
  print('Average of as many calls as fit in 40 ms, so an operation of a few');
  print('hundred nanoseconds and one that rebuilds the line index are both');
  print('measured rather than one being lost to the clock.');
}

/// The average time of one call, measured inside a fixed time budget.
///
/// A fixed iteration count cannot work here: the buffer has operations of a few
/// hundred nanoseconds and operations that are O(lines), so any count is either
/// too small to resolve the first or too large to finish the second on a
/// 10 000-line note.
double _perOperation(void Function() body) {
  const budget = Duration(milliseconds: 40);
  const batch = 50;
  body(); // warm up, and let the first-call allocations settle
  final watch = Stopwatch()..start();
  var count = 0;
  while (watch.elapsed < budget && count < 400000) {
    for (var i = 0; i < batch; i++) {
      body();
    }
    count += batch;
  }
  watch.stop();
  return count == 0 ? 0 : watch.elapsedMicroseconds / count;
}

String _micros(double micros) => micros < 1000
    ? '${micros.toStringAsFixed(3)} µs'
    : '${(micros / 1000).toStringAsFixed(2)} ms';

String _millis(double micros) => '${(micros / 1000).toStringAsFixed(2)} ms';
