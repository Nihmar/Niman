/// The Apple [ReminderBackend]: `flutter_local_notifications` over
/// `UNUserNotificationCenter`, + `timezone` (docs/records/apple-platforms.md).
///
/// As on Android, the system holds the scheduled notifications and
/// delivers them at their time with Niman closed, so the `todo.txt` and
/// `calendar.txt` reminders behave as Android's do rather than as the
/// other desktops' in-process timer. There are no channels, icons or exact
/// alarms to manage: a calendar trigger is exact, and the permission
/// prompt is the only precondition.
///
/// iOS keeps only the 64 most recently scheduled notifications; topping
/// that window up is iOS work of its own (phase 3), not done here.
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/reminder_backend.dart';
import 'package:niman/src/todo/reminder_backend_plugin.dart';
import 'package:niman/src/todo/todo_reminder.dart';
import 'package:timezone/timezone.dart' as tz;

/// Reminders through the notifications plugin on macOS and iOS.
final class DarwinReminderBackend implements ReminderBackend {
  /// Creates the backend; the plugin is only touched on-device.
  new();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  static const AppLogger _log = AppLogger(name: 'todo');

  bool _ready = false;
  bool _permissionAsked = false;
  bool _launchConsumed = false;

  /// Asks nothing at init: the prompt comes from [notificationsAllowed],
  /// when a reminder first wants posting, as on Android.
  static const DarwinInitializationSettings _settings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

  @override
  Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    await initializeReminderTimezone(_log);
    await _plugin.initialize(
      settings: const InitializationSettings(macOS: _settings, iOS: _settings),
      onDidReceiveNotificationResponse: (response) =>
          _taps.add(notificationRoute(response)),
    );
    _ready = true;
  }

  /// What the system currently lets Niman post, without asking.
  Future<NotificationsEnabledOptions?> _permissions() async {
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) return await macos.checkPermissions();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.checkPermissions();
  }

  /// Asks the system for alerts and sounds, once.
  Future<bool> _request() async {
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      return await macos.requestPermissions(alert: true, sound: true) ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// False until the user has answered the prompt: a fresh install has not
  /// been asked yet, which is what [notificationsAllowed] is for.
  @override
  Future<bool> notificationsEnabled() async =>
      (await _permissions())?.isEnabled ?? false;

  /// Shows the system prompt once per process when nothing is granted;
  /// afterwards the stored answer stands, changed only in System Settings.
  @override
  Future<bool> notificationsAllowed() async {
    if (await notificationsEnabled()) {
      return true;
    }
    if (_permissionAsked) {
      return false;
    }
    _permissionAsked = true;
    final granted = await _request();
    _log.info('todo reminders: notifications ${granted ? '' : 'not '}granted');
    return granted;
  }

  /// True: a calendar trigger fires at its minute, with nothing to grant.
  @override
  Future<bool> exactAllowed() async => true;

  @override
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((request) => request.id).toList()..sort();
  }

  /// Nothing to carry: the system holds the notifications, and delivers
  /// them once.
  @override
  void noteWanted(Iterable<TodoReminder> wanted) {}

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// False: a scheduled notification is a future instant, and one whose
  /// moment passed while Niman was closed was delivered by the system.
  @override
  bool get firesOverdue => false;

  @override
  String overdueState(
    TodoReminder reminder, {
    required bool pending,
    required bool exact,
    required bool batteryExempt,
    required bool backgroundRestricted,
  }) => osAlarmOverdueState(
    pending: pending,
    exact: exact,
    batteryExempt: batteryExempt,
    backgroundRestricted: backgroundRestricted,
  );

  @override
  Future<void> schedule(TodoReminder reminder, {required bool exact}) {
    return _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      // Instant-preserving: even on the UTC fallback, the notification
      // lands at the right moment in real time.
      scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(),
        iOS: DarwinNotificationDetails(),
      ),
      // Required by the plugin's signature; read on Android only.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: reminder.payload,
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
      final response = details?.notificationResponse;
      return response == null ? null : notificationRoute(response);
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    await _taps.close();
  }
}
