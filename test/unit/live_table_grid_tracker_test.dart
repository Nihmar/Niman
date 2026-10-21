// The grid a table's + handles are built on is checked once against the
// frame that drew the table, and the correction is kept for the grid it
// corrects (#261).
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/live_table_grid_tracker.dart';

void main() {
  const worked = Rect.fromLTRB(10, 100, 210, 180);

  testWidgets('a grid the frame drew as worked out is left alone', (
    tester,
  ) async {
    var asked = 0;
    final tracker = LiveTableGridTracker(
      drawn: () {
        asked++;
        return worked.shift(const Offset(0.3, 0));
      },
    );
    addTearDown(tracker.dispose);
    var notified = 0;
    tracker.addListener(() => notified++);
    expect(tracker.settle(worked), worked);
    await tester.pump();
    expect(asked, 1, reason: 'checked after the frame');
    expect(notified, 0);
  });

  testWidgets('a grid the frame moved is replaced, and checked once', (
    tester,
  ) async {
    var asked = 0;
    const laid = Rect.fromLTRB(10, 160, 210, 240);
    final tracker = LiveTableGridTracker(
      drawn: () {
        asked++;
        return laid;
      },
    );
    addTearDown(tracker.dispose);
    var notified = 0;
    tracker.addListener(() => notified++);
    // Built before the frame: the worked out grid.
    expect(tracker.settle(worked), worked);
    await tester.pump();
    expect(notified, 1);
    // Built again on the same grid: the drawn one, with no check of its own.
    expect(tracker.settle(worked), laid);
    await tester.pump();
    expect(asked, 1);
    expect(notified, 1);
    // A grid the table has not been at: worked out, and checked again.
    const moved = Rect.fromLTRB(10, 300, 210, 380);
    expect(tracker.settle(moved), moved);
    await tester.pump();
    expect(asked, 2);
  });

  testWidgets('one check serves the builds before the frame ends', (
    tester,
  ) async {
    var asked = 0;
    final tracker = LiveTableGridTracker(
      drawn: () {
        asked++;
        return worked;
      },
    );
    addTearDown(tracker.dispose);
    tracker
      ..settle(worked)
      ..settle(worked.shift(const Offset(0, 20)))
      ..settle(worked.shift(const Offset(0, 40)));
    await tester.pump();
    expect(asked, 1);
  });

  testWidgets('no table in play forgets the correction', (tester) async {
    final tracker = LiveTableGridTracker(
      drawn: () => worked.shift(const Offset(0, 50)),
    );
    addTearDown(tracker.dispose);
    tracker.settle(worked);
    await tester.pump();
    expect(tracker.settle(null), isNull);
    expect(tracker.settle(worked), worked);
  });
}
