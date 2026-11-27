// What Tab costs on an item of a long list (#1355).
//
// `listIndentEdit` used to walk down to the end of the list block and rebuild
// every row and a tree of it: 35 ms at 10 000 items, 118 ms at 100 000 and
// 417 ms at 400 000 on the UI isolate, for one item moved. It now reads down
// only as far as the edit can change anything — the item's subtree and the
// run of siblings it renumbers — so a bulleted list costs the same at any
// length.
//
// Same shape as the other benchmarks here: the numbers are printed, a
// **backstop** is asserted on any host, and the design's ceiling is asserted
// only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/list_indent_edit_perf_test.dart`.
// The backstop is a ratio, which holds on any hardware: ten times the list may
// not cost anywhere near ten times more.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/list_indent_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Whether this run is the one that holds the design's ceiling.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The design's ceiling for Tab on the middle item, in milliseconds.
const double _ceiling = 2;

/// The most the cost may grow when the list is ten times longer.
const double _ratio = 4;

/// The best of [runs] runs of Tab on the middle item of a list of [items]
/// lines written by [item], in milliseconds.
double _tab(int items, String Function(int at) item, {int runs = 7}) {
  final buffer = SourceBuffer.fromText(
    [for (var at = 0; at < items; at++) item(at)].join('\n'),
  );
  final caret = SelectionModel.at(buffer.offsetOfLine(items ~/ 2) + 2);
  var best = double.infinity;
  for (var run = 0; run < runs; run++) {
    final watch = Stopwatch()..start();
    final edit = listIndentEdit(buffer, caret, width: 2, outdent: false);
    watch.stop();
    expect(edit, isNotNull);
    final ms = watch.elapsedMicroseconds / 1000;
    if (ms < best) best = ms;
  }
  return best;
}

void main() {
  test(
    'Tab on the middle item of a bulleted list costs the same at any length',
    () {
      final small = _tab(10000, (at) => '- item $at');
      final large = _tab(100000, (at) => '- item $at');
      print(
        'Tab, 10 000 items: ${small.toStringAsFixed(3)} ms; '
        '100 000 items: ${large.toStringAsFixed(3)} ms',
      );
      // A backstop on any host: the old walk was linear (35 ms and 118 ms).
      // The floor keeps a ratio of two tiny numbers from deciding the test.
      expect(large, lessThan(small * _ratio + 5));
      if (_referenceHost) {
        expect(large, lessThan(_ceiling), reason: 'the design bar');
      } else {
        print(
          '(the ${_ceiling.toStringAsFixed(0)} ms bar runs under NIMAN_PERF)',
        );
      }
    },
  );

  test('Tab on an item of a numbered list is as long as what it renumbers', () {
    // Every item below counts on from the one moved, so every one of them is
    // renumbered: the cost is that of the run, and it is printed, not held.
    final run = _tab(100000, (at) => '${at + 1}. item', runs: 3);
    print(
      'Tab, 100 000 numbered items, 50 000 renumbered: '
      '${run.toStringAsFixed(1)} ms',
    );
  });
}
