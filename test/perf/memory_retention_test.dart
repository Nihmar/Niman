// What the structures a running app keeps hold, in bytes (#1193,
// `docs/records/memory-usage.md`): an open note's buffer, a page of the
// tree's rows, a list of parsed tasks. The block scanner has its own file
// (`block_memory_test.dart`).
//
// **How it is measured.** `HeapMeter` (`heap_meter.dart`): with
// `flutter test --enable-vmservice` the heap after a collection, exact;
// without it the resident set, a bound read as the median of a few runs.
// Each line says which one it printed.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's bar is
// asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test --enable-vmservice
// test/perf/memory_retention_test.dart`. The bars are the exact reading's:
// held to them, a resident-set reading would fail for the collector, not
// for the code.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/todo/parser.dart';

import 'heap_meter.dart';

/// Whether this run is the one that holds the design's bars.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The bar an exact reading is held to under `NIMAN_PERF`, else the
/// backstop.
double _bar(HeapMeter meter, {required double design, required double stop}) =>
    _referenceHost && meter.exact ? design : stop;

void main() {
  late HeapMeter meter;
  setUpAll(() async => meter = await HeapMeter.open());
  tearDownAll(() => meter.close());

  test('a note open in the editor: its buffer over its text', () async {
    // The text is the note as read, held by the load either way: what the
    // buffer adds is its line index — views of that text, not copies.
    const lines = 1000000;
    final text = List<String>.generate(
      lines,
      (at) => 'Line $at of a note, long enough to be a line of prose.',
    ).join('\n');
    final held = await meter.held(() => SourceBuffer.fromText(text));
    final perLine = held / lines;
    // Measured exact (2026-10-27): 21 B a line. The resident set read 7, and
    // a run without the VM service still reads anything from -63 to 64.
    final bar = _bar(meter, design: 32, stop: 64);
    print(
      'buffer, $lines lines: ${(held / (1 << 20)).toStringAsFixed(1)} MB, '
      '${perLine.toStringAsFixed(1)} B a line (${meter.unit}; held to $bar)',
    );
    expect(perLine, lessThan(bar));
  });

  test('a page of the tree: its rows', () async {
    // What `TreeChildCache` keeps of a folder for each page read (#1200).
    const rows = 2000;
    final modified = DateTime(2026, 10, 27);
    final held = await meter.held(
      () => [
        for (var at = 0; at < rows; at++)
          Note(
            id: at + 1,
            path: 'Projects/Notes of the year/note number $at.md',
            parent: 7,
            name: 'note number $at.md',
            nameKey: 'note number $at.md',
            isDir: false,
            size: 4096 + at,
            modified: modified.add(Duration(minutes: at)),
            created: modified.subtract(Duration(minutes: at)),
            sha256: at.toRadixString(16).padLeft(64, '0'),
            pinned: false,
          ),
      ],
    );
    final perRow = held / rows;
    // Measured exact (2026-10-27): 697 B a row — the path, the name and its
    // key, the digest's 64 characters, two `DateTime`s and the fields.
    final bar = _bar(meter, design: 1024, stop: 2048);
    print(
      'tree page, $rows rows: ${(held / 1024).toStringAsFixed(0)} KB, '
      '${perRow.toStringAsFixed(0)} B a row (${meter.unit}; held to $bar)',
    );
    expect(perRow, lessThan(bar));
  });

  test('a list of tasks: each parsed', () async {
    // What the todo controller keeps of `todo.txt` while a library is open.
    const tasks = 10000;
    final lines = List<String>.generate(
      tasks,
      (at) =>
          '(A) 2026-10-${(at % 28 + 1).toString().padLeft(2, '0')} '
          'Call the plumber about task $at +home @phone due:2026-11-01',
    );
    final held = await meter.held(
      () => [for (final line in lines) parseTodoLine(line)],
    );
    final perTask = held / tasks;
    // Measured exact (2026-10-27): 775 B a task, where the resident set had
    // read 193 (the survey's probe, `docs/records/memory-usage.md`).
    final bar = _bar(meter, design: 1024, stop: 2048);
    print(
      'tasks, $tasks: ${(held / 1024).toStringAsFixed(0)} KB, '
      '${perTask.toStringAsFixed(0)} B a task (${meter.unit}; held to $bar)',
    );
    expect(perTask, lessThan(bar));
  });
}
