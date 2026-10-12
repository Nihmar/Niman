// The block scan with the note's columns in it (#729,
// `docs/records/note-columns.md`, "Performance bars"): a new field in the
// state every line enters, read on the hottest path the editor has.
//
// The state stays a shared value — a long column of prose allocates no
// state a line, as a long note of prose does not (#346) — and that is held
// on every run, as a count of the distinct states a scan of a million
// lines keeps. The time is printed: a scan of the prose inside one column
// against the same prose outside, which a run with `NIMAN_PERF=1` holds
// within 3 %. (The scan before the change, the record's bar, is an A/B of
// two builds: `tool/block_scanner_bench.dart`, recorded in the PR.)
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// [lines] lines of prose in paragraphs of four, inside one column when
/// [column].
String _note(int lines, {required bool column}) {
  final note = StringBuffer(column ? ':::: columns\n::: column\n' : '');
  for (var at = 0; at < lines; at++) {
    note.writeln(
      at % 5 == 4 ? '' : 'A line of prose, $at, with **bold** and a [[link]].',
    );
  }
  if (column) note.writeln(':::\n::::');
  return note.toString();
}

/// The scan of [text]: the best of three, and the distinct states its
/// lines enter in.
(Duration, int) _scan(String text) {
  final buffer = SourceBuffer.fromText(text);
  var best = const Duration(days: 1);
  late BlockScanner scanner;
  for (var round = 0; round < 3; round++) {
    final clock = Stopwatch()..start();
    scanner = BlockScanner(buffer);
    clock.stop();
    if (clock.elapsed < best) best = clock.elapsed;
  }
  final states = Set<Object>.identity();
  for (var line = 0; line < buffer.lineCount; line++) {
    states.add(scanner.stateEntering(line));
  }
  return (best, states.length);
}

void main() {
  test('a million lines of prose, in a column and out of one', () {
    const lines = 1000000;
    final (plain, plainStates) = _scan(_note(lines, column: false));
    final (column, columnStates) = _scan(_note(lines, column: true));
    print(
      'columns scan: ${column.inMilliseconds} ms in a column, '
      '${plain.inMilliseconds} ms outside; $columnStates states kept in a '
      'column, $plainStates outside. Bar: a handful of states; within 3 % '
      'under NIMAN_PERF',
    );
    // The two shared states of a run of prose, and the column's pair.
    expect(plainStates, lessThanOrEqualTo(4));
    expect(columnStates, lessThanOrEqualTo(8));
    if (Platform.environment['NIMAN_PERF'] == '1') {
      expect(
        column.inMicroseconds,
        lessThanOrEqualTo(plain.inMicroseconds * 1.03),
      );
    }
  });
}
