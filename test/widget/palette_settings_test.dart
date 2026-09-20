// #229: the palette answers with settings rows as well, under the
// commands and the notes, and a pick opens the settings there — not on
// the home with the search to redo.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/settings_keys.dart';
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
  });

  Future<void> pumpWide(WidgetTester tester) async {
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
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), query);
    await settle(tester);
  }

  testWidgets('a setting is found, under its own heading', (tester) async {
    await pumpWide(tester);
    await search(tester, AppStrings.indentWidthTitle);

    expect(
      find.text(AppStrings.tabSettings.toUpperCase()),
      findsOne,
      reason: 'the settings group heads its own rows',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('command-palette')),
        matching: find.text(AppStrings.indentWidthTitle),
      ),
      findsWidgets,
    );
  });

  testWidgets('picking it opens the settings on that row', (tester) async {
    await pumpWide(tester);
    await search(tester, AppStrings.indentWidthTitle);

    await tester.tap(
      find
          .ancestor(
            of: find.text(AppStrings.indentWidthTitle),
            matching: find.byType(InkWell),
          )
          .last,
    );
    await settle(tester);

    expect(find.byKey(const Key('settings-window')), findsOne);
    // The Editor area opened on the right; its rows scroll, so the row
    // itself is asked for rather than assumed on screen.
    await tester.scrollUntilVisible(
      find.byKey(SettingsKeys.indentWidth),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('settings-window')),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    expect(find.byKey(SettingsKeys.indentWidth), findsOne);
  });

  testWidgets('nothing typed, no settings', (tester) async {
    await pumpWide(tester);
    await search(tester, '');
    expect(find.text(AppStrings.tabSettings.toUpperCase()), findsNothing);
  });
}
