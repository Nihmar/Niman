// T-SC-03..07: a launcher quick action lands on the flow its in-app
// control uses, on a warm start (the tap stream) and on a cold one (the
// launch action the shell consumes when it mounts).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeShortcutService shortcuts;
  late FakeFilePicker filePicker;

  setUp(() {
    AppLanguages.reset();
    controller = FakeLibrarySession();
    shortcuts = FakeShortcutService();
    filePicker = useFakeFilePicker();
  });

  tearDown(AppLanguages.reset);

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

  testWidgets('the four actions are published in order at start', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(shortcuts.published, {
      ShortcutAction.quickNote: AppStrings.shortcutQuickNote,
      ShortcutAction.newTodo: AppStrings.shortcutNewTodo,
      ShortcutAction.newNote: AppStrings.shortcutNewNote,
      ShortcutAction.newList: AppStrings.shortcutNewList,
    });
    expect(
      shortcuts.published!.keys.toList(),
      ShortcutAction.values,
      reason: 'the launcher ranks by publish order',
    );
    await close();
  });

  // 2026-09-10 device report: the launcher's shortcuts kept answering in
  // the system's language. Their labels are strings like any other, and
  // they were published before the stored language had been read — so
  // the launcher was handed whatever the app spoke before the choice
  // landed, on every launch.
  testWidgets('the labels are in the language the app is set to', (
    tester,
  ) async {
    await controller.setLanguage(AppLanguage.italian);
    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(shortcuts.published![ShortcutAction.quickNote], 'Nota rapida');
    expect(AppStrings.shortcutQuickNote, 'Nota rapida');
    await close();
  });

  testWidgets('changing the language republishes them', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    expect(shortcuts.published![ShortcutAction.quickNote], 'Quick note');

    AppLanguages.choice = AppLanguage.italian;
    await settle(tester);
    expect(shortcuts.published![ShortcutAction.quickNote], 'Nota rapida');
    await close();
  });

  testWidgets('New note opens the new-note dialog and creates', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    shortcuts.emit(ShortcutAction.newNote);
    await settle(tester);
    expect(find.text('New note'), findsWidgets);

    await tester.enterText(dialogField(), 'From a shortcut');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('From a shortcut.md'), isNotNull);
    await close();
  });

  testWidgets('New list creates a type: list note in the list folder', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    shortcuts.emit(ShortcutAction.newList);
    await settle(tester);
    await tester.enterText(dialogField(), 'Packing');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(await controller.ops!.find('Lists/Packing.md'), isNotNull);
    expect(controller.contentOf('Lists/Packing.md'), '---\ntype: list\n---\n');
    await close();
  });

  testWidgets('New todo opens the add-task dialog', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    shortcuts.emit(ShortcutAction.newTodo);
    await settle(tester);
    expect(find.text(AppStrings.todoAddTitle), findsOneWidget);
    expect(find.byKey(const Key('todo-dialog-field')), findsOneWidget);
    await close();
  });

  testWidgets('Quick note lands on the chooser (phone tab)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    shortcuts.emit(ShortcutAction.quickNote);
    await settle(tester);
    // No quick note is set yet, so the tab shows its choose/create
    // screen.
    expect(find.byKey(const Key('quick-note-choose')), findsOneWidget);
    await close();
  });

  testWidgets('Quick note lands on the chooser (wide screen)', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    shortcuts.emit(ShortcutAction.quickNote);
    await settle(tester);
    // The tab does not exist on a wide layout, so the chooser is pushed
    // as its own screen instead of the action landing nowhere.
    expect(find.byKey(const Key('quick-note-choose')), findsOneWidget);
    await close();
  });

  testWidgets('a CLI flag runs the same flow as its launcher twin', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          shortcutServiceProvider.overrideWith(
            (ref) => CliShortcutService(ShortcutAction.newTodo),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await settle(tester);

    expect(find.text(AppStrings.todoAddTitle), findsOneWidget);
    expect(find.byKey(const Key('todo-dialog-field')), findsOneWidget);
    await close();
  });

  testWidgets('a cold start runs the action once the shell mounts', (
    tester,
  ) async {
    shortcuts.launchAction = ShortcutAction.newList;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    await settle(tester);

    await tester.enterText(dialogField(), 'Cold start');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('Lists/Cold start.md'), isNotNull);
    await close();
  });
}
