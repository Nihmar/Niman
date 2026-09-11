// T-TD-03 AC: migration-on-open + revision-driven refresh — an external
// `x` line is archived on the next open/refresh, quiet revisions skip
// the content read, and the tab's own ops publish without a round trip.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';

void main() {
  late Directory root;
  late FakeLibrarySession session;
  late TodoController controller;

  /// Waits until [done] holds (or a ~1 s budget runs out, so a stuck
  /// refresh fails the test instead of hanging it).
  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void writeRaw(String name, String content) {
    File(p.join(root.path, name)).writeAsStringSync(content);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_todo_ctrl_');
    session = FakeLibrarySession();
    await session.open(root.path, create: false);
    controller = TodoController(
      session: session,
      clock: () => DateTime(2026, 9, 7),
      refreshDebounce: const Duration(milliseconds: 1),
    );
  });

  tearDown(() async {
    controller.dispose();
    await session.dispose();
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  test('open with no files yields an empty snapshot', () async {
    await controller.open();
    expect(controller.snapshot, isNotNull);
    expect(controller.snapshot!.todo, isEmpty);
    expect(controller.snapshot!.done, isEmpty);
    expect(File(p.join(root.path, 'todo.txt')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'done.txt')).existsSync(), isFalse);
  });

  test('open archives stray x lines after the existing done lines', () async {
    writeRaw('todo.txt', 'open a\nx 2026-09-06 2026-01-02 stray\nopen b\n');
    writeRaw('done.txt', 'x 2026-09-01 old\n');
    await controller.open();
    expect(
      [for (final entry in controller.snapshot!.todo) entry.task.description],
      ['open a', 'open b'],
    );
    expect(
      [for (final entry in controller.snapshot!.done) entry.task.description],
      ['old', 'stray'],
    );
  });

  test('a quiet revision skips the content read', () async {
    writeRaw('todo.txt', 'open\n');
    await controller.open();
    final snapshot = controller.snapshot;
    session.notify();
    await waitFor(() => false);
    expect(identical(controller.snapshot, snapshot), isTrue);
  });

  test('an external append reloads on the next revision', () async {
    writeRaw('todo.txt', 'open a\n');
    await controller.open();
    writeRaw('todo.txt', 'open a\nopen b\n');
    session.notify();
    await waitFor(() => controller.snapshot!.todo.length == 2);
    expect(controller.snapshot!.todo.length, 2);
  });

  test('an external x line is archived on the next revision', () async {
    writeRaw('todo.txt', 'open a\n');
    await controller.open();
    writeRaw('todo.txt', 'open a\nx 2026-09-06 stray\n');
    session.notify();
    await waitFor(() => controller.snapshot!.done.length == 1);
    expect(controller.snapshot!.todo.single.task.description, 'open a');
    expect(controller.snapshot!.done.single.task.description, 'stray');
  });

  test("the tab's own add publishes without a revision", () async {
    await controller.open();
    await controller.add('task +p');
    expect(controller.snapshot!.todo.single.task.projects, ['p']);
    expect(File(p.join(root.path, 'todo.txt')).readAsStringSync(), 'task +p');
  });

  test("the tab's own check stamps the injected clock", () async {
    await controller.open();
    await controller.add('(A) 2026-01-02 task');
    await controller.check(controller.snapshot!.todo.single);
    expect(controller.snapshot!.todo, isEmpty);
    expect(
      File(p.join(root.path, 'done.txt')).readAsStringSync(),
      'x (A) 2026-09-07 2026-01-02 task',
    );
  });

  test('a failing op surfaces on error and keeps the snapshot', () async {
    await controller.open();
    await controller.add('kept');
    final entry = controller.snapshot!.todo.single;
    File(p.join(root.path, 'todo.txt')).deleteSync();
    await controller.check(entry);
    expect(controller.error, isNotNull);
    expect(controller.snapshot!.todo.single.task.description, 'kept');
  });

  test('closing the library clears the snapshot', () async {
    writeRaw('todo.txt', 'open\n');
    await controller.open();
    expect(controller.snapshot!.todo, hasLength(1));
    await session.close();
    await waitFor(() => controller.snapshot == null);
    expect(controller.snapshot, isNull);
  });

  group('reminders', () {
    late FakeReminderService reminders;
    late TodoController reminded;

    setUp(() {
      reminders = FakeReminderService();
      reminded = TodoController(
        session: session,
        clock: () => DateTime(2026, 9, 7),
        refreshDebounce: const Duration(milliseconds: 1),
        reminders: reminders,
      );
    });

    tearDown(() {
      reminded.dispose();
    });

    test('an add with a future rem: reconciles it', () async {
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      await reminded.add('call rem:2026-09-08T10:30');
      await waitFor(() => reminders.reconciled.length == 2);
      final wanted = reminders.reconciled.last;
      expect(wanted.keys.single, todoReminderId('call rem:2026-09-08T10:30'));
      expect(wanted.values.single.when, DateTime(2026, 9, 8, 10, 30));
    });

    test('past reminders reconcile as nothing', () async {
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      await reminded.add('call rem:2026-09-06T10:30');
      await waitFor(() => reminders.reconciled.length == 2);
      expect(reminders.reconciled.last, isEmpty);
    });

    test('checking drops the reminder on the next sync', () async {
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      await reminded.add('call rem:2026-09-08T10:30');
      await waitFor(() => reminders.reconciled.length == 2);
      expect(reminders.reconciled.last, hasLength(1));
      await reminded.check(reminded.snapshot!.todo.single);
      await waitFor(() => reminders.reconciled.length == 3);
      expect(reminders.reconciled.last, isEmpty);
    });

    test('a denied permission reconciles nothing', () async {
      reminders.permissionGranted = false;
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      await reminded.add('call rem:2026-09-08T10:30');
      await waitFor(() => reminders.reconciled.length == 2);
      expect(reminders.reconciled.last, isEmpty);
    });

    test('a failing service keeps the op working', () async {
      reminders.failReconcile = true;
      await reminded.open();
      await reminded.add('kept');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reminded.error, isNull);
      expect(reminded.snapshot!.todo.single.task.description, 'kept');
    });

    test('a resume before anything loaded schedules, never cancels', () async {
      // The shell resumes on every foreground return, including before
      // its own open() has published. Handing the service an empty set
      // there cancelled every pending alarm on the device.
      writeRaw('todo.txt', 'call rem:2026-09-08T10:30\n');
      await reminded.resyncReminders();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      expect(
        reminders.reconciled.single.keys.single,
        todoReminderId('call rem:2026-09-08T10:30'),
      );
    });

    test('repeated resumes never reconcile an empty set', () async {
      writeRaw('todo.txt', 'call rem:2026-09-08T10:30\n');
      await reminded.resyncReminders();
      await reminded.resyncReminders();
      await reminded.resyncReminders();
      await waitFor(() => reminders.reconciled.length >= 3);
      expect(reminders.reconciled, everyElement(hasLength(1)));
    });

    test('no library open reconciles nothing at all', () async {
      await session.close();
      await reminded.resyncReminders();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reminders.reconciled, isEmpty);
    });

    test('closing the library leaves the scheduled alarms alone', () async {
      // Reminders outlive a close and converge on the next open: the
      // clear-on-close path only ever ran in tests, and a stray empty
      // reconcile is indistinguishable from a wipe.
      writeRaw('todo.txt', 'call rem:2026-09-08T10:30\n');
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      final before = reminders.reconciled.length;
      await session.close();
      await waitFor(() => reminded.snapshot == null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reminders.reconciled, hasLength(before));
    });

    test('completing a task in place drops its reminder', () async {
      writeRaw('todo.txt', 'call rem:2026-09-08T10:30\n');
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      expect(reminders.reconciled.last, hasLength(1));
      await reminded.updateTodo(
        reminded.snapshot!.todo.single,
        'x 2026-09-07 call rem:2026-09-08T10:30',
      );
      await waitFor(() => reminders.reconciled.length >= 2);
      expect(reminders.reconciled.last, isEmpty);
    });

    test('resyncReminders reconciles without touching the files', () async {
      await reminded.open();
      await waitFor(() => reminders.reconciled.isNotEmpty);
      await reminded.add('call rem:2026-09-08T10:30');
      await waitFor(() => reminders.reconciled.length == 2);
      expect(reminders.reconciled.last, hasLength(1));
      await reminded.resyncReminders();
      await waitFor(() => reminders.reconciled.length == 3);
      expect(reminders.reconciled.last, hasLength(1));
    });
  });
}
