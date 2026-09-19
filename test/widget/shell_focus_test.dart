// The wide window keeps a key on the app's bindings: a control that lets
// the focus go (the preview's eye, a note closing) left it on the route's
// scope, above the shell, where no key reached a binding — until a click
// put it somewhere again.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
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

  Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  testWidgets('after the preview’s eye, the keys still work', (tester) async {
    await controller.setPreviewMode(PreviewLayoutMode.fullScreen);
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
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('editor-preview-toggle')));
    await settle(tester);
    await ctrl(tester, LogicalKeyboardKey.keyB);
    expect(noteTree(), findsNothing);

    // And after a note closes.
    await ctrl(tester, LogicalKeyboardKey.keyB);
    await ctrl(tester, LogicalKeyboardKey.keyW);
    await ctrl(tester, LogicalKeyboardKey.keyB);
    expect(noteTree(), findsNothing);
  });
}
