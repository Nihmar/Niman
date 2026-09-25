// Issue #23, PR 1: the shell keeps the workspace current — the note it
// shows, and the library changing under it — and keeps it on this device,
// with nothing on screen changed yet.
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

  Future<void> pumpShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1200, 900));
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
  }

  Future<void> rowMenu(WidgetTester tester, String row, String action) async {
    await tester.longPress(noteRow(row));
    await settle(tester);
    final item = find.byKey(Key('menu-$action'));
    await tester.ensureVisible(item);
    await settle(tester);
    await tester.tap(item);
    await settle(tester);
  }

  testWidgets('the note on screen is the one kept', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
    // One note at a time still: the next one takes its place.
    await controller.createNote(parentPath: '', name: 'beta');
    await settle(tester);
    await tester.tap(noteRow('beta.md'));
    await settle(tester);
    expect(controller.workspace.tabs.map((t) => t.path), ['beta.md']);
  });

  testWidgets('a renamed folder takes the open note along', (tester) async {
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await controller.createNote(parentPath: 'Docs', name: 'alpha');
    await settle(tester);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(controller.workspace.activePath, 'Docs/alpha.md');

    await rowMenu(tester, 'Docs', 'rename');
    await tester.enterText(dialogField(), 'Books');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(controller.workspace.activePath, 'Books/alpha.md');
  });

  testWidgets('a deleted note leaves nothing open', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await rowMenu(tester, 'alpha.md', 'delete');
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(controller.workspace.tabs, isEmpty);
  });

  testWidgets('what was left open comes back as tabs', (tester) async {
    // The notes are in the tree, so the store's tabs come back as they are.
    await controller.saveNote('kept.md', '');
    await controller.saveNote('other.md', '');
    controller.workspace = Workspace.empty.open('kept.md').open('other.md');
    await pumpShell(tester);
    await settle(tester);
    expect(controller.workspace.activePath, 'other.md');
    // On a wide window the tabs are drawn from it (#23, PR 2).
    expect(find.byKey(const Key('note-tab-0')), findsOne);
    expect(find.byKey(const Key('note-tab-1')), findsOne);
    expect(find.byKey(const Key('note-top-bar')), findsOne);
  });
}
