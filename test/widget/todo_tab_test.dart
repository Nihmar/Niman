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

  /// Pumps enough fake time for sheets/dialogs to settle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Opens the due-range dropdown and selects [keySuffix]
  /// (a `TodoDueRange` name: `all`, `overdue`, `today`, …).
  /// Opens the due-range dropdown, lets the menu entrance settle, then
  /// selects [keySuffix] (a `TodoDueRange` name: `all`, `overdue`, …).
  /// The extra settle is needed because the popup menu is scrollable and
  /// lays out its items a frame after it opens.
  Future<void> selectDue(WidgetTester tester, String keySuffix) async {
    await tester.tap(find.byKey(const Key('todo-due-menu')));
    await settle(tester);
    await tester.tap(find.byKey(Key('todo-due-$keySuffix')));
    await tester.pump();
  }

  /// Opens the token/sort sheet, letting the slide-up entrance settle.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('todo-filter-button')));
    await settle(tester);
  }

  /// Dismisses the sheet: the modal barrier closes it on tap.
  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(400, 30));
    await settle(tester);
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

  testWidgets('rows show the display text, the due line and the tokens', (
    tester,
  ) async {
    await pumpTab(
      tester,
      todo: [
        'file taxes +finance due:2026-09-01 #bills',
        "chiamare l'idraulico due:2026-09-07 rem:2026-09-07T09:00",
        'renew the passaporto due:2026-10-02',
        'remind me rem:2026-10-02T08:30',
        'plain task',
      ],
    );
    // Titles strip tokens (the mockup's clean rows)...
    expect(find.text('file taxes'), findsOneWidget);
    expect(find.text('plain task'), findsOneWidget);
    // ...and carry a due label (prefixed, state-colored)...
    expect(find.text('Overdue · 1 Sep'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Due 2 Oct'), findsOneWidget);
    // ...and a reminder with its own date + time.
    expect(find.text('7 Sep 09:00'), findsOneWidget);
    expect(find.text('2 Oct 08:30'), findsOneWidget);
    expect(find.byIcon(Icons.access_time), findsNWidgets(2));
    // The tokens show as chips (+project, @context, #tag); the old
    // left accent bar is gone.
    expect(find.byKey(const Key('todo-accent')), findsNothing);
    expect(find.text('+finance'), findsOneWidget);
    expect(find.text('#bills'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('todo-row-token-+finance')),
        matching: find.byType(Container),
      ),
      findsWidgets,
    );
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
    await pumpTab(tester, done: ['x (A) 2026-09-07 2026-01-02 file taxes']);
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

  testWidgets('the due dropdown narrows the list', (tester) async {
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
    // Default sort is due-soonest; the full list shows in order (the
    // display titles strip the due: tokens).
    expect(
      order(tester, ['overdue', 'today', 'soon', 'later', 'undated']),
      isTrue,
    );
    await selectDue(tester, 'overdue');
    expect(find.text('overdue'), findsOneWidget);
    expect(find.text('today'), findsNothing);
    await selectDue(tester, 'today');
    expect(find.text('today'), findsOneWidget);
    expect(find.text('soon'), findsNothing);
    await selectDue(tester, 'next7');
    expect(find.text('today'), findsOneWidget);
    expect(find.text('soon'), findsOneWidget);
    expect(find.text('later'), findsNothing);
    await selectDue(tester, 'noDate');
    expect(find.text('undated'), findsOneWidget);
    expect(find.text('overdue'), findsNothing);
    await selectDue(tester, 'all');
    expect(find.text('undated'), findsOneWidget);
    expect(find.text('overdue'), findsOneWidget);
  });

  testWidgets('the sheet token chips show counts and AND together', (
    tester,
  ) async {
    await pumpTab(tester, todo: ['a +p +q', 'b +p', 'c']);
    expect(find.byKey(const Key('todo-filter-button')), findsOneWidget);
    await openSheet(tester);
    expect(find.text('+p (2)'), findsOneWidget);
    expect(find.text('+q (1)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('todo-token-+p')));
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsNothing);
    await tester.tap(find.byKey(const Key('todo-token-+q')));
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsNothing);
  });

  testWidgets('the sheet shows the live selection (no close and reopen)', (
    tester,
  ) async {
    await pumpTab(tester, todo: ['a +p +q', 'b +p', 'c']);
    await openSheet(tester);
    // The token chip reflects the tap while the sheet is open...
    final tokenChip = find.byKey(const Key('todo-token-+p'));
    expect(tester.widget<FilterChip>(tokenChip).selected, isFalse);
    await tester.tap(tokenChip);
    await tester.pump();
    expect(tester.widget<FilterChip>(tokenChip).selected, isTrue);
    // ...and so does the sort chip.
    final sortChip = find.byKey(const Key('todo-sort-priority'));
    expect(tester.widget<ChoiceChip>(sortChip).selected, isFalse);
    await tester.tap(sortChip);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(sortChip).selected, isTrue);
  });

  testWidgets('a combo that matches nothing shows the filtered empty', (
    tester,
  ) async {
    await pumpTab(tester, todo: ['a +p due:2026-09-01', 'b +q due:2026-10-01']);
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('todo-token-+q')));
    await tester.pump();
    await closeSheet(tester);
    await selectDue(tester, 'overdue');
    expect(find.text('No tasks match'), findsOneWidget);
  });

  testWidgets('the sheet sort chips reorder the list', (tester) async {
    await pumpTab(
      tester,
      todo: ['(B) bee due:2026-09-01', '(A) aye due:2026-09-10', 'plain'],
    );
    // The display titles strip the priorities and due tokens.
    expect(order(tester, ['bee', 'aye', 'plain']), isTrue);
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('todo-sort-priority')));
    await tester.pump();
    expect(order(tester, ['aye', 'bee', 'plain']), isTrue);
    // Sorting is display-only: the file order never moves.
    expect(source.todoLines.first, '(B) bee due:2026-09-01');
  });

  testWidgets('a reminder shows as clock + its own date + time', (
    tester,
  ) async {
    await pumpTab(tester, todo: ['call rem:2026-09-08T10:30', 'plain']);
    expect(find.text('8 Sep 10:30'), findsOneWidget);
    expect(find.byIcon(Icons.access_time), findsOneWidget);
    expect(find.byIcon(Icons.alarm), findsNothing);
  });

  testWidgets('due and reminder keep their own dates apart', (tester) async {
    await pumpTab(tester, todo: ['both due:2026-09-01 rem:2026-10-02T08:30']);
    // The due label is state-colored and prefixed...
    expect(find.text('Overdue · 1 Sep'), findsOneWidget);
    // ...the reminder carries its own date, never the due date's.
    expect(find.text('2 Oct 08:30'), findsOneWidget);
    expect(find.text('1 Sep 08:30'), findsNothing);
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
    await tester.tap(find.text('buy milk'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('todo-dialog-field')), '+g');
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
    await tester.tap(find.text('water plants'));
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
    await tester.tap(find.text('buy milk'));
    await settle(tester);
    expect(find.byKey(const Key('todo-token-chip-+groceries')), findsOneWidget);
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

  testWidgets('add buttons surface already-used projects to pick (done too)', (
    tester,
  ) async {
    // `knownTokens` is what the tab hands the dialog (a snapshotTokens
    // merge of the open file + done.txt), so previously-used kinds from
    // either file are present.
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
                    knownTokens: const {'+errands', '+archive'},
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
      'file the docs',
    );
    await tester.pump();
    // A bare sigil alone already opens the used-kind pool: no need to
    // retype an old +project. +archive is offered as a previous project.
    await tester.tap(find.byKey(const Key('todo-token-add-+')));
    await tester.pump();
    expect(find.byKey(const Key('todo-complete-+errands')), findsOneWidget);
    expect(find.byKey(const Key('todo-complete-+archive')), findsOneWidget);
    await tester.tap(find.byKey(const Key('todo-complete-+archive')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(result, '2026-09-07 file the docs +archive');
  });
}
