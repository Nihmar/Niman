// #840: Tidy the Markdown never runs on a `type: audio` note — its body is
// the clip document, not prose. The ⋮ does not offer it, and the palette
// and the key reach `_formatNote`, which refuses with no write and no
// snackbar. The tidy on close is refused where it is worked out
// (`tidiedNoteText`/`NoteWriter.tidy`), for every caller.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// A tidy would join the paragraph's lines: `one two\n`. The kind body is
/// the note's own lines, a written comment here.
const String _untidy = '---\ntype: audio\n---\none\ntwo\n';

void main() {
  late FakeLibrarySession controller;
  late Directory dir;

  setUp(() async {
    controller = FakeLibrarySession();
    // A real directory: the open note is read off disk (the shell hands
    // the view no reader), so the file has to exist for the kind body to
    // build.
    dir = await Directory.systemTemp.createTemp('niman_audio_tidy_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> openAudioNote(WidgetTester tester, String content) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await controller.open(dir.path, create: true);
    File(p.join(dir.path, 'Take.md')).writeAsStringSync(content);
    await controller.createNote(parentPath: '', name: 'Take', content: content);
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
    await settle(tester);
    await tester.tap(noteRow('Take.md'));
    // The note is read off disk on an isolate: give the real event loop
    // its turns while pumping, until the kind bar action is there.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.byKey(const Key('kind-edit-raw')).evaluate().isNotEmpty) break;
    }
    await settle(tester);
  }

  Future<void> runFromPalette(WidgetTester tester) async {
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
  }

  testWidgets('the ⋮ offers no Tidy the Markdown on an audio note', (
    tester,
  ) async {
    await openAudioNote(tester, _untidy);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);

    expect(find.byKey(const Key('note-menu-export')), findsOneWidget);
    expect(find.byKey(const Key('note-menu-format')), findsNothing);
  });

  testWidgets('the command leaves an audio note byte for byte', (tester) async {
    await openAudioNote(tester, _untidy);
    final savesBefore = controller.saves.length;
    await runFromPalette(tester);

    expect(await controller.readNote('Take.md'), _untidy);
    expect(controller.saves.length, savesBefore, reason: 'nothing written');
    expect(find.text(AppStrings.formatNoteDone), findsNothing);
    expect(find.text(AppStrings.formatNoteAlreadyTidy), findsNothing);
  });
}
