// #1109 phase 5: the alarms follow the Todo and Calendar switches. Off
// schedules nothing and cancels what was scheduled, counting it; on
// schedules again from the file; a switch that arrives from elsewhere (a
// sync) takes the same single path.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/todo/reminder_cancellation.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';

void main() {
  late Directory root;
  late FakeLibrarySession session;
  late FakeReminderService reminders;
  late TodoController controller;

  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Features without(LibraryFeature feature) =>
      const Features().withSwitch(feature, on: false);

  CalendarSnapshot calendarOf(List<String> lines) => calendarSnapshotOf(
    CalendarFileContent(
      lines: [for (final line in lines) CalendarRawLine(line, '\n')],
    ),
  );

  Future<void> openWith({String todo = '', Features? features}) async {
    File(p.join(root.path, 'todo.txt')).writeAsStringSync(todo);
    if (features != null) session.features.value = features;
    controller = TodoController(
      session: session,
      clock: () => DateTime(2026, 9, 7),
      refreshDebounce: const Duration(milliseconds: 1),
      reminders: reminders,
    );
    await controller.open();
    await waitFor(() => reminders.reconciled.isNotEmpty);
  }

  const twoTasks =
      'call rem:2026-09-08T10:30\nwrite rem:2026-09-09T09:00\nplain\n';
  const oneEvent = '2026-09-08 w37 Tue  9 dentist rem:08:30.';

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_rem_features_');
    session = FakeLibrarySession();
    await session.open(root.path, create: false);
    reminders = FakeReminderService();
  });

  tearDown(() async {
    controller.dispose();
    await session.dispose();
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  test('with todo off nothing is scheduled for a task', () async {
    await openWith(todo: twoTasks, features: without(LibraryFeature.todo));
    expect(reminders.reconciled.last, isEmpty);
  });

  test('turning todo off cancels the alarms and counts them', () async {
    await openWith(todo: twoTasks);
    expect(reminders.reconciled.last, hasLength(2));

    session.features.value = without(LibraryFeature.todo);
    final cancelled = await controller.featureReconcile;

    expect(cancelled, const ReminderCancellation(todo: 2));
    expect(cancelled.total, 2);
    expect(reminders.reconciled.last, isEmpty);
    expect(
      File(p.join(root.path, 'todo.txt')).readAsStringSync(),
      twoTasks,
      reason: 'off is inert: the file keeps its rem: tags',
    );
  });

  test('turning todo on again schedules from the file', () async {
    await openWith(todo: twoTasks);
    session.features.value = without(LibraryFeature.todo);
    await controller.featureReconcile;

    session.features.value = const Features();
    final cancelled = await controller.featureReconcile;

    expect(cancelled, ReminderCancellation.none);
    expect(reminders.reconciled.last, hasLength(2));
  });

  test('a file change while todo is off schedules nothing', () async {
    await openWith(todo: twoTasks, features: without(LibraryFeature.todo));
    await controller.add('later rem:2026-09-10T08:00');
    await waitFor(() => reminders.reconciled.length >= 2);
    expect(reminders.reconciled, everyElement(isEmpty));
  });

  test('turning calendar off cancels its events, not the tasks', () async {
    await openWith(todo: twoTasks);
    controller.calendar = calendarOf(const [oneEvent]);
    await waitFor(() => reminders.reconciled.last.length == 3);
    expect(reminders.reconciled.last, hasLength(3));

    session.features.value = without(LibraryFeature.calendar);
    final cancelled = await controller.featureReconcile;

    expect(cancelled, const ReminderCancellation(calendar: 1));
    expect(reminders.reconciled.last, hasLength(2));

    session.features.value = const Features();
    await controller.featureReconcile;
    expect(reminders.reconciled.last, hasLength(3));
  });

  test('with calendar off an event is not scheduled', () async {
    await openWith(todo: twoTasks, features: without(LibraryFeature.calendar));
    controller.calendar = calendarOf(const [oneEvent]);
    await waitFor(() => reminders.reconciled.length >= 2);
    expect(reminders.reconciled.last, hasLength(2));
  });

  test('both off cancels both and counts them together', () async {
    await openWith(todo: twoTasks);
    controller.calendar = calendarOf(const [oneEvent]);
    await waitFor(() => reminders.reconciled.last.length == 3);

    session.features.value = const Features()
        .withSwitch(LibraryFeature.todo, on: false)
        .withSwitch(LibraryFeature.calendar, on: false);
    final cancelled = await controller.featureReconcile;

    expect(cancelled, const ReminderCancellation(todo: 2, calendar: 1));
    expect(cancelled.total, 3);
    expect(reminders.reconciled.last, isEmpty);
  });

  test('a switch from a sync reconciles once, and only that one', () async {
    await openWith(todo: twoTasks);
    final before = reminders.reconciled.length;

    // What a sync does: the settings merge assigns the other device's
    // switches, with no screen involved.
    session.features.value = without(LibraryFeature.todo);
    await controller.featureReconcile;
    expect(reminders.reconciled, hasLength(before + 1));

    // The same value again (the screen's own write landing after the
    // listener): no second run.
    session.features.value = without(LibraryFeature.todo);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(reminders.reconciled, hasLength(before + 1));

    // A switch that owns no alarm: no run either.
    session.features.value = without(LibraryFeature.todo)
        .withSwitch(LibraryFeature.search, on: false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(reminders.reconciled, hasLength(before + 1));
  });

  test('a library with nothing flipped answers nothing cancelled', () async {
    await openWith(todo: twoTasks);
    expect(await controller.featureReconcile, ReminderCancellation.none);
  });
}
