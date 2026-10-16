// #1078: Ctrl+Tab and Ctrl+W act on what the pane shows. With a pinned Home
// or Todo covering the notes, the chip is the shown tab: Ctrl+W closes it,
// and Ctrl+Tab goes on to a note tab, instead of moving the hidden one.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pump(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
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
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.tap(find.byKey(const Key('rail-todo')));
    await settle(tester);
  }

  Future<void> ctrl(
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

  List<String> tabs() => controller.workspace.tabs.map((t) => t.path).toList();

  testWidgets('Ctrl+W closes the chip that shows, not the note under it', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const Key('content-tab-todo')), findsOne);
    expect(tabs(), ['alpha.md', 'beta.md']);

    await ctrl(tester, LogicalKeyboardKey.keyW);
    expect(find.byKey(const Key('content-tab-todo')), findsNothing);
    expect(tabs(), ['alpha.md', 'beta.md']);
    expect(controller.workspace.activePath, 'beta.md');

    // The next one closes the note that now shows.
    await ctrl(tester, LogicalKeyboardKey.keyW);
    expect(tabs(), ['alpha.md']);
  });

  testWidgets('Ctrl+Tab from the chip goes to a note tab, which then shows', (
    tester,
  ) async {
    await pump(tester);
    await ctrl(tester, LogicalKeyboardKey.tab);
    expect(find.byKey(const Key('content-tab-todo')), findsOne);
    // The chip no longer covers the pane: a note is what shows.
    expect(controller.workspace.activePath, 'alpha.md');
    expect(find.byType(TodoTab), findsNothing, reason: 'no longer on show');

    await ctrl(tester, LogicalKeyboardKey.tab);
    expect(controller.workspace.activePath, 'beta.md');
  });

  testWidgets('Ctrl+Shift+Tab from the chip goes to the last note tab', (
    tester,
  ) async {
    await pump(tester);
    await ctrl(tester, LogicalKeyboardKey.tab, shift: true);
    expect(controller.workspace.activePath, 'beta.md');
    expect(find.byType(TodoTab), findsNothing, reason: 'no longer on show');
  });
}
