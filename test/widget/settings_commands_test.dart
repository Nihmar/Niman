// #207: the Commands page lists every command the palette can run, with
// its keys and when it shows, from the table the palette is filtered by.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsCommandsScreen()));
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
}
