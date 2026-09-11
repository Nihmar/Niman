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

/// The platform operations reminders need.
abstract interface class ReminderBackend {
  /// Initializes the platform (timezone data, plugin, channel), once.
  ///
  /// Throws when the platform is unavailable; the caller leaves existing
  /// alarms alone rather than cancelling what it cannot replace.
  Future<void> ensureReady();

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

  /// Releases resources.
  Future<void> dispose();
}
