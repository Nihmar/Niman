// #730 phase 2: the Tasks and events group of a lone-token search — the
// rows above the notes, what each one says, and the way it opens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/search_task_events.dart';
import 'package:niman/src/ui/theme/niman.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_search_source.dart';

SearchHit _note(String path, {String? title, String? snippet}) => SearchHit(
  noteId: 0,
  path: path,
  title: title ?? path,
  snippet: snippet ?? '',
);

/// The file the mockups draw their search from, cut to what a row shows.
List<TaskEventHit> _rows(String token, {DateTime? due}) => taskEventHits(
  token,
  tasks: [
    TodoEntry(
      lineIndex: 0,
      task: parseTodoLine(
        'Send chapter 2 to supervisor +thesis'
        '${due == null ? '' : ' due:${formatDateTime(due, 'YYYY-MM-DD')}'}',
      ),
    ),
    TodoEntry(
      lineIndex: 1,
      task: parseTodoLine('Book the defence room +thesis @phone'),
    ),
  ],
  calendar: [
    CalendarEntry(
      lineIndex: 0,
      line: parseCalendarLine('2026-10  Finish the thesis draft +thesis'),
    ),
    CalendarEntry(
      lineIndex: 1,
      line: parseCalendarLine(
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis @library.',
      ),
    ),
  ],
);

