// #1081: each pane's preview toggle (the eye in its status row) is decided
// by its own note, not by the note of the pane that has the focus.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  testWidgets('a pane with a PDF beside it keeps its own eye', (tester) async {
    final controller = FakeLibrarySession();
    final filePicker = useFakeFilePicker();
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
    await controller.createNote(parentPath: '', name: 'alpha');
    await controller.seedFile('doc.pdf');
    await settle(tester);

    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('doc.pdf'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    // Ctrl+\ moves the PDF into a pane of its own, which has the focus.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(controller.workspace.isSplit, isTrue);
    expect(controller.workspace.activePath, 'doc.pdf');

    // The note's pane keeps its eye; the PDF's has none.
    expect(find.byKey(const Key('editor-preview-toggle')), findsOne);
  });
}
