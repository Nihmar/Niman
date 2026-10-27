// #1200 phase 3: the tree holds the pages around the viewport and the counts
// and ranks that say how many rows there are, not every row it ever read. The
// session is the in-memory fake, whose counters say which read answered.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/visible_tree.dart';

import '../fakes/fake_library_session.dart';

const _pageSize = 10;

/// What the tree flattened to before this model: each child, then the rows of
/// the child when it is an expanded folder, one depth deeper.
Future<List<TreeSlot>> flatten(
  FakeLibrarySession session,
  Set<String> expanded,
  TreeSort sort, [
  int parent = 0,
  int depth = 0,
]) async {
  final out = <TreeSlot>[];
  final children = await session.children(parent, sort: sort);
  for (var i = 0; i < children.length; i++) {
    out.add((parent: parent, position: i, depth: depth));
    final child = children[i];
    if (child.isDir && expanded.contains(child.path)) {
      out.addAll(await flatten(session, expanded, sort, child.id, depth + 1));
    }
  }
  return out;
}

/// Loads every page of [keys] that is not held, one after the other.
Future<void> loadAll(
  TreePages pages,
  FakeLibrarySession session,
  Iterable<TreePageKey> keys,
) async {
  for (final key in keys) {
    await pages.load(session, key.$1, key.$2, TreeSort.nameAsc);
  }
}

