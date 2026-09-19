// T-PP-10 and #159: the keyboard screen is where the keys live. Every
// command is listed, with its key or none; a key is changed by pressing
// it, cleared, reverted, and restored with the rest; a conflict names
// the command it collides with; the text fields' own keys may be taken
// after a warning; the map is kept in the device's settings.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() {
    session = FakeLibrarySession();
    AppKeyMap.current.value = KeyMap.defaults;
  });
  tearDown(() => AppKeyMap.current.value = KeyMap.defaults);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: KeyboardShortcutsScreen(controller: session)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool control = false,
    bool alt = false,
  }) async {
    if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(key);
    if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  Future<void> record(
    WidgetTester tester,
    AppCommand command,
    LogicalKeyboardKey key, {
    bool control = true,
    bool alt = false,
  }) async {
    await tester.tap(find.byKey(Key('shortcut-${command.name}')));
    await tester.pumpAndSettle();
    await press(tester, key, control: control, alt: alt);
    await tester.tap(find.byKey(const Key('key-capture-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('every command is listed, a key or none', (tester) async {
    await pump(tester);
    for (final command in AppCommand.values) {
      expect(find.byKey(Key('shortcut-${command.name}')), findsOne);
    }
    expect(find.text('Ctrl+Shift+N'), findsOne);
    expect(find.text(AppStrings.shortcutNone), findsWidgets);
  });

  testWidgets('a key is changed by pressing it, and kept', (tester) async {
    await pump(tester);
    await record(
      tester,
      AppCommand.newNote,
      LogicalKeyboardKey.keyN,
      alt: true,
    );
    expect(find.text('Ctrl+Alt+N'), findsOne);
    expect(
      KeyMap.fromJson(session.keyMapJson).bindingOf(AppCommand.newNote),
      isNotNull,
    );
    // Changed, so it can go back.
    await tester.tap(find.byKey(const Key('shortcut-revert-newNote')));
    await tester.pumpAndSettle();
    expect(find.text('Ctrl+N'), findsOne);
    expect(AppKeyMap.current.value.isChanged(AppCommand.newNote), isFalse);
  });

  testWidgets('a key can be cleared: none is a valid state', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('shortcut-clear-toggleSidebar')));
    await tester.pumpAndSettle();
    expect(AppKeyMap.current.value.bindingOf(AppCommand.toggleSidebar), isNull);
    expect(session.keyMapJson, contains('"toggleSidebar":null'));
  });

  testWidgets('a conflict names the other command, and moving asks', (
    tester,
  ) async {
    await pump(tester);
    await record(tester, AppCommand.newNote, LogicalKeyboardKey.keyB);
    final dialog = find.byKey(const Key('shortcut-conflict'));
    expect(dialog, findsOne);
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining(
          appCommandLabel(AppCommand.toggleSidebar),
        ),
      ),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('shortcut-conflict-yes')));
    await tester.pumpAndSettle();
    final map = AppKeyMap.current.value;
    expect(
      map.commandOn(
        const SingleActivator(LogicalKeyboardKey.keyB, control: true),
      ),
      AppCommand.newNote,
    );
    expect(map.bindingOf(AppCommand.toggleSidebar), isNull);
  });

  testWidgets('declining a conflict changes nothing', (tester) async {
    await pump(tester);
    await record(tester, AppCommand.newNote, LogicalKeyboardKey.keyB);
    await tester.tap(find.text(AppStrings.actionCancel));
    await tester.pumpAndSettle();
    expect(AppKeyMap.current.value, KeyMap.defaults);
    expect(session.keyMapJson, isNull);
  });

  testWidgets('a text field’s key is taken only after a warning', (
    tester,
  ) async {
    await pump(tester);
    await record(tester, AppCommand.renameNote, LogicalKeyboardKey.keyC);
    expect(find.byKey(const Key('shortcut-editor-key')), findsOne);
    await tester.tap(find.byKey(const Key('shortcut-editor-key-yes')));
    await tester.pumpAndSettle();
    expect(AppKeyMap.current.value.bindingOf(AppCommand.renameNote), isNotNull);
  });

  testWidgets('a key on its own is for typing; F-keys may stand alone', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('shortcut-renameNote')));
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.keyK);
    expect(find.byKey(const Key('key-capture-needs-modifier')), findsOne);
    final save = tester.widget<FilledButton>(
      find.byKey(const Key('key-capture-save')),
    );
    expect(save.onPressed, isNull);
    await press(tester, LogicalKeyboardKey.f2);
    await tester.tap(find.byKey(const Key('key-capture-save')));
    await tester.pumpAndSettle();
    expect(find.text('F2'), findsOne);
  });

  testWidgets('Esc and Tab are recorded; Esc held down leaves', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('shortcut-renameNote')));
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab, control: true);
    expect(
      find.descendant(
        of: find.byKey(const Key('key-capture-keys')),
        matching: find.text('Ctrl+${AppStrings.keyTab}'),
      ),
      findsOne,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('key-capture')), findsNothing);
    expect(AppKeyMap.current.value, KeyMap.defaults);
  });

  testWidgets('restore defaults puts every key back', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('shortcut-clear-newNote')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shortcuts-restore-defaults')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shortcut-restore-defaults-yes')));
    await tester.pumpAndSettle();
    expect(AppKeyMap.current.value, KeyMap.defaults);
    expect(session.keyMapJson, '{}');
  });
}
