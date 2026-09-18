// Issue #175: the right dock in the shell. It shows where the window has
// room, opens and shuts from the note's row and Ctrl+Shift+B, keeps its
// state with the workspace, follows the focused pane, and on a phone the
// same panes come from the note's ⋮ as sheets.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/dock/history_dock_pane.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';

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

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
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
    for (final name in ['alpha', 'beta']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  final dock = find.byKey(const Key('right-dock'));

  testWidgets('open by default where there is room; the note row and '
      'Ctrl+Shift+B shut and open it, and it stays so', (tester) async {
    await pumpAt(tester, const Size(1400, 900));
    expect(dock, findsOne);
    await tester.tap(find.byKey(const Key('dock-toggle')));
    await settle(tester);
    expect(dock, findsNothing);
    expect(controller.workspace.dockOpen, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(dock, findsOne);

    await tester.tap(find.byKey(const Key('dock-pane-history')));
    await settle(tester);
    expect(controller.workspace.dockPane, DockPane.history);
    await tester.tap(find.byKey(const Key('dock-close')));
    await settle(tester);
    expect(dock, findsNothing);
  });

  testWidgets('a narrow window has no dock, and no way to one', (tester) async {
    await pumpAt(tester, const Size(900, 900));
    expect(dock, findsNothing);
    expect(find.byKey(const Key('dock-toggle')), findsNothing);
  });

  testWidgets('it follows the focused pane’s note', (tester) async {
    await pumpAt(tester, const Size(1500, 900));
    await tester.tap(find.byKey(const Key('dock-pane-history')));
    await settle(tester);
    String? shown() =>
        tester.widget<HistoryDockPane>(find.byType(HistoryDockPane)).path;
    expect(shown(), 'alpha.md');
    // The other note, opened beside: the dock follows the focus there.
    await tester.tapAt(
      tester.getCenter(noteRow('beta.md')),
      buttons: kSecondaryButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-open-beside')));
    await settle(tester);
    expect(shown(), 'beta.md');
    // A click back in the first pane, and it follows back.
    final divider = tester.getRect(find.byKey(const Key('pane-divider')));
    await tester.tapAt(Offset(divider.left - 80, 400));
    await settle(tester);
    expect(shown(), 'alpha.md');
  });

  testWidgets('on a phone the note’s ⋮ offers the same panes as sheets', (
    tester,
  ) async {
    await pumpAt(tester, const Size(400, 800));
    expect(dock, findsNothing);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-tags')));
    await settle(tester);
    expect(find.byType(BottomSheet), findsOne);
    await tester.tapAt(const Offset(200, 50));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-outline')));
    await settle(tester);
    expect(find.byType(BottomSheet), findsOne);
  });
}
