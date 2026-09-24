import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/trash.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp([LibrarySession? session]) {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(session ?? controller),
      ],
      child: const NimanApp(),
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
    // Joined the way the app joins it: the create flow and the shell both
    // use `p.join`, which spells the separator the host spells it, so a
    // hard-coded '/' would be asserting about Linux from Windows.
    expect(controller.root, p.join('/fake', 'library'));

    // Create a note via the create affordance (T-UI-05).
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await tester.pump();
    await tester.enterText(dialogField(), 'First note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('First note.md', offstage: true), findsOne);

    // The detail pane gets the absolute path (DB rows carry only the
    // library-relative one).
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      p.join('/fake', 'library', 'First note.md'),
    );

    // Seed a root folder (no row to long-press yet), then use its context
    // menu for the nested note (T-UI-05: new note/folder landmarks).
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    expect(noteRow('Docs', offstage: true), findsOne);

    await tester.tap(noteRow('Docs', offstage: true)); // select + expand
    await settle(tester);

    await tester.longPress(noteRow('Docs', offstage: true));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-new-note')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Nested');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Nested.md', offstage: true), findsOne);

    // Rename the folder via its context menu; the subtree follows.
    await tester.tap(noteRow('Docs', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Docs', offstage: true));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-rename')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Books');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Books', offstage: true), findsOne);
    expect(noteRow('Docs', offstage: true), findsNothing);

    // Move the nested note to the library root, expanding the renamed
    // folder to reach it.
    await tester.tap(noteRow('Books', offstage: true));
    await settle(tester);
    await tester.tap(noteRow('Nested.md', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Nested.md', offstage: true));
    await settle(tester);
    // A note's menu is longer than the test window's sheet (History sits
    // above Rename): the sheet scrolls, so scroll to the row first.
    await tester.ensureVisible(find.byKey(const Key('menu-move')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-move')));
    await settle(tester);
    await tester.tap(find.text('Library root'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('folder-picker-choose')));
    await settle(tester);
    expect(noteRow('Nested.md', offstage: true), findsOne);
    expect(noteRow('Books/Nested.md', offstage: true), findsNothing);
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

    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await tester.pump();
    await tester.enterText(dialogField(), 'Sacrifice');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // Delete into trash (default toggle: on): long-press for the menu.
    await tester.tap(noteRow('Sacrifice.md', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Sacrifice.md', offstage: true));
    await settle(tester);
    // The row sheet scrolls on short screens (it holds eight entries),
    // so the trailing delete may need bringing into view first.
    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-delete')),
      100,
      scrollable: find.ancestor(
        of: find.byKey(const Key('menu-delete')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-delete')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Sacrifice.md', offstage: true), findsNothing);
    expect(find.text('No notes yet'), findsOne);
    expect((await controller.ops!.trashItems()).length, 1);

    // Restore it from the trash screen.
    await tapTreeFooterAction(tester, find.byKey(const Key('open-trash')));
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
    expect(noteRow('Sacrifice.md', offstage: true), findsOne);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // Delete again, then permanently remove it from the trash: the dialog
    // must name the item, and the confirm path must work.
    await tester.tap(noteRow('Sacrifice.md', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Sacrifice.md', offstage: true));
    await settle(tester);
    // The row sheet scrolls on short screens (it holds eight entries),
    // so the trailing delete may need bringing into view first.
    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-delete')),
      100,
      scrollable: find.ancestor(
        of: find.byKey(const Key('menu-delete')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-delete')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Sacrifice.md', offstage: true), findsNothing);

    await tapTreeFooterAction(tester, find.byKey(const Key('open-trash')));
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

    // Switch the trash toggle off in settings, a window on a wide one
    // (#202), where the Trash area shows beside the list rather than
    // over it (#172): nothing to go back from.
    await tester.tap(find.byKey(const Key('rail-settings')));
    await settle(tester);
    final trashArea = find.byKey(const Key('settings-area-trash-history'));
    await tester.scrollUntilVisible(
      trashArea,
      100,
      scrollable: find
          .ancestor(
            of: find.byKey(const Key('settings-area-folders')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await settle(tester);
    await tester.tap(trashArea);
    await settle(tester);
    final trashRow = find.byKey(const Key('trash-setting'));
    await tester.tap(
      find.descendant(of: trashRow, matching: find.byType(Switch)),
    );
    await settle(tester);
    expect(find.backButton(), findsNothing);
    await tester.tap(find.byKey(const Key('floating-window-close')));
    await settle(tester);

    // Recreate the note, then delete it with the toggle off: hard delete.
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await tester.pump();
    await tester.enterText(dialogField(), 'Sacrifice');
    await tester.tap(find.text('OK'));
    await settle(tester);

    await tester.tap(noteRow('Sacrifice.md', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Sacrifice.md', offstage: true));
    await settle(tester);
    // The row sheet scrolls on short screens (it holds eight entries),
    // so the trailing delete may need bringing into view first.
    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-delete')),
      100,
      scrollable: find.ancestor(
        of: find.byKey(const Key('menu-delete')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-delete')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Sacrifice.md', offstage: true), findsNothing);
    expect(find.text('No notes yet'), findsOne);
    expect(await controller.ops!.trashItems(), isEmpty);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('deleting a note offers undo from the trash', (tester) async {
    // The file sits in the trash: the notice offers the way back
    // (issue #131).
    await tester.pumpWidget(buildApp());
    await tester.pump();
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);

    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await tester.pump();
    await tester.enterText(dialogField(), 'Comeback');
    await tester.tap(find.text('OK'));
    await settle(tester);

    await tester.tap(noteRow('Comeback.md', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Comeback.md', offstage: true));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-delete')),
      100,
      scrollable: find.ancestor(
        of: find.byKey(const Key('menu-delete')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-delete')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(noteRow('Comeback.md', offstage: true), findsNothing);

    await tester.tap(find.text(AppStrings.actionUndo));
    await settle(tester);
    expect(noteRow('Comeback.md', offstage: true), findsOne);
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
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await tester.pump();
    await tester.enterText(dialogField(), 'Victim');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(noteRow('Victim.md', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Victim.md', offstage: true));
    await settle(tester);
    // The row sheet scrolls on short screens (it holds eight entries),
    // so the trailing delete may need bringing into view first.
    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-delete')),
      100,
      scrollable: find.ancestor(
        of: find.byKey(const Key('menu-delete')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-delete')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    await tapTreeFooterAction(tester, find.byKey(const Key('open-trash')));
    await settle(tester);
    await tester.tap(find.byTooltip('Empty trash'));
    await tester.pump();
    expect(
      find.text(
        'This deletes everything in the trash folder permanently, '
        'including items Niman did not put there.',
      ),
      findsOne,
    );
    // The dialog's confirmation, not the app bar row behind it.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Empty'),
      ),
    );
    await settle(tester);
    expect(find.text('Trash is empty'), findsOne);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('the move picker does not offer a folder as its own target', (
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

    // Outer > Inner.
    await controller.createFolder(parentPath: '', name: 'Outer');
    await settle(tester);
    await tester.tap(noteRow('Outer', offstage: true));
    await settle(tester);
    await tester.tap(noteRow('Outer', offstage: true)); // select + expand
    await settle(tester);
    await tester.longPress(noteRow('Outer', offstage: true));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-new-folder')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Inner');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // The picker for Outer must not offer Outer, and it must not offer
    // Outer/Inner either: a folder cannot move into its own subtree.
    await tester.tap(noteRow('Outer', offstage: true));
    await settle(tester);
    await tester.longPress(noteRow('Outer', offstage: true));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-move')));
    await tester.pump();
    // Scoped to the dialog: the tree behind it still names the folder.
    Finder inPicker(String label) => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(label),
    );
    expect(inPicker('Library root'), findsOne);
    expect(inPicker('Outer'), findsNothing);
    expect(inPicker('Outer/Inner'), findsNothing);
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

  testWidgets('phone width: notes open full-screen, back returns to tree', (
    tester,
  ) async {
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
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await tester.pump();
    await tester.enterText(dialogField(), 'Phone');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Phone.md'), findsOneWidget); // app bar title.
    // The tree stays mounted under the note (T-TS-08): hidden from the
    // user, kept alive for the way back.
    expect(noteRow('Phone.md'), findsNothing);
    expect(noteRow('Phone.md', offstage: true), findsOne);

    // Back returns to the tree; the selection is kept.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);
    expect(noteRow('Phone.md', offstage: true), findsOne);

    // Tapping the note opens it again.
    await tester.tap(noteRow('Phone.md', offstage: true));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
  });
}
