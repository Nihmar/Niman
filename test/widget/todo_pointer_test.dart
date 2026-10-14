// #712: Todo for the mouse — the row menu with Set due and Priority, the
// hover buttons, the keyboard on the list, the edit in place, the
// quick-add field and the filter under its pill.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  DateTime clock() => DateTime(2026, 9, 7);

  late FakeTodoSource source;
  TodoController? controller;

  Future<void> pumpTab(WidgetTester tester, List<String> todo) async {
    final session = FakeLibrarySession();
    await session.open('/fake', create: false);
    source = FakeTodoSource(todo: todo);
    controller = TodoController(
      session: session,
      clock: clock,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => source,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: TodoTab(controller: controller!, clock: clock),
        ),
      ),
    );
    await tester.pump();
  }

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  final row0 = find.byKey(const Key('todo-row-open-0'));

  testWidgets('the right-click menu sets the due day and the priority', (
    tester,
  ) async {
    await pumpTab(tester, ['2026-09-01 call Ada']);
    expect(find.byType(Dismissible), findsNothing, reason: 'no swipe');

    await tester.tap(row0, buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-menu-due')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-menu-dueTomorrow')));
    await settle(tester);
    expect(source.todoLines, ['2026-09-01 call Ada due:2026-09-08']);

    await tester.tap(row0, buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-menu-priority')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-menu-priorityA')));
    await settle(tester);
    expect(source.todoLines, ['(A) 2026-09-01 call Ada due:2026-09-08']);
  });

  testWidgets('the row calendar button offers the due days alone', (
    tester,
  ) async {
    await pumpTab(tester, ['call Ada due:2026-09-01']);
    await tester.tap(find.byKey(const Key('todo-row-due')));
    await settle(tester);
    expect(find.byKey(const Key('todo-menu-edit')), findsNothing);
    await tester.tap(find.byKey(const Key('todo-menu-dueNone')));
    await settle(tester);
    expect(source.todoLines, ['call Ada']);
  });

  testWidgets('the keyboard moves, checks and deletes; a double click edits '
      'in place', (tester) async {
    await pumpTab(tester, ['one', 'two', 'three']);
    await tester.tap(row0);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['one', 'three']);

    // The selection stays on the line that took the index: `three`.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    expect(source.todoLines, ['one']);
    expect(source.doneLines.single, endsWith('three'));

    await tester.tap(row0);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(row0);
    await tester.pump();
    final field = find.byKey(const Key('tree-rename-field'));
    expect(field, findsOne);
    await tester.enterText(field, 'one, fixed');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(source.todoLines, ['one, fixed']);
    expect(field, findsNothing);
  });

  testWidgets('the quick-add field adds a task per Enter and keeps the '
      'cursor', (tester) async {
    await pumpTab(tester, ['old +work']);
    final field = find.byKey(const Key('todo-quick-add'));
    await tester.tap(field);
    await tester.enterText(field, 'new +w');
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-quick-complete-+work')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(source.todoLines, ['old +work', '2026-09-07 new +work']);
    final editable = tester.widget<TextField>(field);
    expect(editable.controller!.text, isEmpty);
    expect(editable.focusNode!.hasFocus, isTrue);
  });

  testWidgets('the filter opens under its pill, not as a sheet', (
    tester,
  ) async {
    await pumpTab(tester, ['a +work']);
    await tester.tap(find.byKey(const Key('todo-filter-button')));
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('todo-token-+work')), findsOne);
  });
}