void main() {
  late FakeLibrarySession session;
  late TreePages pages;

  setUp(() async {
    session = FakeLibrarySession();
    pages = TreePages(pageSize: _pageSize);
    addTearDown(() async {
      await session.close();
      await session.dispose();
    });
    await session.open('/lib', create: false);
  });

  Future<int> idOf(String path) async => (await session.find(path))!.id;

  /// `f1` and `f2`, each with [count] notes.
  Future<void> seedTwoFolders(int count) async {
    for (final folder in ['f1', 'f2']) {
      await session.createFolder(parentPath: '', name: folder);
      for (var i = 0; i < count; i++) {
        await session.createNote(parentPath: folder, name: 'n$i');
      }
    }
  }

  group('visible', () {
    test('has the length and the slots of the old flattened order', () async {
      for (final name in ['alpha', 'beta', 'gamma']) {
        await session.createFolder(parentPath: '', name: name);
      }
      await session.createFolder(parentPath: 'alpha', name: 'inner');
      await session.createFolder(parentPath: 'gamma', name: 'deep');
      await session.createNote(parentPath: 'alpha/inner', name: 'x');
      await session.createNote(parentPath: 'alpha/inner', name: 'y');
      await session.createNote(parentPath: 'alpha', name: 'a1');
      await session.createNote(parentPath: 'beta', name: 'b1');
      await session.createNote(parentPath: 'beta', name: 'b2');
      await session.createNote(parentPath: 'gamma/deep', name: 'z');
      await session.createNote(parentPath: '', name: 'r1');
      await session.createNote(parentPath: '', name: 'r2');
      // gamma/deep is expanded under a closed gamma: it is not in the list.
      final expanded = {'alpha', 'alpha/inner', 'beta', 'gamma/deep'};
      for (final sort in [TreeSort.nameAsc, TreeSort.nameDesc]) {
        final tree = await pages.visible(session, expanded, sort);
        final expected = await flatten(session, expanded, sort);
        expect(tree.length, expected.length, reason: '$sort');
        expect(
          [for (var i = 0; i < tree.length; i++) tree.slotAt(i)],
          expected,
          reason: '$sort',
        );
        expect(tree.isVisibleFolder(await idOf('gamma/deep')), isFalse);
      }
    });

    test('gives the widget the rows of the expanded folders', () async {
      await seedTwoFolders(2);
      final tree = await pages.visible(session, {'f2'}, TreeSort.nameAsc);
      expect(tree.isVisibleFolder(await idOf('f2')), isTrue);
      expect(pages.folderOf(await idOf('f2'))?.path, 'f2');
      expect(pages.folderOf(await idOf('f1')), isNull);
    });

    test('reads nothing of a folder under a closed one', () async {
      await session.createFolder(parentPath: '', name: 'f1');
      await session.createFolder(parentPath: 'f1', name: 'sub');
      await pages.visible(session, {'f1/sub'}, TreeSort.nameAsc);
      expect(session.countCalls, 1, reason: 'the root alone');
      expect(session.rankCalls, 0);
    });

    test('holds the counts and ranks until they are forgotten', () async {
      await seedTwoFolders(3);
      final f1 = await idOf('f1');
      await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
      expect(session.countCalls, 3);
      expect(session.rankCalls, 2);
      await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
      expect(session.countCalls, 3, reason: 'held');
      expect(session.rankCalls, 2, reason: 'held');

      pages.forget([f1]);
      await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
      expect(session.countCalls, 4, reason: 'f1 alone is counted again');
      expect(session.rankCalls, 2, reason: 'a folder keeps its rank');

      pages.forget([VisibleTree.rootId]);
      await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
      expect(session.countCalls, 5, reason: 'the root');
      expect(session.rankCalls, 4, reason: 'the root moved its folders');
    });

    test('a different order starts afresh', () async {
      await seedTwoFolders(3);
      await pages.visible(session, {'f1'}, TreeSort.nameAsc);
      final epoch = pages.epoch;
      final tree = await pages.visible(session, {'f1'}, TreeSort.nameDesc);
      expect(pages.epoch, epoch + 1);
      expect(
        tree.slotAt(0),
        (await flatten(session, {'f1'}, TreeSort.nameDesc)).first,
      );
      expect(session.rankCalls, 2, reason: 'ranked again, in the new order');
    });
  });

  group('load', () {
    setUp(() => session.seedNotes(35));

    test('reads the first page of a folder by position, which is what the '
        'library warms up (#1230)', () async {
      expect(await pages.load(session, 0, 0, TreeSort.nameAsc), isTrue);
      expect((session.atCalls, session.pageCalls), (1, 0));
    });

    test('reads by the neighbour it has, else by position', () async {
      const sort = TreeSort.nameAsc;
      expect(await pages.load(session, 0, 2, sort), isTrue);
      expect((session.atCalls, session.pageCalls), (1, 0), reason: 'a jump');
      // Page 1 has page 2 and no page 0: the rows before page 2's first.
      expect(await pages.load(session, 0, 1, sort), isTrue);
      expect((session.atCalls, session.pageCalls), (1, 1), reason: 'before');
      // Page 3 has page 2 before it: the rows after page 2's last.
      expect(await pages.load(session, 0, 3, sort), isTrue);
      expect((session.atCalls, session.pageCalls), (1, 2), reason: 'after');
      expect(await pages.load(session, 0, 0, sort), isTrue);
      expect((session.atCalls, session.pageCalls), (1, 3));
      // Held already: nothing read, nothing added.
      expect(await pages.load(session, 0, 2, sort), isFalse);
      expect((session.atCalls, session.pageCalls), (1, 3));

      final all = await session.children(0);
      for (var position = 0; position < all.length; position++) {
        expect(pages.rowAt(0, position)?.path, all[position].path);
      }
      expect(pages.rowAt(0, all.length), isNull, reason: 'past the last row');
      expect(pages.pageRows(0, 3)!.length, 5);
    });

    test('answers nothing for a page that is not loaded', () async {
      expect(pages.rowAt(0, 0), isNull);
      expect(pages.pageRows(0, 0), isNull);
      expect(await pages.load(session, 0, 9, TreeSort.nameAsc), isFalse);
      expect(pages.pageCount, 0, reason: 'an empty page is not held');
    });

    test('reads a page asked for twice at once only once', () async {
      final first = pages.load(session, 0, 1, TreeSort.nameAsc);
      final second = pages.load(session, 0, 1, TreeSort.nameAsc);
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(session.atCalls, 1);
      expect(pages.pageCount, 1);
    });

    test('adds nothing when the order changed on its way', () async {
      await pages.load(session, 0, 0, TreeSort.nameAsc);
      session.treeGate = Completer<void>();
      final late = pages.load(session, 0, 1, TreeSort.nameAsc);
      pages.clear();
      session.treeGate!.complete();
      expect(await late, isFalse);
      expect(pages.pageCount, 0);
      // The same page asked for again is read afresh.
      expect(await pages.load(session, 0, 1, TreeSort.nameAsc), isTrue);
    });

    test('adds nothing to a folder forgotten on its way', () async {
      await pages.load(session, 0, 0, TreeSort.nameAsc);
      session.treeGate = Completer<void>();
      final late = pages.load(session, 0, 1, TreeSort.nameAsc);
      pages.forget([0]);
      session.treeGate!.complete();
      expect(await late, isFalse);
      expect(pages.pageCount, 0);
    });

    test('lands in a folder another one was forgotten around', () async {
      await pages.load(session, 0, 0, TreeSort.nameAsc);
      session.treeGate = Completer<void>();
      final late = pages.load(session, 0, 1, TreeSort.nameAsc);
      pages.forget([4242]);
      session.treeGate!.complete();
      expect(await late, isTrue);
      expect(pages.pageCount, 2);
    });
  });

  group('folders', () {
    test('forget leaves the pages of the other folders', () async {
      await seedTwoFolders(25);
      final f1 = await idOf('f1');
      final f2 = await idOf('f2');
      await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
      await loadAll(pages, session, [(f1, 0), (f1, 1), (f2, 0), (f2, 2)]);
      pages.pinned = const [];
      expect(pages.pageCount, 4);

      pages.forget([f1]);
      expect(pages.pageCount, 2);
      expect(pages.hasPage((f2, 0)), isTrue);
      expect(pages.hasPage((f2, 2)), isTrue);
      expect(pages.pinned, isNull);
    });

    test(
      'closing a folder drops its pages, reopening reads no count',
      () async {
        await seedTwoFolders(25);
        final f1 = await idOf('f1');
        final f2 = await idOf('f2');
        await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
        await loadAll(pages, session, [(f1, 0), (f1, 1), (f2, 1)]);
        final counted = session.countCalls;

        await pages.visible(session, {'f2'}, TreeSort.nameAsc);
        expect(pages.hasPage((f1, 0)), isFalse);
        expect(pages.hasPage((f1, 1)), isFalse);
        expect(pages.hasPage((f2, 1)), isTrue);

        await pages.visible(session, {'f1', 'f2'}, TreeSort.nameAsc);
        expect(session.countCalls, counted, reason: 'the counts were held');
        expect(await pages.load(session, f1, 0, TreeSort.nameAsc), isTrue);
      },
    );

    test('closing a folder drops what is under it, and its reads', () async {
      await session.createFolder(parentPath: '', name: 'f1');
      await session.createFolder(parentPath: 'f1', name: 'sub');
      for (var i = 0; i < 25; i++) {
        await session.createNote(parentPath: 'f1/sub', name: 'n$i');
      }
      final sub = await idOf('f1/sub');
      final open = {'f1', 'f1/sub'};
      await pages.visible(session, open, TreeSort.nameAsc);
      await loadAll(pages, session, [(sub, 0)]);
      session.treeGate = Completer<void>();
      final late = pages.load(session, sub, 1, TreeSort.nameAsc);

      // f1 closes: sub is no longer under an expanded folder.
      await pages.visible(session, {'f1/sub'}, TreeSort.nameAsc);
      session.treeGate!.complete();
      expect(await late, isFalse);
      expect(pages.pageCount, 0);
    });
  });

  group('window', () {
    test(
      'pagesFor is the pages drawn and the neighbours within the folder',
      () {
        final tree = VisibleTree(rootCount: 25);
        expect(pages.pagesFor(tree, 12, 14), {(0, 0), (0, 1), (0, 2)});
        expect(pages.pagesFor(tree, 0, 3), {(0, 0), (0, 1)});
        expect(pages.pagesFor(tree, 22, 99), {(0, 1), (0, 2)});
        expect(pages.pagesFor(tree, -5, 4), {(0, 0), (0, 1)});
        expect(pages.pagesFor(VisibleTree(rootCount: 0), 0, 9), isEmpty);
      },
    );

    test('pagesFor follows the rows of an expanded folder', () {
      // [0] folder 10 (25 children) [1].. : rows 1..25 are its children.
      final tree = VisibleTree(
        rootCount: 3,
        expanded: [(id: 10, parentId: 0, rank: 0, childCount: 25)],
      );
      // Rows 9..12 are positions 8..11 of folder 10: its first two pages,
      // and the third, where the next read starts from.
      expect(pages.pagesFor(tree, 9, 12), {(10, 0), (10, 1), (10, 2)});
      // The root's rows 1 and 2, under the folder's: its only page.
      expect(pages.pagesFor(tree, 26, 27), {(0, 0)});
      // Row 0 is the folder's own, a row of the root.
      expect(pages.pagesFor(tree, 0, 0), {(0, 0)});
    });

    test('drawnPages is the pages drawn, without the neighbours', () {
      final tree = VisibleTree(rootCount: 25);
      expect(pages.drawnPages(tree, 12, 14), {(0, 1)});
      expect(pages.drawnPages(tree, 8, 12), {(0, 0), (0, 1)});
      expect(pages.drawnPages(tree, -5, 99), {(0, 0), (0, 1), (0, 2)});
      expect(pages.drawnPages(VisibleTree(rootCount: 0), 0, 9), isEmpty);
    });

    test('held is a copy of the pages that is not changed by them', () async {
      await session.seedNotes(35);
      await loadAll(pages, session, [(0, 0), (0, 1)]);
      final held = pages.held();
      expect(held.keys.toSet(), {(0, 0), (0, 1)});
      expect(held[(0, 1)], pages.pageRows(0, 1));
      pages.keepOnly(const []);
      expect(pages.pageCount, 0);
      expect(held, hasLength(2), reason: 'the copy kept its pages');
    });

    test('keepOnly drops the pages outside the window', () async {
      await session.seedNotes(35);
      await loadAll(pages, session, [(0, 0), (0, 1), (0, 2), (0, 3)]);
      pages.keepOnly([(0, 1), (0, 2), (7, 7)]);
      expect(pages.pageCount, 2);
      expect(pages.hasPage((0, 0)), isFalse);
      expect(pages.hasPage((0, 1)), isTrue);
      expect(pages.rowAt(0, 5), isNull);
      expect(pages.rowAt(0, 15), isNotNull);
      pages.keepOnly(const []);
      expect(pages.pageCount, 0);
    });

    test('a window over a folder of 100 pages holds its pages alone', () async {
      await session.seedNotes(1000);
      final all = await session.children(0);
      final tree = await pages.visible(session, {}, TreeSort.nameAsc);
      expect(tree.length, 1000);

      var most = 0;
      // A scroll by steps, then jumps to the end and back: 20 rows drawn.
      final firsts = [
        for (var first = 0; first < 980; first += 7) first,
        979,
        0,
        500,
      ];
      for (final first in firsts) {
        final window = pages.pagesFor(tree, first, first + 19);
        await loadAll(pages, session, window);
        pages.keepOnly(window);
        expect(pages.pageCount, lessThanOrEqualTo(window.length));
        most = pages.pageCount > most ? pages.pageCount : most;
        for (var i = first; i < first + 20 && i < 1000; i++) {
          final slot = tree.slotAt(i);
          expect(pages.rowAt(slot.parent, slot.position)?.path, all[i].path);
        }
      }
      // 20 rows touch 3 pages at most, with a neighbour either side.
      expect(most, lessThanOrEqualTo(5));
      expect(pages.pageCount, lessThanOrEqualTo(5));
    });
  });
}
