/// OS reminders for `rem:` tags (plan/todo-tab.md T-TD-07).
///
/// The controller derives the wanted set from the snapshot
/// ([wantedReminders]: open tasks with a future `rem:`) and hands it to
/// the [ReminderService]; reconciliation runs after every publish, so
/// external edits, deletes and reinstalls converge on the next open.
/// Scheduling is a full replace (cancel all, schedule the wanted),
/// idempotent and free of stored state.
///
/// Platform split: Android schedules OS notifications (exact alarms
/// once granted, inexact fallback) through `flutter_local_notifications` +
/// `timezone`; every other platform gets [NoopReminderService] — no OS
/// notifications in v1, the due badges carry the state (documented
/// limitation). Widget tests inject a fake; the plugin itself is only
/// touched on-device.
library;

import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:meta/meta.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The notification payload routing taps to the Todo tab.
const String todoReminderPayload = 'todo';

/// One schedulable reminder: a stable [id] with content + fire time.
@immutable
final class TodoReminder {
  /// Creates a reminder firing at [when] (local wall-clock time).
  const TodoReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });

  /// The notification id, derived from the task text ([todoReminderId]).
  final int id;

  /// The task description.
  final String title;

  /// The due line, or the generic reminder text.
  final String body;

  /// When to fire (local wall-clock time, from `rem:`).
  final DateTime when;
}

