// T-UI-02 AC: the phone/narrow layout shows the 5-tab bottom NavigationBar;
// switching tabs preserves the library state (expanded folders, selected
// note); the wide layout stays unchanged (no tab bar).
// T-UI-10 AC: the Quick note tab opens `Quick note.md` at the library root,
// creating it when missing; the Search tab is disabled until M3 (R3).
import 'package:copist/src/app.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const CopistApp(),
    );
  }

  testWidgets('phone: 5 destinations show and switching preserves state', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    expect(find.text('No notes yet'), findsOne);

    // Create a folder, expand it, and create a note inside it.
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    await tester.longPress(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-new-note')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'In note',
    );
    await tester.tap(find.text('OK'));
    await settle(tester);

    // Back to the tree (the note opened full-screen).
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // The bottom navigation bar is there with the 5 mockup destinations.
    expect(find.byType(NavigationBar), findsOne);
    for (final label in ['Files', 'Todo', 'Search', 'Quick note', 'Settings']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOne,
      );
    }

    // Go to the Settings tab and back: the tree keeps its expansion.
    await tester.tap(find.byKey(const Key('tab-settings')));
    await settle(tester);
    // The first section heading: what the settings list opens on.
    expect(find.text(AppStrings.settingsSectionAppearance), findsOne);
    await tester.tap(find.byKey(const Key('tab-files')));
    await settle(tester);
    expect(noteRow('Docs'), findsOne);
  });

  testWidgets('sort toggle flips the tree order and persists (T-UI-03)', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    // Three notes created out of alphabetical order: the tree sorts them.
    await controller.createNote(parentPath: '', name: 'charlie');
    await controller.createNote(parentPath: '', name: 'alpha');
    await controller.createNote(parentPath: '', name: 'bravo');
    await settle(tester);

    Finder row(String name) => find.descendant(
      of: find.byType(NoteTree),
      matching: find.text('$name.md'),
    );
    double topOf(String name) => tester.getCenter(row(name)).dy;

    // Ascending default.
    expect(topOf('alpha'), lessThan(topOf('bravo')));
    expect(topOf('bravo'), lessThan(topOf('charlie')));

    await tester.tap(find.byKey(const Key('toggle-sort')));
    await settle(tester);

    // Descending now; persisted in the session.
    expect(topOf('charlie'), lessThan(topOf('bravo')));
    expect(topOf('bravo'), lessThan(topOf('alpha')));
    expect(await controller.treeSort, TreeSort.nameDesc);

    // Tapping again returns to ascending.
    await tester.tap(find.byKey(const Key('toggle-sort')));
    await settle(tester);
    expect(topOf('alpha'), lessThan(topOf('charlie')));
    expect(await controller.treeSort, TreeSort.nameAsc);
  });

  testWidgets('quick note: nothing opens by default, create names the note', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Quick note'),
      ),
    );
    await settle(tester);

    // No note is opened or created on entering the tab.
    expect(
      find.text(
        'No quick note yet. Choose an existing note, or create '
        'a new one — the quick note opens here.',
      ),
      findsOne,
    );
    expect(find.byType(NoteView), findsNothing);
    expect(await controller.ops!.find('Quick note.md'), isNull);

    // Create one with a custom name.
    await tester.tap(find.byKey(const Key('quick-note-create')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Scratch pad',
    );
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Scratch pad.md'), findsOneWidget); // app bar title.
    expect(await controller.ops!.quickNotePath, 'Scratch pad.md');

    // Back returns to the Files tab (arrow behaves like any note-open).
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOne);
    expect(noteRow('Scratch pad.md'), findsOne);
  });

  testWidgets('quick note: pick an existing note from the tree', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await controller.createNote(parentPath: '', name: 'Scratch');
    await controller.createNote(parentPath: '', name: 'Other');
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Quick note'),
      ),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('quick-note-choose')));
    await settle(tester);

    // The dialog tree lists the notes; picking one sets + opens it.
    expect(find.text('Choose quick note'), findsOne);
    await tester.tap(
      find.descendant(
        of: find.byType(NoteTree),
        matching: find.text('Scratch.md'),
      ),
    );
    await settle(tester);

    expect(await controller.ops!.quickNotePath, 'Scratch.md');
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Scratch.md'), findsOneWidget); // app bar title.
  });

  testWidgets('quick note: choosing in Settings is honored by the tab', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await controller.createNote(parentPath: '', name: 'Scratch');
    await settle(tester);

    // Choose "Scratch.md" in Settings: the tile shows it after the pick.
    await tester.tap(find.byKey(const Key('tab-settings')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-note-setting')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Not set yet'), findsOne);
    // Scrolled to a known place and tapped by key rather than by its
    // subtitle: the rows above it come and go with the width (the
    // preview layout ones are hidden on a phone), so any fixed nudge is
    // wrong on some layout.
    await tester.ensureVisible(find.byKey(const Key('quick-note-setting')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('quick-note-setting')));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NoteTree),
        matching: find.text('Scratch.md'),
      ),
    );
    await settle(tester);

    expect(find.text('Scratch.md'), findsOne);
    expect(await controller.ops!.quickNotePath, 'Scratch.md');

    // The bottom-nav tile now opens the chosen note directly (no detour
    // through the tab body).
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Quick note'),
      ),
    );
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Scratch.md'), findsOneWidget); // app bar title.

    // Back from the note goes to Files, not back to the Quick note tab.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOne);
    expect(noteRow('Scratch.md'), findsOne);
  });

  testWidgets('FAB creates in the selected folder, menu offers all actions '
      '(T-UI-05)', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);

    // Select the folder: the FAB creates the note inside it.
    await tester.tap(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'In root', // created in Docs (its parent) — see below.
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('Docs/In root.md'), isNotNull);

    // Long-press the note: New note here is offered; New folder is not
    // (file row); Rename/Move/Delete are.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    await tester.longPress(noteRow('In root.md'));
    await settle(tester);
    expect(find.byKey(const Key('menu-new-note')), findsOne);
    expect(find.byKey(const Key('menu-new-folder')), findsNothing);
    expect(find.byKey(const Key('menu-rename')), findsOne);
    expect(find.byKey(const Key('menu-move')), findsOne);
    expect(find.byKey(const Key('menu-delete')), findsOne);

    // Rename through the menu.
    await tester.tap(find.byKey(const Key('menu-rename')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Renamed',
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('Docs/Renamed.md'), isNotNull);

    // Delete through the menu (trash toggle default on).
    await tester.longPress(noteRow('Renamed.md'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-delete')));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(await controller.ops!.find('Docs/Renamed.md'), isNull);
  });

  testWidgets('search tab shows the search screen (M3)', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Search'),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('search-query')), findsOne);
    expect(find.text('Type to search the library'), findsOne);

    // The tags button flips to the Tags screen and back (T-M3-06).
    await tester.tap(find.byKey(const Key('open-tags')));
    await settle(tester);
    expect(find.text('No tags yet — add a #tag or frontmatter tags'), findsOne);
    await tester.tap(find.byKey(const Key('tags-back')));
    await settle(tester);
    expect(find.byKey(const Key('search-query')), findsOne);
  });

  testWidgets('a reminder tap opens the Todo tab (T-TD-07)', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    final reminders = FakeReminderService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          reminderServiceProvider.overrideWithValue(reminders),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    expect(find.text('No notes yet'), findsOne);

    reminders.tap(todoReminderPayload);
    await settle(tester);
    expect(find.text('No open tasks yet'), findsOne);
    await reminders.dispose();
  });

  testWidgets('a tap-started app lands on the Todo tab (T-TD-07)', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    final reminders = FakeReminderService(launchPayload: todoReminderPayload);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          reminderServiceProvider.overrideWithValue(reminders),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await settle(tester);
    expect(find.text('No open tasks yet'), findsOne);
    await reminders.dispose();
  });

  testWidgets('the Todo add button creates a task (T-TD-08)', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    final reminders = FakeReminderService();
    final todos = FakeTodoSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          reminderServiceProvider.overrideWithValue(reminders),
          todoSourceFactoryProvider.overrideWithValue((_) => todos),
        ],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Todo'),
      ),
    );
    await settle(tester);
    expect(find.text('No open tasks yet'), findsOne);

    await tester.tap(find.byKey(const Key('todo-add')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('todo-dialog-field')),
      'shell task',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(find.text('shell task'), findsOneWidget);
    // The add stamps the creation date.
    expect(
      todos.todoLines.single,
      matches(RegExp(r'^\d{4}-\d{2}-\d{2} shell task$')),
    );
    await reminders.dispose();
  });

  // 2026-09-08 user feedback: Files and Todo put a `+` in the same
  // corner, so scaling one out and the next one in read as a flicker on a
  // button that never moved. Scaffold decides by comparing the FAB's key,
  // so one shared key is what keeps the slot still.
  testWidgets('the Files and Todo FABs share one Scaffold slot', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    Key? fabSlotKey() {
      final scaffold = tester.widget<Scaffold>(
        find
            .byType(Scaffold)
            .at(tester.widgetList<Scaffold>(find.byType(Scaffold)).length - 1),
      );
      return scaffold.floatingActionButton?.key;
    }

    expect(find.byKey(const Key('new-note-fab')), findsOne);
    final onFiles = fabSlotKey();
    expect(onFiles, isNotNull);

    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await settle(tester);

    // Same slot key, different button inside it.
    expect(fabSlotKey(), onFiles);
    expect(find.byKey(const Key('todo-add')), findsOne);
    expect(find.byKey(const Key('new-note-fab')), findsNothing);

    // Search has no FAB at all, and there the slot really does empty.
    await tester.tap(find.byIcon(Icons.search));
    await settle(tester);
    expect(fabSlotKey(), isNull);
  });

  testWidgets('wide layout keeps the split, with no tab bar', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    // No bottom navigation on the wide split layout.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Select a note'), findsOne);
  });
}
