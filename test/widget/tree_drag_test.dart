// #567: a note or a folder dragged in the tree moves where it is dropped —
// into a folder, into a note's folder, into the root — and nowhere it
// cannot go.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('a drop moves only where it changes something', () {
    expect(treeDropMoves('a.md', 'docs'), isTrue);
    expect(treeDropMoves('docs/a.md', ''), isTrue);
    expect(treeDropMoves('docs/a.md', 'docs'), isFalse, reason: 'already');
    expect(treeDropMoves('docs', 'docs'), isFalse, reason: 'itself');
    expect(treeDropMoves('docs', 'docs/sub'), isFalse, reason: 'under itself');
    expect(treeDropMoves('docs', 'other'), isTrue);
  });

  /// The tree over a root note, a folder `docs` holding `inner.md` — pinned
  /// when [pinned] — and an empty folder `other`, both open; every drop
  /// recorded.
  Future<List<String>> pump(WidgetTester tester, {bool pinned = false}) async {
    final moves = <String>[];
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'docs');
    await session.createFolder(parentPath: '', name: 'other');
    await session.createNote(parentPath: '', name: 'nota', content: 'x');
    await session.createNote(
      parentPath: 'docs',
      name: 'inner',
      content: pinned ? '---\npinned: true\n---\ny' : 'y',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTree(
            controller: session,
            selectedPath: null,
            expanded: const <String>{'docs', 'other'},
            onToggle: (_) {},
            onSelect: (_) {},
            onMove: (path, folder) => moves.add('$path -> $folder'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return moves;
  }

  Future<void> dragMouse(WidgetTester tester, Object from, Offset to) async {
    final start = tester.getCenter(from is Finder ? from : find.text('$from'));
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(Offset.lerp(start, to, step / 10)!);
      await tester.pump();
    }
    await mouse.up();
    await tester.pumpAndSettle();
  }

  testWidgets("with the mouse: into a folder, a note's folder, the root", (
    tester,
  ) async {
    final moves = await pump(tester);
    final other = tester.getCenter(find.text('other'));
    final inner = tester.getCenter(find.text('inner.md'));
    final below =
        tester.getBottomLeft(find.byType(ListView)) + const Offset(40, -10);
    await dragMouse(tester, 'nota.md', other);
    await dragMouse(tester, 'nota.md', inner);
    await dragMouse(tester, 'inner.md', below);
    expect(moves, ['nota.md -> other', 'nota.md -> docs', 'docs/inner.md -> ']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a folder never into itself, nor anything where it is', (
    tester,
  ) async {
    final moves = await pump(tester);
    final inner = tester.getCenter(find.text('inner.md'));
    final docs = tester.getCenter(find.text('docs'));
    await dragMouse(tester, 'docs', inner);
    await dragMouse(tester, 'inner.md', docs);
    expect(moves, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('the pinned block: a row into its folder, the rest nowhere', (
    tester,
  ) async {
    // #574: a drop on the pinned block fell through to the root.
    final moves = await pump(tester, pinned: true);
    final row = tester.getCenter(find.byKey(const Key('pinned-docs/inner.md')));
    final heading = tester.getCenter(find.byKey(const Key('pinned-heading')));
    final divider = tester.getCenter(find.byType(Divider));
    // The tree's own row of the pinned note, under the block.
    final inner = find.text('inner.md').last;
    await dragMouse(tester, inner, heading);
    await dragMouse(tester, inner, divider);
    expect(moves, isEmpty);
    await dragMouse(tester, 'nota.md', row);
    expect(moves, ['nota.md -> docs']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('by touch: held, then dragged; held still, the menu', (
    tester,
  ) async {
    final moves = <String>[];
    final menus = <String>[];
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'other');
    await session.createNote(parentPath: '', name: 'nota', content: 'x');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTree(
            controller: session,
            selectedPath: null,
            expanded: const <String>{},
            onToggle: (_) {},
            onSelect: (_) {},
            onLongPress: (note) => menus.add(note.path),
            onMove: (path, folder) => moves.add('$path -> $folder'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A quick swipe scrolls, it does not drag.
    await tester.drag(find.text('nota.md'), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(moves, isEmpty);
    // Held, then moved onto the folder.
    final finger = await tester.startGesture(
      tester.getCenter(find.text('nota.md')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await finger.moveTo(tester.getCenter(find.text('other')));
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();
    expect(moves, ['nota.md -> other']);
    expect(menus, isEmpty);
    // Held and let go where it started: the menu.
    await tester.longPress(find.text('nota.md'));
    await tester.pumpAndSettle();
    expect(menus, ['nota.md']);
    // #576: held by the row's edge, drifted a few pixels onto the next row
    // and let go — still the long press, and no move.
    final row = tester.getRect(
      find.ancestor(
        of: find.text('nota.md'),
        matching: find.byType(TreeRowDrag),
      ),
    );
    final edge = await tester.startGesture(row.topCenter + const Offset(0, 3));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await edge.moveBy(const Offset(0, -8));
    await tester.pump();
    await edge.up();
    await tester.pumpAndSettle();
    expect(moves, ['nota.md -> other']);
    expect(menus, ['nota.md', 'nota.md']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
