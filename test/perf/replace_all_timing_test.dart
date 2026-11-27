// What Replace all and its undo cost on a note of several megabytes (#1359):
// the step keeps one hunk per match — what each was and became — not the span
// twice, and an undo and a redo give the note back.
//
// The numbers are printed, a generous backstop is asserted on any host, and
// the design's bar only by `NIMAN_PERF=1 flutter test
// test/perf/replace_all_timing_test.dart` (AGENTS.md).
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

/// Whether this run is the one that holds the design's bar.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The slowest any host may take, for the three of them together.
const int _backstopMs = 60000;

/// The design's bar, for the same.
const int _barMs = 2000;

void main() {
  test('Replace all, undo and redo over 120 000 matches in 5 MB', () {
    const matches = 120000;
    final text = [
      for (var i = 0; i < matches; i++) 'line $i has a cat in it, and words',
    ].join('\n');
    final surface = MarkdownSurfaceController(SourceBuffer.fromText(text));
    final find = SourceFindController(surface: () => surface);
    addTearDown(find.dispose);
    find
      ..open()
      ..replaceInput.text = 'owl'
      ..findInput.text = 'cat'
      ..search();

    final watch = Stopwatch()..start();
    find.replaceAllMatches();
    final replaceMs = watch.elapsedMilliseconds;
    expect(surface.buffer.text.contains('cat'), isFalse);
    final units = surface.history.units;
    watch
      ..reset()
      ..start();
    surface.undo();
    final undoMs = watch.elapsedMilliseconds;
    expect(surface.buffer.text, text);
    watch
      ..reset()
      ..start();
    surface.redo();
    final redoMs = watch.elapsedMilliseconds;
    expect(surface.buffer.length, text.length);

    print(
      'replace all, ${text.length ~/ 1024} KB, $matches matches: '
      'replace $replaceMs ms, undo $undoMs ms, redo $redoMs ms; the step holds '
      '$units code units (the span twice would be ${2 * text.length}); '
      'bar $_barMs ms under NIMAN_PERF, backstop $_backstopMs',
    );
    // What each match was and became — 'cat' and 'owl' — and nothing of the
    // span between them.
    expect(units, matches * 6);
    final total = replaceMs + undoMs + redoMs;
    expect(total, lessThan(_backstopMs));
    if (_referenceHost) expect(total, lessThan(_barMs));
  });
}
