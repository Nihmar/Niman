// #700: back and forward through the notes shown — Alt+Left and
// Alt+Right, and the mouse's side buttons on a desktop. One history for
// the window; a note closed since opens again in a tab of its own, one
// deleted since is skipped.
import 'package:flutter/gestures.dart';
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
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpShell(WidgetTester tester) async {
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
    for (final name in ['alpha', 'beta', 'gamma']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  String? shown() => controller.workspace.activePath;
  List<String> tabs() => controller.workspace.tabs.map((t) => t.path).toList();

  Future<void> show(WidgetTester tester, String name) async {
    await tester.tap(noteRow(name));
    await settle(tester);
  }

  Future<void> alt(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settle(tester);
  }

  Future<void> mouse(WidgetTester tester, int button) async {
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: button,
    );
    await gesture.down(tester.getCenter(find.byKey(const Key('title-bar'))));
    await gesture.up();
    await settle(tester);
  }

  testWidgets('Alt+Left and Alt+Right go back and forward', (tester) async {
    await pumpShell(tester);
    await show(tester, 'alpha.md');
    await show(tester, 'beta.md');
    await show(tester, 'gamma.md');

    await alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(shown(), 'beta.md');
    await alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(shown(), 'alpha.md');
    await alt(tester, LogicalKeyboardKey.arrowRight);
    expect(shown(), 'beta.md');
  });

  testWidgets("the mouse's side buttons go back and forward", (tester) async {
    await pumpShell(tester);
    await show(tester, 'alpha.md');
    await show(tester, 'beta.md');

    await mouse(tester, kBackMouseButton);
    expect(shown(), 'alpha.md');
    await mouse(tester, kForwardMouseButton);
    expect(shown(), 'beta.md');
  });

  testWidgets('a note closed since opens again in a tab of its own', (
    tester,
  ) async {
    await pumpShell(tester);
    // A click shows a note in the tab on screen: alpha is closed by it.
    await show(tester, 'alpha.md');
    await show(tester, 'beta.md');
    expect(tabs(), ['beta.md']);

    await alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(shown(), 'alpha.md');
    expect(tabs(), containsAll(['alpha.md', 'beta.md']));

    await alt(tester, LogicalKeyboardKey.arrowRight);
    expect(shown(), 'beta.md', reason: 'its tab, still open');
    expect(tabs(), hasLength(2));
  });

  testWidgets("a phone's keyboard goes back too", (tester) async {
    await pumpShell(tester);
    setSurfaceSize(tester, const Size(400, 800));
    await settle(tester);
    await show(tester, 'alpha.md');
    // The system's Back: the note leaves the screen, the tree is back.
    await tester.binding.handlePopRoute();
    await settle(tester);
    await show(tester, 'beta.md');
    expect(shown(), 'beta.md');

    await alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(shown(), 'alpha.md');
  });

  testWidgets('a note deleted since is stepped over', (tester) async {
    await pumpShell(tester);
    await show(tester, 'alpha.md');
    await show(tester, 'beta.md');
    await show(tester, 'gamma.md');
    await controller.delete('beta.md');
    await settle(tester);

    await alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(shown(), 'alpha.md');
  });
}
