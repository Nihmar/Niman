import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/reminder_backend_plugin.dart';

void main() {
  test('a tap on the notification is routed by its payload', () {
    const tap = NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: 'todo',
    );
    expect(notificationRoute(tap), 'todo');
  });

  test('a press on a button is routed by the button', () {
    const press = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: 'capture-folder:Reading',
      payload: 'capture-open:Reading/Page.md',
    );
    expect(notificationRoute(press), 'capture-folder:Reading');
  });

  test('an empty button id leaves the payload', () {
    const press = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: '',
      payload: 'todo',
    );
    expect(notificationRoute(press), 'todo');
  });
}
