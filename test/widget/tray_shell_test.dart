// T-PP-06b: a tray quick action runs the same flow its launcher twin
// runs, and an icon click brings the window back to the front.
import 'package:copist/src/app.dart';
import 'package:copist/src/core/shortcuts.dart';
import 'package:copist/src/core/tray.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/window_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/fake_tray_service.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeShortcutService shortcuts;
  late FakeTrayService tray;
  late FakeWindowController window;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    shortcuts = FakeShortcutService();
    tray = FakeTrayService();
    window = FakeWindowController();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        shortcutServiceProvider.overrideWithValue(shortcuts),
        trayServiceProvider.overrideWithValue(tray),
        windowControllerProvider.overrideWithValue(window),
      ],
      child: const CopistApp(),
    );
  }

  Future<void> close() async {
    await controller.close();
    await controller.dispose();
    await shortcuts.dispose();
    await tray.dispose();
  }

  testWidgets('the tray is offered the four actions at start', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(tray.labels, {
      ShortcutAction.quickNote: AppStrings.shortcutQuickNote,
      ShortcutAction.newTodo: AppStrings.shortcutNewTodo,
      ShortcutAction.newNote: AppStrings.shortcutNewNote,
      ShortcutAction.newList: AppStrings.shortcutNewList,
    });
    expect(
      tray.labels!.keys.toList(),
      ShortcutAction.values,
      reason: 'the menu ranks by init order',
    );
    await close();
  });

  testWidgets('a tray action lands on the flow its twin uses', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    tray.emit(ShortcutAction.newNote);
    await settle(tester);
    expect(find.text('New note'), findsWidgets);

    await tester.enterText(dialogField(), 'From the tray');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('From the tray.md'), isNotNull);
    await close();
  });

  testWidgets('a tray new-todo lands on the add-task dialog', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    tray.emit(ShortcutAction.newTodo);
    await settle(tester);
    expect(find.text(AppStrings.todoAddTitle), findsOneWidget);
    await close();
  });

  testWidgets('an icon click brings the window back', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    tray.activate();
    await tester.pump();
    expect(window.showCalls, 1);
    await close();
  });
}
