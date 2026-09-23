// #208: pinned commands. A pin heads the palette before anything is
// typed, above what was used lately; the pin is kept on the device and
// comes back on the next palette; Alt+P pins what is selected.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/pinned_commands.dart';
import 'package:niman/src/ui/strings.dart';
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
    PinnedCommands.current.value = const [];
    addTearDown(() => PinnedCommands.current.value = const []);
  });

  Future<void> pump(WidgetTester tester) async {
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
    await settle(tester);
  }

  Future<void> openPalette(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  /// Whether [command] is the palette's first row.
  bool heads(AppCommand command) => find
      .descendant(
        of: find.byKey(const Key('palette-item-0')),
        matching: find.byKey(Key('palette-pin-${command.name}')),
      )
      .evaluate()
      .isNotEmpty;

  /// Whether the palette lists [command] at all.
  bool lists(AppCommand command) =>
      find.byKey(Key('palette-pin-${command.name}')).evaluate().isNotEmpty;

  testWidgets('a pin from the palette heads it next time', (tester) async {
    await pump(tester);
    await openPalette(tester);
    expect(find.text(AppStrings.palettePinned.toUpperCase()), findsNothing);

    // Re-index now is far from the head: nothing was used yet, so the
    // list opens in registry order.
    final pin = find.byKey(const Key('palette-pin-reindexLibrary'));
    // The list builds its rows as they scroll in: scroll to it.
    await tester.scrollUntilVisible(
      pin,
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(pin);
    await settle(tester);
    expect(PinnedCommands.current.value, [AppCommand.reindexLibrary]);
    expect(controller.pinnedCommandsJson, contains('reindexLibrary'));
    // Its pin reads as pinned at once, and the row moved to the pinned
    // head: back at the top of the list, under its own heading, without
    // the palette being reopened.
    expect(tester.widget<IconButton>(pin).tooltip, AppStrings.paletteUnpin);
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await settle(tester);
    expect(find.text(AppStrings.palettePinned.toUpperCase()), findsOne);
    expect(heads(AppCommand.reindexLibrary), isTrue);

    // And it is still first on the next palette, from the stored pins.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    await openPalette(tester);
    expect(heads(AppCommand.reindexLibrary), isTrue);
  });

  testWidgets('the pin unpins, and the head goes with it', (tester) async {
    await pump(tester);
    PinnedCommands.current.value = const [AppCommand.reindexLibrary];
    await openPalette(tester);
    expect(heads(AppCommand.reindexLibrary), isTrue);

    await tester.tap(find.byKey(const Key('palette-pin-reindexLibrary')));
    await settle(tester);
    expect(PinnedCommands.current.value, isEmpty);
    expect(controller.pinnedCommandsJson, '[]');
    expect(find.text(AppStrings.palettePinned.toUpperCase()), findsNothing);
  });

  // 0.0.8 test round: Alt+P did nothing while the pointer was over a
  // row, because the selection was elsewhere. The pointer moves the
  // selection now, so the row under the hand is the row it pins.
  testWidgets('Alt+P pins the row the pointer is on', (tester) async {
    await pump(tester);
    await openPalette(tester);
    final second = find.byKey(const Key('palette-item-1'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(second));
    await settle(tester);

    // Which command that row is, read off its own pin button.
    final key =
        tester
                .widgetList<IconButton>(
                  find.descendant(
                    of: second,
                    matching: find.byType(IconButton),
                  ),
                )
                .single
                .key!
            as ValueKey<String>;
    final hovered = key.value.replaceFirst('palette-pin-', '');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settle(tester);
    expect(PinnedCommands.current.value, hasLength(1));
    expect(PinnedCommands.current.value.single.name, hovered);
  });

  testWidgets('Alt+P pins what is selected', (tester) async {
    await pump(tester);
    await openPalette(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settle(tester);
    // The selection starts on the first row, whatever it is.
    expect(PinnedCommands.current.value, hasLength(1));
    expect(heads(PinnedCommands.current.value.single), isTrue);
    expect(find.text(AppStrings.palettePinned.toUpperCase()), findsOne);
  });

  testWidgets('a pinned command that cannot run here is not listed', (
    tester,
  ) async {
    await pump(tester);
    // Nothing is open, so there is nothing to rename.
    PinnedCommands.current.value = const [AppCommand.renameNote];
    await openPalette(tester);
    expect(lists(AppCommand.renameNote), isFalse);
    expect(find.text(AppStrings.palettePinned.toUpperCase()), findsNothing);
  });

  test('the stored form survives a round trip, and ignores rubbish', () {
    const pinned = [AppCommand.zenMode, AppCommand.newNote];
    expect(PinnedCommands.decode(PinnedCommands.encode(pinned)), pinned);
    expect(PinnedCommands.decode('not json'), isEmpty);
    expect(PinnedCommands.decode('{"a":1}'), isEmpty);
    expect(PinnedCommands.decode('["nosuchcommand","zenMode"]'), [
      AppCommand.zenMode,
    ]);
  });
}
