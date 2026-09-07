// T-TD-04 AC: todo list UI — rows with badges/chips, checking moves a
// row to Done with today's date, unchecking restores it, Open/Done
// switch, tap-to-edit and long-press delete, all against FakeTodoSource
// (no disk I/O in the fake-async test zone).
import 'package:copist/src/todo/todo_controller.dart';
import 'package:copist/src/ui/todo_edit_dialog.dart';
import 'package:copist/src/ui/todo_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  /// Fixed "today" for badges and check stamps.
  DateTime clock() => DateTime(2026, 9, 7);

  late FakeLibrarySession session;
  late FakeTodoSource source;
  TodoController? controller;

  Future<void> pumpTab(
    WidgetTester tester, {
    List<String>? todo,
    List<String>? done,
  }) async {
    session = FakeLibrarySession();
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
        home: Scaffold(body: TodoTab(controller: controller!, clock: clock)),
      ),
    );
    await tester.pump();
  }

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  /// Pumps enough fake time for sheets/dialogs to settle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Scrolls the horizontal chip bar until [target] shows.
  Future<void> scrollChips(WidgetTester tester, Finder target) {
    return tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('todo-filter-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
  }

  /// Whether [texts] render top to bottom in order.
  bool order(WidgetTester tester, List<String> texts) {
    var lastDy = -1.0;
    for (final text in texts) {
      final dy = tester.getCenter(find.text(text)).dy;
      if (dy <= lastDy) {
        return false;
      }
      lastDy = dy;
    }
    return true;
  }

  testWidgets('open rows show badges, chips and the due date', (
    tester,
  ) async {
    await pumpTab(
      tester,
      todo: [
        '(A) 2026-01-02 file taxes +finance @home due:2026-09-07 #bills',
        'plain task',
      ],
    );
    expect(
      find.text('file taxes +finance @home due:2026-09-07 #bills'),
      findsOneWidget,
    );
    expect(find.text('(A)'), findsOneWidget);
    expect(find.text('+finance'), findsOneWidget);
    expect(find.text('@home'), findsOneWidget);
    expect(find.text('#bills'), findsOneWidget);
    expect(find.text('2026-09-07'), findsOneWidget);
    expect(find.text('plain task'), findsOneWidget);
  });

  testWidgets("checking moves the row to Done with today's date", (
    tester,
  ) async {
    await pumpTab(tester, todo: ['(A) 2026-01-02 file taxes']);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    // Gone from Open...
    expect(find.text('file taxes'), findsNothing);
    // ...present in Done, stamped today, checkbox checked.
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('file taxes'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(source.doneLines, ['x (A) 2026-09-07 2026-01-02 file taxes']);
  });

  testWidgets('unchecking restores the row to Open', (tester) async {
    await pumpTab(
      tester,
      done: ['x (A) 2026-09-07 2026-01-02 file taxes'],
    );
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('file taxes'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('file taxes'), findsOneWidget);
    expect(source.todoLines, ['(A) 2026-01-02 file taxes']);
    expect(source.doneLines, isEmpty);
  });

  testWidgets('tap edits the description, keeping priority', (tester) async {
    await pumpTab(tester, todo: ['(A) 2026-01-02 file taxes']);
    await tester.tap(find.text('file taxes'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('todo-dialog-field')),
      'file taxes early',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await tester.pump();
    expect(find.text('file taxes early'), findsOneWidget);
    expect(source.todoLines, ['(A) 2026-01-02 file taxes early']);
  });

  testWidgets('long-press deletes the row', (tester) async {
    await pumpTab(tester, todo: ['doomed', 'kept']);
    await tester.longPress(find.text('doomed'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-menu-delete')));
    await settle(tester);
    expect(find.text('doomed'), findsNothing);
    expect(find.text('kept'), findsOneWidget);
    expect(source.todoLines, ['kept']);
  });

  testWidgets('empty lists show the empty states', (tester) async {
    await pumpTab(tester);
    expect(find.text('No open tasks yet'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Nothing completed yet'), findsOneWidget);
  });

  testWidgets('due chips narrow the list', (tester) async {
    await pumpTab(
      tester,
      todo: [
        'overdue due:2026-09-01',
        'today due:2026-09-07',
        'soon due:2026-09-10',
        'later due:2026-10-01',
        'undated',
      ],
    );
    // Default sort is due-soonest; the full list shows in order.
    expect(
      order(tester, [
        'overdue due:2026-09-01',
        'today due:2026-09-07',
        'soon due:2026-09-10',
        'later due:2026-10-01',
        'undated',
      ]),
      isTrue,
    );
    await tester.tap(find.text('Overdue'));
    await tester.pump();
    expect(find.text('overdue due:2026-09-01'), findsOneWidget);
    expect(find.text('today due:2026-09-07'), findsNothing);
    await tester.tap(find.text('Today'));
    await tester.pump();
    expect(find.text('today due:2026-09-07'), findsOneWidget);
    expect(find.text('soon due:2026-09-10'), findsNothing);
    await tester.tap(find.text('Next 7 days'));
    await tester.pump();
    expect(find.text('today due:2026-09-07'), findsOneWidget);
    expect(find.text('soon due:2026-09-10'), findsOneWidget);
    expect(find.text('later due:2026-10-01'), findsNothing);
    await tester.tap(find.text('No date'));
    await tester.pump();
    expect(find.text('undated'), findsOneWidget);
    expect(find.text('overdue due:2026-09-01'), findsNothing);
    await tester.tap(find.text('All'));
    await tester.pump();
    expect(find.text('undated'), findsOneWidget);
    expect(find.text('overdue due:2026-09-01'), findsOneWidget);
  });

  testWidgets('token chips show counts and AND together', (tester) async {
    await pumpTab(
      tester,
      todo: ['a +p +q', 'b +p', 'c'],
    );
    expect(find.text('+p (2)'), findsOneWidget);
    expect(find.text('+q (1)'), findsOneWidget);
    await scrollChips(tester, find.byKey(const Key('todo-token-+p')));
    await tester.tap(find.byKey(const Key('todo-token-+p')));
    await tester.pump();
    expect(find.text('a +p +q'), findsOneWidget);
    expect(find.text('b +p'), findsOneWidget);
    expect(find.text('c'), findsNothing);
    await scrollChips(tester, find.byKey(const Key('todo-token-+q')));
    await tester.tap(find.byKey(const Key('todo-token-+q')));
    await tester.pump();
    expect(find.text('a +p +q'), findsOneWidget);
    expect(find.text('b +p'), findsNothing);
  });

  testWidgets('a combo that matches nothing shows the filtered empty', (
    tester,
  ) async {
    await pumpTab(
      tester,
      todo: ['a +p due:2026-09-01', 'b +q due:2026-10-01'],
    );
    await scrollChips(tester, find.byKey(const Key('todo-token-+q')));
    await tester.tap(find.byKey(const Key('todo-token-+q')));
    await tester.pump();
    await scrollChips(tester, find.text('Overdue'));
    await tester.tap(find.text('Overdue'));
    await tester.pump();
    expect(find.text('No tasks match'), findsOneWidget);
  });

  testWidgets('the sort control reorders the list', (tester) async {
    await pumpTab(
      tester,
      todo: ['(B) bee due:2026-09-01', '(A) aye due:2026-09-10', 'plain'],
    );
    expect(
      order(tester, ['bee due:2026-09-01', 'aye due:2026-09-10', 'plain']),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('todo-sort-button')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-sort-priority')));
    await settle(tester);
    expect(
      order(tester, ['aye due:2026-09-10', 'bee due:2026-09-01', 'plain']),
      isTrue,
    );
    // Sorting is display-only: the file order never moves.
    expect(source.todoLines.first, '(B) bee due:2026-09-01');
  });

  testWidgets('a task with a reminder shows the alarm icon', (tester) async {
    await pumpTab(tester, todo: ['call rem:2026-09-08T10:30', 'plain']);
    expect(find.byIcon(Icons.alarm), findsOneWidget);
  });

  testWidgets('due picker writes due: on save', (tester) async {
    await pumpTab(tester, todo: ['tasked']);
    await tester.tap(find.text('tasked'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-due')));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.text('2026-09-07'), findsOneWidget);
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(source.todoLines, ['tasked due:2026-09-07']);
  });

  testWidgets('priority picker rewrites the priority', (tester) async {
    await pumpTab(tester, todo: ['(B) bee']);
    await tester.tap(find.text('bee'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-priority')));
    await settle(tester);
    await tester.tap(find.text('(A)').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(source.todoLines, ['(A) bee']);
  });

  testWidgets('reminder picker writes rem: on save', (tester) async {
    await pumpTab(tester, todo: ['tasked']);
    await tester.tap(find.text('tasked'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-reminder')));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(
      source.todoLines.single,
      matches(RegExp(r'^tasked rem:2026-09-07T\d{2}:\d{2}$')),
    );
  });

  testWidgets('token completion offers known tokens', (tester) async {
    await pumpTab(tester, todo: ['buy milk +groceries']);
    await tester.tap(find.text('buy milk +groceries'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('todo-dialog-field')),
      '+g',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-complete-+groceries')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(source.todoLines, ['+groceries']);
  });

  testWidgets('an untouched edit preserves every token verbatim', (
    tester,
  ) async {
    const line = 'water plants rec:+1d foo:bar +p due:2026-09-01';
    await pumpTab(tester, todo: [line]);
    await tester.tap(find.text(line));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(source.todoLines, [line]);
  });

  testWidgets('add stamps creation and appends picked tags', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTodoTaskDialog(
                    context,
                    today: DateTime(2026, 9, 7),
                    knownTokens: const {'+p'},
                  );
                },
                child: const Text('open dialog'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open dialog'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('todo-dialog-field')),
      'new task',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-due')));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(result, '2026-09-07 new task due:2026-09-07');
  });

  testWidgets('dialog chips show tokens and delete removes one', (
    tester,
  ) async {
    await pumpTab(tester, todo: ['buy milk +groceries @home']);
    await tester.tap(find.text('buy milk +groceries @home'));
    await settle(tester);
    expect(
      find.byKey(const Key('todo-token-chip-+groceries')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('todo-token-chip-@home')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('todo-token-chip-+groceries')),
        matching: find.byIcon(Icons.cancel_outlined),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('todo-token-chip-+groceries')), findsNothing);
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(source.todoLines, ['buy milk @home']);
  });

  testWidgets('add buttons start a token that completion can finish', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTodoTaskDialog(
                    context,
                    today: DateTime(2026, 9, 7),
                    knownTokens: const {'+groceries'},
                  );
                },
                child: const Text('open dialog'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open dialog'));
    await settle(tester);
    // A fresh task has no chips yet, but the add buttons are visible.
    expect(find.byKey(const Key('todo-token-chip-+groceries')), findsNothing);
    expect(find.byKey(const Key('todo-token-add-+')), findsOneWidget);
    expect(find.byKey(const Key('todo-token-add-@')), findsOneWidget);
    expect(find.byKey(const Key('todo-token-add-#')), findsOneWidget);
    await tester.tap(find.byKey(const Key('todo-token-add-+')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('todo-dialog-field')))
          .controller!
          .text,
      '+',
    );
    await tester.enterText(
      find.byKey(const Key('todo-dialog-field')),
      'milk +g',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-complete-+groceries')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(result, '2026-09-07 milk +groceries');
  });
}
