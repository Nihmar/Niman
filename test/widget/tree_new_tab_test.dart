// 0.0.8 test round: a middle click or a double click on a note in the
// tree opens it in a tab of its own; a single click still shows it in
// place of the tab's note.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  Future<void> pumpShell(WidgetTester tester) async {
    controller = FakeLibrarySession();
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
    for (final name in ['alpha', 'beta', 'gamma', 'delta']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  List<String> tabs() => [
    for (final tab in controller.workspace.tabs) tab.path,
  ];

  testWidgets('a click replaces, a middle click and a double click open '
      'beside', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(tabs(), ['alpha.md']);

    // A single click shows the note in place of the tab's.
    await tester.tap(noteRow('beta.md'));
    await settle(tester);
    expect(tabs(), ['beta.md']);

    // A middle click opens it beside.
    await tester.tapAt(
      tester.getCenter(noteRow('gamma.md')),
      buttons: kMiddleMouseButton,
    );
    await settle(tester);
    expect(tabs(), ['beta.md', 'gamma.md']);

    // A double click: its first half replaced gamma, the second puts
    // gamma back and opens delta beside it.
    await tester.tap(noteRow('delta.md'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(noteRow('delta.md'));
    await settle(tester);
    expect(tabs(), ['beta.md', 'gamma.md', 'delta.md']);
    expect(controller.workspace.activePath, 'delta.md');
  });
}
