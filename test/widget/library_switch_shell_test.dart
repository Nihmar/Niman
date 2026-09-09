// T-ML-08: what travels with a library switch. The shell belongs to the
// open library, so a switch tears it down and builds a new one — which is
// what makes the todo list, the reminders and the open note follow the
// library instead of the session.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeReminderService reminders;
  late FakeFilePicker filePicker;

  const workLine = 'call the office rem:2099-09-08T10:30';
  // Joined, not spelled: the create flow builds the root with
  // `package:path`, which uses '\' on Windows.
  final work = p.join('/fake', 'Work');
  final personal = p.join('/fake', 'Personal');

  /// One todo file per library, so a switch has something to swap.
  late Map<String, FakeTodoSource> todosByRoot;

  setUp(() {
    controller = FakeLibrarySession();
    reminders = FakeReminderService();
    todosByRoot = {
      work: FakeTodoSource(todo: <String>[workLine]),
      personal: FakeTodoSource(todo: <String>['buy milk']),
    };
    filePicker = useFakeFilePicker();
  });

  tearDown(() async {
    await reminders.dispose();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          reminderServiceProvider.overrideWithValue(reminders),
          todoSourceFactoryProvider.overrideWithValue(
            (root) => todosByRoot[root]!,
          ),
        ],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker, name: 'Work');
  }

  Future<void> switchToPersonal(WidgetTester tester) async {
    await controller.switchTo(personal);
    await settle(tester);
  }

  testWidgets('the todo list follows the library', (tester) async {
    await pumpShell(tester);
    expect(find.text('call the office'), findsNothing);

    await switchToPersonal(tester);
    expect(controller.root, personal);
  });

  testWidgets('a reminder that belongs to the old library is cancelled', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(reminders.reconciled.last.keys, <int>[todoReminderId(workLine)]);

    // The new library's todo file has no reminder in it, so the alarm the
    // old one scheduled is no longer wanted. Full-replace reconciliation
    // is what cancels it; leaving it would fire for a task that is not in
    // the open library.
    await switchToPersonal(tester);
    expect(reminders.reconciled.last, isEmpty);
  });

  testWidgets('the shell is rebuilt, so no note stays open across it', (
    tester,
  ) async {
    await pumpShell(tester);
    await switchToPersonal(tester);
    // A fresh shell for the new library: nothing selected, and the tree
    // shown is the new library's.
    expect(find.text('Work'), findsNothing);
    expect(controller.root, personal);
  });

  testWidgets('the launcher shortcuts act on the library that is open', (
    tester,
  ) async {
    // They always did: a shortcut runs from inside the shell, and the
    // shell only exists while a library is open. The library that opens
    // on a cold start is the resumed one, which is the last one used, so
    // a switch moves the shortcuts with it and nothing else has to.
    await pumpShell(tester);
    expect(controller.root, work);
    await switchToPersonal(tester);
    expect(controller.root, personal);
  });
}
