// T-TD-04 AC: todo list UI — rows with badges/chips, checking moves a
// row to Done with today's date, unchecking restores it, Open/Done
// switch, tap-to-edit and long-press delete, all against FakeTodoSource
// (no disk I/O in the fake-async test zone).
import 'package:copist/src/todo/todo_controller.dart';
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
  late TodoController controller;

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
      MaterialApp(home: Scaffold(body: TodoTab(controller: controller))),
    );
    await tester.pump();
  }

  tearDown(() {
    controller.dispose();
  });

  /// Pumps enough fake time for sheets/dialogs to settle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
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
}
