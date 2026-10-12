// The folder grid in the shell (#727): the List | Grid switch in the
// footer and in the phone's sort menu, the grid starting in the tree's
// selection and writing its folder back, the phone's Back walking up, and
// the rename in place on a tile.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;
  late FakeFilePicker filePicker;

  setUp(() {
    session = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Widget app() => ProviderScope(
    overrides: [librarySessionProvider.overrideWithValue(session)],
    child: const NimanApp(),
  );

  Future<void> openShell(
    WidgetTester tester, {
    Size size = const Size(1200, 900),
  }) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(app());
    await tester.pump();
    await openLibrary(tester, filePicker);
    await settle(tester);
  }

  /// The folder the grid itself is showing.
  String gridFolder(WidgetTester tester) =>
      tester.widget<FolderGrid>(find.byType(FolderGrid)).folder;

  testWidgets('the footer pair switches the pane and remembers it', (
    tester,
  ) async {
    await openShell(tester);
    expect(find.byType(NoteTree), findsOne);
    expect(find.byType(FolderGrid), findsNothing);
    expect(await session.treeView, TreeView.list);

    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    expect(find.byType(FolderGrid), findsOne);
    expect(find.byType(NoteTree), findsNothing);
    expect(await session.treeView, TreeView.grid);

    await tester.tap(find.byKey(const Key('view-list-toggle')));
    await settle(tester);
    expect(find.byType(NoteTree), findsOne);
    expect(await session.treeView, TreeView.list);
  });

  testWidgets("the grid starts in the tree's selected folder", (tester) async {
    await openShell(tester);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    await settle(tester);

    // Clicking a folder row selects it (and leaves the note pane alone).
    await tester.tap(noteRow('Projects'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    expect(gridFolder(tester), 'Projects');
    expect(find.byKey(const Key('grid-tile-Projects/Roadmap.md')), findsOne);
  });

  testWidgets('entering a folder in the grid opens it in the tree', (
    tester,
  ) async {
    await openShell(tester);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    await settle(tester);

    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('grid-tile-Projects')));
    await settle(tester);
    expect(gridFolder(tester), 'Projects');

    // Back to the tree: the folder is selected and expanded there.
    await tester.tap(find.byKey(const Key('view-list-toggle')));
    await settle(tester);
    expect(find.byType(NoteTree), findsOne);
    expect(noteRow('Projects'), findsOne);
    expect(noteRow('Roadmap.md'), findsOne);
  });

  testWidgets('the phone switches the view from the sort menu', (tester) async {
    await openShell(tester, size: const Size(390, 844));
    expect(find.byType(NoteTree), findsOne);

    await tester.tap(find.byKey(const Key('toggle-sort')));
    await settle(tester);
    expect(find.text('VIEW'), findsOne);
    expect(find.byKey(const Key('view-list')), findsOne);
    expect(find.byKey(const Key('view-grid')), findsOne);
    await tester.tap(find.byKey(const Key('view-grid')));
    await settle(tester);

    expect(find.byType(FolderGrid), findsOne);
    expect(await session.treeView, TreeView.grid);
  });

  testWidgets("the phone's Back walks up one folder", (tester) async {
    await openShell(tester, size: const Size(390, 844));
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    await settle(tester);
    await tester.tap(find.byKey(const Key('toggle-sort')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-grid')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('grid-tile-Projects')));
    await settle(tester);
    expect(gridFolder(tester), 'Projects');

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(gridFolder(tester), '');
  });

  testWidgets('the footer drops the New label in a narrow pane', (
    tester,
  ) async {
    await session.setTreeWidth(200);
    await openShell(tester);

    expect(find.byKey(const Key('new-item-menu')), findsOne);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('F2 renames a tile in place, as a tree row', (tester) async {
    // In-place rename is a Linux/Windows shape (#707); the platform is
    // overridden so the app builds one and the desktop path runs here.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await openShell(tester);
      await session.createNote(parentPath: '', name: 'Ideas');
      await settle(tester);
      await tester.tap(find.byKey(const Key('view-grid-toggle')));
      await settle(tester);

      // Open the note (a tile click selects it) and rename it with F2.
      await tester.tap(find.byKey(const Key('grid-tile-Ideas.md')));
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await settle(tester);
      expect(find.byKey(const Key('tree-rename-field')), findsOne);

      await tester.enterText(
        find.byKey(const Key('tree-rename-field')),
        'Roadmap',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(await session.find('Roadmap.md'), isNotNull);
      expect(find.byKey(const Key('tree-rename-field')), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets("the switch starts in the tree's selection every time", (
    tester,
  ) async {
    await openShell(tester);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createFolder(parentPath: '', name: 'Archive');
    await settle(tester);

    await tester.tap(noteRow('Projects'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    expect(gridFolder(tester), 'Projects');

    // Back to the list, another folder selected: the grid follows it, not
    // the folder it held last time.
    await tester.tap(find.byKey(const Key('view-list-toggle')));
    await settle(tester);
    await tester.tap(noteRow('Archive'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    expect(gridFolder(tester), 'Archive');
  });

  testWidgets('a middle click and Ctrl+click open a note in its own tab', (
    tester,
  ) async {
    await openShell(tester);
    for (final name in ['alpha', 'bravo', 'charlie']) {
      await session.createNote(parentPath: '', name: name);
    }
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);

    List<String> tabs() => [for (final tab in session.workspace.tabs) tab.path];

    await tester.tap(find.byKey(const Key('grid-tile-alpha.md')));
    await settle(tester);
    expect(tabs(), ['alpha.md']);

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('grid-tile-bravo.md'))),
      buttons: kMiddleMouseButton,
    );
    await settle(tester);
    expect(tabs(), ['alpha.md', 'bravo.md']);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('grid-tile-charlie.md')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(tabs(), ['alpha.md', 'bravo.md', 'charlie.md']);
  });

  testWidgets('the background menu makes a folder in the folder shown', (
    tester,
  ) async {
    await openShell(tester);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    await settle(tester);

    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('grid-tile-Projects')));
    await settle(tester);
    expect(gridFolder(tester), 'Projects');

    // The empty space below the tiles is the folder shown.
    final grid = tester.getRect(find.byKey(const Key('folder-grid-scroll')));
    await tester.tapAt(
      Offset(grid.center.dx, grid.bottom - 20),
      buttons: kSecondaryMouseButton,
    );
    await settle(tester);
    expect(find.byKey(const Key('tree-menu-new-folder')), findsOneWidget);
    expect(
      find.text(AppStrings.exportFolderTitle),
      findsOneWidget,
      reason: "the folder's export, not the library's",
    );

    await tester.tap(find.byKey(const Key('tree-menu-new-folder')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Nested',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
    expect(await session.find('Projects/Nested'), isNotNull);
    expect(
      await session.find('Nested'),
      isNull,
      reason: 'inside the folder shown',
    );
  });
}
