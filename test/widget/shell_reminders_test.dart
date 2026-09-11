// T-TD-07 regression: reminders reconcile from the shell's own load, so a
// foreground return never cancels the pending alarms. Before this, the
// TodoController only loaded when TodoTab mounted -- unreachable in the
// wide layout -- so every resume handed the service an empty set and
// cancelled everything.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_source.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeReminderService reminders;
  late FakeTodoSource todos;
  late FakeFilePicker filePicker;

  const line = 'call rem:2099-09-08T10:30';

  setUp(() {
    controller = FakeLibrarySession();
    reminders = FakeReminderService();
    todos = FakeTodoSource(todo: <String>[line]);
    filePicker = useFakeFilePicker();
  });

  tearDown(() async {
    await reminders.dispose();
  });

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          reminderServiceProvider.overrideWithValue(reminders),
          todoSourceFactoryProvider.overrideWithValue((_) => todos),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  /// The wanted ids of the last recorded reconcile.
  Iterable<int> lastWanted() => reminders.reconciled.last.keys;

  testWidgets('the shell reconciles without opening the Todo tab', (
    tester,
  ) async {
    await pumpShell(tester, const Size(390, 844));
    expect(reminders.reconciled, isNotEmpty);
    expect(lastWanted(), <int>[todoReminderId(line)]);
  });

  testWidgets('a resume keeps the alarms scheduled', (tester) async {
    await pumpShell(tester, const Size(390, 844));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(reminders.reconciled, everyElement(isNotEmpty));
    expect(lastWanted(), <int>[todoReminderId(line)]);
  });

  testWidgets('the wide layout opens the todo list from the rail', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));
    expect(find.byKey(const Key('shell-rail')), findsOne);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('shell-rail')),
        matching: find.text('Todo'),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('todo-view-switch')), findsOne);
  });

  testWidgets('a reminder tap opens the todo list on a wide layout', (
    tester,
  ) async {
    // The tap used to set the bottom-nav tab, which the wide build
    // ignores: the app came up on the file tree with no hint of why.
    await pumpShell(tester, const Size(1200, 900));
    reminders.tap(todoReminderPayload);
    await settle(tester);
    expect(find.byKey(const Key('todo-view-switch')), findsOne);
  });

  testWidgets('the format help is one tap from the list', (tester) async {
    await pumpShell(tester, const Size(390, 844));
    reminders.tap(todoReminderPayload);
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-help')));
    await settle(tester);
    expect(find.text('The todo.txt format'), findsOne);
  });

  testWidgets('the wide layout reconciles too (no Todo tab there)', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));
    expect(reminders.reconciled, isNotEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(reminders.reconciled, everyElement(isNotEmpty));
    expect(lastWanted(), <int>[todoReminderId(line)]);
  });
}
