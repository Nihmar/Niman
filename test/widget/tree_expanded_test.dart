// #1069: the tree's expanded folders follow a rename or a move of the folder
// they are under, are dropped with a deleted one, and are kept with the
// library's workspace across a restart.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pump(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await controller.createFolder(parentPath: 'Docs', name: 'Inner');
    await controller.createNote(parentPath: 'Docs/Inner', name: 'deep');
    await settle(tester);
  }

  Future<void> rename(WidgetTester tester, String from, String to) async {
    await tester.tap(noteRow(from), buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-rename')));
    await settle(tester);
    await tester.enterText(dialogField(), to);
    await tester.tap(find.text('OK'));
    await settle(tester);
  }

  testWidgets('a renamed folder keeps its open folders open, and saves them', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    await tester.tap(noteRow('Inner'));
    await settle(tester);
    expect(noteRow('deep.md'), findsOne);
    expect(controller.workspace.expanded, ['Docs', 'Docs/Inner']);

    await rename(tester, 'Docs', 'Books');
    // The tree comes back as it was: nothing collapsed, nothing left under
    // the old name.
    expect(noteRow('Books'), findsOne);
    expect(noteRow('Inner'), findsOne);
    expect(noteRow('deep.md'), findsOne);
    expect(controller.workspace.expanded, ['Books', 'Books/Inner']);

    // A folder made later under the old name starts closed.
    await controller.createFolder(parentPath: '', name: 'Docs');
    await controller.createNote(parentPath: 'Docs', name: 'fresh');
    await settle(tester);
    expect(noteRow('Docs'), findsOne);
    expect(noteRow('fresh.md'), findsNothing);
  });

  testWidgets('what was left expanded is expanded when the library opens', (
    tester,
  ) async {
    controller.workspace = Workspace.empty.withExpanded(['Docs', 'Docs/Inner']);
    await pump(tester);
    expect(noteRow('Inner'), findsOne);
    expect(noteRow('deep.md'), findsOne);
  });

  testWidgets('a deleted folder leaves the saved set', (tester) async {
    await pump(tester);
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    await tester.tap(noteRow('Inner'));
    await settle(tester);
    expect(controller.workspace.expanded, ['Docs', 'Docs/Inner']);

    await tester.tap(noteRow('Inner'), buttons: kSecondaryButton);
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('menu-delete')));
    await tester.tap(find.byKey(const Key('menu-delete')));
    await settle(tester);
    await settle(tester);
    expect(controller.workspace.expanded, ['Docs']);
  });
}
