// #535: the Home in the shell — its destination, its tiles on the desktop
// grid and in the phone's column, what they read, and where they lead.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/home/home_screen.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_sync_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late FakeTodoSource todo;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    todo = FakeTodoSource(
      todo: ['(A) Send the quote +alpha due:2026-01-01', 'Renew the domain'],
    );
  });

  Future<void> open(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => todo),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> goHome(WidgetTester tester, {bool wide = false}) async {
    await tester.tap(find.byKey(Key(wide ? 'rail-home' : 'tab-home')));
    await settle(tester);
  }

  Finder tile(String id) => find.byKey(Key('home-tile-$id'));

  testWidgets('phone: Home is in the bar, the default tiles in a column', (
    tester,
  ) async {
    await open(tester, _phone);
    await goHome(tester);

    expect(find.byType(HomeScreen), findsOne);
    final ids = ['actions', 'journalToday', 'tasksDue', 'recent', 'pinned'];
    for (final id in ids) {
      expect(tile(id), findsOne, reason: id);
    }
    final tops = [for (final id in ids) tester.getTopLeft(tile(id)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(
      tester.getTopLeft(tile('actions')).dx,
      tester.getTopLeft(tile('recent')).dx,
      reason: 'one column',
    );
  });

  testWidgets('a sync that brings only the Home file shows it (#680)', (
    tester,
  ) async {
    final sync = FakeSyncService();
    controller.syncService = sync;
    await open(tester, _phone);
    await goHome(tester);
    expect(tile('recent'), findsOne);

    controller.libraryHome = HomeLayout.defaults.hide('recent');
    sync.emitChanges({HomeFile.filePath});
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);

    expect(tile('recent'), findsNothing);
  });

  testWidgets('desktop: Home is in the rail, the tiles on the grid', (
    tester,
  ) async {
    await open(tester, _desktop);
    await goHome(tester, wide: true);

    final actions = tester.getRect(tile('actions'));
    final journal = tester.getRect(tile('journalToday'));
    final tasks = tester.getRect(tile('tasksDue'));
    expect(journal.left, greaterThan(actions.right), reason: 'side by side');
    expect(journal.top, actions.top);
    expect(tasks.top, greaterThan(actions.bottom), reason: 'tasks below');
    expect(tasks.left, actions.left);
    expect(journal.height, greaterThan(actions.height * 2));
  });

  testWidgets('the library Home replaces the defaults, the device one wins', (
    tester,
  ) async {
    controller.libraryHome = const HomeLayout([
      HomeTile(
        id: 'tags',
        kind: HomeTileKind.topTags,
        cell: (x: 0, y: 0, w: 1, h: 1),
        at: 0,
      ),
      HomeTile(
        id: 'recent',
        kind: HomeTileKind.recent,
        cell: (x: 1, y: 0, w: 1, h: 2),
        at: 1,
        hidden: true,
      ),
    ]);
    await open(tester, _phone);
    await goHome(tester);
    expect(tile('tags'), findsOne);
    expect(tile('recent'), findsNothing, reason: 'hidden');
    expect(tile('actions'), findsNothing, reason: 'not the defaults');
  });

  testWidgets('recently modified lists notes newest first and opens one', (
    tester,
  ) async {
    await open(tester, _phone);
    await controller.createNote(parentPath: '', name: 'Older');
    await controller.createNote(parentPath: '', name: 'Newer');
    await goHome(tester);

    final newer = find.byKey(const Key('home-note-Newer.md'));
    final older = find.byKey(const Key('home-note-Older.md'));
    expect(tester.getTopLeft(newer).dy, lessThan(tester.getTopLeft(older).dy));

    await tester.ensureVisible(newer);
    await tester.pump();
    await tester.tap(newer);
    await settle(tester);
    expect(find.byType(NoteView), findsOne, reason: 'the note is up');
  });

  testWidgets('a note made while the Home was away is there on return', (
    tester,
  ) async {
    await open(tester, _phone);
    await goHome(tester);
    expect(find.byKey(const Key('home-note-Later.md')), findsNothing);

    await tester.tap(find.byKey(const Key('tab-files')));
    await settle(tester);
    await controller.createNote(parentPath: '', name: 'Later');
    await settle(tester);
    await goHome(tester);

    expect(find.byKey(const Key('home-note-Later.md')), findsOne);
  });

  testWidgets('tasks due lists the open tasks; a tap shows the todo list', (
    tester,
  ) async {
    await open(tester, _phone);
    await goHome(tester);

    expect(find.text('Send the quote'), findsOne);
    expect(find.text('Renew the domain'), findsOne);
    expect(
      tester.getTopLeft(find.text('Send the quote')).dy,
      lessThan(tester.getTopLeft(find.text('Renew the domain')).dy),
      reason: 'due first',
    );

    await tester.tap(find.text('Renew the domain'));
    await settle(tester);
    expect(find.byType(TodoTab), findsOne);
  });

  testWidgets('checking a task off on the Home checks it in the list', (
    tester,
  ) async {
    await open(tester, _phone);
    await goHome(tester);
    final row = find.ancestor(
      of: find.text('Renew the domain'),
      matching: find.byType(InkWell),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.byType(Checkbox)),
    );
    await settle(tester);
    expect(todo.todoLines, isNot(contains('Renew the domain')));
    expect(find.text('Renew the domain'), findsNothing);
    expect(
      tester.element(find.byType(HomeScreen)).mounted,
      isTrue,
      reason: 'still on the Home',
    );
  });

  testWidgets("the journal tile writes today's entry", (tester) async {
    await open(tester, _phone);
    await goHome(tester);

    await tester.tap(find.byKey(const Key('home-journal-write')));
    await settle(tester);
    final journal = await controller.journal;
    final entry = journal.entryPath(journal.today(DateTime.now()));
    expect(await controller.find(entry), isNotNull);
  });

  testWidgets('the add task button asks for the task', (tester) async {
    await open(tester, _phone);
    await goHome(tester);

    await tester.tap(find.byKey(const Key('home-action-task')));
    await settle(tester);
    expect(find.byKey(const Key('todo-dialog-save')), findsOne);
  });

  testWidgets('an action of a kind this build does not know is not shown', (
    tester,
  ) async {
    controller.libraryHome = HomeLayout([
      HomeTile(
        id: 'a',
        kind: HomeTileKind.actions,
        cell: const (x: 0, y: 0, w: 2, h: 1),
        at: 0,
        actions: [
          HomeAction.fromJson({'id': 'x', 'label': 'Deck', 'do': 'study'})!,
          const HomeAction(
            id: 'j',
            label: 'Journal',
            kind: HomeActionKind.journal,
          ),
        ],
      ),
    ]);
    await open(tester, _phone);
    await goHome(tester);
    expect(find.byKey(const Key('home-action-x')), findsNothing);
    expect(find.byKey(const Key('home-action-j')), findsOne);
  });
}
