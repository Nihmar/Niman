// The right dock on a window without room to dock it beside the note
// (a half-screen window, 960 px): its button stays in its place, and the
// panel opens over the note instead, shut by its x, Esc, a press outside
// it, the button or Ctrl+Shift+B. The note under it never moves, and the
// docked state that was remembered comes back with the room.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
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

  const narrow = Size(960, 1000);
  const wide = Size(1280, 1000);

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
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    await settle(tester);
  }

  Future<void> chord(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  final dock = find.byKey(const Key('right-dock'));
  final overlay = find.byKey(const Key('dock-overlay'));
  final toggle = find.byKey(const Key('dock-toggle'));
  final panes = find.byKey(const Key('panes-island'));

  testWidgets('the button is there, and the panel opens over the note and '
      'leaves it where it is', (tester) async {
    await pumpAt(tester, narrow);
    expect(toggle, findsOne);
    expect(dock, findsNothing, reason: 'no room beside the note');
    final note = tester.getRect(panes);
    final button = tester.getTopLeft(toggle);

    await tester.tap(toggle);
    await settle(tester);
    expect(overlay, findsOne);
    expect(dock, findsOne);
    expect(tester.getRect(panes), note);
    expect(tester.getTopLeft(toggle), button);
    final rect = tester.getRect(dock);
    expect(rect.width, defaultDockWidth);
    expect(rect.right, narrow.width - Island.gap, reason: 'right edge');
    expect(rect.top, note.top);
    expect(rect.bottom, note.bottom);
    expect(tester.widget<IconButton>(toggle).isSelected, isTrue);
    expect(
      controller.workspace.dockOpen,
      isTrue,
      reason: 'the remembered state is the docked one, untouched',
    );
  }, variant: desktopDensity);

  testWidgets('Ctrl+Shift+B, Esc, the cross and a press outside close it', (
    tester,
  ) async {
    await pumpAt(tester, narrow);
    Future<void> open() async {
      await tester.tap(toggle);
      await settle(tester);
      expect(overlay, findsOne);
    }

    // The button itself lies under the panel while it is open (the panel
    // takes the edge the button sits at): the panel's own cross, Esc, a
    // press outside and the key are the ways out.
    await chord(tester, LogicalKeyboardKey.keyB);
    expect(overlay, findsOne);
    await chord(tester, LogicalKeyboardKey.keyB);
    expect(overlay, findsNothing);

    await open();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(overlay, findsNothing);

    await open();
    await tester.tap(find.byKey(const Key('dock-close')));
    await settle(tester);
    expect(overlay, findsNothing);

    await open();
    await tester.tapAt(const Offset(300, 400));
    await settle(tester);
    expect(overlay, findsNothing);
    expect(
      controller.workspace.dockOpen,
      isTrue,
      reason: 'closing the overlay is not closing the dock',
    );
  }, variant: desktopDensity);

  testWidgets('a pane picked in the overlay is kept, and the overlay stays', (
    tester,
  ) async {
    await pumpAt(tester, narrow);
    await tester.tap(toggle);
    await settle(tester);
    await tester.tap(find.byKey(const Key('dock-pane-history')));
    await settle(tester);
    expect(overlay, findsOne);
    expect(controller.workspace.dockPane, DockPane.history);
  }, variant: desktopDensity);

  testWidgets('the palette lists the toggle, and runs it', (tester) async {
    await pumpAt(tester, narrow);
    await chord(tester, LogicalKeyboardKey.keyP);
    final listed = {
      for (final command
          in tester
              .widget<CommandPalette>(find.byType(CommandPalette))
              .commands)
        command.command,
    };
    expect(listed, contains(AppCommand.toggleDock));
    await tester.enterText(
      find.byKey(const Key('palette-field')),
      'side panel',
    );
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(overlay, findsOne);
  }, variant: desktopDensity);

  testWidgets('with room the panel docks, as it always did', (tester) async {
    await pumpAt(tester, wide);
    expect(dock, findsOne);
    expect(overlay, findsNothing);
    await tester.tap(toggle);
    await settle(tester);
    expect(dock, findsNothing);
    expect(controller.workspace.dockOpen, isFalse);
    await tester.tap(toggle);
    await settle(tester);
    expect(dock, findsOne);
    expect(overlay, findsNothing);
  }, variant: desktopDensity);

  testWidgets('narrowing a docked panel does not open the overlay by itself; '
      'widening brings the dock back', (tester) async {
    await pumpAt(tester, wide);
    expect(dock, findsOne);
    final button = tester.getTopLeft(toggle);

    await resize(tester, narrow);
    expect(dock, findsNothing);
    expect(overlay, findsNothing);
    expect(toggle, findsOne);
    expect(
      tester.getTopLeft(toggle).dy,
      button.dy,
      reason: 'the button keeps its row',
    );
    expect(controller.workspace.dockOpen, isTrue, reason: 'still remembered');

    await resize(tester, wide);
    expect(dock, findsOne);
    expect(overlay, findsNothing);
  }, variant: desktopDensity);

  testWidgets('an overlay left open does not come back by itself after the '
      'window has widened and narrowed', (tester) async {
    await pumpAt(tester, narrow);
    await tester.tap(toggle);
    await settle(tester);
    expect(overlay, findsOne);

    await resize(tester, wide);
    expect(overlay, findsNothing);
    expect(dock, findsOne);
    await resize(tester, narrow);
    expect(overlay, findsNothing);
  }, variant: desktopDensity);
}