/// A stable notification id for a task description.
///
/// FNV-1a over the UTF-16 units, masked to a positive 31-bit int:
/// identical descriptions share one notification (documented: exact
/// duplicate tasks collapse to a single alarm), a description edit
/// yields a new id while reconciliation cancels the orphan, and line
/// moves between the files keep the id (only the description feeds
/// it — never the `x`/date prefix or the line index).
int todoReminderId(String description) {
  var hash = 0x811C9DC5;
  for (final unit in description.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// The schedulable reminders of [snapshot]: open (`todo.txt`) tasks
/// with a `rem:` after [now]. Completed tasks and past times never
/// fire. [now] is the wall clock (the controller's injected clock in
/// tests, real time on device).
Map<int, TodoReminder> wantedReminders(
  TodoSnapshot snapshot,
  DateTime now,
) {
  final wanted = <int, TodoReminder>{};
  for (final entry in snapshot.todo) {
    final task = entry.task;
    final when = task.reminder;
    if (when == null || !when.isAfter(now)) {
      continue;
    }
    wanted[todoReminderId(task.description)] = TodoReminder(
      id: todoReminderId(task.description),
      title: task.description,
      body: task.due == null
          ? AppStrings.todoReminderBody
          : '${AppStrings.todoReminderDue} ${formatTodoDate(task.due!)}',
      when: when,
    );
  }
  return wanted;
}

/// What the todo UI needs from the OS notification layer.
///
/// Implemented by [LocalReminderService] (Android) and
/// [NoopReminderService] (elsewhere), plus an in-memory fake in widget
/// and controller tests.
abstract interface class ReminderService {
  /// Schedules exactly [wanted] (cancelling everything stale first).
  Future<void> reconcile(Map<int, TodoReminder> wanted);

  /// Notification tap payloads; the shell opens the Todo tab.
  Stream<String?> get taps;

  /// The launch payload when a tap started the app (once, then null).
  Future<String?> consumeLaunchPayload();

  /// Releases resources.
  Future<void> dispose();
}

/// Creates the platform service: scheduled OS notifications on
/// Android, a no-op elsewhere.
ReminderService createReminderService() {
  if (Platform.isAndroid) {
    return LocalReminderService();
  }
  return NoopReminderService();
}

/// The single reminder service for the app session.
///
/// Typed as the [ReminderService] interface so the UI (and tests, which
/// substitute a fake) never depends on the platform implementation.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = createReminderService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Android reminders via `flutter_local_notifications` (exact alarms
/// with an inexact fallback — see [_ensureExact]) + `timezone` for the
/// local wall clock.
final class LocalReminderService implements ReminderService {
  /// The plugin (method channels — on-device only, never in tests).
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  static const AppLogger _log = AppLogger(name: 'todo');

  bool _ready = false;
  bool _permissionAsked = false;
  bool _exactAsked = false;
  bool _launchConsumed = false;

  /// Timezone database + plugin init, once (idempotent).
  Future<void> _ensureReady() async {
    if (_ready) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } on Object catch (error) {
      // The schedule below falls back to tz.local (UTC): wrong wall
      // clock, but loud in the logs instead of silent.
      _log.warning('todo reminders: local timezone unknown ($error)');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _taps.add(response.payload),
    );
    _ready = true;
  }

  /// The runtime permission state (Android 13+): granted at install
  /// below 13 (the query answers null there — treated as granted); on
  /// 13+ the system dialog shows once per process, afterwards the
  /// stored answer stands.
  Future<bool> _ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return true;
    }
    if (await android.areNotificationsEnabled() ?? true) {
      return true;
    }
    if (_permissionAsked) {
      return false;
    }
    _permissionAsked = true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Whether minute-precise (exact) alarms can be scheduled: granted in
  /// system settings on Android 12+ (the request opens settings once per
  /// process — only called while future reminders are wanted);
  /// install-granted below 12 (the query answers null there).
  Future<bool> _ensureExact() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return true;
    }
    if (await android.canScheduleExactNotifications() ?? true) {
      return true;
    }
    if (_exactAsked) {
      return false;
    }
    _exactAsked = true;
    _log.info('todo reminders: asking for the exact-alarm grant');
    return await android.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<void> reconcile(Map<int, TodoReminder> wanted) async {
    try {
      await _ensureReady();
    } on Object catch (error) {
      _log.warning('todo reminders unavailable: $error');
      return;
    }
    // Grants resolve BEFORE the cancel: the exact request opens system
    // settings (the app backgrounds), and cancelling first would leave
    // zero alarms behind when the user returns through onResume instead
    // of a fresh reconcile. Nothing is asked while nothing is wanted.
    final granted = wanted.isEmpty || await _ensurePermission();
    final exact = granted && wanted.isNotEmpty && await _ensureExact();
    // Full replace: no stored scheduling state to drift from the files.
    await _plugin.cancelAll();
    if (wanted.isEmpty) {
      _log.info('todo reminders reconciled: 0 scheduled');
      return;
    }
    if (!granted) {
      _log.info(
        'todo reminders: permission denied, '
        'clearing ${wanted.length} wanted',
      );
      return;
    }
    if (!exact) {
      _log.info('todo reminders: exact denied, falling back to inexact');
    }
    final now = DateTime.now();
    var scheduled = 0;
    for (final reminder in wanted.values) {
      if (!reminder.when.isAfter(now)) {
        continue;
      }
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'copist_reminders',
              AppStrings.todoReminderChannel,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: todoReminderPayload,
        );
      } on Object catch (error) {
        // One bad alarm (e.g. exact without the grant) must not abort
        // the rest of the set.
        _log.warning(
          'todo reminders: schedule failed for id ${reminder.id} ($error)',
        );
        continue;
      }
      scheduled++;
    }
    _log.info(
      'todo reminders reconciled: $scheduled scheduled '
      '(${exact ? 'exact' : 'inexact'})',
    );
  }

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> consumeLaunchPayload() async {
    if (_launchConsumed) {
      return null;
    }
    _launchConsumed = true;
    try {
      await _ensureReady();
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        _log.info('todo reminders: launched from a tap');
        return details?.notificationResponse?.payload;
      }
    } on Object catch (error) {
      _log.debug('todo reminders: no launch payload ($error)');
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    await _taps.close();
  }
}

/// Desktop (and test) no-op: v1 shows no OS notifications off Android;
/// the due badges carry the state (documented limitation, T-TD-07).
final class NoopReminderService implements ReminderService {
  @override
  Future<void> reconcile(Map<int, TodoReminder> wanted) async {}

  @override
  Stream<String?> get taps => const Stream<String?>.empty();

  @override
  Future<String?> consumeLaunchPayload() async => null;

  @override
  Future<void> dispose() async {}
}
