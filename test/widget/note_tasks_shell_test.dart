// #1152: the whole shell with "Tasks for this note" in its three places -- the
// side panel's Tasks pane, the header under the note, the sheet of the phone's
// ⋮ menu -- and Add task opening the task dialog with the note's link already
// in the description.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late Directory dir;

  setUp(() async {
    controller = FakeLibrarySession();
    // A real directory: the open note is read off disk (the shell hands the
    // view no reader), so the file has to exist for the body to build.
    dir = await Directory.systemTemp.createTemp('niman_note_tasks_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  const todo = [
    'Call the plumber [[alpha]] due:2026-09-08',
    'Pay the electrician [[alpha]]',
    'Elsewhere [[beta]]',
  ];

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    String content = 'The alpha note\n',
  }) async {
    setSurfaceSize(tester, size);
    await controller.open(dir.path, create: true);
    File(p.join(dir.path, 'alpha.md')).writeAsStringSync(content);
    File(p.join(dir.path, 'beta.md')).writeAsStringSync('The beta note\n');
    await controller.createNote(
      parentPath: '',
      name: 'alpha',
      content: content,
    );
    await controller.createNote(parentPath: '', name: 'beta');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue(
            (_) => FakeTodoSource(todo: todo),
          ),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    // The note is read off disk on an isolate, and the tasks' links are
    // resolved a beat after: give the real event loop its turns.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.byType(MarkdownSourceView).evaluate().isNotEmpty && i > 3) break;
    }
    await settle(tester);
  }

  String dialogText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!.text;

  group('on a wide window', () {
    testWidgets('the side panel has a Tasks pane for the open note', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      // The strip scrolls (#1000): the tab is brought into view first.
      await tester.ensureVisible(find.byKey(const Key('dock-pane-tasks')));
      await tester.tap(find.byKey(const Key('dock-pane-tasks')));
      await settle(tester);

      expect(controller.workspace.dockPane, DockPane.tasks);
      expect(find.text('Call the plumber'), findsOneWidget);
      expect(find.text('Pay the electrician'), findsOneWidget);
      expect(find.text('Elsewhere'), findsNothing);
    });

    testWidgets('Add task opens the dialog with the note linked', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      await tester.ensureVisible(find.byKey(const Key('dock-pane-tasks')));
      await tester.tap(find.byKey(const Key('dock-pane-tasks')));
      await settle(tester);

      await tester.tap(find.byKey(const Key('tasks-for-note-add')));
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(dialogText(tester), '[[alpha]]');
    });

    testWidgets('the header under the note counts the open tasks', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      expect(find.byKey(const Key('tasks-for-note-section')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('tasks-for-note-count'))).data,
        '2',
      );
      await tester.tap(find.byKey(const Key('tasks-for-note-header')));
      await settle(tester);
      expect(find.text('Call the plumber'), findsOneWidget);
    });

    testWidgets('with the Todo feature off there is no header and no tab', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      await controller.setFeatures(
        controller.features.value.withSwitch(LibraryFeature.todo, on: false),
      );
      await settle(tester);
      expect(find.byKey(const Key('tasks-for-note-section')), findsNothing);
      expect(find.byKey(const Key('dock-pane-tasks')), findsNothing);
    });
  });

  group('on a phone', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('note-menu')));
      await settle(tester);
    }

    testWidgets('the note’s ⋮ offers the tasks as a sheet', (tester) async {
      await pumpAt(tester, const Size(400, 800));
      await openMenu(tester);
      expect(find.byKey(const Key('note-menu-tasks')), findsOneWidget);
      await tester.tap(find.byKey(const Key('note-menu-tasks')));
      await settle(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Call the plumber'), findsOneWidget);
      expect(find.text('Elsewhere'), findsNothing);

      // A tick ticks it, in the sheet too.
      await tester.tap(find.byKey(const Key('note-task-check-open-0')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await settle(tester);
      expect(find.text('Call the plumber'), findsNothing);
      expect(find.text('Done (1)'), findsOneWidget);
    });

    testWidgets('the menu has neither entry while the Todo feature is off', (
      tester,
    ) async {
      await pumpAt(tester, const Size(400, 800));
      await controller.setFeatures(
        controller.features.value.withSwitch(LibraryFeature.todo, on: false),
      );
      await settle(tester);
      await openMenu(tester);
      expect(find.byKey(const Key('note-menu-links')), findsOneWidget);
      expect(find.byKey(const Key('note-menu-tasks')), findsNothing);
    });
  });
}
