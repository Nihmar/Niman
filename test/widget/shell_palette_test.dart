// Issue #155 in the shell: Ctrl+Shift+P and Ctrl+O open the palette over
// whatever is on screen, what it picks runs through the same handlers
// the keys use, it offers only what can run now, and on a phone the
// search screen is the palette.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/palette/command_needs.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
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
    for (final name in ['alpha', 'beta']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  Future<void> keys(
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

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('palette-field')), text);
    await settle(tester);
  }

  testWidgets('Ctrl+O finds a note by name and opens it', (tester) async {
    await pumpAt(tester, const Size(1400, 900));
    await keys(tester, LogicalKeyboardKey.keyO);
    await type(tester, 'bet');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.byKey(const Key('command-palette')), findsNothing);
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      endsWith('beta.md'),
    );
  });

  testWidgets('Ctrl+Shift+P runs a command, the same as its key', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1400, 900));
    await keys(tester, LogicalKeyboardKey.keyP, shift: true);
    await type(tester, 'go settings');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.byKey(const Key('settings-search-field')), findsOne);
  });

  testWidgets('it offers what can run now', (tester) async {
    await pumpAt(tester, const Size(1400, 900));
    await keys(tester, LogicalKeyboardKey.keyP, shift: true);
    // No note open: nothing to rename.
    await type(tester, 'rename');
    expect(find.byKey(const Key('palette-item-0')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await keys(tester, LogicalKeyboardKey.keyP, shift: true);
    await type(tester, 'rename');
    expect(find.byKey(const Key('palette-item-0')), findsOne);
  });

  // #207: the palette and the Commands page read one table. Whatever the
  // page says a command needs, the palette offers it exactly when that
  // holds: every command has a handler, and none shows early.
  Set<AppCommand> offered(WidgetTester tester) => {
    for (final command
        in tester.widget<CommandPalette>(find.byType(CommandPalette)).commands)
      command.command,
  };

  Set<AppCommand> expected(Set<CommandNeed> met) => {
    for (final command in AppCommand.values)
      if (command != AppCommand.openPalette &&
          command != AppCommand.goToNote &&
          commandNeeds(command).every(met.contains))
        command,
  };

  testWidgets('it offers a command exactly when the Commands page says', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1400, 900));
    await keys(tester, LogicalKeyboardKey.keyP, shift: true);
    expect(
      offered(tester),
      expected({
        CommandNeed.wideWindow,
        CommandNeed.dockRoom,
        CommandNeed.notInZen,
        CommandNeed.desktop,
      }),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await keys(tester, LogicalKeyboardKey.keyP, shift: true);
    expect(
      offered(tester),
      expected({
        CommandNeed.openNote,
        CommandNeed.wideWindow,
        CommandNeed.dockRoom,
        CommandNeed.notInZen,
        CommandNeed.desktop,
        CommandNeed.zenRoom,
        CommandNeed.previewToggle,
        CommandNeed.twoEditors,
      }),
    );
  });

  testWidgets('on a phone the search lists the commands, and runs them', (
    tester,
  ) async {
    await pumpAt(tester, const Size(400, 800));
    await tester.tap(find.byKey(const Key('tab-search')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'settings');
    await settle(tester);
    final command = find.byKey(const Key('search-command-tabSettings'));
    expect(command, findsOne);
    await tester.tap(command);
    await settle(tester);
    expect(find.byKey(const Key('settings-search-field')), findsOne);
  });
}
