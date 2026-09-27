// #309: the open note's ⋮ is the only way between a list and a
// shopping list — there is no "New shopping list" anywhere.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/strings.dart';
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
    dir = await Directory.systemTemp.createTemp('niman_list_kind_');
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
    File(p.join(dir.path, 'Spesa.md')).writeAsStringSync(content);
    await controller.createNote(
      parentPath: '',
      name: 'Spesa',
      content: content,
    );
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('Spesa.md'));
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

  testWidgets('the ⋮ turns a list into a shopping list, and back', (
    tester,
  ) async {
    const list = '---\ntype: list\n---\n- [ ] Pane\n';
    await openNote(tester, list);

    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.byKey(const Key('note-menu-kindSwitch')), findsOneWidget);
    expect(find.text(AppStrings.shoppingListName), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-menu-kindSwitch')));
    await settle(tester);

    // The frontmatter changed, one line, and the body is a shopping list
    // now (the item carries its quantity pill).
    expect(
      controller.contentOf('Spesa.md'),
      '---\ntype: shopping-list\n---\n- [ ] Pane\n',
    );
    expect(find.byKey(const Key('list-quantity-pill')), findsOneWidget);

    // And the way back reads Checklist.
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.text(AppStrings.checklistName), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-menu-kindSwitch')));
    await settle(tester);
    expect(controller.contentOf('Spesa.md'), list);
  });

  testWidgets('a plain note offers no kind entry at all', (tester) async {
    await openNote(tester, 'just prose\n');
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.byKey(const Key('note-menu-kindSwitch')), findsNothing);
  });
}
