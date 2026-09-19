// Issue #69: Zen mode. F11 or the palette leaves the note and a thin bar
// with its name; Esc, the bar's button or F11 again bring the chrome back.
// The window is maximized on the way in and restored on the way out, but
// only when Zen maximized it. Nothing is lost on the way: the other pane
// keeps its editors. It is the desktop's alone.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late FakeWindowController window;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    window = FakeWindowController(customTitleBar: true);
  });

  Future<void> pumpAt(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
  }) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(window),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    for (final name in ['alpha', 'beta']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool control = false,
    bool shift = false,
  }) async {
    if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  final zenBar = find.byKey(const Key('zen-title-bar'));

  void expectChrome({required bool shown}) {
    final matcher = shown ? findsWidgets : findsNothing;
    expect(find.byType(ShellRail), matcher);
    expect(noteTree(), matcher);
    expect(find.byType(NoteTabBar), matcher);
    expect(find.byType(NoteTopBar), matcher);
    expect(find.byType(NoteStatusRow), matcher);
    expect(find.byKey(const Key('right-dock')), matcher);
    expect(find.byKey(const Key('title-bar')), matcher);
    expect(zenBar, shown ? findsNothing : findsOne);
  }

  testWidgets('F11 leaves the note and its name; Esc brings the chrome and '
      'the window back', (tester) async {
    await pumpAt(tester);
    expectChrome(shown: true);

    NoteView note() => tester.widget<NoteView>(find.byType(NoteView));
    expect(note().zen, isFalse);
    await press(tester, LogicalKeyboardKey.f11);
    expectChrome(shown: false);
    // The note hides its own chrome and preview (note_view_zen_test).
    expect(note().zen, isTrue);
    expect(
      find.descendant(of: zenBar, matching: find.text('alpha.md')),
      findsOne,
    );
    expect(find.byType(NoteView), findsOne);
    expect(window.maximized.value, isTrue);
    await press(tester, LogicalKeyboardKey.escape);
    expectChrome(shown: true);
    expect(window.maximized.value, isFalse);
    expect(window.maximizeCalls, 2);
  });

  testWidgets('the bar’s button and F11 again leave it too', (tester) async {
    await pumpAt(tester);
    await press(tester, LogicalKeyboardKey.f11);
    await tester.tap(find.byKey(const Key('zen-leave')));
    await settle(tester);
    expectChrome(shown: true);

    await press(tester, LogicalKeyboardKey.f11);
    await press(tester, LogicalKeyboardKey.f11);
    expectChrome(shown: true);
  });

  testWidgets('a window already maximized stays so on the way out', (
    tester,
  ) async {
    window.maximized.value = true;
    await pumpAt(tester);
    await press(tester, LogicalKeyboardKey.f11);
    await press(tester, LogicalKeyboardKey.escape);
    expect(window.maximizeCalls, 0);
    expect(window.maximized.value, isTrue);
  });

  testWidgets('the palette enters and leaves it, and keeps working in it, '
      'without the toggles for chrome Zen hides', (tester) async {
    await pumpAt(tester);
    Future<void> palette(String query) async {
      await press(tester, LogicalKeyboardKey.keyP, control: true, shift: true);
      await tester.enterText(find.byKey(const Key('palette-field')), query);
      await settle(tester);
    }

    await palette('zen');
    expect(find.textContaining('Enter Zen mode'), findsOne);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(zenBar, findsOne);

    await palette('file tree');
    expect(find.byKey(const Key('palette-item-0')), findsNothing);
    // Esc closes the palette first, not Zen.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(zenBar, findsOne);

    await palette('zen');
    expect(find.textContaining('Leave Zen mode'), findsOne);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expectChrome(shown: true);
  });

  testWidgets('Esc from inside the editor leaves it', (tester) async {
    await pumpAt(tester);
    await press(tester, LogicalKeyboardKey.f11);
    await tester.tap(find.byType(NoteView));
    await settle(tester);
    await press(tester, LogicalKeyboardKey.escape);
    expectChrome(shown: true);
  });

  testWidgets('split, it shows the focused pane alone, and both panes come '
      'back with the same editors', (tester) async {
    await pumpAt(tester);
    await tester.tapAt(
      tester.getCenter(noteRow('beta.md')),
      buttons: kSecondaryButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-open-beside')));
    await settle(tester);
    List<State> editors() => tester
        .stateList<State>(find.byType(NoteView, skipOffstage: false))
        .toList();
    final before = editors();
    expect(before, hasLength(2));

    await press(tester, LogicalKeyboardKey.f11);
    expect(find.byType(NoteView), findsOne);
    expect(
      find.descendant(of: zenBar, matching: find.text('beta.md')),
      findsOne,
    );

    await press(tester, LogicalKeyboardKey.escape);
    expect(find.byType(NoteView), findsNWidgets(2));
    expect(editors(), unorderedEquals(before));
  });

  testWidgets('closing the last note leaves it, window and all', (
    tester,
  ) async {
    await pumpAt(tester);
    await press(tester, LogicalKeyboardKey.f11);
    await press(tester, LogicalKeyboardKey.keyW, control: true);
    expect(zenBar, findsNothing);
    expect(find.byType(ShellRail), findsOne);
    expect(noteTree(), findsOne);
    expect(window.maximized.value, isFalse);
  });

  testWidgets('it is the desktop’s: no custom title bar, no Zen', (
    tester,
  ) async {
    window = FakeWindowController();
    await pumpAt(tester);
    await press(tester, LogicalKeyboardKey.f11);
    expect(zenBar, findsNothing);
    expect(window.maximizeCalls, 0);
  });
}
