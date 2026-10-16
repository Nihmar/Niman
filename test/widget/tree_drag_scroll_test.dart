// #1071: a row dragged in the tree scrolls the list at its edges and opens
// the closed folder it dwells on, closing it again if the drop lands
// elsewhere.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:niman/src/ui/tree_drag.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  /// The tree over [notes] root notes and the folders `docs` (holding
  /// `inner.md`) and `other`, every drop recorded; the folders open as the
  /// tree asks.
  Future<List<String>> pump(WidgetTester tester, {int notes = 0}) async {
    final moves = <String>[];
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'docs');
    await session.createFolder(parentPath: '', name: 'other');
    await session.createNote(parentPath: 'docs', name: 'inner', content: 'y');
    for (var i = 0; i < notes; i++) {
      await session.createNote(
        parentPath: '',
        name: 'note${i.toString().padLeft(3, '0')}',
        content: 'x',
      );
    }
    final expanded = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NoteTree(
              controller: session,
              selectedPath: null,
              expanded: expanded,
              onToggle: (path) => setState(() {
                if (!expanded.remove(path)) expanded.add(path);
              }),
              onSelect: (_) {},
              onMove: (paths, folder) =>
                  moves.addAll([for (final path in paths) '$path -> $folder']),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return moves;
  }

  /// Presses the mouse on [row] and drags it to [to]; the gesture is left
  /// held for the test to dwell and let go.
  Future<TestGesture> grab(WidgetTester tester, String row, Offset to) async {
    final start = tester.getCenter(find.text(row));
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(Offset.lerp(start, to, step / 10)!);
      await tester.pump();
    }
    return mouse;
  }

  double offset(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byKey(const Key('note-tree-list')),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .pixels;

  /// Lets [duration] pass in frames, as a held drag does.
  Future<void> dwell(WidgetTester tester, Duration duration) async {
    for (var left = duration; left > Duration.zero;) {
      const step = Duration(milliseconds: 50);
      await tester.pump(step);
      left -= step;
    }
  }

  testWidgets('a drag held at the bottom edge scrolls the list', (
    tester,
  ) async {
    await pump(tester, notes: 60);
    expect(offset(tester), 0);
    final bottom = tester.getBottomLeft(find.byType(ListView));
    final mouse = await grab(tester, 'docs', bottom + const Offset(60, -8));
    expect(TreeRowDrag.active.value, isTrue);
    await dwell(tester, const Duration(seconds: 1));
    final scrolled = offset(tester);
    expect(scrolled, greaterThan(100));
    // Further from the edge's border it goes slower: back out of the zone
    // and it stops.
    await mouse.moveTo(bottom + const Offset(60, -200));
    await tester.pump();
    await dwell(tester, const Duration(milliseconds: 200));
    final stopped = offset(tester);
    await dwell(tester, const Duration(milliseconds: 300));
    expect(offset(tester), stopped);
    // And near the top it comes back.
    final top = tester.getTopLeft(find.byType(ListView));
    await mouse.moveTo(top + const Offset(60, 6));
    await tester.pump();
    await dwell(tester, const Duration(seconds: 1));
    expect(offset(tester), lessThan(stopped));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(TreeRowDrag.active.value, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a drag far from the edges leaves the list where it is', (
    tester,
  ) async {
    await pump(tester, notes: 60);
    final middle = tester.getCenter(find.byType(ListView));
    final mouse = await grab(tester, 'docs', middle);
    await dwell(tester, const Duration(seconds: 1));
    expect(offset(tester), 0);
    await mouse.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a dwell on a closed folder opens it', (tester) async {
    final moves = await pump(tester, notes: 2);
    expect(find.text('inner.md'), findsNothing);
    final mouse = await grab(
      tester,
      'note000.md',
      tester.getCenter(find.text('docs')),
    );
    await dwell(tester, const Duration(milliseconds: 300));
    expect(find.text('inner.md'), findsNothing, reason: 'not yet');
    await dwell(tester, const Duration(milliseconds: 500));
    expect(find.text('inner.md'), findsOneWidget);
    // Dropped inside the folder it opened: it stays open.
    await mouse.moveTo(tester.getCenter(find.text('inner.md')));
    await tester.pump();
    await mouse.up();
    await tester.pumpAndSettle();
    expect(moves, ['note000.md -> docs']);
    expect(find.text('inner.md'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a folder opened by a drag closes if the drop lands elsewhere', (
    tester,
  ) async {
    final moves = await pump(tester, notes: 2);
    final mouse = await grab(
      tester,
      'note000.md',
      tester.getCenter(find.text('docs')),
    );
    await dwell(tester, const Duration(milliseconds: 800));
    expect(find.text('inner.md'), findsOneWidget);
    await mouse.moveTo(tester.getCenter(find.text('other')));
    await tester.pump();
    await mouse.up();
    await tester.pumpAndSettle();
    expect(moves, ['note000.md -> other']);
    expect(find.text('inner.md'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('passing over a folder without a dwell opens nothing', (
    tester,
  ) async {
    await pump(tester, notes: 2);
    final mouse = await grab(
      tester,
      'note000.md',
      tester.getCenter(find.text('docs')),
    );
    await dwell(tester, const Duration(milliseconds: 300));
    await mouse.moveTo(tester.getCenter(find.text('other')));
    await tester.pump();
    await dwell(tester, const Duration(seconds: 1));
    expect(find.text('inner.md'), findsNothing);
    await mouse.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a tile dragged to the edge of the grid scrolls it', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    for (var i = 0; i < 120; i++) {
      await session.createNote(
        parentPath: '',
        name: 'note${i.toString().padLeft(3, '0')}',
        content: 'x',
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderGrid(
            controller: session,
            folder: '',
            sort: TreeSort.nameAsc,
            selectedPath: null,
            onOpen: (_) {},
            onGoTo: (_) {},
            onUp: () {},
            onMove: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final grid = find.byKey(const Key('folder-grid-scroll'));
    double pixels() => tester
        .state<ScrollableState>(
          find.descendant(of: grid, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(pixels(), 0);
    final start = tester.getCenter(
      find.byKey(const Key('grid-tile-note000.md')),
    );
    final bottom = tester.getBottomLeft(grid);
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(
        Offset.lerp(start, bottom + const Offset(60, -8), step / 10)!,
      );
      await tester.pump();
    }
    await dwell(tester, const Duration(seconds: 1));
    expect(pixels(), greaterThan(100));
    await mouse.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
