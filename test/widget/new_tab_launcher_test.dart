// #1133, #1134: the tab row's `+` opens a new tab with no note in it, and
// the pane's launcher shows there; the note opened next fills it.
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

  /// A tablet's shell with alpha and beta open, beta showing.
  Future<void> pumpShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          // No title bar of the app's own: a tablet's.
          windowControllerProvider.overrideWithValue(FakeWindowController()),
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
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  final launcher = find.byKey(const Key('launcher-new-note'));

  testWidgets('`+` opens a new tab with the launcher; a note fills it', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(launcher, findsNothing);

    await tester.tap(find.byKey(const Key('tab-new')));
    await settle(tester);
    expect(launcher, findsOne);
    expect(find.text('New tab'), findsOne);
    expect(controller.workspace.activePath, isNull);
    expect(controller.workspace.tabs, hasLength(3));

    await tester.tap(noteRow('gamma.md'));
    await settle(tester);
    expect(launcher, findsNothing);
    expect(find.text('New tab'), findsNothing);
    expect(controller.workspace.activePath, 'gamma.md');
    expect(
      [for (final tab in controller.workspace.tabs) tab.path],
      ['alpha.md', 'beta.md', 'gamma.md'],
    );
  });

  testWidgets('`+` again shows the new tab the pane has', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(const Key('tab-new')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-tab-0')));
    await settle(tester);
    expect(launcher, findsNothing);

    await tester.tap(find.byKey(const Key('tab-new')));
    await settle(tester);
    expect(launcher, findsOne);
    expect(controller.workspace.tabs, hasLength(3));
  });

  testWidgets('the launcher lists the notes shown last, and opens them', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(const Key('tab-new')));
    await settle(tester);
    // The latest first: beta, then alpha.
    expect(
      find.descendant(
        of: find.byKey(const Key('launcher-recent-0')),
        matching: find.text('beta'),
      ),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('launcher-recent-1')));
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
  });

  testWidgets('a new note named from the launcher fills the new tab', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(const Key('tab-new')));
    await settle(tester);
    await tester.tap(launcher);
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'delta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(controller.workspace.activePath, 'delta.md');
    expect(controller.workspace.tabs, hasLength(3));
  });
}
