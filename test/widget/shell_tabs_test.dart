// Issue #23, PR 2: the desktop's tabs. A click shows a note in the tab
// on screen, Ctrl+click or the row menu opens it alongside, the tree
// follows the showing tab, a folder leaves the tabs alone, and the tabs
// behind keep their editor.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/window_controller.dart';

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
    for (final name in ['alpha', 'beta', 'gamma']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  List<String> tabs() => controller.workspace.tabs.map((t) => t.path).toList();

  Future<void> ctrlClick(WidgetTester tester, Finder target) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(target);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool shift = false,
  }) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  testWidgets('a click shows the note in the tab on screen', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.tap(noteRow('beta.md'));
    await settle(tester);
    expect(tabs(), ['beta.md']);
  });

  testWidgets('Ctrl+click and the row menu open alongside', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await ctrlClick(tester, noteRow('beta.md'));
    expect(tabs(), ['alpha.md', 'beta.md']);
    expect(controller.workspace.activePath, 'beta.md');

    await tester.tapAt(
      tester.getCenter(noteRow('gamma.md')),
      buttons: kSecondaryButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-open-new-tab')));
    await settle(tester);
    expect(tabs(), ['alpha.md', 'beta.md', 'gamma.md']);
    expect(find.byKey(const Key('note-tab-2')), findsOne);
  });

  testWidgets('a tab shows its note, and the tree follows it', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await ctrlClick(tester, noteRow('beta.md'));
    await tester.tap(find.byKey(const Key('note-tab-0')));
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
    // The tab behind keeps its editor mounted, offstage.
    expect(find.byType(NoteView, skipOffstage: false), findsNWidgets(2));
    expect(find.byType(NoteView), findsOne);
  });

  testWidgets('closing: the × and Ctrl+W, the neighbour shows', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await ctrlClick(tester, noteRow('beta.md'));
    await ctrlClick(tester, noteRow('gamma.md'));
    await tester.tap(find.byKey(const Key('note-tab-1')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-tab-close-1')));
    await settle(tester);
    expect(tabs(), ['alpha.md', 'gamma.md']);
    expect(controller.workspace.activePath, 'gamma.md');

    await press(tester, LogicalKeyboardKey.keyW);
    expect(tabs(), ['alpha.md']);
    await press(tester, LogicalKeyboardKey.keyW);
    expect(tabs(), isEmpty);
    expect(find.byType(NoteView), findsNothing);
  });

  testWidgets('Ctrl+Tab and Ctrl+Shift+Tab go round the tabs', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await ctrlClick(tester, noteRow('beta.md'));
    await press(tester, LogicalKeyboardKey.tab);
    expect(controller.workspace.activePath, 'alpha.md');
    await press(tester, LogicalKeyboardKey.tab, shift: true);
    expect(controller.workspace.activePath, 'beta.md');
  });

  testWidgets('selecting a folder leaves the note on screen', (tester) async {
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    expect(tabs(), ['alpha.md']);
    expect(find.byType(NoteView), findsOne);
  });

  testWidgets('each tab keeps its own preview', (tester) async {
    // One pane at a time, so the eye toggles it (side by side has none).
    await controller.setPreviewMode(PreviewLayoutMode.fullScreen);
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await ctrlClick(tester, noteRow('beta.md'));
    await tester.tap(find.byKey(const Key('editor-preview-toggle')));
    await settle(tester);
    NoteView shown() => tester.widget<NoteView>(find.byType(NoteView));
    expect(shown().showPreview, isTrue);
    await tester.tap(find.byKey(const Key('note-tab-0')));
    await settle(tester);
    expect(shown().path, endsWith('alpha.md'));
    expect(shown().showPreview, isFalse);
  });
}
