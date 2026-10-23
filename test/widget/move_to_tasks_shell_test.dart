// #1152: Move to tasks in the whole shell -- the command palette's entry, the
// task dialog it opens titled and saved as a move, the files written and the
// item gone from the note, and the entry going with the Todo feature.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

/// The palette's row for Move to tasks (the search field also reads that).
final Finder _paletteRow = find.byWidgetPredicate(
  (widget) => widget is Text && (widget.data ?? '').contains('Move to tasks'),
);

void main() {
  late FakeLibrarySession controller;
  late Directory dir;
  late FakeTodoSource source;

  setUp(() async {
    controller = FakeLibrarySession();
    source = FakeTodoSource();
    // A real directory: the open note is read off disk (the shell hands the
    // view no reader), so the file has to exist for the body to build.
    dir = await Directory.systemTemp.createTemp('niman_note_tasks_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    String content = '# Alpha\n\n- [ ] Call the plumber\n- [x] Pay the bill\n',
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
          todoSourceFactoryProvider.overrideWithValue((_) => source),
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

  Future<void> search(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-palette')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('palette-field')),
      'Move to tasks',
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  void caretOnItem(WidgetTester tester) {
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .placeCaret('# Alpha\n\n- [ ] Call'.length);
  }

  group('the command palette', () {
    testWidgets('offers Move to tasks, which opens the dialog and moves', (
      tester,
    ) async {
      await pumpAt(tester, const Size(400, 800));
      caretOnItem(tester);
      await tester.pump();
      await search(tester);
      expect(_paletteRow, findsOneWidget);
      await tester.tap(find.byKey(const Key('palette-item-0')));
      await settle(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Call the plumber [[alpha]]',
      );
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      // The dialog closes and the files are written on a real clock; the
      // snackbar then shows for a few seconds of the fake one.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(source.todoLines.single, endsWith('Call the plumber [[alpha]]'));
      expect(
        tester
            .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
            .widget
            .buffer
            .text,
        '# Alpha\n\n- [x] Pay the bill\n',
      );
      expect(find.text(AppStrings.movedToTasksOne), findsOneWidget);
    });

    testWidgets('does not offer it while the Todo feature is off', (
      tester,
    ) async {
      await pumpAt(tester, const Size(400, 800));
      await controller.setFeatures(
        controller.features.value.withSwitch(LibraryFeature.todo, on: false),
      );
      await settle(tester);
      await search(tester);
      expect(_paletteRow, findsNothing);
    });
  });
}
