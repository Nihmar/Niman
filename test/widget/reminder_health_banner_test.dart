// T-TD-07: a scheduled reminder is silent about everything that can stop
// it reaching the user, so the Todo tab says so while it can still be
// fixed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  late FakeLibrarySession session;
  late FakeReminderService reminders;
  late TodoController controller;

  setUp(() async {
    session = FakeLibrarySession();
    await session.open('/fake/library', create: false);
    reminders = FakeReminderService();
    controller = TodoController(
      session: session,
      reminders: reminders,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => FakeTodoSource(),
    );
  });

  tearDown(() async {
    controller.dispose();
    await reminders.dispose();
    await session.dispose();
  });

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoTab(controller: controller, reminders: reminders),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('healthy shows no banner', (tester) async {
    await pumpTab(tester);
    expect(find.byKey(const Key('todo-reminder-health')), findsNothing);
  });

  testWidgets('blocked notifications warn and offer settings', (tester) async {
    reminders.healthState.value = ReminderHealth.notificationsBlocked;
    await pumpTab(tester);
    expect(find.byKey(const Key('todo-reminder-health')), findsOne);
    expect(find.textContaining('Notifications are off'), findsOne);
    await tester.tap(find.byKey(const Key('todo-reminder-health-fix')));
    await tester.pump();
    expect(reminders.settingsOpened, 1);
  });

  testWidgets('battery optimization warns and offers settings', (tester) async {
    reminders.healthState.value = ReminderHealth.batteryRestricted;
    await pumpTab(tester);
    expect(find.textContaining('Battery optimization'), findsOne);
    expect(find.byKey(const Key('todo-reminder-health-fix')), findsOne);
  });

  testWidgets('inexact alarms warn with no settings action', (tester) async {
    reminders.healthState.value = ReminderHealth.inexactOnly;
    await pumpTab(tester);
    expect(find.textContaining('exact alarms'), findsOne);
    // Nothing to open: the exact privilege is auto-granted, so a build
    // that refuses it is not offering a toggle either.
    expect(find.byKey(const Key('todo-reminder-health-fix')), findsNothing);
  });

  testWidgets('dismiss hides the banner', (tester) async {
    reminders.healthState.value = ReminderHealth.notificationsBlocked;
    await pumpTab(tester);
    await tester.tap(find.byKey(const Key('todo-reminder-health-dismiss')));
    await tester.pump();
    expect(find.byKey(const Key('todo-reminder-health')), findsNothing);
  });
}
