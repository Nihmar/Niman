import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/trash.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

/// A [FilePickerPlatform] stub: [directory] is what
/// `getDirectoryPath` returns (`null` = the user canceled).
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

/// The text input of whichever dialog is open (the note editor is a text
/// field too, so the unscoped finder is ambiguous in the shell).
Finder dialogField() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

/// The tree row (not the detail pane) showing [name].
///
/// `skipOffstage: false` because a pushed screen (trash, settings) covers
/// the shell; the tree keeps rebuilding underneath and must stay reachable.
Finder noteRow(String name) => find.descendant(
  of: find.byType(NoteTree, skipOffstage: false),
  matching: find.text(name, skipOffstage: false),
  skipOffstage: false,
);

/// Pumps enough fake time for streams/dialogs to settle and snackbars to
/// auto-dismiss.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(seconds: 1));
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

  Widget buildApp([LibrarySession? session]) {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(session ?? controller),
      ],
      child: const CopistApp(),
    );
  }

  testWidgets('open, create, rename, and move work end to end', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    // The open/create screen is the entry point.
    expect(find.text('Open existing'), findsOne);
    expect(find.text('Create new'), findsOne);

    // "Create new": the native picker resolves a parent folder, then the
    // name dialog names the library.
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);

    // The shell is up with an empty tree.
    expect(find.text('No notes yet'), findsOne);
    expect(controller.root, '/fake/library');

    // Create a note.
    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(dialogField(), 'First note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('First note.md'), findsOne);

    // The detail pane gets the absolute path (DB rows carry only the
    // library-relative one).
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      '/fake/library/First note.md',
    );

    // Create a folder, expand it, and add a nested note.
    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump();
    await tester.enterText(dialogField(), 'Docs');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Docs'), findsOne);

    await tester.tap(noteRow('Docs')); // select + expand
    await settle(tester);

    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(dialogField(), 'Nested');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Nested.md'), findsOne);

    // Rename the folder; the subtree follows.
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(dialogField(), 'Books');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Books'), findsOne);
    expect(noteRow('Docs'), findsNothing);

    // Move the nested note to the library root.
    await tester.tap(noteRow('Books')); // expand the renamed folder
    await settle(tester);
    await tester.tap(noteRow('Nested.md'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.drive_folder_upload));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.tap(find.text('Library root'));
    await tester.pump();
    await tester.tap(find.text('Move'));
    await settle(tester);
    expect(noteRow('Nested.md'), findsOne);
    expect(noteRow('Books/Nested.md'), findsNothing);
    expect(
      (await controller.folders()).map((note) => note.path),
      containsAll(<String>['Books']),
    );

    await controller.close();
    await controller.dispose();
  });

  testWidgets('trash: delete, restore, then hard delete with the toggle off', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOne);

    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(dialogField(), 'Sacrifice');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // Delete into trash (default toggle: on).
    await tester.tap(noteRow('Sacrifice.md'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Sacrifice.md'), findsNothing);
    expect(find.text('No notes yet'), findsOne);
    expect((await controller.ops!.trashItems()).length, 1);

    // Restore it from the trash screen.
    await tester.tap(find.byKey(const Key('open-trash')));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byType(TrashScreen),
        matching: find.text('Sacrifice.md'),
      ),
      findsOne,
    );
    await tester.tap(find.byTooltip('Restore'));
    await settle(tester);
    expect(find.text('Trash is empty'), findsOne);
    expect(noteRow('Sacrifice.md'), findsOne);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // Delete again, then permanently remove it from the trash: the dialog
    // must name the item, and the confirm path must work.
    await tester.tap(noteRow('Sacrifice.md'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Sacrifice.md'), findsNothing);

    await tester.tap(find.byKey(const Key('open-trash')));
    await settle(tester);
    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pump();
    expect(
      find.text('Sacrifice.md will be deleted permanently (no restore)'),
      findsOne,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(find.text('Trash is empty'), findsOne);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // Switch the trash toggle off in settings.
    await tester.tap(find.byKey(const Key('open-settings')));
    await settle(tester);
    expect(find.text('Deletions move to .trash/ (off = hard delete)'), findsOne);
    final trashRow = find.ancestor(
      of: find.text('Deletions move to .trash/ (off = hard delete)'),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(
      find.descendant(of: trashRow, matching: find.byType(Switch)),
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // Recreate the note, then delete it with the toggle off: hard delete.
    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(dialogField(), 'Sacrifice');
    await tester.tap(find.text('OK'));
    await settle(tester);

    await tester.tap(noteRow('Sacrifice.md'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Sacrifice.md'), findsNothing);
    expect(find.text('No notes yet'), findsOne);
    expect(await controller.ops!.trashItems(), isEmpty);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('emptying the trash says what it deletes', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);

    // A note in the trash, so the empty action is offered.
    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(dialogField(), 'Victim');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(noteRow('Victim.md'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('open-trash')));
    await settle(tester);
    await tester.tap(find.byTooltip('Empty trash'));
    await tester.pump();
    expect(
      find.text(
        'This deletes everything in the trash folder permanently, '
        'including items Copist did not put there.',
      ),
      findsOne,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Empty'));
    await settle(tester);
    expect(find.text('Trash is empty'), findsOne);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('the move picker does not offer a folder as its own target',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);

    // Outer > Inner.
    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump();
    await tester.enterText(dialogField(), 'Outer');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(noteRow('Outer'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump();
    await tester.enterText(dialogField(), 'Inner');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // The picker for Outer must not offer Outer, and it must not offer
    // Outer/Inner either: a folder cannot move into its own subtree.
    await tester.tap(noteRow('Outer'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.drive_folder_upload));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    expect(find.byType(DropdownMenuItem<String>), findsOne);
    expect(find.text('Library root'), findsOne);
    expect(find.text('Outer/Inner'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('open existing picks a folder and opens it', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    filePicker.directory = '/fake/library';
    await tester.tap(find.text('Open existing'));
    await settle(tester);

    expect(find.text('No notes yet'), findsOne);
    expect(controller.root, '/fake/library');

    await controller.close();
    await controller.dispose();
  });

  testWidgets('canceling the pickers stays on the open screen', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    // Cancel the directory picker itself.
    filePicker.directory = null;
    await tester.tap(find.text('Open existing'));
    await settle(tester);
    expect(find.text('Open existing'), findsOne);

    // Then cancel the name dialog after a successful parent pick.
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Open existing'), findsOne);

    await controller.dispose();
  });

  testWidgets('a 10k-note tree renders lazily', (tester) async {
    await controller.open('/fake/library', create: true);
    await controller.seedNotes(10000);
    await tester.pumpWidget(buildApp());
    await settle(tester);

    // The visible window renders immediately... (no timeout, no jank).
    expect(find.text('note_0.md'), findsOne);
    // ...and the far end of the list is not materialized.
    expect(find.text('note_9999.md'), findsNothing);
    final materialized = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => text.data?.startsWith('note_') ?? false)
        .length;
    expect(materialized, greaterThan(0));
    expect(materialized, lessThan(100));

    await controller.close();
    await controller.dispose();
  });

  testWidgets('a fresh controller resumes the persisted library', (
    tester,
  ) async {
    // Simulated previous run: a session opened the library.
    final previous = FakeLibrarySession();
    await previous.open('/fake/library', create: true);
    expect(previous.phase, LibraryPhase.ready);
    await previous.dispose();

    // Simulated restart: a new session remembers the last library.
    final session = FakeLibrarySession(resumePath: '/fake/library');
    await tester.pumpWidget(buildApp(session));
    await settle(tester);

    // It resumes straight into the shell, skipping the open screen.
    expect(find.text('Open existing'), findsNothing);
    expect(find.text('No notes yet'), findsOne);

    await session.close();
    await session.dispose();
  });

  testWidgets('phone width: notes open full-screen, back returns to tree',
      (tester) async {
    // Phone-sized surface (390 x 844 logical).
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pump();

    // Open a library.
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOne);

    // Creating a note opens it full-screen.
    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(dialogField(), 'Phone');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Phone.md'), findsOneWidget); // app bar title.
    expect(noteRow('Phone.md'), findsNothing);

    // Back returns to the tree; the selection is kept.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);
    expect(noteRow('Phone.md'), findsOne);

    // Tapping the note opens it again.
    await tester.tap(noteRow('Phone.md'));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
  });
}
