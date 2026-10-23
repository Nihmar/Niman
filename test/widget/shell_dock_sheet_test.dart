// Issue #1011: a pane asked for on a surface with no dock gets the sheet that
// holds *that* pane. The fall-through used to build the tags pane for every
// pane the function did not name, so a spelling or history request opened
// tags.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/ui/dock/history_dock_pane.dart';
import 'package:niman/src/ui/dock/links_dock_pane.dart';
import 'package:niman/src/ui/dock/spelling_dock_pane.dart';
import 'package:niman/src/ui/dock/tags_dock_pane.dart';
import 'package:niman/src/ui/dock/tasks_dock_pane.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/shell_dock.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/note_tasks_fixture.dart';

/// The parts of a note the panes read; anything else is a test mistake.
final class _Note implements NoteViewHandle {
  @override
  final ValueNotifier<List<OutlineEntry>> outline = ValueNotifier(const []);

  @override
  SpellReview? get spellReview => null;

  @override
  String get currentText => '';

  @override
  String get notePath => '/fake/Celestia.md';

  @override
  String? get notePathInLibrary => 'Celestia.md';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeLibrarySession session;
  late ShellDock dock;
  late NoteTasksHost tasks;
  final note = _Note();

  setUp(() {
    session = FakeLibrarySession();
    dock = ShellDock(
      workspace: ShellWorkspace(session),
      controller: session,
      // A phone: not wide, no room for a docked panel.
      windowWidth: () => 400,
      wide: () => false,
      panelNote: () => note,
      journalBrowser: (_) => const Text('journal-browser'),
      tasks: () => tasks,
      onOpenHistory: (_) {},
      onOpenNoteFromLink: (_) {},
      onChanged: () {},
    );
  });

  Future<void> show(WidgetTester tester, DockPane pane) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => dock.showPanel(context, pane),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // A pane may animate a progress bar for good: pump the sheet in, no more.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the spelling request opens the spelling pane, not tags', (
    tester,
  ) async {
    await show(tester, DockPane.spelling);
    expect(find.byType(SpellingDockPane), findsOneWidget);
    expect(find.byType(TagsDockPane), findsNothing);
  });

  testWidgets('the history request opens the history pane, not tags', (
    tester,
  ) async {
    await show(tester, DockPane.history);
    expect(find.byType(HistoryDockPane), findsOneWidget);
    expect(find.byType(TagsDockPane), findsNothing);
  });

  testWidgets('the journal request opens the journal, not tags', (
    tester,
  ) async {
    await show(tester, DockPane.journal);
    expect(find.text('journal-browser'), findsOneWidget);
    expect(find.byType(TagsDockPane), findsNothing);
  });

  testWidgets('tags and links each open their own pane', (tester) async {
    await show(tester, DockPane.tags);
    expect(find.byType(TagsDockPane), findsOneWidget);
    expect(find.byType(LinksDockPane), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await show(tester, DockPane.links);
    expect(find.byType(LinksDockPane), findsOneWidget);
    expect(find.byType(TagsDockPane), findsNothing);
  });

  testWidgets('the tasks request opens the tasks of the note in a sheet', (
    tester,
  ) async {
    await session.open('/fake', create: false);
    final fixture = (await tester.runAsync(
      () => NoteTasksFixture.open(
        todo: ['Call the plumber [[Celestia]]', 'Other [[Ideas]]'],
        notes: ['Celestia.md', 'Ideas.md'],
      ),
    ))!;
    addTearDown(fixture.dispose);
    tasks = fixture.host;
    await show(tester, DockPane.tasks);
    expect(find.byType(TasksDockPane), findsOneWidget);
    expect(find.byType(TagsDockPane), findsNothing);
    await fixture.settle(tester);
    expect(find.text('Call the plumber'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
    expect(find.byKey(const Key('tasks-for-note-add')), findsOneWidget);
  });
}
