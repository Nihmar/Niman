// T-PP-03: the desktop backend keeps the reminder schedule in-process.
// The plugin is faked so the timer, the pending map and the full-replace
// semantics are exercised without a desktop session.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/reminder_backend_desktop.dart';
import 'package:niman/src/todo/todo_reminder.dart';

import '../fakes/fake_desktop_notifier.dart';

void main() {
  late FakeDesktopNotifier notifier;
  late DesktopReminderBackend backend;
  var nextId = 0;

  TodoReminder reminder(Duration ahead) {
    final id = ++nextId;
    return TodoReminder(
      id: id,
      title: 'task $id',
      body: 'body',
      when: DateTime.now().add(ahead),
    );
  }

  setUp(() {
    notifier = FakeDesktopNotifier();
    backend = DesktopReminderBackend(notifier: notifier);
  });

  tearDown(() => backend.dispose());

  test(
    'a due reminder is posted at its time, then drops out of pending',
    () async {
      final r = reminder(const Duration(milliseconds: 30));
      await backend.schedule(r, exact: true);
      expect(await backend.pendingIds(), [r.id]);
      expect(notifier.shown, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(notifier.shown.map((posted) => posted.id), [r.id]);
      expect(await backend.pendingIds(), isEmpty);
    },
  );

  // #42: the overdue line has to read true on a desktop, where no OS
  // keeps the alarm: not armed is not the same as fired.
  group('an overdue reminder reads as what happened here', () {
    String state(TodoReminder r, {required bool pending}) =>
        backend.overdueState(
          r,
          pending: pending,
          exact: true,
          batteryExempt: true,
          backgroundRestricted: false,
        );

    test('a timer that fired says how late', () async {
      final r = reminder(const Duration(milliseconds: -5));
      await backend.schedule(r, exact: true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(await backend.pendingIds(), isEmpty);
      final line = state(r, pending: false);
      expect(line, startsWith('timer fired '));
      expect(line, endsWith(' s late'));
      expect(line, isNot(contains('battery')));
    });

    test('one never armed in this run did not fire', () {
      final r = reminder(const Duration(hours: -1));
      final line = state(r, pending: false);
      expect(line, contains('NOT FIRED'));
      expect(line, contains('not running'));
      // #356: no timer was armed, so the line must not claim it fires now.
      expect(line, isNot(contains('fires now')));
    });

    test('one still armed past its time was slept through', () async {
      final r = reminder(const Duration(hours: 1));
      await backend.schedule(r, exact: true);
      expect(state(r, pending: true), contains('STILL ARMED'));
    });
  });

  test('a reminder fired at its time is not fired again for it', () async {
    final r = reminder(const Duration(milliseconds: 10));
    await backend.schedule(r, exact: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifier.shown.map((posted) => posted.id), [r.id]);

    // Scheduled again for the same moment, now past: it was delivered.
    await backend.schedule(r, exact: true);
    expect(await backend.pendingIds(), isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifier.shown.map((posted) => posted.id), [r.id]);

    // Moved to another moment, it is a reminder not yet delivered.
    final moved = TodoReminder(
      id: r.id,
      title: r.title,
      body: r.body,
      when: DateTime.now().add(const Duration(milliseconds: 10)),
    );
    await backend.schedule(moved, exact: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifier.shown.map((posted) => posted.id), [r.id, r.id]);
  });

  // #497. A firing is identified by its moment and by the task: editing
  // the text — or moving `due:`, which is part of the description the id
  // hashes — gives the task a new id while its `rem:` stands, and the
  // reminder is already shown for that moment. Another task at that moment
  // is shown (see reminder_service_test.dart).
  test(
    'an edit to the task does not show it again for the same moment',
    () async {
      final when = DateTime.now().subtract(const Duration(minutes: 5));
      await backend.schedule(
        TodoReminder(id: 1, title: 'Call Bob', body: 'body', when: when),
        exact: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(notifier.shown.map((posted) => posted.id), [1]);

      // At 10:05 the user fixes a typo, or moves `due:`: a new id, the same
      // moment, still inside the grace hour.
      final edited = TodoReminder(
        id: 2,
        title: 'Call Bob today',
        body: 'body',
        when: when,
      );
      // The service says what it wants before it schedules: id 1 has left
      // the set, so id 2 is the same task, rewritten.
      backend.noteWanted([edited]);
      await backend.schedule(edited, exact: true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(notifier.shown.map((posted) => posted.id), [
        1,
      ], reason: 'the task was already shown for this moment');
    },
  );

  // #497. A show that failed was still recorded as shown, and every later
  // reconcile in the grace window took the "already shown" early return:
  // the reminder was never retried.
  test('a notification that failed is shown by the next reconcile', () async {
    notifier.failShows = 1;
    final when = DateTime.now().subtract(const Duration(minutes: 5));
    final r = TodoReminder(id: 7, title: 'task', body: 'body', when: when);
    await backend.schedule(r, exact: true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifier.shown, isEmpty, reason: 'the daemon did not answer');

    // A todo edit inside the grace hour hands the same moment over again.
    await backend.schedule(r, exact: true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifier.shown.map((posted) => posted.id), [7]);
  });

  test('a cancelled reminder never fires', () async {
    final r = reminder(const Duration(milliseconds: 30));
    await backend.schedule(r, exact: true);
    await backend.cancel(r.id);
    expect(await backend.pendingIds(), isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(notifier.shown, isEmpty);
  });

  test(
    'rescheduling one id replaces the timer instead of duplicating it',
    () async {
      final soon = reminder(const Duration(milliseconds: 20));
      final later = TodoReminder(
        id: soon.id,
        title: soon.title,
        body: soon.body,
        when: DateTime.now().add(const Duration(seconds: 5)),
      );
      await backend.schedule(later, exact: true);
      await backend.schedule(soon, exact: true);

      expect(await backend.pendingIds(), [soon.id]);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(notifier.shown.map((posted) => posted.id), [soon.id]);
    },
  );

  test('the plugin is initialized once however often we schedule', () async {
    await backend.schedule(reminder(const Duration(seconds: 5)), exact: true);
    await backend.schedule(reminder(const Duration(seconds: 5)), exact: true);
    expect(notifier.initCalls, 1);
  });

  test('the desktop needs no grant and offers no launch payload', () async {
    expect(await backend.notificationsAllowed(), isTrue);
    expect(await backend.exactAllowed(), isTrue);
    expect(await backend.launchPayload(), isNull);
  });

  test('a notification tap reaches the service stream', () async {
    final taps = <String?>[];
    final subscription = backend.taps.listen(taps.add);
    await backend.ensureReady();

    notifier.emit('todo');
    await Future<void>.delayed(Duration.zero);

    expect(taps, ['todo']);
    await subscription.cancel();
  });

  test('dispose cancels every armed timer', () async {
    await backend.schedule(
      reminder(const Duration(milliseconds: 30)),
      exact: true,
    );
    await backend.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(notifier.shown, isEmpty);
  });
}
