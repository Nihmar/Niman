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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/quick_note_tab.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/todo_tab.dart';

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

  int? railIndex(WidgetTester tester) =>
      tester.widget<ShellRail>(find.byType(ShellRail)).selectedIndex;

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
    expect(railIndex(tester), 0);
    expect(find.text('No notes yet'), findsOne);
  });

  testWidgets('wide: the rail foot opens the library switcher', (tester) async {
    await pumpWide(tester);

    // Not a destination: it opens a screen and leaves the selection
    // where it was (#170).
    await tester.tap(railDest('library'));
    await settle(tester);

    expect(find.byType(SwitchLibraryScreen), findsOne);

    // Back out: the rail is where it was. The pushed route takes the
    // shell offstage, so the selection is checked after returning.
    await tester.tap(find.backButton());
    await settle(tester);
    expect(railIndex(tester), 0);
  });

  testWidgets('wide: the rail todo shows the list inline, rail stays', (
    tester,
  ) async {
    await pumpWide(tester);

    await tester.tap(railDest('todo'));
    await settle(tester);

    expect(find.byType(TodoTab), findsOne);
    expect(find.byKey(const Key('shell-rail')), findsOne);
    expect(railIndex(tester), 1);
  });

  testWidgets('wide: the rail settings show inline, then back to files', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);

    await tester.tap(railDest('settings'));
    await settle(tester);
    expect(find.text(AppStrings.settingsSectionAppearance), findsOne);
    expect(find.byKey(const Key('shell-rail')), findsOne);

    await tester.tap(railDest('files'));
    await settle(tester);
    expect(noteRow('Docs'), findsOne);
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

  testWidgets('wide: the layout menu switches split and single', (
    tester,
  ) async {
    await pumpWide(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    // Auto on wide = side by side, so no editor/preview eye toggle. (The
    // note body itself still loads off-isolate, which the fake session
    // cannot drive — the eye toggle is the load-independent signal of
    // the effective layout.)
    expect(find.byKey(const Key('layout-mode')), findsOne);
    expect(find.byKey(const Key('editor-preview-toggle')), findsNothing);

    await tester.tap(find.byKey(const Key('layout-mode')));
    // No pumpAndSettle here: the note body still shows its loading
    // spinner, which animates forever.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(AppStrings.previewModeSwitch));
    await settle(tester);

    expect(find.byKey(const Key('editor-preview-toggle')), findsOne);
    expect(await controller.previewMode, PreviewLayoutMode.fullScreen);

    await tester.tap(find.byKey(const Key('layout-mode')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(AppStrings.previewModeAuto));
    await settle(tester);

    expect(find.byKey(const Key('editor-preview-toggle')), findsNothing);
    expect(await controller.previewMode, PreviewLayoutMode.auto);
  });

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

  testWidgets('wide: opening a search result flips the rail to files', (
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

    // The rail is back on Files: the search pane is kept alive but no
    // longer on screen (the wide bodies stay mounted, T-PP-22), the tree
    // is showing and the note is open in the detail pane next to it.
    expect(find.byType(SearchScreen).hitTestable(), findsNothing);
    expect(noteRow('alpha.md'), findsOne);
    expect(railIndex(tester), 0);
  });
}
