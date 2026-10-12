// The folder grid (#727): the folder's children as tiles, the breadcrumb
// above them, and the ways a tile is opened, entered and renamed.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/tree.dart' show TreeRename;

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() {
    session = FakeLibrarySession();
  });
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  /// A bare [FolderGrid] over [session], with the callbacks recorded.
  ///
  /// [width] draws it in a pane that narrow — the sidebar's own minimum,
  /// near enough — so the breadcrumb's fold can be asked for.
  Widget gridFor({
    String folder = '',
    TreeSort sort = TreeSort.nameAsc,
    String? selectedPath,
    double? width,
    bool active = true,
    void Function(Note)? onOpen,
    ValueChanged<String>? onGoTo,
    VoidCallback? onUp,
    void Function(Note, Rect?)? onLongPress,
    void Function(Note, TapDownDetails)? onSecondaryTapDown,
    Future<void> Function(String, TapUpDetails)? onBackgroundSecondaryTapUp,
    void Function(Note)? onOpenInNewTab,
    ValueChanged<String>? onFolderResolved,
    ValueChanged<String>? onRename,
    ValueChanged<String>? onDelete,
    TreeRename? renaming,
  }) {
    final grid = FolderGrid(
      controller: session,
      folder: folder,
      sort: sort,
      selectedPath: selectedPath,
      active: active,
      onOpen: onOpen ?? (_) {},
      onGoTo: onGoTo ?? (_) {},
      onUp: onUp ?? () {},
      onLongPress: onLongPress,
      onSecondaryTapDown: onSecondaryTapDown,
      onBackgroundSecondaryTapUp: onBackgroundSecondaryTapUp,
      onOpenInNewTab: onOpenInNewTab,
      onFolderResolved: onFolderResolved,
      onRename: onRename,
      onDelete: onDelete,
      renaming: renaming,
    );
    return MaterialApp(
      home: Scaffold(
        body: width == null
            ? grid
            : Align(
                child: SizedBox(width: width, child: grid),
              ),
      ),
    );
  }

  testWidgets("the grid draws the folder's children, folders first", (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Meetings');
    await session.createNote(parentPath: '', name: 'Ideas');
    await session.createNote(parentPath: '', name: 'alpha');

    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grid-tile-Meetings')), findsOneWidget);
    expect(find.byKey(const Key('grid-tile-Ideas.md')), findsOneWidget);
    expect(find.byKey(const Key('grid-tile-alpha.md')), findsOneWidget);
    expect(find.text('Ideas.md'), findsOneWidget);
    expect(find.text('alpha.md'), findsOneWidget);
    // A folder tile leads a note tile.
    expect(
      tester.getTopLeft(find.byKey(const Key('grid-tile-Meetings'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('grid-tile-Ideas.md'))).dx,
      ),
    );
  });

  testWidgets('a tap opens a note and enters a folder', (tester) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Meetings');
    await session.createNote(parentPath: '', name: 'Ideas');
    Note? opened;
    await tester.pumpWidget(gridFor(onOpen: (note) => opened = note));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('grid-tile-Ideas.md')));
    expect(opened?.name, 'Ideas.md');
    await tester.tap(find.byKey(const Key('grid-tile-Meetings')));
    expect(opened?.name, 'Meetings');
    expect(opened?.isDir, isTrue);
  });

  testWidgets('the breadcrumb walks up and straight to a folder', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createFolder(parentPath: 'Projects', name: 'Niman');
    await session.createNote(parentPath: 'Projects/Niman', name: 'Roadmap');

    final opened = <String>[];
    var ups = 0;
    await tester.pumpWidget(
      gridFor(folder: 'Projects/Niman', onGoTo: opened.add, onUp: () => ups++),
    );
    await tester.pumpAndSettle();

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Niman'), findsOneWidget);
    await tester.tap(find.byKey(const Key('folder-up')));
    expect(ups, 1);
    await tester.tap(find.text('Projects'));
    expect(opened, ['Projects']);
    expect(
      find.byKey(const Key('grid-tile-Projects/Niman/Roadmap.md')),
      findsOneWidget,
    );
  });

  testWidgets('Up is disabled at the root, not hidden', (tester) async {
    await session.open('/lib', create: false);
    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(
      find.byKey(const Key('folder-up')),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const Key('folder-up')), findsOneWidget);
  });

  testWidgets('an empty folder invites a note', (tester) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Meetings');
    await tester.pumpWidget(gridFor(folder: 'Meetings'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing in Meetings yet'), findsOneWidget);
    expect(find.text('Tap + to make a note or a folder here.'), findsOneWidget);
  });

  testWidgets('a note is marked selected, its tile only', (tester) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'Ideas');
    await session.createNote(parentPath: '', name: 'alpha');
    await tester.pumpWidget(gridFor(selectedPath: 'Ideas.md'));
    await tester.pumpAndSettle();

    final selected =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byKey(const Key('grid-tile-Ideas.md')),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration?;
    expect(selected?.color, isNotNull);
  });

  testWidgets('the date is the field the folder is sorted by', (tester) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'Ideas');
    session.setNoteMetrics(
      'Ideas.md',
      modified: DateTime(2026, 1, 2),
      created: DateTime(2026, 3, 4),
    );

    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();
    expect(find.text('2026-01-02'), findsOneWidget);

    await tester.pumpWidget(gridFor(sort: TreeSort.createdAsc));
    await tester.pumpAndSettle();
    expect(find.text('2026-03-04'), findsOneWidget);
  });

  testWidgets('a pinned note wears a filled pin', (tester) async {
    await session.open('/lib', create: false);
    await session.createNote(
      parentPath: '',
      name: 'Roadmap',
      content: '---\npinned: true\n---\nbody',
    );
    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('grid-tile-Roadmap.md')),
        matching: find.byIcon(Icons.push_pin),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an OCR sidecar follows its file, dimmed', (tester) async {
    await session.open('/lib', create: false);
    await session.seedFile('scan.pdf');
    await session.seedFile('scan.pdf.ocr.md');
    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grid-tile-scan.pdf')), findsOneWidget);
    expect(find.byKey(const Key('grid-tile-scan.pdf.ocr.md')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('grid-tile-scan.pdf.ocr.md')),
        matching: find.byIcon(Icons.document_scanner_outlined),
      ),
      findsOneWidget,
    );
    // The sidecar sits right after its file.
    expect(
      tester.getTopLeft(find.byKey(const Key('grid-tile-scan.pdf'))).dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('grid-tile-scan.pdf.ocr.md')))
            .dx,
      ),
    );
  });

  testWidgets('a folder takes the keys, and the arrows walk the tiles', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    // Folders lead the tiles: Zulu takes the keys above the notes.
    await session.createFolder(parentPath: '', name: 'Zulu');
    await session.createNote(parentPath: '', name: 'alpha');
    await session.createNote(parentPath: '', name: 'bravo');
    final opened = <String>[];
    await tester.pumpWidget(gridFor(onOpen: (note) => opened.add(note.name)));
    await tester.pumpAndSettle();

    // A folder's click takes the keys for the walk (#727).
    await tester.tap(find.byKey(const Key('grid-tile-Zulu')));
    await tester.pumpAndSettle();
    expect(opened, ['Zulu']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, ['Zulu', 'alpha.md']);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'Zulu');
  });

  testWidgets('a click on a note tile leaves the keyboard where it is', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'alpha');
    await session.createNote(parentPath: '', name: 'bravo');
    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();

    // A note opens for writing: the grid must not hold the keys it takes
    // for the walk, or the note could not be typed into (#727).
    await tester.tap(find.byKey(const Key('grid-tile-alpha.md')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'nothing took the arrow, and nothing renamed',
    );
  });

  testWidgets('F2 and Delete act on the cursor', (tester) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Zulu');
    await session.createNote(parentPath: '', name: 'alpha');
    final renamed = <String>[];
    final deleted = <String>[];
    await tester.pumpWidget(
      gridFor(onRename: renamed.add, onDelete: deleted.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('grid-tile-Zulu')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    expect(renamed, ['alpha.md']);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(deleted, ['alpha.md']);
  });

  testWidgets("a long press offers the tile's own menu", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await session.open('/lib', create: false);
      await session.createNote(parentPath: '', name: 'alpha');
      Note? pressed;
      await tester.pumpWidget(
        gridFor(onLongPress: (note, _) => pressed = note),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('grid-tile-alpha.md')));
      await tester.pumpAndSettle();
      expect(pressed?.name, 'alpha.md');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('rename in place lays the tree field over the tile', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'alpha');
    String? submitted;
    var cancelled = 0;
    await tester.pumpWidget(
      gridFor(
        renaming: (
          path: 'alpha.md',
          submit: (name) async {
            submitted = name;
            return null;
          },
          cancel: () => cancelled++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('tree-rename-field'));
    expect(field, findsOneWidget);
    // Wider than a tile, so a name can be read as it is typed.
    expect(tester.getSize(field).width, greaterThanOrEqualTo(200));
    await tester.enterText(field, 'Roadmap');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(submitted, 'Roadmap');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(cancelled, 0);
  });

  testWidgets('a narrow pane folds the middle crumbs into a menu', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createFolder(parentPath: 'Projects', name: 'Niman');
    await session.createFolder(parentPath: 'Projects/Niman', name: 'Docs');
    final opened = <String>[];
    await tester.pumpWidget(
      gridFor(folder: 'Projects/Niman/Docs', width: 220, onGoTo: opened.add),
    );
    await tester.pumpAndSettle();

    // The root and the folder shown stay; the middle folds away.
    expect(find.byKey(const Key('crumbs-more')), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Docs'), findsOneWidget);
    expect(find.text('Projects'), findsNothing);

    await tester.tap(find.byKey(const Key('crumbs-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crumb-Projects/Niman')), findsOneWidget);
    await tester.tap(find.byKey(const Key('crumb-Projects/Niman')));
    await tester.pumpAndSettle();
    expect(opened, ['Projects/Niman']);
  });

  testWidgets('a folder that is gone falls back to the nearest that is not', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    String? resolved;
    await tester.pumpWidget(
      gridFor(
        folder: 'Projects/Gone',
        onFolderResolved: (path) => resolved = path,
      ),
    );
    await tester.pumpAndSettle();

    expect(resolved, 'Projects');
    expect(
      find.byKey(const Key('grid-tile-Projects/Roadmap.md')),
      findsOneWidget,
    );
  });

  testWidgets('the empty space answers for the folder shown, a tile itself', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    final background = <String>[];
    final tileMenu = <String>[];
    await tester.pumpWidget(
      gridFor(
        folder: 'Projects',
        onSecondaryTapDown: (note, _) => tileMenu.add(note.path),
        onBackgroundSecondaryTapUp: (folder, _) async => background.add(folder),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('grid-tile-Projects/Roadmap.md'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(tileMenu, ['Projects/Roadmap.md']);
    expect(background, isEmpty, reason: 'a tile keeps its own menu');

    // Below the tiles, inside the viewport: the folder shown is "here".
    final grid = tester.getRect(find.byKey(const Key('folder-grid-scroll')));
    await tester.tapAt(
      Offset(grid.center.dx, grid.bottom - 20),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(background, ['Projects']);
  });

  testWidgets('a modified key is left to the app accelerators', (tester) async {
    await session.open('/lib', create: false);
    // The grid shows Projects, with a folder of its own to take the keys
    // from, and a parent to go up to.
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createFolder(parentPath: 'Projects', name: 'Zulu');
    await session.createNote(parentPath: 'Projects', name: 'alpha');
    await session.createNote(parentPath: 'Projects', name: 'bravo');
    final opened = <String>[];
    var ups = 0;
    await tester.pumpWidget(
      gridFor(
        folder: 'Projects',
        onOpen: (note) => opened.add(note.path),
        onUp: () => ups++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('grid-tile-Projects/Zulu')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    opened.clear();

    // Ctrl+Shift+PageDown is the journal's, Alt+Right the notes'
    // history: the walk must not shadow either (#23).
    await sendWithModifiers(tester, LogicalKeyboardKey.pageDown, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
    ]);
    await sendWithModifiers(tester, LogicalKeyboardKey.arrowRight, [
      LogicalKeyboardKey.altLeft,
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, ['Projects/bravo.md'], reason: 'the cursor did not move');

    // Alt+Up is the pane's own way up, and keeps its key.
    await sendWithModifiers(tester, LogicalKeyboardKey.arrowUp, [
      LogicalKeyboardKey.altLeft,
    ]);
    expect(ups, 1);
  });

  testWidgets('a middle click opens a note in a tab of its own', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'alpha');
    final tabs = <String>[];
    await tester.pumpWidget(gridFor(onOpenInNewTab: (n) => tabs.add(n.path)));
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('grid-tile-alpha.md'))),
      buttons: kMiddleMouseButton,
    );
    await tester.pumpAndSettle();
    expect(tabs, ['alpha.md']);
  });

  testWidgets('a hidden grid does not re-read its folder on a revision', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'alpha');
    await tester.pumpWidget(gridFor(active: false));
    await tester.pumpAndSettle();
    final reads = session.childrenCalls;

    // A revision that adds a row: the pane on screen would read again.
    await session.createNote(parentPath: '', name: 'bravo');
    await tester.pumpAndSettle();
    expect(session.childrenCalls, reads, reason: 'hidden, nothing asks again');

    await tester.pumpWidget(gridFor());
    await tester.pumpAndSettle();
    expect(session.childrenCalls, greaterThan(reads));
  });
}
