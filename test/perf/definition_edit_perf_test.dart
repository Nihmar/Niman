// A keystroke in a link or footnote definition of a note of 100 000 of them
// (#1372). The styler used to read every definition again for it — about
// 200 ms on the UI isolate; it reads the line it changed, and combines the
// scope from what it kept.
//
// The numbers are printed, a **backstop** is asserted on any host, and the
// design's bar is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/definition_edit_perf_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// Whether this run is the one that holds the design's bars.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// What an edit and the sixty lines of a frame took, in milliseconds, the
/// median of [rounds] edits at the middle of a note made of [line] lines.
double _median(String Function(int i) line, int offset, {int rounds = 9}) {
  final buffer = SourceBuffer.fromText(
    [for (var i = 0; i < 100000; i++) line(i)].join('\n'),
  );
  final styler = SourceStyler(buffer);
  final times = <int>[];
  final at = buffer.offsetOfLine(50000) + offset;
  for (var round = 0; round < rounds; round++) {
    final watch = Stopwatch()..start();
    styler.edited(buffer.insert(at, 'x'));
    for (var l = 49990; l < 50050; l++) {
      styler.tokensOf(l);
    }
    times.add(watch.elapsedMilliseconds);
  }
  // Still what a fresh read has: the edits did not lose a definition.
  expect(
    styler.scope.references.length + styler.scope.footnoteCounts.length,
    100000,
  );
  times.sort();
  return times[rounds ~/ 2].toDouble();
}

void main() {
  test('a keystroke in a link definition of 100 000', () {
    final took = _median((i) => '[l$i]: /u$i', 10);
    print('a link definition edited: $took ms (before: ~220 ms)');
    expect(took, lessThan(_referenceHost ? 80 : 400));
  });

  test('a keystroke in a footnote definition of 100 000', () {
    final took = _median((i) => '[^n$i]: note $i', 12);
    print('a footnote definition edited: $took ms (before: ~215 ms)');
    expect(took, lessThan(_referenceHost ? 150 : 600));
  });
}
