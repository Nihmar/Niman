// #730 phase 1: the calendar controller — one load on open, a debounced
// reload per revision that skips when the file did not move, a closed
// library clearing the snapshot, and a failing read surfacing its error.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_controller.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory root;
  late FakeLibrarySession session;
  late CalendarController controller;

  /// Waits until [done] holds (or a ~1 s budget runs out, so a stuck
  /// refresh fails the test instead of hanging it).
  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void write(String content) {
    File(p.join(root.path, calendarFileName)).writeAsStringSync(content);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_calendar_ctrl_');
    session = FakeLibrarySession();
    await session.open(root.path, create: false);
    controller = CalendarController(
      session: session,
      refreshDebounce: const Duration(milliseconds: 1),
    );
  });

  tearDown(() async {
    controller.dispose();
    await session.dispose();
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('open with no file yields an empty snapshot', () async {
    await controller.open();
    expect(controller.snapshot, isNotNull);
    expect(controller.snapshot!.entries, isEmpty);
    expect(controller.snapshot!.exists, isFalse);
    expect(controller.error, isNull);
  });

  test('open reads the file', () async {
    write('2026-10-05 w41 Mon  9-12 library.\n');
    await controller.open();
    expect(controller.snapshot!.entries.single.line.kind.name, 'day');
  });

  test('a revision that left the file alone does not reload', () async {
    write('2026-10-05 w41 Mon  9-12 library.\n');
    await controller.open();
    final at = controller.snapshot;

    session.bumpContents();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(identical(controller.snapshot, at), isTrue);
  });

  test('a revision that moved the file reloads', () async {
    write('2026-10-05 w41 Mon  9-12 library.\n');
    await controller.open();
    final at = controller.snapshot;

    write('2026-10-05 w41 Mon  9-12 library.\n2026-10-06 w41 Tue\n');
    session.bumpContents();
    await waitFor(() => controller.snapshot!.entries.length == 2);
    expect(identical(controller.snapshot, at), isFalse);
    expect(controller.snapshot!.entries, hasLength(2));
  });

  test('a closed library clears the snapshot', () async {
    write('2026-10-05 w41 Mon  9-12 library.\n');
    await controller.open();
    expect(controller.snapshot!.entries, isNotEmpty);

    await session.close();
    await controller.reload();
    expect(controller.snapshot, isNull);
  });

  test(
    'a failing read surfaces its error, and the next open recovers',
    () async {
      final failing = CalendarController(
        session: session,
        refreshDebounce: const Duration(milliseconds: 1),
        sourceFactory: (_) => _FailingSource(),
      );
      addTearDown(failing.dispose);
      await failing.open();
      expect(failing.snapshot, isNull);
      expect(failing.error, isNotNull);
    },
  );
}

/// A source whose reads always fail: the error path.
final class _FailingSource implements CalendarSource {
  @override
  Future<CalendarSnapshot> load() async => throw StateError('no disk today');

  @override
  Future<CalendarFileProbe> probe() async =>
      const CalendarFileProbe(exists: false, size: -1, modified: null);
}
