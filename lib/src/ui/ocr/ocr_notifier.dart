import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_reminder.dart';
import 'package:niman/src/ui/strings.dart';

/// What a recognition notification's tap carries: `ocr:` and the
/// sidecar to open.
const String ocrNotificationPrefix = 'ocr:';

/// Says, outside the app, that a recognition finished (#594): when the
/// reader left Niman while a long PDF was read.
///
/// Through the plugin the reminders already initialize — initializing it
/// again would take their taps — on a channel of its own on Android, with
/// the tap routed by its payload ([ocrNotificationPrefix]). A platform
/// where the plugin is not ready says nothing: the snackbar still waits
/// in the app.
final class OcrNotifier {
  /// A notifier over the shared plugin.
  new();

  static const String _channel = 'niman_ocr';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _channelMade = false;
  int _next = 0x0C0000;

  /// Shows [title] and [body]; a tap opens [sidecar].
  Future<void> show({
    required String title,
    required String body,
    required String sidecar,
  }) async {
    try {
      if (Platform.isAndroid && !_channelMade) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              AndroidNotificationChannel(
                _channel,
                AppStrings.settingsSectionTextRecognition,
              ),
            );
        _channelMade = true;
      }
      await _plugin.show(
        id: _next++,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            AppStrings.settingsSectionTextRecognition,
            icon: todoReminderIcon,
          ),
          linux: const LinuxNotificationDetails(),
          windows: const WindowsNotificationDetails(),
        ),
        payload: '$ocrNotificationPrefix$sidecar',
      );
    } on Object catch (error) {
      _log.warning('notification not shown: $error');
    }
  }
}

const _log = AppLogger(name: 'ocr');
