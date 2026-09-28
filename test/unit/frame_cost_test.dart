// What a frame costs, read off the frame's own path (#316): two `Stopwatch`es
// and their clock reads per frame, charged to the very frames the report is
// about. They run only in a build that asked for them (#362) — what this
// holds is the gate, in the configuration every release build and every test
// runs in.
//
// The gate is what keeps the report a log line, and a test frame is far under
// a bar a real frame misses, so the naming is pinned where it is written —
// `FrameCost.report()`, the same call `book()` makes after a frame — and read
// back through the same log buffer (`AppLog`) the rest of the suite uses.
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

  test('a frame with both panes silent is named for the shell', () {
    // The editor and the read pane report their own share of a frame (#316,
    // #323). A frame that misses outside them had no name: the app-wide
    // `[frames] slow frame` line (main.dart) names no region, and a pane
    // under its bar says nothing at all, so silence read the same at 2 ms and
    // at 15.9 ms. The shell is that region (#324).
    AppLog.clear();
    addTearDown(AppLog.clear);

    final shell = shellFrameCost();
    expect(shell.label, shellFrameLabel);
    // A whole frame, as for a pane: what the shell's line adds is the frame
    // at its top, the panes' own lines being the shares inside it.
    expect(shell.barMicros, FrameCost.paneBarMicros);

    // The line the post-frame report writes for a frame this region missed.
    shell
      ..build = FrameCost.paneBarMicros
      ..report();

    final line = AppLog.lines().single;
    expect(
      line,
      contains(
        '[$shellFrameLabel] $shellFrameLabel frame: edit 0.0 ms, '
        'build 16.0 ms',
      ),
      reason: line,
    );
    // Its own name, not the unnamed app-wide line it used to be left to.
    expect(line, isNot(contains('slow frame')), reason: line);
  });
}
