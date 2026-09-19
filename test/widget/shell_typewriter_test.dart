// Issue #70 in the shell: typewriter mode switches from its key, the
// palette and the note's status row, for the whole library; and it lives
// beside Zen mode (#69) without either touching the other — in Zen, where
// the status row is hidden, the key and the palette still reach it.
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

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
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
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool shift = false,
    bool control = true,
  }) async {
    if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  bool noteTypewriter(WidgetTester tester) =>
      tester.widget<NoteView>(find.byType(NoteView)).typewriter;

  testWidgets('Ctrl+Shift+T and the note’s switch turn it for the library', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1400, 900));
    expect(noteTypewriter(tester), isFalse);

    await press(tester, LogicalKeyboardKey.keyT, shift: true);
    expect(noteTypewriter(tester), isTrue);
    expect(await controller.typewriter, isTrue);
    // The note hands its status row the switch (typewriter_test).
    tester.widget<NoteView>(find.byType(NoteView)).onToggleTypewriter!();
    await settle(tester);
    expect(noteTypewriter(tester), isFalse);
    expect(await controller.typewriter, isFalse);
  });

  testWidgets('the palette names what it would do', (tester) async {
    await pumpAt(tester, const Size(1400, 900));
    await press(tester, LogicalKeyboardKey.keyP, shift: true);
    await tester.enterText(
      find.byKey(const Key('palette-field')),
      'typewriter',
    );
    await settle(tester);
    expect(find.textContaining('Turn typewriter mode on'), findsOne);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(noteTypewriter(tester), isTrue);
  });

  testWidgets('beside Zen: neither touches the other, and in Zen the key '
      'still switches it', (tester) async {
    await pumpAt(tester, const Size(1400, 900));
    await press(tester, LogicalKeyboardKey.keyT, shift: true);

    await press(tester, LogicalKeyboardKey.f11, control: false);
    expect(find.byKey(const Key('zen-title-bar')), findsOne);
    expect(noteTypewriter(tester), isTrue);
    await press(tester, LogicalKeyboardKey.keyT, shift: true);
    expect(noteTypewriter(tester), isFalse);
    expect(find.byKey(const Key('zen-title-bar')), findsOne);

    await press(tester, LogicalKeyboardKey.escape, control: false);
    expect(find.byKey(const Key('zen-title-bar')), findsNothing);
    // Leaving Zen leaves typewriter as Zen found it last: off.
    expect(noteTypewriter(tester), isFalse);
    expect(await controller.typewriter, isFalse);
  });

  // 0.0.8 test round: on the phone there was no way to it but Settings.
  testWidgets('on a phone the note’s ⋮ switches it', (tester) async {
    await pumpAt(tester, const Size(400, 800));
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.text('Turn typewriter mode on'), findsOne);
    await tester.tap(find.byKey(const Key('note-menu-typewriter')));
    await settle(tester);
    expect(await controller.typewriter, isTrue);
    expect(noteTypewriter(tester), isTrue);

    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.text('Turn typewriter mode off'), findsOne);
  });
}
