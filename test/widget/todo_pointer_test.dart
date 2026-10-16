// #712, #1003: Todo for the mouse — the row menu with Set due and Priority,
// the one-line rows with the menu slot, the keyboard on the list across
// rows and section headers, the edit in place, the quick-add field and the
// filter under its pill.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/todo_pointer_row.dart';
import 'package:niman/src/ui/todo_section_header.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  DateTime clock() => DateTime(2026, 9, 7);

  late FakeTodoSource source;
  TodoController? controller;
  late TodoListView view;

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
    view = TodoListView();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: TodoTab(controller: controller!, view: view, clock: clock),
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

  testWidgets('a row is one line, with its menu slot reserved (#1003)', (
    tester,
  ) async {
    await pumpTab(tester, ['(A) call Ada +work due:2026-09-10', 'plain']);
    final first = tester.getRect(row0);
    final second = tester.getRect(find.byKey(const Key('todo-row-open-1')));
    expect(first.height, second.height, reason: 'same height with or without');
    expect(first.height, lessThan(48), reason: 'one line');

    // The priority, the token and the due day sit on the right, in order.
    final badge = find.descendant(
      of: row0,
      matching: find.byKey(const Key('todo-row-priority')),
    );
    expect(badge, findsOne);
    final text = tester.getRect(find.text('call Ada'));
    final token = tester.getRect(find.text('+work'));
    final due = tester.getRect(find.text('Due 10 Sep'));
    expect(tester.getRect(badge).left, greaterThan(text.right));
    expect(token.left, greaterThan(tester.getRect(badge).right));
    expect(due.left, greaterThan(token.right));

    // The menu button is hidden until the pointer or the selection comes,
    // and keeps its place: the text does not move.
    final more = find.descendant(
      of: row0,
      matching: find.byKey(const Key('todo-row-more')),
    );
    Finder shown() =>
        find.descendant(of: row0, matching: find.byType(Visibility));
    expect(tester.widget<Visibility>(shown().first).visible, isFalse);
    final before = tester.getRect(find.text('call Ada'));
    await tester.tap(row0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<Visibility>(shown().first).visible, isTrue);
    expect(tester.getRect(more), isNotNull);
    expect(tester.getRect(find.text('call Ada')), before);
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

  testWidgets('the selection and the edit in place stay in their file '
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
    // Down to the Done header, open it with Space, down into its rows.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    expect(find.byKey(const Key('todo-row-done-2')), findsOne);
    for (var line = 0; line < 3; line++) {
      expect(selected('todo-row-done-$line'), isFalse, reason: 'done $line');
    }
    expect(selected('todo-row-open-2'), isFalse);

    // The keys of the list act on the Done file: the newest line first.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(selected('todo-row-done-2'), isTrue);
    expect(find.byKey(const Key('tree-rename-field')), findsOne);
    await tester.enterText(
      find.byKey(const Key('tree-rename-field')),
      'd3, fixed',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(source.todoLines, ['a', 'b', 'c']);
    expect(source.doneLines.last, 'x 2026-09-01 d3, fixed');
    expect(source.doneLines, hasLength(3));
  });

  testWidgets('a row menu left open across the removal of its row closes '
      '(#1009)', (tester) async {
    await pumpTab(tester, ['alpha', 'beta']);
    await tester.tap(row0, buttons: kSecondaryButton);
    await settle(tester);
    expect(find.byKey(const Key('todo-menu-delete')), findsOne);

    // Another write takes the menu's row away: the next one slides into its
    // line, and a pick must not land on it.
    await controller!.deleteTodo(controller!.snapshot!.todo.first);
    await settle(tester);
    expect(source.todoLines, ['beta']);
    expect(find.byKey(const Key('todo-menu-delete')), findsNothing);
  });

  testWidgets('a row menu survives a publish that leaves its row alone '
      '(#1009)', (tester) async {
    await pumpTab(tester, ['alpha', 'beta']);
    await tester.tap(
      find.byKey(const Key('todo-row-open-1')),
      buttons: kSecondaryButton,
    );
    await settle(tester);

    await controller!.add('gamma');
    await settle(tester);
    expect(find.byKey(const Key('todo-menu-delete')), findsOne);
    await tester.tap(find.byKey(const Key('todo-menu-delete')));
    await settle(tester);
    expect(source.todoLines, ['alpha', 'gamma']);
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

  testWidgets('a row leaving above the selection keeps it on its task '
      '(#910)', (tester) async {
    await pumpTab(tester, ['a', 'b', 'c']);
    await tester.tap(find.byKey(const Key('todo-row-open-2')));
    await tester.pump(const Duration(milliseconds: 500));

    // The checkbox of another row checks it, selected or not.
    await tester.tap(
      find.descendant(of: row0, matching: find.byType(Checkbox)),
    );
    await settle(tester);
    expect(source.todoLines, ['b', 'c']);

    // `c` is still the selected one: Delete takes it, not `b`.
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, ['b']);
  });

  testWidgets('a section header folds on a click and keeps the selection '
      '(#1003)', (tester) async {
    await pumpTab(tester, ['a due:2026-09-01', 'b']);
    final overdue = find.byKey(const Key('todo-section-due.overdue'));
    expect(find.text('a'), findsOne);
    await tester.tap(overdue);
    await settle(tester);
    expect(find.text('a'), findsNothing);
    expect(view.isCollapsed('due.overdue'), isTrue);
    expect(find.text('b'), findsOne, reason: 'the other section stays open');
    // The header is the selected row: Enter opens it again.
    expect(tester.widget<TodoSectionHeader>(overdue).selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.text('a'), findsOne);
    expect(view.isCollapsed('due.overdue'), isFalse);
  });

  testWidgets('the arrows cross headers and Space folds one (#1003)', (
    tester,
  ) async {
    await pumpTab(tester, ['a due:2026-09-01', 'b due:2026-09-07', 'c']);
    // Items: Overdue, a, Today, b, No date, c, (no Done).
    await tester.tap(find.byKey(const Key('todo-row-open-0')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    TodoSectionHeader header(String id) =>
        tester.widget<TodoSectionHeader>(find.byKey(Key('todo-section-$id')));
    expect(header('due.today').selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    expect(find.text('b'), findsNothing);
    expect(header('due.today').selected, isTrue, reason: 'still on it');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(header('due.none').selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      tester
          .widget<TodoPointerRow>(find.byKey(const Key('todo-row-open-0')))
          .selected,
      isTrue,
    );
    // Delete on a header does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(source.todoLines, hasLength(3));
  });

  testWidgets('Enter and the keypad Enter fold the selected header, and open '
      'it again (#1028)', (tester) async {
    await pumpTab(tester, ['a due:2026-09-01', 'b']);
    // Select the Overdue header with the arrows: from nothing, the first
    // arrow down lands on the first item.
    await tester.tap(find.byKey(const Key('todo-quick-add')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final overdue = find.byKey(const Key('todo-section-due.overdue'));
    expect(tester.widget<TodoSectionHeader>(overdue).selected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(view.isCollapsed('due.overdue'), isTrue);
    expect(find.text('a'), findsNothing);
    expect(tester.widget<TodoSectionHeader>(overdue).selected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    await settle(tester);
    expect(view.isCollapsed('due.overdue'), isFalse);
    expect(find.text('a'), findsOne);
  });

  testWidgets('the row edited in place is filtered away: the edit is dropped '
      'and does not come back with the row (#1028)', (tester) async {
    await pumpTab(tester, ['alpha +x', 'beta']);
    await tester.tap(find.byKey(const Key('todo-row-open-1')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(find.byKey(const Key('tree-rename-field')), findsOne);

    // The filter takes `beta` out of the list: its field goes with it.
    view.toggleToken('+x');
    await settle(tester);
    expect(find.text('beta'), findsNothing);
    expect(find.byKey(const Key('tree-rename-field')), findsNothing);

    // Back in the list it is a row again, not a field nobody sees.
    view.clearFilters();
    await settle(tester);
    expect(find.text('beta'), findsOne);
    expect(find.byKey(const Key('tree-rename-field')), findsNothing);
  });

  testWidgets('a reveal brings the edge facing the selection into view '
      '(#909, #1028)', (tester) async {
    await pumpTab(tester, [for (var i = 0; i < 60; i++) 'task $i']);
    final list = find.byKey(const Key('todo-list'));
    Rect rowAt(int line) => tester.getRect(
      find.byKey(Key('todo-row-open-$line'), skipOffstage: false),
    );
    final box = tester.getRect(list);

    await tester.tap(row0);
    await tester.pump(const Duration(milliseconds: 500));
    for (var line = 1; line <= 30; line++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    // Moving down past the bottom edge, the row's bottom meets it.
    expect(rowAt(30).bottom, closeTo(box.bottom, 0.5));

    // The wheel took the list up, so the selected row's neighbour above is
    // under the bottom edge: an arrow up brings the neighbour's bottom in
    // -- the edge nearest the list -- though the move goes up.
    await tester.drag(list, const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(rowAt(29).top, greaterThan(box.bottom - 0.5), reason: 'below');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(rowAt(29).bottom, closeTo(box.bottom, 0.5));

    // And the wheel took the list down, so the neighbour below is over the
    // top edge: an arrow down brings its top in, though the move goes down.
    await tester.drag(list, Offset(0, -(box.height + 100)));
    await tester.pumpAndSettle();
    expect(rowAt(30).bottom, lessThan(box.top + 0.5), reason: 'above');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(rowAt(30).top, closeTo(box.top, 0.5));
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
