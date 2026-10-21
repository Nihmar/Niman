/// The background capture on iOS (#531): what Android's notifier does
/// with a short foreground service and its notifications
/// (plugin_capture_notifier.dart), in the shape iOS allows.
///
/// The capture under way holds background time (core/background_time.dart)
/// rather than a notification: iOS shows no ongoing one, and suspends the
/// app within seconds of the user going back to the browser without the
/// time. Its end is a notification through the plugin the reminders
/// initialize, whose taps they route: a tap opens the note it made. iOS
/// gives a notification's buttons fixed ids, declared at start, so the
/// folder it went to has no button of its own.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:niman/src/core/background_time.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/capture/background_capture.dart';

/// [CaptureNotifier] over iOS's background time and the notifications
/// plugin.
final class IosCaptureNotifier implements CaptureNotifier {
  /// A notifier over the shared plugin.
  new();

  /// The first result's id, clear of the reminders' as on Android.
  static const int _first = 0x0CA001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  int? _time;
  bool _asked = false;
  int _next = _first;

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Takes the background time, once for every capture queued, and asks
  /// to post the result while the app is on screen: the reminders may
  /// not have asked yet.
  @override
  Future<void> begin({
    required String title,
    String? body,
    String? cancel,
  }) async {
    _time ??= await beginBackgroundTime('capture');
    if (_asked) return;
    _asked = true;
    try {
      await _ios?.requestPermissions(alert: true, sound: true);
    } on Object catch (error) {
      _log.warning('capture notifications not asked for: $error');
    }
  }

  /// Nothing: iOS has no ongoing notification to update.
  @override
  Future<void> update({
    required String title,
    String? body,
    String? cancel,
  }) async {}

  @override
  Future<void> end() async {
    final time = _time;
    _time = null;
    await endBackgroundTime(time);
  }

  @override
  Future<void> result({
    required String title,
    required String body,
    String? open,
    String? folder,
  }) async {
    try {
      await _plugin.show(
        id: _next++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
        ),
        payload: open ?? folder,
      );
    } on Object catch (error) {
      _log.warning('capture notification not shown: $error');
    }
  }
}

const _log = AppLogger(name: 'capture');
