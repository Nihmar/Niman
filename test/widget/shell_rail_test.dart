// T-PP-14 AC: the wide layout shows a fixed left rail mirroring the
// narrow bottom bar — same 5 tabs, same routing — instead of the
// tab-less tree+detail shell; Todo/Search/Settings render inline and
// opening a search result flips the rail back to Files with the note in
// the detail pane. Sizes are explicit per test (wide = 1200x900).
//
// Since #170 the rail is 48 px and icons only, so the destinations are
// found by key: their labels are tooltips, not text on screen.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/home/home_screen.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/quick_note_tab.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/todo_tab.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
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
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> pumpWide(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  // The rail is icons only now (#170): the label is the tooltip, so the
  // destinations are found by key rather than by text on screen.
  Finder railDest(String name) => find.byKey(Key('rail-$name'));

  ShellTab railIndex(WidgetTester tester) =>
      tester.widget<ShellRail>(find.byType(ShellRail)).current;

  testWidgets('wide: the fixed rail shows the same 5 tabs, no bottom bar', (
    tester,
  ) async {
    await pumpWide(tester);

    expect(find.byKey(const Key('shell-rail')), findsOne);
    expect(find.byType(NavigationBar), findsNothing);
    for (final name in ['files', 'todo', 'search', 'quicknote', 'settings']) {
      expect(railDest(name), findsOne);
    }
    // No labels on screen: the rail is 48 px of icons, and the names
    // live in the tooltips.
    expect(
      find.descendant(
        of: find.byKey(const Key('shell-rail')),
        matching: find.text(AppStrings.tabFiles),
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const Key('shell-rail'))).width,
      ShellRail.width,
    );
    // The library switcher sits at its foot, below the destinations.
    expect(railDest('library'), findsOne);
    expect(
      tester.getCenter(railDest('library')).dy,
      greaterThan(tester.getCenter(railDest('quicknote')).dy),
    );
    // Files is selected and the tree is showing.
    expect(railIndex(tester), ShellTab.files);
    expect(find.text('No notes yet'), findsOne);
  });

  // #712: the rail's tooltips name the key that selects the destination,
  // and follow a remap, so the tip cannot point at a key that does
  // nothing.
  testWidgets('wide: the rail tooltips carry the keys bound now (#712)', (
    tester,
  ) async {
    final previous = AppKeyMap.current.value;
    addTearDown(() => AppKeyMap.current.value = previous);
    await pumpWide(tester);

    IconButton files() => tester.widget<IconButton>(railDest('files'));
    expect(files().tooltip, contains('Ctrl+1'));

    AppKeyMap.current.value = previous.withBinding(
      AppCommand.tabFiles,
      const SingleActivator(LogicalKeyboardKey.keyB, alt: true),
    );
    await tester.pump();
    expect(files().tooltip, contains('Alt+B'));
  });

  // #203: a floating window, like Settings, and not a destination: the
  // selection stays where it was.
  testWidgets('wide: the rail foot opens the library window', (tester) async {
    await pumpWide(tester);

    await tester.tap(railDest('library'));
    await settle(tester);
    final window = find.byKey(const Key('library-window'));
    expect(window, findsOne);
    expect(find.byType(SwitchLibraryScreen), findsNothing);
    expect(
      find.descendant(
        of: window,
        matching: find.byKey(const Key('library-window-close-library')),
      ),
      findsOne,
    );
    expect(railIndex(tester), ShellTab.files);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(window, findsNothing);
    expect(find.byKey(const Key('shell-rail')), findsOne);
  });

  testWidgets('wide: Close library from the library window goes back to '
      'the opening screen, window and all', (tester) async {
    await pumpWide(tester);
    await tester.tap(railDest('library'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('library-window-close-library')));
    await settle(tester);
    expect(find.byType(ShellRail), findsNothing, reason: 'the library closed');
    expect(find.byKey(const Key('library-window')), findsNothing);
    expect(find.byKey(const Key('create-library')), findsOne);
  });

  testWidgets('wide: a new library from the library window opens it', (
    tester,
  ) async {
    await pumpWide(tester);
    await tester.tap(railDest('library'));
    await settle(tester);
    filePicker.directory = '/elsewhere';
    await tester.tap(find.byKey(const Key('library-window-create')));
    await settle(tester);
    await tester.enterText(dialogField(), 'second');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await settle(tester);
    expect(find.byKey(const Key('library-window')), findsNothing);
    expect(find.byType(ShellRail), findsOne);
    // Joined with `p.join`, as the app joins it: the host's separator.
    expect(controller.root, p.join('/elsewhere', 'second'));
  });

  testWidgets('wide: a library opened from disk in the library window is '
      'switched to', (tester) async {
    await pumpWide(tester);
    await tester.tap(railDest('library'));
    await settle(tester);
    filePicker.directory = '/other';
    await tester.tap(find.byKey(const Key('library-window-open')));
    await settle(tester);
    expect(find.byKey(const Key('library-window')), findsNothing);
    expect(controller.root, '/other');
  });

  testWidgets('wide: the rail todo opens a pane tab, tree and rail stay', (
    tester,
  ) async {
    await pumpWide(tester);

    await tester.tap(railDest('todo'));
    await settle(tester);

    Offstage contentPane(String name) =>
        tester.widget<Offstage>(find.byKey(Key('content-pane-$name')));

    // The Todo rail entry is a content destination (#712): the list is
    // the pane's body, the tree and the rail stay, and the pinned tab
    // carries a chip in the row above the panes.
    expect(find.byType(TodoTab), findsOne);
    expect(contentPane('todo').offstage, isFalse);
    expect(find.byKey(const Key('shell-rail')), findsOne);
    expect(find.byKey(const Key('tree-island')), findsOne);
    expect(find.byKey(const Key('panes-island')), findsOne);
    expect(find.byKey(const Key('content-tab-todo')), findsOne);
    // The pinned tab is a [TabSurface] like the note tabs (#712): showing
    // takes the surface and the focused pane's outline.
    final chip = tester.widget<TabSurface>(
      find.byKey(const Key('content-tab-todo')),
    );
    expect(chip.selected, isTrue, reason: 'the pane shows it');
    expect(chip.focused, isTrue, reason: 'its pane has the focus');
    expect(railIndex(tester), ShellTab.todo);

    // Files brings the notes back; the chip stays and brings Todo back.
    await tester.tap(railDest('files'));
    await settle(tester);
    expect(contentPane('todo').offstage, isTrue);
    expect(find.byKey(const Key('content-tab-todo')), findsOne);
    expect(
      tester
          .widget<TabSurface>(find.byKey(const Key('content-tab-todo')))
          .selected,
      isFalse,
      reason: 'nothing is showing it',
    );
    await tester.tap(find.byKey(const Key('content-tab-todo')));
    await settle(tester);
    expect(contentPane('todo').offstage, isFalse);
    expect(railIndex(tester), ShellTab.todo);

    // The ✕ closes it: no chip, Files on the rail, the tree in place.
    await tester.tap(find.byKey(const Key('content-tab-close-todo')));
    await settle(tester);
    expect(find.byKey(const Key('content-tab-todo')), findsNothing);
    expect(find.byKey(const Key('content-pane-todo')), findsNothing);
    expect(railIndex(tester), ShellTab.files);
    expect(find.byKey(const Key('tree-island')), findsOne);
  });

  testWidgets('wide: the rail home opens a pane tab, tree and rail stay', (
    tester,
  ) async {
    await pumpWide(tester);

    await tester.tap(railDest('home'));
    await settle(tester);

    Offstage contentPane(String name) =>
        tester.widget<Offstage>(find.byKey(Key('content-pane-$name')));

    expect(find.byType(HomeScreen), findsOne);
    expect(contentPane('home').offstage, isFalse);
    expect(find.byKey(const Key('tree-island')), findsOne);
    expect(find.byKey(const Key('panes-island')), findsOne);
    expect(find.byKey(const Key('content-tab-home')), findsOne);
    expect(railIndex(tester), ShellTab.home);

    // A note opened under the content tab takes the pane back: the
    // content hides, its chip stays.
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(contentPane('home').offstage, isTrue);
    expect(find.byType(NoteView), findsOne);
    expect(find.byKey(const Key('content-tab-home')), findsOne);
    expect(railIndex(tester), ShellTab.files);
  });

  // #202: a floating window over what was on screen, which it closes
  // back to; the rail keeps its selection.
  testWidgets('wide: the rail settings open a window, and close back', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);

    await tester.tap(railDest('settings'));
    await settle(tester);
    final window = find.byKey(const Key('settings-window'));
    expect(window, findsOne);
    // Two columns (#172): Appearance is listed on the left and, as the
    // first area, shown on the right.
    expect(
      find.descendant(
        of: window,
        matching: find.text(AppStrings.settingsSectionAppearance),
      ),
      findsNWidgets(2),
    );
    expect(railIndex(tester), ShellTab.files, reason: 'Files keeps the rail');
    expect(noteRow('Docs'), findsOne, reason: 'the tree is still there');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(window, findsNothing);
    expect(noteRow('Docs'), findsOne);

    await tester.tap(railDest('settings'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('floating-window-close')));
    await settle(tester);
    expect(window, findsNothing);
  });

  // #203: the library window switches and closes; the settings window
  // does not offer the same two rows again.
  testWidgets('wide: the settings window leaves switch and close to the '
      'library window', (tester) async {
    await pumpWide(tester);
    await tester.tap(railDest('settings'));
    await settle(tester);
    // The areas list is longer than the window; the maintenance group is
    // at its end.
    await tester.scrollUntilVisible(
      find.byKey(const Key('reindex-setting')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('settings-areas')),
        matching: find.byType(Scrollable),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('reindex-setting')), findsOne);
    expect(find.byKey(const Key('switch-library-setting')), findsNothing);
    expect(find.byKey(const Key('close-library-setting')), findsNothing);
  });

  testWidgets('wide: opening a tree note keeps the rail, note in detail', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);

    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    // The rail persists next to the tree, and the note opens in the
    // detail pane instead of covering the tabs (the narrow behavior).
    expect(find.byKey(const Key('shell-rail')), findsOne);
    expect(noteRow('alpha.md'), findsOne);
    expect(find.byType(NoteView), findsOne);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('wide: dragging the tree divider resizes and persists', (
    tester,
  ) async {
    await pumpWide(tester);
    expect(tester.getRect(noteTree()).width, defaultTreeWidth);

    await tester.drag(
      find.byKey(const Key('tree-divider')),
      const Offset(60, 0),
    );
    await settle(tester);

    expect(tester.getRect(noteTree()).width, defaultTreeWidth + 60);
    expect(await controller.treeWidth, defaultTreeWidth + 60);
  });

  testWidgets('wide: right-clicking a tree row opens the cursor menu', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);

    await tester.tap(noteRow('Docs'), buttons: kSecondaryMouseButton);
    await settle(tester);

    // The cursor menu, not the phone's bottom sheet: the rail stays
    // mounted underneath and the same entries show.
    expect(find.byKey(const Key('shell-rail')), findsOne);
    expect(find.byKey(const Key('menu-new-note')), findsOne);
    expect(find.byKey(const Key('menu-new-folder')), findsOne);

    await tester.tap(find.byKey(const Key('menu-new-note')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOne);
  });

  testWidgets(
    "wide: right-clicking the tree's empty space creates at the root",
    (tester) async {
      await pumpWide(tester);
      await controller.createFolder(parentPath: '', name: 'Docs');
      await settle(tester);

      // Well below the one row: the tree's background.
      final tree = tester.getRect(noteTree());
      await tester.tapAt(
        Offset(tree.center.dx, tree.top + tree.height * 0.7),
        buttons: kSecondaryMouseButton,
      );
      await settle(tester);
      expect(find.byKey(const Key('tree-menu-new-note')), findsOne);
      expect(find.byKey(const Key('tree-menu-new-folder')), findsOne);
      expect(find.byKey(const Key('menu-new-note')), findsNothing);

      await tester.tap(find.byKey(const Key('tree-menu-new-folder')));
      await settle(tester);
      expect(find.byType(AlertDialog), findsOne);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Radice',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await settle(tester);
      expect(noteRow('Radice'), findsOne, reason: 'at the root, beside Docs');
    },
  );

  testWidgets('wide: quick-note chooser is inline, rail persists', (
    tester,
  ) async {
    await pumpWide(tester);

    // No quick note set: the tab shows the choose/create screen inside
    // the shell instead of a pushed route covering the rail.
    await tester.tap(railDest('quicknote'));
    await settle(tester);

    expect(find.byType(QuickNoteTab), findsOne);
    expect(find.byKey(const Key('shell-rail')), findsOne);
  });

  testWidgets('wide: files/quicknote on the open note keeps editor state', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await controller.setQuickNotePath(path: 'alpha.md');
    await settle(tester);

    await tester.tap(railDest('quicknote'));
    await settle(tester);
    expect(find.byType(NoteView), findsOne);
    final view = tester.state(find.byType(NoteView));

    // The open note is identical on both tabs: switching must only flip
    // the rail selection, never close and reopen (the flash). The same
    // NoteView state across both taps proves nothing remounted.
    await tester.tap(railDest('files'));
    await settle(tester);
    await tester.tap(railDest('quicknote'));
    await settle(tester);

    expect(find.byType(QuickNoteTab), findsNothing);
    expect(tester.state(find.byType(NoteView)), same(view));
  });

  testWidgets('wide: a search result opens beside the results (#712)', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    controller.searchHits = [
      const SearchHit(
        noteId: 0,
        path: 'alpha.md',
        title: 'alpha',
        snippet: 'first',
      ),
    ];
    await settle(tester);

    await tester.tap(railDest('search'));
    await settle(tester);
    expect(find.byType(SearchScreen), findsOne);

    await tester.enterText(find.byKey(const Key('search-query')), 'al');
    await settle(tester);
    await tester.tap(find.byKey(const Key('search-hit-alpha.md')));
    await settle(tester);

    // Search is a sidebar view on a wide window: the rail stays on it, the
    // results stay on screen, and the note opens in the detail pane beside
    // them. The tree is not on screen.
    expect(railIndex(tester), ShellTab.search);
    expect(find.byType(SearchScreen).hitTestable(), findsOne);
    expect(find.byKey(const Key('panes-island')), findsOne);
    expect(noteRow('alpha.md'), findsNothing);
    expect(controller.workspace.activePath, 'alpha.md');
  });

  testWidgets('wide: Files brings the tree back from the search sidebar', (
    tester,
  ) async {
    await pumpWide(tester);
    await tester.tap(railDest('search'));
    await settle(tester);
    expect(find.byType(SearchScreen), findsOne);
    expect(find.byKey(const Key('tree-footer')), findsNothing);

    await tester.tap(railDest('files'));
    await settle(tester);
    expect(find.byType(SearchScreen).hitTestable(), findsNothing);
    expect(find.byKey(const Key('tree-footer')), findsOne);
  });

  // #712: F4/Shift+F4 step the sidebar's hits while the note is on screen,
  // and the list keeps the current one marked.
  testWidgets('wide: F4 steps the search hits from the note (#712)', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await controller.createNote(parentPath: '', name: 'beta');
    controller.searchHits = [
      const SearchHit(
        noteId: 0,
        path: 'alpha.md',
        title: 'alpha',
        snippet: 'x',
      ),
      const SearchHit(noteId: 0, path: 'beta.md', title: 'beta', snippet: 'x'),
    ];
    await settle(tester);

    await tester.tap(railDest('search'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('search-query')), 'al');
    await settle(tester);

    bool marked(String path) =>
        tester.widget<ListTile>(find.byKey(Key('search-hit-$path'))).selected;

    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
    expect(railIndex(tester), ShellTab.search, reason: 'the list stays');
    expect(marked('alpha.md'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await settle(tester);
    expect(controller.workspace.activePath, 'beta.md');
    expect(marked('beta.md'), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
  });

  // #769: a note tab clicked with the search sidebar showing switches the
  // note, not the sidebar: the hits stay, and F4 still steps them.
  testWidgets('wide: a note tab leaves the search sidebar on screen (#769)', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await controller.createNote(parentPath: '', name: 'beta');
    await controller.createNote(parentPath: '', name: 'gamma');
    controller.searchHits = [
      const SearchHit(
        noteId: 0,
        path: 'alpha.md',
        title: 'alpha',
        snippet: 'x',
      ),
      const SearchHit(noteId: 0, path: 'beta.md', title: 'beta', snippet: 'x'),
      const SearchHit(
        noteId: 0,
        path: 'gamma.md',
        title: 'gamma',
        snippet: 'x',
      ),
    ];
    await settle(tester);
    // Two tabs, the second opened with Ctrl from the tree.
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(find.byKey(const Key('note-tab-1')), findsOne);

    await tester.tap(railDest('search'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('search-query')), 'al');
    await settle(tester);
    await tester.tap(find.byKey(const Key('search-hit-beta.md')));
    await settle(tester);
    expect(controller.workspace.activePath, 'beta.md');

    await tester.tap(find.byKey(const Key('note-tab-0')));
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
    expect(railIndex(tester), ShellTab.search);
    expect(find.byType(SearchScreen).hitTestable(), findsOne);
    expect(find.byKey(const Key('tree-footer')), findsNothing);

    // The steps continue from the hit last opened, beta.
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await settle(tester);
    expect(controller.workspace.activePath, 'gamma.md');
  });

  // #712: Ctrl+Shift+F shows the sidebar and puts the cursor in its field,
  // from wherever the window was.
  testWidgets('wide: Ctrl+Shift+F gives the search field the focus (#712)', (
    tester,
  ) async {
    await pumpWide(tester);
    await tester.tap(railDest('search'));
    await settle(tester);
    await tester.tap(railDest('files'));
    await settle(tester);
    expect(find.byType(SearchScreen).hitTestable(), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);

    expect(railIndex(tester), ShellTab.search);
    // The field, not the screen's center: with no results there the empty
    // hint does not take a hit, and the field is what the ask is about.
    expect(find.byKey(const Key('search-query')).hitTestable(), findsOne);
    expect(find.byKey(const Key('tree-island')), findsOne);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('search-query')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });
}
