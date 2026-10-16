// #567: a note or a folder dragged in the tree moves where it is dropped —
// into a folder, into a note's folder, into the root — and nowhere it
// cannot go.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  test('a drop lists the paths it would move, in the order given', () {
    expect(treeDropPaths(['b.md', 'a.md'], 'docs'), ['b.md', 'a.md']);
    // Where it is, itself, and under itself are left out.
    expect(treeDropPaths(['docs/a.md', 'docs', 'docs/sub', 'x.md'], 'docs'), [
      'x.md',
    ]);
    expect(treeDropPaths(['docs/a.md', 'docs/b.md'], 'docs'), isEmpty);
    expect(treeDropPaths(const <String>[], 'docs'), isEmpty);
    // The root: what is in a folder comes out, what is at the root stays.
    expect(treeDropPaths(['docs/a.md', 'top.md', 'docs'], ''), ['docs/a.md']);
    // A marked folder and a path inside it are both listed: the move skips
    // the inner one (treeOutermost).
    expect(treeDropPaths(['docs', 'docs/a.md'], 'other'), [
      'docs',
      'docs/a.md',
    ]);
  });

  test('the outermost of the paths drops what a folder carries along', () {
    expect(treeOutermost(['docs', 'docs/a.md']), ['docs']);
    expect(treeOutermost(['docs/a.md', 'docs']), ['docs']);
    expect(treeOutermost(['docs', 'docs/sub', 'docs/sub/a.md']), ['docs']);
    // Siblings, and a name that merely starts like a folder's, all stay.
    expect(treeOutermost(['a.md', 'b.md', 'docs', 'docs2/x.md']), [
      'a.md',
      'b.md',
      'docs',
      'docs2/x.md',
    ]);
    expect(treeOutermost(['docs/a.md', 'docs/b.md']), [
      'docs/a.md',
      'docs/b.md',
    ]);
    expect(treeOutermost(const <String>[]), isEmpty);
  });

  test('a drop then a move: what is listed, then what is moved', () {
    List<String> moved(List<String> paths, String folder) =>
        treeOutermost(treeDropPaths(paths, folder));
    expect(moved(['docs', 'docs/a.md', 'x.md'], 'other'), ['docs', 'x.md']);
    // Into the folder a marked path is in: the inner path is left out first,
    // so the folder is not carried into itself.
    expect(moved(['docs', 'docs/a.md', 'x.md'], 'docs'), ['x.md']);
    // Neither is inside the other: both leave their folders for the root.
    expect(moved(['docs/a.md', 'docs/sub/b.md'], ''), [
      'docs/a.md',
      'docs/sub/b.md',
    ]);
    expect(moved(['docs/a.md', 'docs/b.md'], 'docs'), isEmpty);
  });

  /// The tree over a root note, a folder `docs` holding `inner.md` — pinned
  /// when [pinned] — and an empty folder `other`, both open; every drop
  /// recorded. [extraNotes] are root notes `alpha`-style (name, no
  /// extension); [marked] turns the marks on, without which nothing can be
  /// selected (#712).
  Future<List<String>> pump(
    WidgetTester tester, {
    bool pinned = false,
    bool marked = false,
    List<String> extraNotes = const <String>[],
  }) async {
    final moves = <String>[];
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'docs');
    await session.createFolder(parentPath: '', name: 'other');
    await session.createNote(parentPath: '', name: 'nota', content: 'x');
    for (final name in extraNotes) {
      await session.createNote(parentPath: '', name: name, content: 'x');
    }
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
            onMove: (paths, folder) =>
                moves.addAll([for (final path in paths) '$path -> $folder']),
            onMarkedMenu: marked ? (_, _) {} : null,
            onDeleteMarked: marked ? (_) {} : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return moves;
  }

  Future<void> dragMouse(
    WidgetTester tester,
    Object from,
    Offset to, {
    VoidCallback? during,
  }) async {
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
    during?.call();
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

  testWidgets('several marked rows dragged together all move (#996)', (
    tester,
  ) async {
    final moves = await pump(
      tester,
      marked: true,
      extraNotes: ['alpha', 'bravo', 'charlie'],
    );
    await tester.tap(find.text('alpha.md'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('charlie.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    await dragMouse(
      tester,
      'alpha.md',
      tester.getCenter(find.text('other')),
      // The card says how many rows the drag carries, not the one's name.
      during: () {
        expect(find.text('Selected: 3'), findsOneWidget);
        expect(find.text('alpha.md'), findsOneWidget);
      },
    );
    expect(moves, [
      'alpha.md -> other',
      'bravo.md -> other',
      'charlie.md -> other',
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a marked folder carries its marked child, once (#996)', (
    tester,
  ) async {
    final moves = await pump(tester, marked: true);
    await tester.tap(find.text('docs'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('inner.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    await dragMouse(tester, 'docs', tester.getCenter(find.text('other')));
    // The tree hands every marked path a drop moves; the shell keeps only
    // the outermost, so docs/inner goes with docs and moves once
    // (shell_tree_desktop_test.dart).
    expect(moves, ['docs -> other', 'docs/inner.md -> other']);
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
            onLongPress: (note, _) => menus.add(note.path),
            onMove: (paths, folder) =>
                moves.addAll([for (final path in paths) '$path -> $folder']),
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
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
