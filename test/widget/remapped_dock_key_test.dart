// 0.0.8 test round: the side panel's shortcut moved from Ctrl+Shift+B to
// Ctrl+Shift+L did nothing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  tearDown(() => AppKeyMap.current.value = KeyMap.defaults);

  testWidgets('a remapped side-panel key toggles the side panel', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    final picker = useFakeFilePicker();
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
    await openLibrary(tester, picker);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    final dock = find.byKey(const Key('right-dock'));
    expect(dock, findsOne);

    AppKeyMap.current.value = KeyMap.defaults.withBinding(
      AppCommand.toggleDock,
      const SingleActivator(
        LogicalKeyboardKey.keyL,
        control: true,
        shift: true,
      ),
    );
    await settle(tester);

    Future<void> press() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
    }

    await press();
    expect(dock, findsNothing, reason: 'closed by the new key');
    await press();
    expect(dock, findsOne, reason: 'opened again');
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
