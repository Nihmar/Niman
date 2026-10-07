// #538: the note's text zooms in and out from the keyboard — Ctrl+=,
// Ctrl+- and Ctrl+0, the browsers' keys — through the library's note text
// size, the setting the slider sets.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  tearDown(AppTextScales.reset);

  test('a zoom step lands on the grid, in range', () {
    expect(AppTextScales.zoomed(1, 1), closeTo(1.1, 1e-9));
    expect(AppTextScales.zoomed(1, -1), closeTo(0.9, 1e-9));
    expect(AppTextScales.zoomed(1.25, 1), closeTo(1.4, 1e-9));
    expect(AppTextScales.zoomed(maxTextScale, 1), maxTextScale);
    expect(AppTextScales.zoomed(minTextScale, -1), minTextScale);
    expect(AppTextScales.zoomed(1.6, 0), defaultTextScale);
  });

  testWidgets('Ctrl+= and Ctrl+- zoom the note, Ctrl+0 puts it back', (
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

    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
    }

    await press(LogicalKeyboardKey.equal);
    await press(LogicalKeyboardKey.equal);
    expect(await controller.noteTextScale, closeTo(1.2, 1e-9));
    expect(AppTextScales.note, closeTo(1.2, 1e-9));
    await press(LogicalKeyboardKey.minus);
    expect(await controller.noteTextScale, closeTo(1.1, 1e-9));
    await press(LogicalKeyboardKey.digit0);
    expect(await controller.noteTextScale, defaultTextScale);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
