// The folder grid (#727): the folder's children as tiles, the breadcrumb
// above them, and the ways a tile is opened, entered and renamed.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/tree.dart' show TreeRename;

import '../fakes/fake_library_session.dart';

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
  Widget gridFor({
    String folder = '',
    TreeSort sort = TreeSort.nameAsc,
    String? selectedPath,
    void Function(Note)? onOpen,
    ValueChanged<String>? onGoTo,
    VoidCallback? onUp,
    void Function(Note, Rect?)? onLongPress,
    ValueChanged<String>? onRename,
    ValueChanged<String>? onDelete,
    TreeRename? renaming,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FolderGrid(
          controller: session,
          folder: folder,
          sort: sort,
          selectedPath: selectedPath,
          onOpen: onOpen ?? (_) {},
          onGoTo: onGoTo ?? (_) {},
          onUp: onUp ?? () {},
          onLongPress: onLongPress,
          onRename: onRename,
          onDelete: onDelete,
          renaming: renaming,
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
    await session.setTreeView(TreeView.grid);
    expect(await session.treeView, TreeView.grid);
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

  testWidgets('the keyboard walks the tiles, Enter opens', (tester) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'alpha');
    await session.createNote(parentPath: '', name: 'bravo');
    final opened = <String>[];
    await tester.pumpWidget(gridFor(onOpen: (note) => opened.add(note.name)));
    await tester.pumpAndSettle();

    // A click puts the focus on the tile it opened.
    await tester.tap(find.byKey(const Key('grid-tile-alpha.md')));
    expect(opened, ['alpha.md']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['alpha.md', 'bravo.md']);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened.last, 'alpha.md');
  });

  testWidgets('F2 and Delete act on the focused tile', (tester) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'alpha');
    final renamed = <String>[];
    final deleted = <String>[];
    await tester.pumpWidget(
      gridFor(onRename: renamed.add, onDelete: deleted.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('grid-tile-alpha.md')));
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(renamed, ['alpha.md']);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
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
}
