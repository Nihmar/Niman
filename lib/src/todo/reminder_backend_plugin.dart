/// The Android [ReminderBackend]: `flutter_local_notifications` +
/// `timezone` (plan/todo-tab.md T-TD-07).
///
/// Everything here needs a device: method channels, the timezone
/// database, AlarmManager. Nothing above it does, which is the point of
/// the split — the scheduling logic is testable and this file is verified
/// on-device.
///
/// Exact alarms come from `setExactAndAllowWhileIdle`, so a reminder
/// fires in Doze (screen off) and with the app closed; the privilege is
/// the auto-granted `USE_EXACT_ALARM`, with an inexact fallback if a
/// build reports otherwise.
library;

import 'dart:async';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/reminder_backend.dart';
import 'package:copist/src/todo/todo_reminder.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reminders through the notifications plugin.
final class PluginReminderBackend implements ReminderBackend {
  /// Creates the backend; the plugin is only touched on-device.
  new();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  static const AppLogger _log = AppLogger(name: 'todo');

  bool _ready = false;
  bool _permissionAsked = false;
  bool _launchConsumed = false;

  /// The icon that actually resolved (see [_iconCandidates]).
  String _icon = todoReminderIcon;

  /// Icons to try at init, best first.
  ///
  /// An icon the build does not carry throws out of `initialize`, and a
  /// failed init means no reminders at all — a cosmetic resource must
  /// never cost the feature. `launch_background` is the app's own
  /// drawable: wrong shape for a status bar, but it is always there.
  static const List<String> _iconCandidates = <String>[
    todoReminderIcon,
    'launch_background',
  ];

  /// The Android side of the plugin, or null off Android.
  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      _log.info('todo reminders: timezone ${local.identifier}');
    } on Object catch (error) {
      // Scheduling falls back to tz.local (UTC). Instants still line up,
      // since a TZDateTime.from conversion preserves them, but say so.
      _log.warning('todo reminders: local timezone unknown ($error)');
    }
    await _initializeWithIcon();
    // Create the channel up front instead of letting the first schedule
    // create it implicitly: it then exists, with a description the user
    // can read, before any notification does, and shows in the app's
    // notification settings even when nothing has been scheduled yet.
    // Re-creating with the same id updates name and description;
    // importance is frozen at creation, and max is what installs have.
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        todoReminderChannelId,
        AppStrings.todoReminderChannel,
        description: AppStrings.todoReminderChannelDescription,
        importance: Importance.max,
      ),
    );
    _ready = true;
  }

  /// Initializes the plugin, falling back through [_iconCandidates].
  ///
  /// Rethrows only when every candidate fails, so the caller still knows
  /// the platform is unusable.
  Future<void> _initializeWithIcon() async {
    Exception? failure;
    for (final candidate in _iconCandidates) {
      try {
        await _plugin.initialize(
          settings: InitializationSettings(
            android: AndroidInitializationSettings(candidate),
          ),
          onDidReceiveNotificationResponse: (response) =>
              _taps.add(response.payload),
        );
        _icon = candidate;
        if (candidate == todoReminderIcon) {
          _log.info('todo reminders: icon $candidate');
        } else {
          // A build problem, not a device one: the drawable is in the
          // source tree, so this means it did not reach the APK.
          _log.warning(
            'todo reminders: icon $todoReminderIcon missing from '
            'the build, falling back to $candidate '
            '(a plain white block in the status bar)',
          );
        }
        return;
      } on Object catch (error) {
        _log.warning('todo reminders: icon $candidate rejected ($error)');
        failure = Exception('$error');
      }
    }
    throw failure ?? Exception('todo reminders: no usable icon');
  }

  /// The runtime permission state (Android 13+): granted at install
  /// below 13 (the query answers null there — treated as granted); on
  /// 13+ the system dialog shows once per process, afterwards the
  /// stored answer stands.
  @override
  Future<bool> notificationsAllowed() async {
    final android = _android;
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

  /// Whether minute-precise (exact) alarms can be scheduled.
  ///
  /// A defensive query, not a gate: `USE_EXACT_ALARM` is declared and
  /// auto-granted at install, so this is true on any stock Android the
  /// app runs on (minSdk 35). It can still come back false on an OEM
  /// build that gates exact alarms behind its own toggle, and there is no
  /// in-app remedy — requesting `SCHEDULE_EXACT_ALARM` would trade an
  /// always-granted privilege for one denied by default on Android 14+.
  @override
  Future<bool> exactAllowed() async {
    final android = _android;
    if (android == null) {
      return true;
    }
    if (await android.canScheduleExactNotifications() ?? true) {
      return true;
    }
    _log.warning('todo reminders: exact alarms unavailable on this build');
    return false;
  }

  @override
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((request) => request.id).toList()..sort();
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> schedule(TodoReminder reminder, {required bool exact}) {
    return _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      // Instant-preserving: even on the UTC fallback above, the alarm
      // lands at the right moment in real time.
      scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          todoReminderChannelId,
          AppStrings.todoReminderChannel,
          icon: _icon,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: todoReminderPayload,
    );
  }

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    if (_launchConsumed) {
      return null;
    }
    _launchConsumed = true;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _log.info('todo reminders: launched from a tap');
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    await _taps.close();
  }
}
