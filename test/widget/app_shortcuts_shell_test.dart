// T-PP-10: the shell installs the registry over the desktop layout, so a
// registered accelerator reaches the same command its button does.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/shell.dart';
import 'package:niman/src/ui/shell_navigation.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeShortcutService shortcuts;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    shortcuts = FakeShortcutService();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        shortcutServiceProvider.overrideWithValue(shortcuts),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> close() async {
    await controller.close();
    await controller.dispose();
    await shortcuts.dispose();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  int? railIndex(WidgetTester tester) =>
      tester.widget<ShellRail>(find.byType(ShellRail)).selectedIndex;

  testWidgets('Ctrl+2 selects the Todo tab and Ctrl+1 returns', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    expect(railIndex(tester), ShellTab.files.index);

    await press(tester, LogicalKeyboardKey.digit2);
    expect(railIndex(tester), ShellTab.todo.index);

    // The tab switch unfocuses the search field; the shell has to be
    // focusable again or this second accelerator would go nowhere.
    await press(tester, LogicalKeyboardKey.digit1);
    expect(railIndex(tester), ShellTab.files.index);
    await close();
  });

  testWidgets('Ctrl+N opens the new-note dialog', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await press(tester, LogicalKeyboardKey.keyN);
    expect(find.text('New note'), findsWidgets);
    await close();
  });

  testWidgets("Ctrl+Shift+J makes today's journal entry and opens it (#7)", (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    const journal = JournalSettings();
    final path = journal.entryPath(journal.today(DateTime.now()));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(controller.contentOf(path), startsWith('# '));
    expect(find.text(path.split('/').last.replaceAll('.md', '')), findsWidgets);
    await close();
  });
}
