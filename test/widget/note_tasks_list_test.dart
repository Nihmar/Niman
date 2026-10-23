// #1152: the tasks that link a note, listed: the open ones by due date with
// the undated last, Done folded underneath, the link to the note itself left
// out of a row (a heading it names stays as `§ Boiler`), a tick that ticks
// the task, a tap that opens it, and a line that says so when there is none.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_tasks_list.dart';

import '../fakes/note_tasks_fixture.dart';

void main() {
  late NoteTasksFixture fixture;

  Future<void> pumpList(
    WidgetTester tester, {
    List<String> todo = const <String>[],
    List<String> done = const <String>[],
    String? path = 'House/Repairs.md',
    bool pointer = false,
  }) async {
    fixture = (await tester.runAsync(
      () => NoteTasksFixture.open(todo: todo, done: done),
    ))!;
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: pointer ? ThemeData(visualDensity: VisualDensity.compact) : null,
        home: Scaffold(
          body: NoteTasksList(host: fixture.host, path: path),
        ),
      ),
    );
    await fixture.settle(tester);
  }

  Future<void> written(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await fixture.settle(tester);
  }

  Finder text(String value) => find.text(value);

  double top(WidgetTester tester, String value) =>
      tester.getTopLeft(find.text(value)).dy;

  group('the order', () {
    testWidgets('open tasks by due date, undated last, then Done folded', (
      tester,
    ) async {
      await pumpList(
        tester,
        todo: [
          'Later [[House/Repairs]] due:2026-09-20',
          'Whenever [[House/Repairs]]',
          'Sooner [[House/Repairs]] due:2026-09-08',
          'Elsewhere [[Ideas]] due:2026-09-01',
        ],
        done: ['x 2026-09-01 Finished [[House/Repairs]]'],
      );
      expect(text('Elsewhere'), findsNothing);
      expect(top(tester, 'Sooner'), lessThan(top(tester, 'Later')));
      expect(top(tester, 'Later'), lessThan(top(tester, 'Whenever')));
      // Done is folded: its header, not its rows.
      expect(text('Done (1)'), findsOneWidget);
      expect(text('Finished'), findsNothing);
      expect(top(tester, 'Whenever'), lessThan(top(tester, 'Done (1)')));
    });

    testWidgets('Done opens onto the completed tasks and folds again', (
      tester,
    ) async {
      await pumpList(
        tester,
        todo: ['Open one [[House/Repairs]]'],
        done: [
          'x 2026-09-01 Finished one [[House/Repairs]]',
          'x 2026-09-02 Finished two [[House/Repairs]]',
        ],
      );
      expect(text('Done (2)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tasks-for-note-done')));
      await tester.pump();
      expect(text('Finished one'), findsOneWidget);
      expect(text('Finished two'), findsOneWidget);
      // A completed task is struck through.
      final one = tester.widget<Text>(
        find.byKey(const Key('note-task-text-done-0')),
      );
      expect(one.style!.decoration, TextDecoration.lineThrough);
      await tester.tap(find.byKey(const Key('tasks-for-note-done')));
      await tester.pump();
      expect(text('Finished one'), findsNothing);
    });

    testWidgets('a note with only done tasks still lists Done', (tester) async {
      await pumpList(tester, done: ['x 2026-09-01 Finished [[House/Repairs]]']);
      expect(text('Done (1)'), findsOneWidget);
      expect(find.byKey(const Key('tasks-for-note-empty')), findsNothing);
    });
  });

  group('a row', () {
    testWidgets('leaves out the link to this note, keeps the others', (
      tester,
    ) async {
      await pumpList(
        tester,
        todo: ['(A) Pay the electrician [[House/Repairs]] [[Budget 2026]]'],
      );
      expect(text('Pay the electrician'), findsOneWidget);
      expect(find.textContaining('[['), findsNothing);
      // The other note is a chip; this one is not drawn at all.
      expect(
        find.byKey(const Key('todo-link-chip-Budget 2026')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('todo-link-chip-Repairs')), findsNothing);
      // The priority is a badge, and no letter is left in the text.
      expect(find.byKey(const Key('todo-row-priority')), findsOneWidget);
      expect(text('A'), findsOneWidget);
    });

    testWidgets('keeps the heading or block the link names as a chip', (
      tester,
    ) async {
      await pumpList(
        tester,
        todo: [
          'Order filter cartridges [[House/Repairs#Boiler]]',
          'Check the vessel [[Repairs#^b7]]',
        ],
      );
      expect(find.byKey(const Key('note-task-anchor-Boiler')), findsOneWidget);
      expect(text('§ Boiler'), findsOneWidget);
      expect(find.byKey(const Key('note-task-anchor-^b7')), findsOneWidget);
      // Neither is a note chip: the note is the list's subject.
      expect(
        find.byKey(const Key('todo-link-chip-Repairs › Boiler')),
        findsNothing,
      );
      expect(text('Order filter cartridges'), findsOneWidget);
    });

    testWidgets('shows the project and the context', (tester) async {
      await pumpList(
        tester,
        todo: [
          'Call the plumber [[House/Repairs]] +house @phone due:2026-09-08',
        ],
      );
      expect(text('+house'), findsOneWidget);
      expect(text('@phone'), findsOneWidget);
    });

    testWidgets('a task that is only the link reads as the note', (
      tester,
    ) async {
      await pumpList(tester, todo: ['[[House/Repairs]]']);
      expect(text('Repairs'), findsOneWidget);
    });

    testWidgets('ticking the box ticks the task', (tester) async {
      await pumpList(
        tester,
        todo: ['Call the plumber [[House/Repairs]]', 'Other [[Ideas]]'],
      );
      await tester.tap(find.byKey(const Key('note-task-check-open-0')));
      await written(tester);
      expect(fixture.source.todoLines, ['Other [[Ideas]]']);
      expect(fixture.source.doneLines.single, contains('Call the plumber'));
      // It moved to Done, where the list now counts it.
      expect(text('Call the plumber'), findsNothing);
      expect(text('Done (1)'), findsOneWidget);
    });

    testWidgets('unticking a done task reopens it', (tester) async {
      await pumpList(tester, done: ['x 2026-09-01 Finished [[House/Repairs]]']);
      await tester.tap(find.byKey(const Key('tasks-for-note-done')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('note-task-check-done-0')));
      await written(tester);
      expect(fixture.source.doneLines, isEmpty);
      expect(fixture.source.todoLines.single, contains('Finished'));
      expect(text('Finished'), findsOneWidget);
      expect(find.byKey(const Key('tasks-for-note-done')), findsNothing);
    });

    testWidgets('a tap on the text opens the task dialog', (tester) async {
      await pumpList(
        tester,
        todo: ['Call the plumber [[House/Repairs]] due:2026-09-08'],
      );
      await tester.tap(text('Call the plumber'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Call the plumber [[House/Repairs]] due:2026-09-08',
      );
    });

    testWidgets('a rewrite in the dialog is written to todo.txt', (
      tester,
    ) async {
      await pumpList(tester, todo: ['Call the plumber [[House/Repairs]]']);
      await tester.tap(text('Call the plumber'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Call the plumber back [[House/Repairs]]',
      );
      await tester.pump();
      await tester.tap(find.byType(FilledButton).last);
      await written(tester);
      await tester.pumpAndSettle();
      expect(fixture.source.todoLines.single, contains('plumber back'));
    });
  });

  group('the empty list', () {
    testWidgets('says so in a line, under Add task', (tester) async {
      await pumpList(tester, todo: ['Elsewhere [[Ideas]]']);
      expect(find.byKey(const Key('tasks-for-note-empty')), findsOneWidget);
      expect(text('No task links to this note'), findsOneWidget);
      expect(find.byKey(const Key('tasks-for-note-add')), findsOneWidget);
      expect(find.byKey(const Key('tasks-for-note-done')), findsNothing);
    });

    testWidgets('a note outside a library has no list', (tester) async {
      await pumpList(tester, path: null);
      expect(find.byKey(const Key('tasks-for-note-add')), findsNothing);
    });
  });

  testWidgets('the list follows the tasks as they change', (tester) async {
    await pumpList(tester, todo: ['Call the plumber [[House/Repairs]]']);
    expect(text('Call the plumber'), findsOneWidget);
    await tester.runAsync(() => fixture.controller.add('New one [[Repairs]]'));
    await fixture.settle(tester);
    expect(text('New one'), findsOneWidget);
  });
}
