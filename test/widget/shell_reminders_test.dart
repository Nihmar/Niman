// T-TD-07 regression: reminders reconcile from the shell's own load, so a
// foreground return never cancels the pending alarms. Before this, the
// TodoController only loaded when TodoTab mounted -- unreachable in the
// wide layout -- so every resume handed the service an empty set and
// cancelled everything.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_todo_source.dart';

/// A [FilePickerPlatform] stub returning [directory] from
/// `getDirectoryPath` (the "Create new" flow needs a parent folder).
final class _FakeFilePicker extends FilePickerPlatform {
  String? directory;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return directory;
  }
}

void main() {
  late FakeLibrarySession controller;
  late FakeReminderService reminders;
  late FakeTodoSource todos;
  late _FakeFilePicker filePicker;
  late FilePickerPlatform previousPicker;

  const line = 'call rem:2099-09-08T10:30';

  setUp(() {
    controller = FakeLibrarySession();
    reminders = FakeReminderService();
    todos = FakeTodoSource(todo: <String>[line]);
    filePicker = _FakeFilePicker();
    previousPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = filePicker;
  });

  tearDown(() async {
    FilePickerPlatform.instance = previousPicker;
    await reminders.dispose();
  });

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openLibrary(WidgetTester tester) async {
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'library',
    );
    await tester.pump();
    await tester.tap(find.text('Create'));
    await settle(tester);
  }

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    setSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          reminderServiceProvider.overrideWithValue(reminders),
          todoSourceFactoryProvider.overrideWithValue((_) => todos),
        ],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester);
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

  testWidgets('the wide layout opens the todo list from the app bar', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));
    expect(find.byKey(const Key('open-todo')), findsOne);
    await tester.tap(find.byKey(const Key('open-todo')));
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
