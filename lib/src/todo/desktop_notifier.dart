/// The desktop notification surface behind `DesktopReminderBackend`
/// (T-PP-03).
///
/// Split from the backend so the scheduling half -- the in-process timer,
/// the full replace, the pending map -- is ordinary Dart a test drives with
/// a fake, while the one part that needs the Linux/Windows plugin lives
/// here.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:niman/src/todo/todo_reminder.dart';

/// Where a desktop reminder is posted.
///
/// `init` wires notification taps; `show` posts one reminder now. The
/// backend owns *when*, this owns *how*.
abstract interface class DesktopNotifier {
  /// Prepares the plugin and routes taps to [onTap] (a payload, or null).
  Future<void> init({required void Function(String? payload) onTap});

  /// Posts [reminder] now.
  Future<void> show(TodoReminder reminder);
}

/// The Windows toast identity.
///
/// Stable for the life of the install: Windows keys toasts by
/// `appUserModelId`, and `guid` identifies the activation callback. MSIX
/// packaging (M7) may revisit these; changing them strands toasts the OS
/// already holds.
const String desktopNotificationAppName = 'Niman';

/// The stable Windows Application User Model ID.
const String desktopNotificationAppUserModelId = 'dev.niman.niman';

/// The GUID Windows uses to route a toast activation back to this app.
const String desktopNotificationGuid = 'd7f0f2c4-3b1e-4a8f-9c2d-6e5a1b0c9f3d';

/// [DesktopNotifier] over `flutter_local_notifications`.
final class PluginDesktopNotifier implements DesktopNotifier {
  /// Creates the notifier; the plugin is only touched on-device.
  new();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open Niman'),
        windows: WindowsInitializationSettings(
          appName: desktopNotificationAppName,
          appUserModelId: desktopNotificationAppUserModelId,
          guid: desktopNotificationGuid,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  @override
  Future<void> show(TodoReminder reminder) {
    return _plugin.show(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      notificationDetails: const NotificationDetails(
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
        ),
        windows: WindowsNotificationDetails(),
      ),
      payload: todoReminderPayload,
    );
  }
}
