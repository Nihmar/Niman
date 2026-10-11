// The list drag's edge scroll and its release (#720).
//
// The reported fault: a drag held at a list edge scrolled the list under the
// finger (a jump per move event), and the release could freeze — the row the
// gesture lived on scrolled out of the viewport, its recognizer went with it,
// and the drag never ended: no drop, the indicator stuck, the edge scroll
// still running, every later drag refused. The row is kept alive while it is
// the drag source now, the edge scroll runs a frame at a time like the tree's
// (#580) and stops with the drag, and the release reads the drop against the
// rows as they then stand.
//
// What is timed is a **held frame** — the scroll, the drop read again over
// the built rows, and the rebuild that lights it — and the **release work** —
// the drop resolved and the move rewritten — with the frame that rebuilds
// after it reported too. All of them are what a finger feels.
//
// The property that holds on any host is the ratio: ten times the list may
// not make a held frame cost anywhere near ten times more, which is what a
// step proportional to the note would look like (the drop used to be read
// against every item). The absolute numbers are printed; the design's
// ceilings — one frame (16 ms) for a held frame, and one for the release
// work — are asserted only by a run that asks for it:
// `NIMAN_PERF=1 flutter test test/perf/list_drag_release_test.dart`, the
// shape every benchmark here keeps.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/kinds/list_note.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// A backstop for the hosts that are not the reference one: a real
/// regression — the stuck drag, a rewrite gone quadratic — blows well past
/// these, and no calibration explains that away.
const double _frameBackstop = 120;
const double _releaseBackstop = 400;

/// The design's ceiling for a held frame and for the release's own work, in
/// milliseconds: one frame either way.
const double _frameCeiling = 16;
const double _releaseCeiling = 16;

/// A list note of [items] items.
String _list(int items) =>
    '${[for (var i = 0; i < items; i++) '- [ ] item $i'].join('\n')}\n';

/// The held frame, the release's own work and the frame after it, in
/// milliseconds, for a list of [items].
Future<({double frame, double release, double after})> _perDrag(
  WidgetTester tester,
  int items,
) async {
  tester.view.physicalSize = const Size(400, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  String? out;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListNoteView(text: _list(items), onChanged: (t) => out = t),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final list = tester.getRect(find.byType(ListView));
  await tester.fling(find.byType(ListView), const Offset(0, -600), 2000);
  await tester.pumpAndSettle();

  // A visible handle, dragged to the top edge and held there.
  final handle = find.byKey(const Key('list-drag-handle')).at(1);
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await tester.pump();
  await gesture.moveTo(Offset(list.center.dx, list.top + 4));
  await tester.pump();
  // Warm: the first frames build the rows the scroll brings in.
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }

  const frames = 60;
  final held = Stopwatch()..start();
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  held.stop();

  // The release's own work: the drop read, the move rewritten, the state
  // set. The frame after it rebuilds the rows the move redrew — the same
  // cost as any frame of this list, timed apart so the bar is the work.
  final release = Stopwatch()..start();
  await gesture.up();
  release.stop();
  final after = Stopwatch()..start();
  await tester.pump();
  after.stop();
  await tester.pumpAndSettle();

  // The release resolved a drop and landed it, whatever the list's length.
  expect(out, isNotNull, reason: 'the release resolved a drop');
  expect(out!.startsWith('- [ ] item 0\n'), isTrue, reason: out);
  return (
    frame: held.elapsedMicroseconds / 1000 / frames,
    release: release.elapsedMicroseconds / 1000,
    after: after.elapsedMicroseconds / 1000,
  );
}

void main() {
  testWidgets('a held drag frame and the release do not cost the note (#720)', (
    tester,
  ) async {
    // Warm: the first drag pays the JIT for the row build.
    await _perDrag(tester, 300);
    final small = await _perDrag(tester, 500);
    final large = await _perDrag(tester, 5000);
    print(
      'list drag: held frame ${small.frame.toStringAsFixed(3)} ms at 500 '
      'items, ${large.frame.toStringAsFixed(3)} ms at 5 000 '
      '(×${(large.frame / small.frame).toStringAsFixed(1)}); release work '
      '${small.release.toStringAsFixed(3)} / '
      '${large.release.toStringAsFixed(3)} ms; frame after '
      '${small.after.toStringAsFixed(3)} / '
      '${large.after.toStringAsFixed(3)} ms',
    );
    // Ten times the list. A step proportional to the note would show here.
    expect(large.frame / small.frame, lessThan(4));
    // The backstop every run keeps.
    expect(large.frame, lessThan(_frameBackstop));
    expect(large.release, lessThan(_releaseBackstop));
    if (_referenceHost) {
      // The design's own budget, asked for rather than assumed: one frame
      // of the edge scroll, and one frame for the release's work.
      expect(large.frame, lessThan(_frameCeiling));
      expect(large.release, lessThan(_releaseCeiling));
    }
  });
}
