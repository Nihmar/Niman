// #712: Todo for the mouse — the row menu with Set due and Priority, the
// hover buttons, the keyboard on the list, the edit in place, the
// quick-add field and the filter under its pill.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/todo_pointer_row.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  DateTime clock() => DateTime(2026, 9, 7);

  late FakeTodoSource source;
  TodoController? controller;

  Future<void> pumpTab(
    WidgetTester tester,
    List<String> todo, {
    List<String>? done,
  }) async {
    final session = FakeLibrarySession();
    await session.open('/fake', create: false);
    source = FakeTodoSource(todo: todo, done: done);
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

  testWidgets('the arrows keep the selected row in view (#909)', (
    tester,
  ) async {
    await pumpTab(tester, [for (var i = 0; i < 60; i++) 'task $i']);
    final list = find.byKey(const Key('todo-list'));

    // Whether the row on [line] is built and inside the list's box.
    bool inView(int line) {
      final row = find.byKey(Key('todo-row-open-$line'));
      if (row.evaluate().isEmpty) return false;
      final box = tester.getRect(list);
      final at = tester.getRect(row);
      return at.top >= box.top - 0.5 && at.bottom <= box.bottom + 0.5;
    }

    expect(inView(59), isFalse, reason: 'more rows than fit');
    await tester.tap(row0);
    await tester.pump(const Duration(milliseconds: 500));
    for (var line = 1; line <= 40; line++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(inView(line), isTrue, reason: 'down to line $line');
    }
    for (var line = 39; line >= 0; line--) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(inView(line), isTrue, reason: 'up to line $line');
    }
  });

  testWidgets('the first arrow up reaches the last row, built or not (#909)', (
    tester,
  ) async {
    await pumpTab(tester, [for (var i = 0; i < 300; i++) 'task $i']);
    // Tab from the quick-add field to the list: focused, nothing selected.
    await tester.tap(find.byKey(const Key('todo-quick-add')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    final last = find.byKey(const Key('todo-row-open-299'));
    expect(last, findsOne);
    final box = tester.getRect(find.byKey(const Key('todo-list')));
    final at = tester.getRect(last);
    expect(at.top, greaterThanOrEqualTo(box.top - 0.5));
    expect(at.bottom, lessThanOrEqualTo(box.bottom + 0.5));
  });

  testWidgets('the selection and the edit in place stay in their view '
      '(#910)', (tester) async {
    await pumpTab(
      tester,
      ['a', 'b', 'c'],
      done: ['x 2026-09-01 d1', 'x 2026-09-01 d2', 'x 2026-09-01 d3'],
    );
    bool selected(String key) =>
        tester.widget<TodoPointerRow>(find.byKey(Key(key))).selected;

    // Open, line 2 selected; the same line of Done is another task.
    await tester.tap(find.byKey(const Key('todo-row-open-2')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(selected('todo-row-open-2'), isTrue);
    await tester.tap(find.text('Done'));
    await settle(tester);
    for (var line = 0; line < 3; line++) {
      expect(selected('todo-row-done-$line'), isFalse, reason: 'done $line');
    }

    // The keys of the list start over, and act on the Done file.
    await tester.tap(find.byKey(const Key('todo-row-done-0')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(find.byKey(const Key('tree-rename-field')), findsOne);
    await tester.tap(find.text('Open'));
    await settle(tester);
    expect(find.byKey(const Key('tree-rename-field')), findsNothing);
    for (var line = 0; line < 3; line++) {
      expect(selected('todo-row-open-$line'), isFalse, reason: 'open $line');
    }
    expect(source.todoLines, ['a', 'b', 'c']);
    expect(source.doneLines, hasLength(3));
  });

  testWidgets('a delete leaves the selection on the row that takes its '
      'place, the one before at the end (#910)', (tester) async {
    await pumpTab(tester, ['a', 'b', 'c', 'd']);
    await tester.tap(find.byKey(const Key('todo-row-open-1')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['a', 'c', 'd']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    // `d` was the last row: the one before, `c`, is selected.
    expect(source.todoLines, ['a', 'c']);
    expect(
      tester
          .widget<TodoPointerRow>(find.byKey(const Key('todo-row-open-1')))
          .selected,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['a']);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, isEmpty);
  });

  testWidgets('a delete follows the display order, not the line order '
      '(#910)', (tester) async {
    // Shown by due day: line 1, line 2, line 0.
    await pumpTab(tester, [
      'c due:2026-09-09',
      'a due:2026-09-01',
      'b due:2026-09-05',
    ]);
    // `b` (line 2) is selected; the row after it in the list is `c`, on a
    // line above it.
    await tester.tap(find.byKey(const Key('todo-row-open-2')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['c due:2026-09-09', 'a due:2026-09-01']);
    // The selection is on `c`: the next Delete takes it, not `a`.
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['a due:2026-09-01']);
  });

  testWidgets('a delete at the end of a sorted list selects the row before '
      'it, on whatever line (#910)', (tester) async {
    await pumpTab(tester, [
      'c due:2026-09-09',
      'a due:2026-09-01',
      'b due:2026-09-05',
    ]);
    // `c`, line 0, is the last row shown; the row before it is `b`, on a
    // line below it.
    await tester.tap(find.byKey(const Key('todo-row-open-0')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['a due:2026-09-01', 'b due:2026-09-05']);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['a due:2026-09-01']);
  });

  testWidgets('checking the last row leaves the selection on the one before '
      '(#910)', (tester) async {
    await pumpTab(tester, ['a', 'b']);
    await tester.tap(find.byKey(const Key('todo-row-open-1')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    expect(source.todoLines, isEmpty);
    expect(source.doneLines, hasLength(2));
  });

  testWidgets('a delete above the selection keeps it on its task (#910)', (
    tester,
  ) async {
    await pumpTab(tester, ['a', 'b', 'c']);
    await tester.tap(find.byKey(const Key('todo-row-open-2')));
    await tester.pump(const Duration(milliseconds: 500));

    // The trash of a row under the pointer deletes it, selected or not.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(row0));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: row0,
        matching: find.byKey(const Key('todo-row-delete')),
      ),
    );
    await settle(tester);
    expect(source.todoLines, ['b', 'c']);

    // `c` is still the selected one: Delete takes it, not `b`.
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['b']);
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
