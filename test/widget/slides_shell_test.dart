// #534: a slides note in the shell — its ⋮ leads with the slide entries,
// the bar presents, and Markdown preview leaves the slides for the note.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';
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
    // A real directory: the open note is read off disk (the shell hands
    // the view no reader), so the file has to exist for the body to build.
    dir = await Directory.systemTemp.createTemp('niman_slides_shell_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        windowControllerProvider.overrideWithValue(
          FakeWindowController(customTitleBar: true),
        ),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> openNote(WidgetTester tester, String content) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await controller.open(dir.path, create: true);
    File(p.join(dir.path, 'Deck.md')).writeAsStringSync(content);
    await controller.createNote(parentPath: '', name: 'Deck', content: content);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('Deck.md'));
    // The note is read off disk on an isolate: give the real event loop
    // its turns while pumping, until the body has the note.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.byKey(const Key('kind-edit-raw')).evaluate().isNotEmpty) break;
    }
    await settle(tester);
  }

  testWidgets('the ⋮ of a slides note: present, presenter, Markdown', (
    tester,
  ) async {
    await openNote(tester, '---\ntype: slides\n---\n\n# One\n\n---\n\n# Two\n');
    expect(find.byKey(const Key('slides-strip')), findsOneWidget);
    expect(find.byKey(const Key('slides-present-action')), findsOneWidget);

    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.byKey(const Key('note-menu-present')), findsOneWidget);
    expect(find.byKey(const Key('note-menu-presenterView')), findsOneWidget);
    expect(find.byKey(const Key('note-menu-typewriter')), findsNothing);

    await tester.tap(find.byKey(const Key('note-menu-present')));
    await settle(tester);
    expect(find.byKey(const Key('slides-present')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byKey(const Key('slides-present')), findsNothing);

    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-markdownPreview')));
    await settle(tester);
    expect(find.byKey(const Key('slides-strip')), findsNothing);
    expect(find.byKey(const Key('kind-show-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('pane-preview')), findsOneWidget);

    // Back to the slides, then the pencil: the editor, not that preview.
    await tester.tap(find.byKey(const Key('kind-show-list')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('kind-edit-raw')));
    await settle(tester);
    expect(find.byKey(const ValueKey('pane-preview')), findsNothing);
  });
}
