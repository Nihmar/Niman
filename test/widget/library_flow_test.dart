import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/trash.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

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

  setUp(() {
    controller = FakeLibrarySession();
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

    await tester.enterText(find.byType(TextField), '/fake/library');
    await tester.tap(find.text('Create new'));
    await settle(tester);

    // The shell is up with an empty tree.
    expect(find.text('No notes yet'), findsOne);
    expect(controller.root, '/fake/library');

    // Create a note.
    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'First note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('First note.md'), findsOne);

    // Create a folder, expand it, and add a nested note.
    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Docs');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Docs'), findsOne);

    await tester.tap(noteRow('Docs')); // select + expand
    await settle(tester);

    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Nested');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Nested.md'), findsOne);

    // Rename the folder; the subtree follows.
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Books');
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
    await tester.enterText(find.byType(TextField), '/fake/library');
    await tester.tap(find.text('Create new'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOne);

    await tester.tap(find.byIcon(Icons.note_add));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Sacrifice');
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

    // Switch the trash toggle off in settings.
    await tester.tap(find.byKey(const Key('open-settings')));
    await settle(tester);
    expect(find.text('Deletions move to .trash/ (off = hard delete)'), findsOne);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // Delete again: now a hard delete.
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
}
