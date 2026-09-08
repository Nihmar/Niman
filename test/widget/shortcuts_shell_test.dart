// T-SC-03..07: a launcher quick action lands on the flow its in-app
// control uses, on a warm start (the tap stream) and on a cold one (the
// launch action the shell consumes when it mounts).
import 'package:copist/src/app.dart';
import 'package:copist/src/core/shortcuts.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_shortcut_service.dart';

/// A [FilePickerPlatform] stub: [directory] is what getDirectoryPath
/// returns (null = the user canceled).
final class _FakeFilePicker extends FilePickerPlatform {
  String? directory;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return directory;
  }
}

/// The text input of whichever dialog is open.
Finder dialogField() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

/// Pumps enough fake time for streams and dialogs to settle.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  late FakeLibrarySession controller;
  late FakeShortcutService shortcuts;
  late _FakeFilePicker filePicker;
  late FilePickerPlatform previousPicker;

  setUp(() {
    controller = FakeLibrarySession();
    shortcuts = FakeShortcutService();
    filePicker = _FakeFilePicker();
    previousPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = filePicker;
  });

  tearDown(() {
    FilePickerPlatform.instance = previousPicker;
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        shortcutServiceProvider.overrideWithValue(shortcuts),
      ],
      child: const CopistApp(),
    );
  }

  /// Opens a library at /fake/library through the "Create new" flow.
  Future<void> openLibrary(WidgetTester tester) async {
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await settle(tester);
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
    await tester.pump();

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

  testWidgets('New note opens the new-note dialog and creates', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

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
    await openLibrary(tester);

    shortcuts.emit(ShortcutAction.newList);
    await settle(tester);
    await tester.enterText(dialogField(), 'Packing');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(await controller.ops!.find('Lists/Packing.md'), isNotNull);
    expect(
      controller.contentOf('Lists/Packing.md'),
      '---\ntype: list\n---\n',
    );
    await close();
  });

  testWidgets('New todo opens the add-task dialog', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

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
    await openLibrary(tester);

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
    await openLibrary(tester);

    shortcuts.emit(ShortcutAction.quickNote);
    await settle(tester);
    // The tab does not exist on a wide layout, so the chooser is pushed
    // as its own screen instead of the action landing nowhere.
    expect(find.byKey(const Key('quick-note-choose')), findsOneWidget);
    await close();
  });

  testWidgets('a cold start runs the action once the shell mounts', (
    tester,
  ) async {
    shortcuts.launchAction = ShortcutAction.newList;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);
    await settle(tester);

    await tester.enterText(dialogField(), 'Cold start');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('Lists/Cold start.md'), isNotNull);
    await close();
  });
}
