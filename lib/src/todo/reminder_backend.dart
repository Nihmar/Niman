/// The OS surface a reminder service drives (T-TD-07).
///
/// Narrow on purpose: everything that needs a device — method channels,
/// the timezone database, AlarmManager — sits behind this, so the
/// scheduling logic above it (the full replace, the single flight, the
/// grant gating) is ordinary Dart that tests can drive with a fake.
///
/// The alternative, stubbing the plugin's own method channels, would mean
/// re-encoding two plugins' wire protocols and would still not exercise a
/// line of Android. Real plugin behaviour stays where T-TD-07 already
/// puts it: on-device.
library;

import 'package:niman/src/todo/todo_reminder.dart';

/// [ReminderBackend.overdueState] where the OS holds the alarms (Android):
/// one still pending past its time never fired, one that is gone did,
/// and the two settings say which way a deferred one leans.
String osAlarmOverdueState({
  required bool pending,
  required bool exact,
  required bool batteryExempt,
  required bool backgroundRestricted,
}) =>
    '${pending ? 'STILL PENDING, never fired' : 'no longer pending, fired'}, '
    'alarms ${exact ? 'exact' : 'inexact'}, '
    'battery ${batteryExempt ? 'unrestricted' : 'optimized'}, '
    'background ${backgroundRestricted ? 'restricted' : 'allowed'}';

/// The platform operations reminders need.
abstract interface class ReminderBackend {
  /// Initializes the platform (timezone data, plugin, channel), once.
  ///
  /// Throws when the platform is unavailable; the caller leaves existing
  /// alarms alone rather than cancelling what it cannot replace.
  Future<void> ensureReady();

  /// Whether notifications may be posted right now, without asking.
  ///
  /// The Todo tab warns from this even when no reminder is set, so the
  /// permission is surfaced before the first one is created. Off Android
  /// 13+ a freshly installed app answers false until it asks, which is
  /// why the warning is not the whole story: [notificationsAllowed]
  /// still asks when a reminder wants posting.
  Future<bool> notificationsEnabled();

  /// Whether notifications may be posted (asking once if it can).
  Future<bool> notificationsAllowed();

  /// Whether minute-precise alarms may be scheduled.
  Future<bool> exactAllowed();

  /// The ids the OS reports as pending.
  ///
  /// The authoritative answer to what is actually armed, as opposed to
  /// what was asked for.
  Future<List<int>> pendingIds();

  /// Cancels the pending alarm [id], if any.
  Future<void> cancel(int id);

  /// Schedules [reminder], replacing any pending alarm with its id.
  ///
  /// [exact] picks minute precision over a Doze-batched fallback.
  Future<void> schedule(TodoReminder reminder, {required bool exact});

  /// The payload of the notification that started the app, once.
  Future<String?> launchPayload();

  /// Payloads of notification taps while the app runs.
  Stream<String?> get taps;

  /// What an overdue [reminder]'s state means here, for the log (#42):
  /// [pending] is whether [pendingIds] still lists it, and [exact] and
  /// [batteryExempt] are the settings that could have deferred it.
  ///
  /// The same facts read differently per backend. An OS alarm that is no
  /// longer pending did fire; a desktop timer that is not armed may never
  /// have been, because the process was not running at its time.
  String overdueState(
    TodoReminder reminder, {
    required bool pending,
    required bool exact,
    required bool batteryExempt,
    required bool backgroundRestricted,
  });

  /// Releases resources.
  Future<void> dispose();
}
