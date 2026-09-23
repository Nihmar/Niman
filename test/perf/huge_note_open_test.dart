// What opening a huge note costs the UI isolate, piece by piece
// (`docs/dev/read-live-parity.md`, "Opening the 246 MB note").
//
// The height map is built on the frame that first draws the note, for every
// row of it: 413 ms of a frozen window on the 246 MB note (profile build),
// most of it allocating a boxed double per row.
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/huge_note_open_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';

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
}
