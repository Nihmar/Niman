// Issue #77 in the shell: Ctrl+Shift+O opens a Markdown file from
// anywhere. One inside the open library is one of its notes and opens as
// one; anything else opens on its own, over the library. The screen that
// opens a library offers the same, with no library at all.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  Future<void> ctrlShiftO(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  final outside = find.byKey(const Key('outside-file-bar'));

  testWidgets('a file outside the library opens on its own, over it, and '
      'back returns to it', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester, filePicker);
    filePicker.file = '/elsewhere/README.md';
    await ctrlShiftO(tester);
    expect(filePicker.offeredExtensions, containsAll(['md', 'markdown']));
    expect(outside, findsOne);
    expect(
      find.descendant(of: outside, matching: find.text('README.md')),
      findsOne,
    );

    await tester.tap(
      find.descendant(of: outside, matching: find.byType(BackButton)),
    );
    await settle(tester);
    expect(outside, findsNothing);
    expect(noteTree(), findsOne);
  });

  testWidgets('a file inside the library opens as its note', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    filePicker.file = '${controller.root}/alpha.md';
    await ctrlShiftO(tester);
    expect(outside, findsNothing);
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      endsWith('alpha.md'),
    );
  });

  testWidgets('with no library open, the opening screen offers it', (
    tester,
  ) async {
    await pumpApp(tester);
    filePicker.file = '/elsewhere/draft.md';
    await tester.tap(find.byKey(const Key('open-outside-file')));
    await settle(tester);
    expect(outside, findsOne);
    await tester.tap(
      find.descendant(of: outside, matching: find.byType(BackButton)),
    );
    await settle(tester);
    expect(find.byKey(const Key('open-outside-file')), findsOne);
  });

  testWidgets('a canceled pick opens nothing', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester, filePicker);
    await ctrlShiftO(tester);
    expect(outside, findsNothing);
  });
}
