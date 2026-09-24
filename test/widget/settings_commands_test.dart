// #207: the Commands page lists every command the palette can run, with
// its keys and when it shows, from the table the palette is filtered by.
// #264: it says it is a reference, and its keys lead to where they change.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  late bool wasAttached;
  setUp(() {
    wasAttached = KeyboardPresence.shared.attached;
    KeyboardPresence.shared.attached = true;
  });
  tearDown(() => KeyboardPresence.shared.attached = wasAttached);

  Future<void> pump(
    WidgetTester tester, {
    void Function(AppCommand? command)? openShortcuts,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsCommandsScreen(openShortcuts: openShortcuts)),
    );
    await tester.pumpAndSettle();
  }

  Finder inRow(AppCommand command, Finder matching) => find.descendant(
    of: find.byKey(commandRowKey(command)),
    matching: matching,
  );

  testWidgets('every command has its row', (tester) async {
    await pump(tester);
    for (final command in AppCommand.values) {
      expect(find.byKey(commandRowKey(command)), findsOne, reason: '$command');
    }
  });

  testWidgets('each row says when its command shows', (tester) async {
    await pump(tester);
    expect(
      inRow(AppCommand.renameNote, find.text(AppStrings.commandNeedOpenNote)),
      findsOne,
    );
    expect(
      inRow(AppCommand.tabFiles, find.text(AppStrings.commandNeedNone)),
      findsOne,
    );
    // Two needs, both said.
    expect(
      inRow(
        AppCommand.splitRight,
        find.textContaining(AppStrings.commandNeedWideWindow),
      ),
      findsOne,
    );
    expect(
      inRow(
        AppCommand.splitRight,
        find.textContaining(AppStrings.commandNeedNotInZen),
      ),
      findsOne,
    );
  });

  testWidgets('a row shows its keys, and follows a change', (tester) async {
    await pump(tester);
    final keys = AppKeyMap.current.value.bindingOf(AppCommand.openPalette)!;
    expect(
      inRow(AppCommand.openPalette, find.text(describeActivator(keys))),
      findsOne,
    );
    final before = AppKeyMap.current.value;
    addTearDown(() => AppKeyMap.current.value = before);
    AppKeyMap.current.value = before.withBinding(AppCommand.openPalette, null);
    await tester.pump();
    expect(
      inRow(AppCommand.openPalette, find.text(describeActivator(keys))),
      findsNothing,
    );
  });

  testWidgets('the page says its keys come from Keyboard shortcuts', (
    tester,
  ) async {
    final opened = <AppCommand?>[];
    await pump(tester, openShortcuts: opened.add);
    expect(find.text(AppStrings.commandsKeysNote), findsOne);
    await tester.tap(find.byKey(const Key('commands-open-shortcuts')));
    expect(opened, [null]);
  });

  testWidgets('a keycap opens that command in Keyboard shortcuts', (
    tester,
  ) async {
    final opened = <AppCommand?>[];
    await pump(tester, openShortcuts: opened.add);
    final keycap = find.byKey(
      Key('command-keys-${AppCommand.openPalette.name}'),
    );
    await tester.ensureVisible(keycap);
    await tester.tap(keycap);
    expect(opened, [AppCommand.openPalette]);
  });

  testWidgets('with nowhere to go, the keys are only shown', (tester) async {
    await pump(tester);
    expect(find.text(AppStrings.commandsKeysNote), findsOne);
    expect(find.byKey(const Key('commands-open-shortcuts')), findsNothing);
    expect(
      find.byKey(Key('command-keys-${AppCommand.openPalette.name}')),
      findsNothing,
    );
  });

  testWidgets('without a keyboard, no word about keys', (tester) async {
    KeyboardPresence.shared.attached = false;
    await pump(tester, openShortcuts: (_) {});
    expect(find.text(AppStrings.commandsKeysNote), findsNothing);
    expect(find.byKey(const Key('commands-open-shortcuts')), findsNothing);
  });
}
