// What opening a huge note costs the UI isolate, piece by piece
// (`docs/dev/read-live-parity.md`, "Opening the 246 MB note").
//
// The height map is built on the frame that first draws the note, for every
// row of it: 413 ms of a frozen window on the 246 MB note (profile build),
// most of it allocating a boxed double per row. And the buffer is read from
// the note's text on the load: split into a string per line, it was ~600 ms
// of the 246 MB note's load.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/huge_note_open_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The rows the fixtures have: a million, a third of the 246 MB note's.
const int _rows = 1000000;

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

void main() {
  test('a height map over a million rows', () {
    late BlockHeightMap map;
    final ms = _best(5, () {
      map = BlockHeightMap(
        count: _rows,
        estimate: (row) => (row % 7 + 1) * 21.0,
      );
    });
    // Before the values were unboxed: 72 ms here, where it is 10 now; the
    // backstop is what a runner twice as slow reads for the boxed build.
    const ceiling = 20.0;
    const backstop = 50.0;
    final bar = _referenceHost ? ceiling : backstop;
    print(
      'height map, $_rows rows: ${ms.toStringAsFixed(1)} ms '
      '(held to $bar ms)',
    );
    expect(map.length, _rows);
    expect(ms, lessThan(bar));
  });

  test('a buffer read from a million lines', () {
    final text = List<String>.generate(
      _rows,
      (at) => 'line $at of a note that is long enough to be read',
    ).join('\n');
    late SourceBuffer buffer;
    final ms = _best(3, () => buffer = SourceBuffer.fromText(text));
    // A string per line: 135 ms here; views of the text: 60. Two runners
    // apart differ by as much as that, so the backstop is a regression's
    // and the ceiling, which the old reading fails, is the design's.
    const ceiling = 80.0;
    const backstop = 250.0;
    final bar = _referenceHost ? ceiling : backstop;
    print(
      'buffer, $_rows lines: ${ms.toStringAsFixed(1)} ms (held to $bar ms)',
    );
    expect(buffer.lineCount, _rows);
    expect(ms, lessThan(bar));
  });

  // The map the source surface builds over the note's lines, asking each
  // line's length of the buffer: 202 ms of the frame that opened the 246 MB
  // note in the profile build (2026-09-24), 2.76 M lines. Made lazy, a
  // chunk of lines stands at an estimate from its characters until a frame
  // reaches it, and the frame that opens the note asks about one screen.
  test('the height map over a million lines, and the first screen', () {
    final text = List<String>.generate(
      _rows,
      (at) => 'line $at of a note that is long enough to be read',
    ).join('\n');
    final buffer = SourceBuffer.fromText(text);
    const columns = 80.0;
    const row = 21.0;
    double estimate(int line) =>
        ((buffer.lineLengthAt(line) / columns).ceil().clamp(1, 1 << 30)) * row;
    // One screen, as a first frame asks for it: where the top is, and each
    // row's offset down to the bottom.
    void firstScreen(BlockHeightMap map) {
      final top = map.indexAt(0) ?? 0;
      for (var line = top; line < top + 60; line++) {
        map.offsetOf(line);
      }
    }

    final eager = _best(3, () {
      firstScreen(BlockHeightMap(count: _rows, estimate: estimate));
    });
    late BlockHeightMap lazy;
    final ms = _best(3, () {
      lazy = BlockHeightMap.lazy(
        count: _rows,
        estimate: estimate,
        estimateSpan: (first, end) => (end - first) * row,
      );
      firstScreen(lazy);
    });
    // Every line asked: 17.6 ms here; a chunk at a time: 0.1. The
    // backstop is a fifth of the eager build on the same run, which holds
    // on any runner; the ceiling is the design's.
    const ceiling = 5.0;
    final bar = _referenceHost ? ceiling : eager / 5;
    print(
      'height map over $_rows lines, first screen: eager '
      '${eager.toStringAsFixed(1)} ms, lazy ${ms.toStringAsFixed(1)} ms '
      '(held to ${bar.toStringAsFixed(1)} ms)',
    );
    expect(lazy.length, _rows);
    expect(ms, lessThan(bar));
  });
}
