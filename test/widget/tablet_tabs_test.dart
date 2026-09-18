// A wide window without a title bar of the app's own — an Android
// tablet, a phone in landscape — still shows the open notes' tabs: they
// head the panes instead, dividing where the panes do (#23).
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

  Future<void> pumpShell(WidgetTester tester, {required bool ownBar}) async {
    setSurfaceSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: ownBar),
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
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  final row = find.byKey(const Key('pane-tab-row'));

  testWidgets('no title bar of its own: the tabs head the panes', (
    tester,
  ) async {
    await pumpShell(tester, ownBar: false);
    expect(find.byKey(const Key('title-bar')), findsNothing);
    expect(row, findsOne);
    expect(
      find.descendant(of: row, matching: find.byKey(const Key('note-tab-1'))),
      findsOne,
    );
    // They work as the title bar's do.
    await tester.tap(
      find.descendant(of: row, matching: find.byKey(const Key('note-tab-0'))),
    );
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');

    // Split right: the row divides where the panes do.
    await tester.tapAt(
      tester.getCenter(
        find.descendant(of: row, matching: find.byKey(const Key('note-tab-1'))),
      ),
      buttons: kSecondaryMouseButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('tab-menu-split-right')));
    await settle(tester);
    final divider = tester.getRect(find.byKey(const Key('pane-divider')));
    final second = tester.getRect(find.byKey(const Key('pane-tabs-1')));
    expect(second.left, closeTo(divider.right, 1));
  });

  testWidgets('with its own title bar, the tabs stay up there', (tester) async {
    await pumpShell(tester, ownBar: true);
    expect(row, findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('title-bar')),
        matching: find.byKey(const Key('note-tab-1')),
      ),
      findsOne,
    );
  });
}
