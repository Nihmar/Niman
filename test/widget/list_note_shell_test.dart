// T-TK-06/07: the FAB's "New list note" mini — creates a `type: list`
// note in the configured folder (default `Lists/`, re-targetable via the
// library setting) and opens it.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

/// A [FilePickerPlatform] stub: [directory] is what
/// getDirectoryPath returns (null = the user canceled).
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

/// The tree row (not the detail pane) showing [name].
Finder noteRow(String name) => find.descendant(
      of: find.byType(NoteTree),
      matching: find.text(name),
    );

/// Pumps enough fake time for streams/dialogs to settle and snackbars to
/// auto-dismiss.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(seconds: 1));
}

/// Animates the FAB menu to its resting state (the minis take 150 ms).
Future<void> settleFabMenu(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late FakeLibrarySession controller;
  late _FakeFilePicker filePicker;
  late FilePickerPlatform previousPicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = _FakeFilePicker();
    previousPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = filePicker;
  });

  tearDown(() {
    FilePickerPlatform.instance = previousPicker;
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const CopistApp(),
    );
  }

  /// Opens a library at /fake/library through the "Create new" flow.
  Future<void> openLibrary(WidgetTester tester) async {
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);
  }

  testWidgets('the FAB expands into note, folder and list-note actions', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(find.byKey(const Key('new-note-action')), findsOneWidget);
    expect(find.byKey(const Key('new-folder-action')), findsOneWidget);
    expect(find.byKey(const Key('new-list-note-action')), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('New list note creates a type: list note under Lists/', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-list-note-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(dialogField(), 'Groceries');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // The configured folder was created and the note landed in it.
    expect(await controller.ops!.find('Lists'), isNotNull);
    final note = await controller.ops!.find('Lists/Groceries.md');
    expect(note, isNotNull);
    expect(
      controller.contentOf('Lists/Groceries.md'),
      '---\ntype: list\n---\n',
    );
    // Expand Lists/ in the tree: the created note row is there.
    await tester.tap(noteRow('Lists'));
    await settle(tester);
    expect(noteRow('Groceries.md'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('changing the list folder re-targets creation', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await controller.ops!.setListNoteFolder(folder: 'Checklists');

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-list-note-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Second');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(await controller.ops!.find('Checklists'), isNotNull);
    expect(await controller.ops!.find('Checklists/Second.md'), isNotNull);
    expect(await controller.ops!.find('Lists'), isNull);

    await controller.close();
    await controller.dispose();
  });
}
