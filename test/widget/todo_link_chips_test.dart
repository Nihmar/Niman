// #1152: a link in a task is a chip in the Todo list -- the note's name, the
// heading or block after it, an alias in place of both -- and its words are
// not drawn a second time in the task's text. A tap opens the note as a
// wikilink in a note does; a missing note is offered; a name two notes share
// asks which; a fresh edit is a chip from the first frame and keeps its size
// as the library answers.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/note_link_targets.dart';
import 'package:niman/src/ui/todo_link_host.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_link_source.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  DateTime clock() => DateTime(2026, 9, 7);

  late FakeTodoSource source;
  late FakeLinkSource links;
  late TodoController controller;
  late TaskLinkMap map;
  late TodoLinkHost host;
  late TodoListView view;
  late List<(String, String?)> opened;
  late List<String> created;

  Future<void> pumpTab(
    WidgetTester tester,
    List<String> todo, {
    bool pointer = false,
    Future<void> Function(int batch)? gate,
  }) async {
    final session = FakeLibrarySession();
    await session.open('/fake', create: false);
    source = FakeTodoSource(todo: todo);
    links = FakeLinkSource(
      notes: ['House/Repairs.md', 'Ideas.md', 'a/Twin.md', 'b/Twin.md'],
    )..queryGate = gate;
    opened = [];
    created = [];
    controller = TodoController(
      session: session,
      clock: clock,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => source,
    );
    map = TaskLinkMap(
      tasks: controller,
      snapshot: () => controller.snapshot,
      links: () async => links,
      indexDebounce: Duration.zero,
    );
    host = TodoLinkHost(
      map: map,
      source: () => links,
      previewEnabled: () => false,
      targets: (anchor) => NoteLinkTargets(
        source: links,
        notePath: '/fake/todo.txt',
        libraryRoot: '/fake',
        newItemLocation: NewItemLocation.openNoteFolder,
        outline: const [],
        jumpToHeading: (_) {},
        onOpenNote: (path, anchor) => opened.add((path, anchor)),
        createMissingNote: (path) async {
          created.add(path);
          return path;
        },
        anchor: anchor,
      ),
    );
    view = TodoListView();
    addTearDown(() {
      host.dispose();
      map.dispose();
      controller.dispose();
      view.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: pointer ? ThemeData(visualDensity: VisualDensity.compact) : null,
        home: Scaffold(
          body: TodoTab(
            controller: controller,
            view: view,
            clock: clock,
            links: host,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Lets the map resolve what the list holds and the rows follow it.
  Future<void> resolved(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
  }

  Finder chip(String label) => find.byKey(Key('todo-link-chip-$label'));

  group('the chip', () {
    testWidgets("a live link is the note's name, and not drawn twice", (
      tester,
    ) async {
      await pumpTab(tester, [
        'Call the plumber [[House/Repairs]] due:2026-09-09',
      ]);
      await resolved(tester);
      expect(chip('Repairs'), findsOneWidget);
      expect(find.text('Call the plumber'), findsOneWidget);
      expect(find.textContaining('[['), findsNothing);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('a heading and a block read after the name', (tester) async {
      await pumpTab(tester, [
        'Fix the boiler [[Repairs#Boiler]]',
        'Check the notes [[Repairs#^b7]] and [[Repairs#A#B]]',
      ]);
      await resolved(tester);
      expect(chip('Repairs › Boiler'), findsOneWidget);
      expect(chip('Repairs › ^b7'), findsOneWidget);
      expect(chip('Repairs › A › B'), findsOneWidget);
    });

    testWidgets("an alias is the chip's text", (tester) async {
      await pumpTab(tester, [
        "Ring them [[House/Repairs|the plumber's notes]]",
      ]);
      await resolved(tester);
      expect(chip("the plumber's notes"), findsOneWidget);
      expect(find.text('Repairs'), findsNothing);
      expect(find.text('Ring them'), findsOneWidget);
    });

    testWidgets('a dead link is dashed and dimmed, with the written target', (
      tester,
    ) async {
      await pumpTab(tester, ['Fix the door [[Garage]]']);
      await resolved(tester);
      expect(chip('Garage'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      expect(find.text('Fix the door'), findsOneWidget);
      expect(find.textContaining('[['), findsNothing);
    });

    testWidgets('a task that is only a link reads as its chip', (tester) async {
      await pumpTab(tester, ['[[Ideas]]']);
      await resolved(tester);
      expect(chip('Ideas'), findsOneWidget);
      expect(find.text('[[Ideas]]'), findsNothing);
    });

    testWidgets(
      'a fresh link is a chip before the answer, and keeps its size',
      (tester) async {
        final gate = Completer<void>();
        await pumpTab(tester, [
          'Call the plumber [[House/Repairs]]',
        ], gate: (_) => gate.future);
        await tester.pump(const Duration(milliseconds: 10));
        // The library has not answered: the chip is drawn from the text.
        expect(map.index.isEmpty, isTrue);
        expect(chip('Repairs'), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
        expect(find.textContaining('[['), findsNothing);
        final before = tester.getSize(chip('Repairs'));

        gate.complete();
        await resolved(tester);
        expect(chip('Repairs'), findsOneWidget);
        expect(tester.getSize(chip('Repairs')), before);
      },
    );

    testWidgets("a pointer's row has the chip after the text", (tester) async {
      await pumpTab(tester, [
        'Call the plumber [[House/Repairs]]',
      ], pointer: true);
      await resolved(tester);
      expect(chip('Repairs'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.text('Call the plumber'), findsOneWidget);
      final text = tester.getTopRight(find.text('Call the plumber'));
      final box = tester.getTopLeft(chip('Repairs'));
      expect(box.dx, greaterThan(text.dx), reason: 'the chip follows the text');
    });
  });

  group('a tap', () {
    testWidgets('opens the note', (tester) async {
      await pumpTab(tester, ['Call the plumber [[House/Repairs]]']);
      await resolved(tester);
      await tester.tap(chip('Repairs'));
      await tester.pump();
      expect(opened, [('House/Repairs.md', null)]);
    });

    testWidgets('on a heading link opens the note at the heading', (
      tester,
    ) async {
      await pumpTab(tester, [
        'Fix the boiler [[Repairs#Boiler]] and [[Repairs#^b7]]',
      ]);
      await resolved(tester);
      await tester.tap(chip('Repairs › Boiler'));
      await tester.pump();
      await tester.tap(chip('Repairs › ^b7'));
      await tester.pump();
      expect(opened, [
        ('House/Repairs.md', 'Boiler'),
        ('House/Repairs.md', '^b7'),
      ]);
    });

    testWidgets("opens a note from a pointer's row too", (tester) async {
      await pumpTab(tester, ['Call the plumber [[Ideas]]'], pointer: true);
      await resolved(tester);
      await tester.tap(chip('Ideas'));
      await tester.pump();
      expect(opened, [('Ideas.md', null)]);
    });

    testWidgets('on a name two notes share asks which', (tester) async {
      await pumpTab(tester, ['Compare [[Twin]]']);
      await resolved(tester);
      expect(chip('Twin'), findsOneWidget);
      await tester.tap(chip('Twin'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Several notes match'), findsOneWidget);
      await tester.tap(find.text('b/Twin.md'));
      await tester.pump();
      expect(opened, [('b/Twin.md', null)]);
    });

    testWidgets('on a dead link offers to create the note', (tester) async {
      await pumpTab(tester, ['Fix the door [[Garage]]']);
      await resolved(tester);
      await tester.tap(chip('Garage'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(created, isEmpty, reason: 'asked first');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(created, ['Garage.md']);
      expect(opened, [('Garage.md', null)]);
    });

    testWidgets("on a pointer's row asks where the pointer went", (
      tester,
    ) async {
      await pumpTab(tester, ['Fix the door [[Garage]]'], pointer: true);
      await resolved(tester);
      await tester.tap(chip('Garage'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('missing-note-create')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(created, ['Garage.md']);
    });

    testWidgets('declining the offer creates nothing', (tester) async {
      await pumpTab(tester, ['Fix the door [[Garage]]']);
      await resolved(tester);
      await tester.tap(chip('Garage'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump(const Duration(seconds: 1));
      expect(created, isEmpty);
      expect(opened, isEmpty);
    });

    testWidgets('a pointer over a chip is told where it goes', (tester) async {
      await pumpTab(tester, [
        'Call the plumber [[House/Repairs]]',
      ], pointer: true);
      await resolved(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(chip('Repairs')));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Open House/Repairs.md'), findsOneWidget);
    });
  });
}
