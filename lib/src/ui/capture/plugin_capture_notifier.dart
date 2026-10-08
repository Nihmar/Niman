/// The background capture's notifications on Android (#531), through the
/// plugin the reminders already initialize — initializing it again would
/// take their taps — on a channel of its own.
///
/// The capture under way is the notification of the plugin's foreground
/// service, typed `shortService`: what keeps the process alive once the
/// user is back in the browser, with no second engine and no scheduler.
/// Its later steps re-post the same notification rather than start the
/// service again, which Android refuses from the background.
///
/// Every button opens the app (`showsUserInterface`): a button that does
/// not would be delivered to a second Flutter engine the plugin starts for
/// it, and the capture lives in this one. So Cancel brings Niman forward,
/// and the shell cancels there.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_reminder.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/strings.dart';

/// [CaptureNotifier] over the notifications plugin.
final class PluginCaptureNotifier implements CaptureNotifier {
  /// A notifier over the shared plugin.
  new();

  static const String _channel = 'niman_capture';

  /// The foreground service's notification: never 0, which the plugin
  /// refuses for a service.
  static const int _ongoing = 0x0CA000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _channelMade = false;
  bool _serving = false;
  int _next = _ongoing + 1;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _ensureChannel() async {
    if (_channelMade) return;
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(_channel, AppStrings.captureWebPage),
    );
    _channelMade = true;
  }

  AndroidNotificationDetails _working(String? cancel) =>
      AndroidNotificationDetails(
        _channel,
        AppStrings.captureWebPage,
        icon: todoReminderIcon,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showProgress: true,
        indeterminate: true,
        actions: [
          if (cancel != null)
            AndroidNotificationAction(
              cancel,
              AppStrings.actionCancel,
              showsUserInterface: true,
              cancelNotification: false,
            ),
        ],
      );

  @override
  Future<void> begin({
    required String title,
    String? body,
    String? cancel,
  }) async {
    try {
      await _ensureChannel();
      await _android?.startForegroundService(
        id: _ongoing,
        title: title,
        body: body,
        notificationDetails: _working(cancel),
        startType: AndroidServiceStartType.startNotSticky,
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeShortService,
        },
      );
      _serving = true;
    } on Object catch (error) {
      // No service — refused, or started from the background: the
      // capture still runs while the process lives, and says so.
      _log.warning('capture service not started: $error');
      await update(title: title, body: body, cancel: cancel);
    }
  }

  @override
  Future<void> update({
    required String title,
    String? body,
    String? cancel,
  }) async {
    try {
      await _ensureChannel();
      await _plugin.show(
        id: _ongoing,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: _working(cancel)),
      );
    } on Object catch (error) {
      _log.warning('capture notification not shown: $error');
    }
  }

  @override
  Future<void> end() async {
    try {
      if (_serving) await _android?.stopForegroundService();
      _serving = false;
      await _plugin.cancel(id: _ongoing);
    } on Object catch (error) {
      _log.warning('capture service not stopped: $error');
    }
  }

  @override
  Future<void> result({
    required String title,
    required String body,
    String? open,
    String? folder,
  }) async {
    try {
      await _ensureChannel();
      await _plugin.show(
        id: _next++,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            AppStrings.captureWebPage,
            icon: todoReminderIcon,
            actions: [
              if (open != null)
                AndroidNotificationAction(
                  open,
                  AppStrings.captureOpen,
                  showsUserInterface: true,
                ),
              if (folder != null)
                AndroidNotificationAction(
                  folder,
                  AppStrings.captureShowFolder,
                  showsUserInterface: true,
                ),
            ],
          ),
        ),
        payload: open,
      );
    } on Object catch (error) {
      _log.warning('capture notification not shown: $error');
    }
  }
}

const _log = AppLogger(name: 'capture');
