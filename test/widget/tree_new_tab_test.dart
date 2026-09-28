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
import 'package:niman/src/ui/tree_click_clock.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;

  /// Pumps the whole shell. [now] is the tree's click clock: given, the
  /// test owns the window the double click is judged against; left out,
  /// the app's own ([DateTime.now]) answers.
  Future<void> pumpShell(
    WidgetTester tester, {
    DateTime Function()? now,
  }) async {
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
          if (now != null) treeClickClockProvider.overrideWithValue(now),
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

  testWidgets('a click replaces and a middle click opens beside', (
    tester,
  ) async {
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
  });

  testWidgets('a double click opens beside, and two clicks past the window '
      'do not', (tester) async {
    // The window is `kDoubleTapTimeout` of real time, which pumping cannot
    // move: it is the test's clock that answers here, so the gap between
    // the test's two clicks is the test's to decide and the load on the
    // machine cannot turn the pair into two single clicks (#437).
    var now = DateTime(2026, 9, 28, 12);
    await pumpShell(tester, now: () => now);
    await tester.tap(noteRow('beta.md'));
    await settle(tester);
    expect(tabs(), ['beta.md']);

    // A double click: its first half replaced beta with gamma, the second
    // puts beta back and opens gamma beside it.
    await tester.tap(noteRow('gamma.md'));
    now = now.add(const Duration(milliseconds: 50));
    await tester.pump(); // Between the two halves: a frame each.
    await tester.tap(noteRow('gamma.md'));
    await settle(tester);
    expect(tabs(), ['beta.md', 'gamma.md']);
    expect(controller.workspace.activePath, 'gamma.md');

    // A full window apart they are two clicks: the second one replaces the
    // tab's note, and gamma stays where the double click left it.
    await tester.tap(noteRow('delta.md'));
    now = now.add(kDoubleTapTimeout + const Duration(milliseconds: 1));
    await tester.pump();
    await tester.tap(noteRow('delta.md'));
    await settle(tester);
    expect(tabs(), ['beta.md', 'delta.md']);
    expect(controller.workspace.activePath, 'delta.md');
  });
}
