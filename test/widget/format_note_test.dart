// #227: Tidy the Markdown, from the palette and from the note's ⋮ menu.
// It works through the file the editors already watch: the buffer is
// saved, the note tidied on disk and read back, so both editors show the
// result.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

const String _untidy =
    '1. an item that runs on\n'
    'and wraps without any indent\n'
    '2. the second\n';

const String _tidy =
    '1. an item that runs on\n'
    '   and wraps without any indent\n'
    '2. the second\n';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpWithNote(WidgetTester tester, String text) async {
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
    await controller.createNote(parentPath: '', name: 'note');
    await controller.saveNote('note.md', text);
    await settle(tester);
    await tester.tap(noteRow('note.md'));
    await settle(tester);
  }

  Future<void> runFromMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-format')));
    await settle(tester);
  }

  testWidgets('it tidies the note on disk and says so', (tester) async {
    await pumpWithNote(tester, _untidy);
    await runFromMenu(tester);

    expect(await controller.readNote('note.md'), _tidy);
    expect(find.text(AppStrings.formatNoteDone), findsOne);
  });

  testWidgets('a note already tidy is left alone', (tester) async {
    await pumpWithNote(tester, _tidy);
    final savesBefore = controller.saves.length;
    await runFromMenu(tester);

    expect(await controller.readNote('note.md'), _tidy);
    expect(controller.saves.length, savesBefore, reason: 'nothing written');
    expect(find.text(AppStrings.formatNoteAlreadyTidy), findsOne);
  });

  testWidgets('the palette runs it too', (tester) async {
    await pumpWithNote(tester, _untidy);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('palette-field')),
      AppStrings.formatNoteTitle,
    );
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    expect(await controller.readNote('note.md'), _tidy);
  });
}
