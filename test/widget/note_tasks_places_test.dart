// #1152: "Tasks for this note" in the places "Links to this note" lives in --
// the header under the note (a count, always there while the Todo feature is
// on, gone with it off), the side panel's Tasks pane (after Links, before
// History, following the note beside it) and the ⋮ menu's entry that a phone
// opens as a sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/dock/right_dock.dart';
import 'package:niman/src/ui/dock/tasks_dock_pane.dart';
import 'package:niman/src/ui/note_menu.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/note_tasks_section.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/note_tasks_fixture.dart';

/// The one part of a note the Tasks pane reads.
final class _Note implements NoteViewHandle {
  new(this.notePath);

  @override
  final String notePath;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Features _off(LibraryFeature feature) =>
    const Features().withSwitch(feature, on: false);

const List<String> _todo = [
  'Call the plumber [[House/Repairs]] due:2026-09-08',
  'Pay the electrician [[House/Repairs]]',
  'Elsewhere [[Ideas]]',
];

void main() {
  late NoteTasksFixture fixture;

  Future<void> open(
    WidgetTester tester, {
    List<String> todo = _todo,
    List<String> done = const <String>[],
  }) async {
    fixture = (await tester.runAsync(
      () => NoteTasksFixture.open(todo: todo, done: done),
    ))!;
    addTearDown(fixture.dispose);
  }

  group('the section under the note', () {
    Future<void> pumpNote(
      WidgetTester tester, {
      Features features = const Features(),
      NoteTasksHost? tasks,
      String path = '/fake/House/Repairs.md',
      String? libraryRoot = '/fake',
      bool linked = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: path,
              showLineNumbers: false,
              autofocusEditor: false,
              libraryRoot: libraryRoot,
              linkSource: linked ? fixture.links : null,
              features: ValueNotifier(features),
              tasks: tasks ?? fixture.host,
              readNote: (_) async => 'the note\n',
              writeNote: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await fixture.settle(tester);
    }

    testWidgets('is a header with the open count, closed until asked', (
      tester,
    ) async {
      await open(tester, done: ['x 2026-09-01 Finished [[House/Repairs]]']);
      await pumpNote(tester);
      expect(find.text('Tasks for this note'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('tasks-for-note-count'))).data,
        '2',
      );
      expect(find.byKey(const Key('tasks-for-note')), findsNothing);
    });

    testWidgets('opens onto the list and shuts again', (tester) async {
      await open(tester);
      await pumpNote(tester);
      await tester.tap(find.byKey(const Key('tasks-for-note-header')));
      await tester.pumpAndSettle();
      expect(find.text('Call the plumber'), findsOneWidget);
      expect(find.text('Pay the electrician'), findsOneWidget);
      expect(find.text('Elsewhere'), findsNothing);
      expect(find.byKey(const Key('tasks-for-note-add')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tasks-for-note-header')));
      await tester.pumpAndSettle();
      expect(find.text('Call the plumber'), findsNothing);
    });

    testWidgets('sits below "Links to this note", which keeps its place', (
      tester,
    ) async {
      await open(tester);
      await pumpNote(tester, linked: true);
      final links = tester.getTopLeft(
        find.byKey(const Key('links-to-note-header')),
      );
      final tasks = tester.getTopLeft(
        find.byKey(const Key('tasks-for-note-header')),
      );
      expect(tasks.dy, greaterThan(links.dy));
      expect(tasks.dx, links.dx);
    });

    testWidgets('a note with no task counts zero and says so when opened', (
      tester,
    ) async {
      await open(tester, todo: ['Elsewhere [[Ideas]]']);
      await pumpNote(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('tasks-for-note-count'))).data,
        '0',
      );
      await tester.tap(find.byKey(const Key('tasks-for-note-header')));
      await tester.pumpAndSettle();
      expect(find.text('No task links to this note'), findsOneWidget);
    });

    testWidgets('is gone while the Todo feature is off', (tester) async {
      await open(tester);
      await pumpNote(tester, features: _off(LibraryFeature.todo));
      expect(find.byKey(const Key('tasks-for-note-section')), findsNothing);
      expect(find.text('Tasks for this note'), findsNothing);
    });

    testWidgets('is absent for a note outside the library', (tester) async {
      await open(tester);
      await pumpNote(tester, path: '/elsewhere/loose.md');
      expect(find.byKey(const Key('tasks-for-note-section')), findsNothing);
    });

    testWidgets('counts follow the tasks as they change', (tester) async {
      await open(tester);
      await pumpNote(tester);
      await tester.runAsync(
        () => fixture.controller.add('A third [[Repairs]]'),
      );
      await fixture.settle(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('tasks-for-note-count'))).data,
        '3',
      );
    });

    testWidgets('the section alone draws nothing without a host', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoteTasksSection(host: null, path: 'House/Repairs.md'),
          ),
        ),
      );
      expect(find.byKey(const Key('tasks-for-note-section')), findsNothing);
    });
  });

  group("the dock's pane", () {
    Future<void> pumpDock(
      WidgetTester tester, {
      Features features = const Features(),
      DockPane pane = DockPane.tasks,
      Widget Function(DockPane pane)? builder,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RightDock(
              features: features,
              pane: pane,
              onPane: (_) {},
              onClose: () {},
              paneBuilder: builder ?? (pane) => Text('pane ${pane.name}'),
            ),
          ),
        ),
      );
    }

    test('comes after Links and before History', () {
      const order = DockPane.values;
      expect(order.indexOf(DockPane.tasks), order.indexOf(DockPane.links) + 1);
      expect(
        order.indexOf(DockPane.history),
        order.indexOf(DockPane.tasks) + 1,
      );
    });

    testWidgets('is a tab with an outline icon, filled when selected', (
      tester,
    ) async {
      await open(tester);
      await pumpDock(tester, pane: DockPane.links);
      final tab = find.byKey(const Key('dock-pane-tasks'));
      expect(tab, findsOneWidget);
      expect(
        find.descendant(
          of: tab,
          matching: find.byIcon(Icons.check_box_outlined),
        ),
        findsOneWidget,
      );
      await pumpDock(tester);
      expect(
        find.descendant(of: tab, matching: find.byIcon(Icons.check_box)),
        findsOneWidget,
      );
      expect(find.text('Tasks for this note'), findsOneWidget);
    });

    testWidgets('has no tab while the Todo feature is off', (tester) async {
      await open(tester);
      await pumpDock(tester, features: _off(LibraryFeature.todo));
      expect(find.byKey(const Key('dock-pane-tasks')), findsNothing);
      // The outline shows in its place, as for any pane that is off.
      expect(find.text('pane outline'), findsOneWidget);
    });

    testWidgets('lists the tasks of the note beside it, and follows it', (
      tester,
    ) async {
      await open(tester);
      final notes = ValueNotifier<_Note>(_Note('/fake/House/Repairs.md'));
      addTearDown(notes.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<_Note>(
              valueListenable: notes,
              builder: (context, note, _) => TasksDockPane(
                note: note,
                host: fixture.host,
                libraryRoot: '/fake',
              ),
            ),
          ),
        ),
      );
      await fixture.settle(tester);
      expect(find.text('Call the plumber'), findsOneWidget);
      expect(find.text('Elsewhere'), findsNothing);

      notes.value = _Note('/fake/Ideas.md');
      await tester.pump();
      expect(find.text('Call the plumber'), findsNothing);
      expect(find.text('Elsewhere'), findsOneWidget);
    });

    testWidgets('no note beside it, nothing to list', (tester) async {
      await open(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasksDockPane(
              note: null,
              host: fixture.host,
              libraryRoot: '/fake',
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('tasks-for-note-add')), findsNothing);
    });

    testWidgets('a note outside the library has no list', (tester) async {
      await open(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasksDockPane(
              note: _Note('/elsewhere/loose.md'),
              host: fixture.host,
              libraryRoot: '/fake',
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('tasks-for-note-add')), findsNothing);
    });
  });

  group("the note's ⋮ menu", () {
    Future<List<NoteMenuAction>> pumpMenu(
      WidgetTester tester, {
      bool tasks = true,
    }) async {
      final picked = <NoteMenuAction>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMenuButton(onSelected: picked.add, tasks: tasks),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('note-menu')));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('offers Tasks for this note right after Links to this note', (
      tester,
    ) async {
      await pumpMenu(tester);
      final links = tester.getTopLeft(find.byKey(const Key('note-menu-links')));
      final tasks = tester.getTopLeft(find.byKey(const Key('note-menu-tasks')));
      expect(find.text('Tasks for this note'), findsOneWidget);
      expect(tasks.dy, greaterThan(links.dy));
      // Nothing else sits between the two.
      expect(tasks.dy - links.dy, lessThan(60));
    });

    testWidgets('reports the choice', (tester) async {
      final picked = await pumpMenu(tester);
      await tester.tap(find.byKey(const Key('note-menu-tasks')));
      await tester.pumpAndSettle();
      expect(picked, [NoteMenuAction.tasks]);
    });

    testWidgets('leaves it out while the Todo feature is off', (tester) async {
      await pumpMenu(tester, tasks: false);
      expect(find.byKey(const Key('note-menu-tasks')), findsNothing);
      expect(find.byKey(const Key('note-menu-links')), findsOneWidget);
    });
  });
}
