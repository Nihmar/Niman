// T-TD-07: the scheduling policy, driven without a device through the
// backend seam. Covers the three ways reconciliation used to lose alarms:
// a blanket cancel that also cleared the tray, two overlapping passes
// interleaving, and a stale set scheduling into the past.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/reminder_backend_desktop.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminder_settings.dart';
import 'package:niman/src/todo/reminders.dart';

import '../fakes/fake_desktop_notifier.dart';
import '../fakes/fake_reminder_backend.dart';

/// A [ReminderSettings] answering fixed values, recording the screens
/// the health banner asks to open.
final class _FakeSettings implements ReminderSettings {
  bool batteryExempt = true;
  bool backgroundRestricted = false;
  int appOpened = 0;

  @override
  Future<bool> isBatteryExempt() async => batteryExempt;

  @override
  Future<bool> isBackgroundRestricted() async => backgroundRestricted;

  @override
  Future<bool> openAppSettings() async {
    appOpened++;
    return true;
  }
}

void main() {
  late FakeReminderBackend backend;
  late _FakeSettings settings;

  final now = DateTime(2026, 9, 7, 12);

  TodoReminder reminderAt(
    int id, {
    int hours = 2,
    int minutes = 0,
    String title = 'task',
  }) {
    return TodoReminder(
      id: id,
      title: title,
      body: 'Todo reminder',
      when: now.add(Duration(hours: hours, minutes: minutes)),
    );
  }

  Map<int, TodoReminder> wanted(List<TodoReminder> reminders) {
    return <int, TodoReminder>{for (final r in reminders) r.id: r};
  }

  LocalReminderService serviceOf() {
    return LocalReminderService(
      backend: backend,
      settings: settings,
      clock: () => now,
    );
  }

  setUp(() {
    backend = FakeReminderBackend();
    settings = _FakeSettings();
  });

  group('the full replace', () {
    test('cancels only the pending ids nobody wants', () async {
      // Never a blanket cancel: that also dismisses notifications already
      // in the tray, which is how an edit wiped a reminder the user had
      // not acted on.
      backend = FakeReminderBackend(pending: <int>[1, 2]);
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(2), reminderAt(3)]));

      expect(backend.cancelled, <int>[1]);
      expect(backend.scheduled.map((r) => r.id).toList()..sort(), <int>[2, 3]);
      expect(backend.pending, <int>[2, 3]);
      await service.dispose();
    });

    test('an empty set clears everything', () async {
      backend = FakeReminderBackend(pending: <int>[7]);
      final service = serviceOf();
      await service.reconcile(const {});
      expect(backend.cancelled, <int>[7]);
      expect(backend.scheduled, isEmpty);
      await service.dispose();
    });

    test('a failing pending query cancels nothing', () async {
      // A stale alarm beats an empty schedule.
      backend = FakeReminderBackend(pending: <int>[1])..failPending = true;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(2)]));
      expect(backend.cancelled, isEmpty);
      expect(backend.scheduled.single.id, 2);
      await service.dispose();
    });

    test('a dead platform leaves the alarms alone', () async {
      backend = FakeReminderBackend(pending: <int>[1])..failReady = true;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(2)]));
      expect(backend.cancelled, isEmpty);
      expect(backend.scheduled, isEmpty);
      await service.dispose();
    });

    test('one bad alarm does not abort the set', () async {
      final service = serviceOf();
      backend.failSchedule.add(2);
      await service.reconcile(
        wanted([reminderAt(1), reminderAt(2), reminderAt(3)]),
      );
      expect(backend.scheduled.map((r) => r.id).toList()..sort(), <int>[1, 3]);
      await service.dispose();
    });
  });

  group('single flight', () {
    test('overlapping reconciles never interleave', () async {
      // The bug: one pass's schedule landing before the other's cancel
      // left the device with nothing armed.
      backend = FakeReminderBackend(pending: <int>[1]);
      final service = serviceOf();
      final hold = Completer<void>();
      backend.holdSchedule = hold;

      final first = service.reconcile(wanted([reminderAt(2)]));
      await Future<void>.delayed(Duration.zero);
      final second = service.reconcile(wanted([reminderAt(3)]));
      backend.holdSchedule = null;
      hold.complete();
      await Future.wait(<Future<void>>[first, second]);

      // Two contiguous passes, in order, with nothing from one inside
      // the other. The startup pending read runs once; each pass then
      // reads pending, sweeps, schedules and reads back.
      expect(backend.calls, <String>[
        'ready',
        'pending',
        'pending',
        'cancel:1',
        'schedule:2',
        'pending',
        'ready',
        'pending',
        'cancel:2',
        'schedule:3',
        'pending',
      ]);
      expect(backend.pending, <int>[3]);
      await service.dispose();
    });

    test('a superseded set is dropped, not scheduled', () async {
      final service = serviceOf();
      final hold = Completer<void>();
      backend.holdSchedule = hold;

      final first = service.reconcile(wanted([reminderAt(1)]));
      await Future<void>.delayed(Duration.zero);
      final second = service.reconcile(wanted([reminderAt(2)]));
      final third = service.reconcile(wanted([reminderAt(3)]));
      backend.holdSchedule = null;
      hold.complete();
      await Future.wait(<Future<void>>[first, second, third]);

      // Two passes, not three: the middle set never ran.
      expect(backend.scheduled.map((r) => r.id), <int>[1, 3]);
      await service.dispose();
    });
  });

  group('grants and health', () {
    test('blocked notifications schedule nothing but still sweep', () async {
      backend = FakeReminderBackend(pending: <int>[9])..allowed = false;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));

      expect(backend.scheduled, isEmpty);
      expect(backend.cancelled, <int>[9]);
      expect(service.health.value, ReminderHealth.notificationsBlocked);
      await service.openHealthSettings();
      expect(settings.appOpened, 1);
      await service.dispose();
    });

    test('blocked notifications warn even with no reminder', () async {
      // The Todo tab says the permission is off before the first reminder
      // exists; only the permission dialog waits for one, so an app with
      // none never puts a dialog in front of the user.
      backend.allowed = false;
      final service = serviceOf();
      await service.reconcile(const {});

      expect(service.health.value, ReminderHealth.notificationsBlocked);
      expect(backend.calls, contains('ready'));
      await service.dispose();
    });

    test('a background restriction outranks inexact alarms', () async {
      // Worst-first: an app the system will not run in the background may
      // never fire at all, while inexact only arrives late.
      backend.exact = false;
      settings.backgroundRestricted = true;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));

      expect(service.health.value, ReminderHealth.batteryRestricted);
      await service.openHealthSettings();
      expect(settings.appOpened, 1);
      await service.dispose();
    });

    test('Doze optimization alone does not warn', () async {
      // The regression the fix is about: an exact alarm is
      // setExactAndAllowWhileIdle and fires in Doze, and the App info page
      // Niman opens has no Doze switch. Warning about it kept the banner
      // up after the switch that page does have was turned on.
      settings.batteryExempt = false;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));

      expect(service.health.value, ReminderHealth.ok);
      await service.dispose();
    });

    test('a background restriction warns and opens the app settings', () async {
      // Android's "Allow background usage", off, on the app's battery
      // page: App info holds it, and its switch clears the state.
      settings.backgroundRestricted = true;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));

      expect(service.health.value, ReminderHealth.batteryRestricted);
      await service.openHealthSettings();
      expect(settings.appOpened, 1);
      await service.dispose();
    });

    test('inexact alarms still schedule, and report', () async {
      backend.exact = false;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));

      expect(backend.scheduled.single.id, 1);
      expect(service.health.value, ReminderHealth.inexactOnly);
      // No system screen offers the exact privilege back.
      expect(await service.openHealthSettings(), isFalse);
      await service.dispose();
    });

    test('everything in place reports healthy', () async {
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));
      expect(service.health.value, ReminderHealth.ok);
      await service.dispose();
    });
  });

  test('a reminder already in the past is not scheduled', () async {
    // The wanted set is stamped before the grant round trip, which can
    // open a system screen and take minutes.
    final service = serviceOf();
    await service.reconcile(wanted([reminderAt(1, hours: -1), reminderAt(2)]));
    expect(backend.scheduled.single.id, 2);
    await service.dispose();
  });

  // T-RL-03. The sweep cancels every pending alarm outside the wanted
  // set, so a reminder the OS is holding past its time must stay in the
  // set while it could still ring. `wantedReminders` keeps it there for
  // `reminderGrace`; what the service owes is to leave it alone.
  test('an overdue alarm the OS still holds is not cancelled', () async {
    backend = FakeReminderBackend(pending: [1]);
    final service = serviceOf();
    await service.reconcile(wanted([reminderAt(1, hours: 0, minutes: -3)]));

    expect(backend.cancelled, isEmpty);
    expect(backend.scheduled, isEmpty, reason: 'a past instant cannot arm');
    await service.dispose();
  });

  // #356. On a desktop the alarm is an in-process timer, so a reminder
  // due while Niman was closed has no OS alarm behind it and used to be
  // dropped: `_scheduleAll` skipped every past reminder. A backend that
  // can fire an already-past reminder must be handed the wanted one
  // inside the grace window instead. Android, whose OS already fired the
  // alarm, keeps skipping it.
  group('an overdue reminder on a backend that fires overdue', () {
    test('one due while Niman was closed is shown now', () async {
      backend = FakeReminderBackend(firesOverdue: true);
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: 0, minutes: -30)]));

      expect(backend.scheduled.map((r) => r.id), [1]);
      await service.dispose();
    });

    test('one past the grace window is not shown on launch', () async {
      backend = FakeReminderBackend(firesOverdue: true);
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: -3)]));

      expect(backend.scheduled, isEmpty);
      await service.dispose();
    });

    test('Android keeps dropping it: the OS alarm already fired', () async {
      // The capability is the whole difference: the same past set that a
      // desktop shows is skipped where the OS owns the alarm.
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: 0, minutes: -30)]));

      expect(backend.scheduled, isEmpty);
      await service.dispose();
    });

    test('it reaches a desktop notifier through the real backend', () async {
      final notifier = FakeDesktopNotifier();
      final service = LocalReminderService(
        backend: DesktopReminderBackend(notifier: notifier),
        settings: settings,
        clock: DateTime.now,
      );
      await service.reconcile({
        7: TodoReminder(
          id: 7,
          title: 'task',
          body: 'body',
          when: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notifier.shown.map((r) => r.id), [7]);
      await service.dispose();
    });

    test('a reconcile does not show again what was shown', () async {
      // Fired at its time, the reminder stays in the wanted set for the
      // grace window: a todo edit or a focus regain reconciles it again,
      // and that is not a second delivery. Its time changed is a new one.
      final notifier = FakeDesktopNotifier();
      final service = LocalReminderService(
        backend: DesktopReminderBackend(notifier: notifier),
        settings: settings,
        clock: DateTime.now,
      );
      TodoReminder at(Duration ago) => TodoReminder(
        id: 7,
        title: 'task',
        body: 'body',
        when: DateTime.now().subtract(ago),
      );
      final first = at(const Duration(minutes: 20));
      Future<void> reconcileAndSettle(TodoReminder reminder) async {
        await service.reconcile({7: reminder});
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      await reconcileAndSettle(first);
      await reconcileAndSettle(first);
      await reconcileAndSettle(first);
      expect(notifier.shown.map((r) => r.id), [7]);

      await reconcileAndSettle(at(const Duration(minutes: 5)));
      expect(notifier.shown.map((r) => r.id), [7, 7]);
      await service.dispose();
    });

    // #497. The record identifies "this task at this moment": an id that
    // is new at a shown moment is the same task only when a shown id of
    // that moment has left the set (the task was rewritten); otherwise it
    // is another task, and it is shown.
    group('a moment shown once is told apart by task', () {
      late FakeDesktopNotifier notifier;
      late LocalReminderService service;
      late DateTime moment;

      setUp(() {
        notifier = FakeDesktopNotifier();
        service = LocalReminderService(
          backend: DesktopReminderBackend(notifier: notifier),
          settings: settings,
          clock: DateTime.now,
        );
        moment = DateTime.now().subtract(const Duration(minutes: 5));
      });

      tearDown(() => service.dispose());

      TodoReminder task(int id) =>
          TodoReminder(id: id, title: 'task $id', body: 'body', when: moment);

      Future<void> reconcileAndSettle(List<TodoReminder> reminders) async {
        await service.reconcile(wanted(reminders));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      test('editing a shown task does not show it again', () async {
        await reconcileAndSettle([task(1)]);
        expect(notifier.shown.map((r) => r.id), [1]);

        // The text was fixed: id 1 is gone, id 2 stands at the same moment.
        await reconcileAndSettle([task(2)]);
        await reconcileAndSettle([task(2)]);
        expect(notifier.shown.map((r) => r.id), [1]);

        // And it is the same task from then on: edited again, still once.
        await reconcileAndSettle([task(3)]);
        expect(notifier.shown.map((r) => r.id), [1]);
      });

      test('a second task at a shown moment is shown', () async {
        await reconcileAndSettle([task(1)]);
        expect(notifier.shown.map((r) => r.id), [1]);

        // Task 1 is still there: 2 is another task due at the same minute.
        await reconcileAndSettle([task(1), task(2)]);
        expect(notifier.shown.map((r) => r.id), [1, 2]);

        // Neither shows again.
        await reconcileAndSettle([task(1), task(2)]);
        expect(notifier.shown.map((r) => r.id), [1, 2]);
      });

      test('two tasks edited at once are two edits, not two shows', () async {
        await reconcileAndSettle([task(1), task(2)]);
        expect(notifier.shown.map((r) => r.id), [1, 2]);

        await reconcileAndSettle([task(3), task(4)]);
        expect(notifier.shown.map((r) => r.id), [1, 2]);
      });

      test('a task added after another was deleted is shown', () async {
        await reconcileAndSettle([task(1)]);
        await reconcileAndSettle(const []);

        await reconcileAndSettle([task(2)]);
        expect(notifier.shown.map((r) => r.id), [1, 2]);
      });
    });
  });

  // T-RL-01: the user reports reminders arriving minutes late, and
  // nothing in the app sees a delivery. What the OS still holds after a
  // reminder's own time is the evidence, so it goes in the log.
  group('the overdue report', () {
    /// The lines the reconcile logged about overdue reminders.
    List<String> overdueLines() => [
      for (final line in AppLog.lines())
        if (line.contains('todo reminders: overdue')) line,
    ];

    setUp(AppLog.clear);
    tearDown(AppLog.clear);

    test('an alarm the OS still holds past its time never fired', () async {
      backend = FakeReminderBackend(pending: [1]);
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: -1)]));

      final line = overdueLines().single;
      expect(line, contains('overdue 1'));
      expect(line, contains('STILL PENDING'));
      expect(line, contains('1h 0m ago'));
      expect(line, contains('alarms exact'));
      expect(line, contains('battery unrestricted'));
      await service.dispose();
    });

    test('an alarm the OS no longer holds did fire', () async {
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: -1)]));

      expect(overdueLines().single, contains('no longer pending, fired'));
      await service.dispose();
    });

    test('the line carries what would defer an alarm', () async {
      backend = FakeReminderBackend(pending: [1])..exact = false;
      settings.batteryExempt = false;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: -2)]));

      final line = overdueLines().single;
      expect(line, contains('alarms inexact'));
      expect(line, contains('battery optimized'));
      await service.dispose();
    });

    test('the line carries a background restriction too', () async {
      backend = FakeReminderBackend(pending: [1]);
      settings.backgroundRestricted = true;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1, hours: -1)]));

      final line = overdueLines().single;
      expect(line, contains('background restricted'));
      await service.dispose();
    });

    test('nothing is logged while every reminder is still ahead', () async {
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1), reminderAt(2)]));

      expect(overdueLines(), isEmpty);
      // And it costs no extra query: the three reads are the startup
      // report, the cancel sweep and the read-back, as before.
      expect(backend.calls.where((c) => c == 'pending').length, 3);
      await service.dispose();
    });
  });
}
