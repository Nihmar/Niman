// #1134: where the panes head their own tab row — an Android tablet — the
// row carries the sidebar's toggle and the history's arrows at its start
// and the dock's toggle at its end, with a note open or none.
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

  /// A tablet's shell [size] wide, alpha and beta in its library, none
  /// open.
  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(1280, 800),
  }) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(FakeWindowController()),
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

  final row = find.byKey(const Key('pane-tab-row'));
  Finder inRow(String key) =>
      find.descendant(of: row, matching: find.byKey(Key(key)));
  IconButton button(WidgetTester tester, String key) =>
      tester.widget<IconButton>(inRow(key));

  testWidgets('with no note open the toggles are there, thumb-sized', (
    tester,
  ) async {
    await pumpShell(tester);
    for (final key in [
      'tabs-toggle-sidebar',
      'tabs-back',
      'tabs-forward',
      'dock-toggle',
    ]) {
      expect(inRow(key), findsOne, reason: key);
      final size = tester.getSize(inRow(key));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    // Nothing shown yet: no step back or forward.
    expect(button(tester, 'tabs-back').onPressed, isNull);
    expect(button(tester, 'tabs-forward').onPressed, isNull);
  });

  testWidgets('the sidebar toggle hides and shows the tree', (tester) async {
    await pumpShell(tester);
    final tree = find.byKey(const Key('tree-island'));
    expect(tree, findsOne);
    expect(button(tester, 'tabs-toggle-sidebar').isSelected, isTrue);

    await tester.tap(inRow('tabs-toggle-sidebar'));
    await settle(tester);
    expect(tree, findsNothing);
    expect(button(tester, 'tabs-toggle-sidebar').isSelected, isFalse);

    await tester.tap(inRow('tabs-toggle-sidebar'));
    await settle(tester);
    expect(tree, findsOne);
  });

  testWidgets('the dock toggle ends the tab row, not the note row', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(find.byKey(const Key('dock-toggle')), findsOne);
    expect(inRow('dock-toggle'), findsOne);
  });

  testWidgets('back and forward step through the notes shown', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(button(tester, 'tabs-back').onPressed, isNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(controller.workspace.activePath, 'beta.md');
    expect(button(tester, 'tabs-forward').onPressed, isNull);

    await tester.tap(inRow('tabs-back'));
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
    expect(button(tester, 'tabs-back').onPressed, isNull);

    await tester.tap(inRow('tabs-forward'));
    await settle(tester);
    expect(controller.workspace.activePath, 'beta.md');
  });

  testWidgets('a row too short for the arrows keeps the toggles', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(1024, 768));
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(inRow('tabs-toggle-sidebar'), findsOne);
    expect(inRow('dock-toggle'), findsOne);
    expect(inRow('tabs-back'), findsNothing);

    // The dock closed gives the row the room back.
    await tester.tap(inRow('dock-toggle'));
    await settle(tester);
    expect(inRow('tabs-back'), findsOne);
  });
}
