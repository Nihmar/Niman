// A picture, a PDF or a book on a phone's screen is shown, not edited:
// its bar has no editor/preview eye, and its ⋮ menu keeps the file's own
// actions without the editor's (outline, tags, typewriter, tidy,
// cheatsheet, history).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> openOnPhone(WidgetTester tester, String name) async {
    setSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    if (name.endsWith('.md')) {
      await controller.createNote(parentPath: '', name: 'note');
    } else {
      await controller.seedFile(name);
    }
    await settle(tester);
    await tester.tap(noteRow(name));
    await settle(tester);
  }

  const editorItems = ['outline', 'tags', 'typewriter', 'format'];
  const fileItems = ['palette', 'rename', 'move', 'delete'];

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
  }

  Finder item(String name) => find.byKey(Key('note-menu-$name'));

  testWidgets('a note has the eye and the editor in its menu', (tester) async {
    await openOnPhone(tester, 'note.md');
    expect(find.byKey(const Key('editor-preview-toggle')), findsOne);
    await openMenu(tester);
    for (final name in [...editorItems, ...fileItems]) {
      expect(item(name), findsOne, reason: name);
    }
  });

  for (final name in ['book.epub', 'photo.png', 'paper.pdf']) {
    testWidgets('$name has neither', (tester) async {
      await openOnPhone(tester, name);
      expect(find.byKey(const Key('editor-preview-toggle')), findsNothing);
      await openMenu(tester);
      for (final name in editorItems) {
        expect(item(name), findsNothing, reason: name);
      }
      expect(item('cheatsheet'), findsNothing);
      expect(item('history'), findsNothing);
      for (final name in fileItems) {
        expect(item(name), findsOne, reason: name);
      }
    });
  }
}
