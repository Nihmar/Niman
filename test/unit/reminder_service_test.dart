// T-TD-07: the scheduling policy, driven without a device through the
// backend seam. Covers the three ways reconciliation used to lose alarms:
// a blanket cancel that also cleared the tray, two overlapping passes
// interleaving, and a stale set scheduling into the past.
import 'dart:async';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/reminder_health.dart';
import 'package:copist/src/todo/reminder_settings.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_reminder_backend.dart';

/// A [ReminderSettings] answering fixed values, recording the screens
/// the health banner asks to open.
final class _FakeSettings implements ReminderSettings {
  bool batteryExempt = true;
  int batteryOpened = 0;
  int notificationsOpened = 0;

  @override
  Future<bool> isBatteryExempt() async => batteryExempt;

  @override
  Future<bool> openBatterySettings() async {
    batteryOpened++;
    return true;
  }

  @override
  Future<bool> openNotificationSettings() async {
    notificationsOpened++;
    return true;
  }
}

void main() {
  late FakeReminderBackend backend;
  late _FakeSettings settings;

  final now = DateTime(2026, 9, 7, 12);

  TodoReminder reminderAt(int id, {int hours = 2, String title = 'task'}) {
    return TodoReminder(
      id: id,
      title: title,
      body: 'Todo reminder',
      when: now.add(Duration(hours: hours)),
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
      expect(
        backend.scheduled.map((r) => r.id).toList()..sort(),
        <int>[2, 3],
      );
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
      expect(
        backend.scheduled.map((r) => r.id).toList()..sort(),
        <int>[1, 3],
      );
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
      expect(settings.notificationsOpened, 1);
      await service.dispose();
    });

    test('battery optimization outranks inexact alarms', () async {
      // Worst-first: a sleeping app may never fire at all, while inexact
      // only arrives late.
      backend.exact = false;
      settings.batteryExempt = false;
      final service = serviceOf();
      await service.reconcile(wanted([reminderAt(1)]));

      expect(service.health.value, ReminderHealth.batteryRestricted);
      await service.openHealthSettings();
      expect(settings.batteryOpened, 1);
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
