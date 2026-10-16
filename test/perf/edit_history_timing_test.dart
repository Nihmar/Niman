// The cost of coalescing in the undo history (#1050): a long run of typing, or
// of deletions, is one step built in O(size), not a step re-joined whole at
// every key.
//
// The measure is a *ratio*, the only thing wall-clock can give across hosts:
// the same run eight times as long should cost about eight times as much
// (linear), not sixty-four (quadratic, which is what joining the whole step
// per key cost). Same shape as the other benchmarks here: the numbers are
// printed, a generous backstop is asserted on any host, and the design's bar
// is asserted only by `NIMAN_PERF=1 flutter test
// test/perf/edit_history_timing_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';

/// Whether this run is the one that holds the design's bar.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The ratio no host explains away: quadratic growth is 64.
const double _backstop = 20;

/// The design's bar: 8x the keystrokes cost at most this many times as much.
const double _ceiling = 14;

/// Records [count] single-character insertions, one after the other, and
/// answers how long the history took, in microseconds.
int _typing(int count) {
  final history = EditHistory();
  final watch = Stopwatch()..start();
  for (var at = 0; at < count; at++) {
    history.record(EditRecord(start: at, removed: '', inserted: 'x'));
  }
  watch.stop();
  expect(history.length, 1, reason: 'one run of typing, one step');
  return watch.elapsedMicroseconds;
}

/// Records [count] Backspaces, from the end of a run, and answers how long.
int _backspacing(int count) {
  final history = EditHistory();
  final watch = Stopwatch()..start();
  for (var at = count; at > 0; at--) {
    history.record(EditRecord(start: at - 1, removed: 'x', inserted: ''));
  }
  watch.stop();
  expect(history.length, 1, reason: 'one run of deletions, one step');
  return watch.elapsedMicroseconds;
}

/// The cost of the longer run over the shorter, best of a few to shed noise.
double _ratio(int Function(int count) run, int small, int large) {
  var best = double.infinity;
  for (var attempt = 0; attempt < 3; attempt++) {
    final short = run(small);
    final long = run(large);
    final ratio = long / (short == 0 ? 1 : short);
    if (ratio < best) best = ratio;
  }
  return best;
}

void main() {
  const small = 20000;
  const large = 160000;

  for (final (name, run) in [
    ('typing', _typing),
    ('backspacing', _backspacing),
  ]) {
    test('$name $large keys costs about ${large ~/ small}x $small', () {
      final ratio = _ratio(run, small, large);
      print(
        'edit history, $name: $large keys cost ${ratio.toStringAsFixed(1)}x '
        '$small keys (linear is ${large ~/ small}x, quadratic '
        '${(large ~/ small) * (large ~/ small)}x); bar $_ceiling under '
        'NIMAN_PERF, backstop $_backstop',
      );
      expect(ratio, lessThan(_backstop), reason: 'quadratic growth');
      if (_referenceHost) expect(ratio, lessThan(_ceiling));
    });
  }
}
