// #1200: the tree holds the rows its list can draw, not the rows it has
// scrolled past. A folder of 5 000 notes, in pages of 50, is walked end to end
// and back, jumped in with the keyboard, searched by name, marked across pages,
// renamed far down and written into, and at every step the tree holds the
// window's pages and every row keeps its height.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';
import 'package:niman/src/ui/visible_tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

/// How many notes the long folder holds, and how many a page does.
const int _notes = 5000;
const int _pageSize = 50;

/// A note's file name, the way the long folder names them: ordered by name
/// as by number.
String _name(int i) => 'n${i.toString().padLeft(4, '0')}.md';

void main() {
  late FakeLibrarySession session;
  late TreePages pages;
  late _Calls calls;
  late ValueNotifier<Set<String>> expanded;
  late ValueNotifier<TreeCreate?> creating;
  late ValueNotifier<TreeRename?> renaming;

  setUp(() {
    session = FakeLibrarySession();
    pages = TreePages(pageSize: _pageSize);
    calls = _Calls();
    expanded = ValueNotifier<Set<String>>(const <String>{});
    creating = ValueNotifier<TreeCreate?>(null);
    renaming = ValueNotifier<TreeRename?>(null);
  });

  tearDown(() async {
    expanded.dispose();
    creating.dispose();
    renaming.dispose();
    await session.close();
    await session.dispose();
  });

  /// Opens the library with the notes `n0000` to `n4999` in [folder] ('' the
  /// root), after a folder `Zulu` that leads the root when it is the root.
  Future<void> seed({String folder = ''}) async {
    await session.open('/lib', create: false);
    if (folder.isEmpty) {
      await session.createFolder(parentPath: '', name: 'Zulu');
    } else {
      await session.createFolder(parentPath: '', name: folder);
    }
    for (var i = 0; i < _notes; i++) {
      await session.createNote(
        parentPath: folder,
        name: _name(i).replaceAll('.md', ''),
      );
    }
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: Listenable.merge([expanded, creating, renaming]),
            builder: (context, _) => NoteTree(
              controller: session,
              pages: pages,
              selectedPath: null,
              expanded: expanded.value,
              creating: creating.value,
              renaming: renaming.value,
              onToggle: (_) {},
              onSelect: (_) {},
              onSecondaryTapDown: (note, details) {},
              onMarkedMenu: (paths, _) => calls.menus.add(paths),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The list's scroll: its first scrollable, a field in a row having its own.
  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('note-tree-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;

  /// Where the row showing [name] begins.
  double rowTop(WidgetTester tester, String name) => tester
      .getTopLeft(
        find.ancestor(of: noteRow(name), matching: find.byType(InkWell)).first,
      )
      .dy;

  /// The row's height: the tests run on a touch surface.
  double rowHeight(WidgetTester tester) =>
      TreeRowMetrics.of(tester.element(find.byType(NoteTree))).height;

  /// Presses the keys of [letters], within a second of one another, and lets
  /// the jump they ask the index for land.
  Future<void> type(WidgetTester tester, String letters) async {
    for (final letter in letters.split('')) {
      await tester.sendKeyEvent(switch (letter) {
        'n' => LogicalKeyboardKey.keyN,
        '0' => LogicalKeyboardKey.digit0,
        '3' => LogicalKeyboardKey.digit3,
        '4' => LogicalKeyboardKey.digit4,
        _ => throw ArgumentError(letter),
      });
    }
    await tester.pumpAndSettle();
  }

  /// Whether the keyboard's ring is drawn on the row showing [name].
  bool ringOn(WidgetTester tester, String name) {
    final container = find
        .ancestor(of: noteRow(name), matching: find.byType(Container))
        .first;
    final decoration = tester.widget<Container>(container).foregroundDecoration;
    return decoration is BoxDecoration && decoration.border != null;
  }

  // The window is the viewport and the list's cache extent on both sides, 300
  // and two times 250 pixels of rows of 40: twenty rows, two pages at most,
  // and a page either side that a keyset read starts from.
  const window = 4;

  testWidgets('scrolled to the end and back, it holds the window and no more', (
    tester,
  ) async {
    await seed();
    await pump(tester);
    expect(pages.pageCount, lessThanOrEqualTo(window));
    final scroll = position(tester);

    // A page at a time down to the end: the pages passed are let go.
    var reads = session.pageCalls + session.atCalls;
    while (scroll.pixels < scroll.maxScrollExtent) {
      scroll.jumpTo(scroll.pixels + _pageSize * rowHeight(tester));
      await tester.pumpAndSettle();
      expect(pages.pageCount, lessThanOrEqualTo(window));
    }
    expect(noteRow(_name(_notes - 1)), findsOneWidget);
    // Each page was read once on the way down, and not the whole folder.
    reads = session.pageCalls + session.atCalls - reads;
    expect(reads, lessThanOrEqualTo(_notes ~/ _pageSize + 1));

    // And a jump straight back to the top reads the page it lands on alone.
    final before = session.pageCalls + session.atCalls;
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(noteRow(_name(0)), findsOneWidget);
    expect(pages.pageCount, lessThanOrEqualTo(window));
    expect(session.pageCalls + session.atCalls - before, 1);
  });

  testWidgets('End jumps to the last row and the cursor lands on it', (
    tester,
  ) async {
    await seed();
    await pump(tester);
    await tester.tap(noteRow('Zulu'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(noteRow(_name(_notes - 1)), findsOneWidget);
    expect(ringOn(tester, _name(_notes - 1)), isTrue);
    expect(pages.pageCount, lessThanOrEqualTo(window));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Zulu'), isTrue);
    expect(position(tester).pixels, 0);
  });

  testWidgets('typing a name jumps to a row in a page that is not loaded', (
    tester,
  ) async {
    await seed();
    await pump(tester);
    await tester.tap(noteRow('Zulu'));
    await tester.pumpAndSettle();
    expect(noteRow(_name(3000)), findsNothing);

    await type(tester, 'n3000');

    expect(noteRow(_name(3000)), findsOneWidget);
    expect(ringOn(tester, _name(3000)), isTrue);
    expect(pages.pageCount, lessThanOrEqualTo(window));
  });

  testWidgets('Shift+click across pages marks the rows between', (
    tester,
  ) async {
    await seed();
    await pump(tester);
    await tester.tap(noteRow(_name(0)));
    await tester.pumpAndSettle();

    // Two and a half pages down, where the first row's page is gone.
    position(tester).jumpTo(120 * rowHeight(tester));
    await tester.pumpAndSettle();
    expect(pages.hasPage((VisibleTree.rootId, 0)), isFalse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(noteRow(_name(120)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    await tester.tap(noteRow(_name(120)), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.menus, hasLength(1));
    expect(calls.menus.single.toSet(), {
      for (var i = 0; i <= 120; i++) _name(i),
    });
    expect(pages.pageCount, lessThanOrEqualTo(window));
  });

  testWidgets('a rename far down brings its row into view', (tester) async {
    await seed();
    await pump(tester);
    expect(noteRow(_name(4000)), findsNothing);

    renaming.value = (
      path: _name(4000),
      submit: (name) async => null,
      cancel: () => renaming.value = null,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tree-rename-field')), findsOneWidget);
    expect(position(tester).pixels, greaterThan(3000 * rowHeight(tester)));
    expect(pages.pageCount, lessThanOrEqualTo(window));
  });

  testWidgets('a row made in a long folder keeps every row its height', (
    tester,
  ) async {
    await seed(folder: 'docs');
    expanded.value = {'docs'};
    await pump(tester);
    final height = rowHeight(tester);

    creating.value = (
      folder: 'docs',
      isDir: false,
      initial: 'fresh',
      submit: (name) async => null,
      cancel: () => creating.value = null,
    );
    await tester.pumpAndSettle();

    final create = find.byKey(const Key('tree-create-row'));
    expect(create, findsOneWidget);
    expect(tester.getSize(create).height, height);
    // The row made sits right under its folder's, and the folder's first
    // note right under it: nothing is taller than a row.
    expect(tester.getTopLeft(create).dy - rowTop(tester, 'docs'), height);
    expect(rowTop(tester, _name(0)) - tester.getTopLeft(create).dy, height);
    expect(rowTop(tester, _name(1)) - rowTop(tester, _name(0)), height);
    expect(rowTop(tester, _name(2)) - rowTop(tester, _name(1)), height);
  });
}

final class _Calls {
  final menus = <List<String>>[];
}
