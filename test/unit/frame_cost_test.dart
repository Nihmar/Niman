// What a frame costs, read off the frame's own path (#316): two `Stopwatch`es
// and their clock reads per frame, charged to the very frames the report is
// about. They run only in a build that asked for them (#362) — what this
// holds is the gate, in the configuration every release build and every test
// runs in.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:niman/src/core/logging.dart';

void main() {
  test('the frame instrumentation is off unless asked for', () {
    // The flag is read at compile time: a profiling build sets
    // `--dart-define=NIMAN_FRAMES=true`, and nothing else turns it on.
    expect(nimanFrames, isFalse, reason: 'the tests run with the flag off');

    final cost = FrameCost(
      label: 'x',
      log: const AppLogger(name: 'x'),
    );
    const child = SizedBox.shrink();

    // Nothing wraps the built subtree: what a frame's layout and paint are
    // timed by is the render object `timed` would return.
    expect(identical(cost.timed(() => child), child), isTrue);
    expect(cost.build, 0);

    // And the edit path reads no clock either.
    cost
      ..startEdit()
      ..endEdit();
    expect(cost.total, 0);
  });
}