void main() {
  late FakeLibrarySession session;
  late FakeSearchSource source;
  final opened = <String>[];
  final openedRows = <TaskEventHit>[];

  setUp(() {
    session = FakeLibrarySession();
    source = FakeSearchSource();
    opened.clear();
    openedRows.clear();
  });

  Widget buildApp({
    List<TaskEventHit> rows = const [],
    ChangeNotifier? changes,
    bool withGroup = true,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SearchScreen(
          controller: session,
          onOpenNote: opened.add,
          source: source,
          taskEvents: withGroup
              ? TaskEvents(
                  hits: (_) => rows,
                  changes: changes ?? ChangeNotifier(),
                )
              : null,
          onOpenTaskEvent: openedRows.add,
        ),
      ),
    );
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('search-query')), text);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }

  testWidgets('a lone +project shows the group above the notes', (
    tester,
  ) async {
    source.hits = [_note('Docs/Thesis.md', title: 'Thesis outline')];
    final groupRows = _rows('+thesis');
    final event = groupRows.firstWhere(
      (row) => row.kind == TaskEventKind.event,
    );
    await tester.pumpWidget(buildApp(rows: groupRows));
    await tester.pump();

    await search(tester, '+thesis');

    expect(find.byKey(const Key('search-group-tasks-events')), findsOne);
    expect(find.byKey(const Key('search-group-notes')), findsOne);
    expect(find.text('TASKS AND EVENTS · 4'), findsOne);
    expect(find.text('NOTES · 1'), findsOne);
    expect(
      find.byKey(
        Key(
          'search-task-event-event-${event.lineIndex}'
          '-${event.event!.event.start}',
        ),
      ),
      findsOne,
      reason: 'the event of the day line is a row',
    );
    expect(find.byKey(const Key('search-task-event-goal-0')), findsOne);
    expect(find.byKey(const Key('search-task-event-task-0')), findsOne);
    expect(find.byKey(const Key('search-task-event-task-1')), findsOne);
    // Above the notes, below nothing else: the group heads the list.
    final group = tester.getTopLeft(
      find.byKey(const Key('search-group-tasks-events')),
    );
    final row = tester.getTopLeft(
      find.byKey(const Key('search-task-event-goal-0')),
    );
    final notes = tester.getTopLeft(
      find.byKey(const Key('search-group-notes')),
    );
    final note = tester.getTopLeft(
      find.byKey(const Key('search-hit-Docs/Thesis.md')),
    );
    expect(group.dy, lessThan(row.dy));
    expect(row.dy, lessThan(notes.dy));
    expect(notes.dy, lessThan(note.dy));
  });

  testWidgets('an event row is its time, its text, its day and its file', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(rows: _rows('+thesis')));
    await tester.pump();

    await search(tester, '+thesis');

    expect(find.text('9-12'), findsOne);
    expect(find.textContaining('thesis chapter 3'), findsOne);
    expect(find.text('Mon 12 Oct · calendar.txt'), findsOne);
  });

  testWidgets("a goal row's flag wears the palette's goal colour", (
    tester,
  ) async {
    final syntax = nimanSyntax(Brightness.dark);
    final rows = _rows('+thesis');
    final goal = rows.firstWhere((row) => row.kind == TaskEventKind.goal);
    await tester.pumpWidget(
      buildApp(
        rows: rows,
        theme: ThemeData(extensions: [syntax]),
      ),
    );
    await tester.pump();

    await search(tester, '+thesis');

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(Key('search-task-event-goal-${goal.lineIndex}')),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.color, syntax.calendarGoal);
    expect(syntax.calendarGoal, isNot(syntax.calendarHead));
  });

  testWidgets('a goal row says what it covers', (tester) async {
    await tester.pumpWidget(buildApp(rows: _rows('+thesis')));
    await tester.pump();

    await search(tester, '+thesis');

    expect(find.textContaining('Finish the thesis draft'), findsOne);
    expect(find.text('October goal · calendar.txt'), findsOne);
  });

  testWidgets('a task row says its due date, or that it has none', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(buildApp(rows: _rows('+thesis', due: today)));
    await tester.pump();

    await search(tester, '+thesis');

    expect(find.text('Due today'), findsOne);
    expect(find.text('No date'), findsOne);
    expect(find.text(' · todo.txt'), findsNWidgets(2));
  });

  testWidgets('tapping a row opens it, and only it', (tester) async {
    final rows = _rows('+thesis');
    await tester.pumpWidget(buildApp(rows: rows));
    await tester.pump();

    await search(tester, '+thesis');
    final event = rows.firstWhere((row) => row.kind == TaskEventKind.event);
    await tester.tap(
      find.byKey(
        Key(
          'search-task-event-event-${event.lineIndex}'
          '-${event.event!.event.start}',
        ),
      ),
    );
    await tester.pump();

    expect(openedRows, [event]);
    expect(opened, isEmpty);
  });

  testWidgets('a mixed query, a tag or Contains draws no group', (
    tester,
  ) async {
    source.hits = [_note('Docs/Thesis.md')];
    await tester.pumpWidget(buildApp(rows: _rows('+thesis')));
    await tester.pump();

    await search(tester, '+thesis chapter');
    expect(find.byKey(const Key('search-group-tasks-events')), findsNothing);

    await search(tester, '#thesis');
    expect(find.byKey(const Key('search-group-tasks-events')), findsNothing);

    await tester.tap(find.text('Contains'));
    await tester.pump();
    await search(tester, '+thesis');
    expect(find.byKey(const Key('search-group-tasks-events')), findsNothing);
    // Contains asked the notes for the literal text, and drew their answer.
    expect(source.queries.last, '+thesis');
  });

  testWidgets('the group follows the files, without a new query', (
    tester,
  ) async {
    final changes = ChangeNotifier();
    final rows = <TaskEventHit>[..._rows('+thesis')];
    await tester.pumpWidget(buildApp(rows: rows, changes: changes));
    await tester.pump();

    await search(tester, '+thesis');
    expect(find.text('TASKS AND EVENTS · 4'), findsOne);

    // A task arrives (the file changed, the box did not).
    rows.add(_rows('+thesis').first);
    changes.notifyListeners();
    await tester.pump();

    expect(find.text('TASKS AND EVENTS · 5'), findsOne);
  });

  testWidgets('the group alone answers; nothing anywhere says no matches', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(rows: _rows('+thesis')));
    await tester.pump();

    await search(tester, '+thesis');

    expect(find.text('No matches'), findsNothing);
    expect(find.byKey(const Key('search-group-tasks-events')), findsOne);
    expect(find.byKey(const Key('search-group-notes')), findsNothing);

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await search(tester, '+thesis');
    expect(find.text('No matches'), findsOne);
  });

  testWidgets('without the seam the screen is the notes alone (#730)', (
    tester,
  ) async {
    source.hits = [_note('Docs/Thesis.md', title: 'Thesis outline')];
    await tester.pumpWidget(buildApp(withGroup: false));
    await tester.pump();

    await search(tester, '+thesis');

    expect(find.byKey(const Key('search-group-tasks-events')), findsNothing);
    expect(find.byKey(const Key('search-group-notes')), findsNothing);
    expect(find.text('Thesis outline'), findsOne);
  });
}
