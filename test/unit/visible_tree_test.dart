// #1200 phase 2: the visible tree is described by counts and ranks alone, and
// answers which row sits at an index, and where a row is, without holding
// any. The property test is the proof: the list the tree flattened to before
// (each child, then an expanded folder's own children) is built the old way,
// and the model has to agree with it row by row.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/visible_tree.dart';

/// A folder given to the model, for the tests' brevity.
ExpandedFolder folder(int id, int parent, int rank, int count) =>
    (id: id, parentId: parent, rank: rank, childCount: count);

/// The slots of the whole list, by index.
List<TreeSlot> slots(VisibleTree tree) => [
  for (var i = 0; i < tree.length; i++) tree.slotAt(i),
];

TreeSlot slot(int parent, int position, int depth) =>
    (parent: parent, position: position, depth: depth);

void main() {
  group('hand-built trees', () {
    test('an empty root has no rows', () {
      final tree = VisibleTree(rootCount: 0);
      expect(tree.length, 0);
      expect(() => tree.slotAt(0), throwsRangeError);
      expect(tree.indexOf(0, 0), isNull);
      expect(tree.isVisibleFolder(0), isTrue);
    });

    test('says how many children a visible folder has', () {
      final tree = VisibleTree(
        rootCount: 3,
        expanded: [folder(10, 0, 0, 2), folder(11, 99, 0, 5)],
      );
      expect(tree.childCount(0), 3);
      expect(tree.childCount(10), 2);
      expect(tree.childCount(11), isNull, reason: 'under a folder not open');
    });

    test('a root alone is its children at depth 0', () {
      final tree = VisibleTree(rootCount: 3);
      expect(slots(tree), [slot(0, 0, 0), slot(0, 1, 0), slot(0, 2, 0)]);
      expect(tree.childDepth(0), 0);
      expect(() => tree.slotAt(3), throwsRangeError);
      expect(() => tree.slotAt(-1), throwsRangeError);
    });

    test('a folder expanded first opens its rows right after its own', () {
      // [0] folder 10 (2 children), [1], [2].
      final tree = VisibleTree(rootCount: 3, expanded: [folder(10, 0, 0, 2)]);
      expect(tree.length, 5);
      expect(slots(tree), [
        slot(0, 0, 0),
        slot(10, 0, 1),
        slot(10, 1, 1),
        slot(0, 1, 0),
        slot(0, 2, 0),
      ]);
      expect(tree.indexOf(10, 0), 1);
      expect(tree.indexOf(0, 1), 3);
    });

    test('a folder expanded in the middle and at the end', () {
      final middle = VisibleTree(rootCount: 4, expanded: [folder(10, 0, 2, 1)]);
      expect(slots(middle), [
        slot(0, 0, 0),
        slot(0, 1, 0),
        slot(0, 2, 0),
        slot(10, 0, 1),
        slot(0, 3, 0),
      ]);
      final end = VisibleTree(rootCount: 3, expanded: [folder(10, 0, 2, 2)]);
      expect(slots(end), [
        slot(0, 0, 0),
        slot(0, 1, 0),
        slot(0, 2, 0),
        slot(10, 0, 1),
        slot(10, 1, 1),
      ]);
      expect(end.indexOf(10, 1), 4);
    });

    test('an expanded folder with no children opens nothing', () {
      final tree = VisibleTree(rootCount: 2, expanded: [folder(10, 0, 0, 0)]);
      expect(tree.length, 2);
      expect(slots(tree), [slot(0, 0, 0), slot(0, 1, 0)]);
      expect(tree.isVisibleFolder(10), isTrue);
      expect(tree.indexOf(10, 0), isNull);
    });

    test('nested folders open at one more depth each', () {
      // root: [a(10) [b(11) [x, y], c], d]
      final tree = VisibleTree(
        rootCount: 2,
        expanded: [folder(10, 0, 0, 2), folder(11, 10, 0, 2)],
      );
      expect(tree.length, 6);
      expect(slots(tree), [
        slot(0, 0, 0),
        slot(10, 0, 1),
        slot(11, 0, 2),
        slot(11, 1, 2),
        slot(10, 1, 1),
        slot(0, 1, 0),
      ]);
      expect(tree.childDepth(0), 0);
      expect(tree.childDepth(10), 1);
      expect(tree.childDepth(11), 2);
      expect(tree.indexOf(11, 1), 3);
      expect(tree.indexOf(10, 1), 4);
    });

    test('siblings are taken by rank whatever the order they are given', () {
      final tree = VisibleTree(
        rootCount: 5,
        expanded: [folder(12, 0, 3, 1), folder(10, 0, 1, 2)],
      );
      expect(slots(tree), [
        slot(0, 0, 0),
        slot(0, 1, 0),
        slot(10, 0, 1),
        slot(10, 1, 1),
        slot(0, 2, 0),
        slot(0, 3, 0),
        slot(12, 0, 1),
        slot(0, 4, 0),
      ]);
    });

    test('a folder under a collapsed one is ignored', () {
      // 11 is expanded, its parent 10 is not: 11 is hidden.
      final tree = VisibleTree(rootCount: 2, expanded: [folder(11, 10, 0, 4)]);
      expect(tree.length, 2);
      expect(tree.isVisibleFolder(11), isFalse);
      expect(tree.childDepth(11), isNull);
      expect(tree.indexOf(11, 0), isNull);
      expect(slots(tree), [slot(0, 0, 0), slot(0, 1, 0)]);
    });

    test('a folder whose chain stops at a collapsed one is ignored', () {
      // 10 (visible) > 11 (visible) ; 21 under 20, and 20 is not given.
      final tree = VisibleTree(
        rootCount: 1,
        expanded: [
          folder(10, 0, 0, 1),
          folder(11, 10, 0, 1),
          folder(21, 20, 0, 9),
        ],
      );
      expect(tree.length, 3);
      expect(tree.isVisibleFolder(21), isFalse);
    });

    test('an id given twice counts once and a cycle is never entered', () {
      final tree = VisibleTree(
        rootCount: 1,
        expanded: [
          folder(10, 0, 0, 2),
          folder(10, 0, 0, 7),
          folder(30, 31, 0, 1),
          folder(31, 30, 0, 1),
        ],
      );
      expect(tree.length, 3);
    });

    test('indexOf answers null for a position the folder does not have', () {
      final tree = VisibleTree(rootCount: 2);
      expect(tree.indexOf(0, -1), isNull);
      expect(tree.indexOf(0, 2), isNull);
      expect(tree.indexOf(99, 0), isNull);
    });
  });

  group('property: the model agrees with the flattened list', () {
    test('200 random trees', () {
      final random = Random(1200);
      for (var round = 0; round < 200; round++) {
        _checkRandomTree(random, round);
      }
    });
  });

  group('scale', () {
    test('a million children and 50 big expanded folders cost no rows', () {
      const rootCount = 1000000;
      const opened = 50;
      const each = 10000;
      final random = Random(7);
      final clock = Stopwatch()..start();
      final tree = VisibleTree(
        rootCount: rootCount,
        expanded: [
          for (var i = 0; i < opened; i++)
            folder(1000 + i, 0, 1000 + i * 19000, each),
        ],
      );
      final built = clock.elapsedMicroseconds;
      expect(tree.length, rootCount + opened * each);

      clock.reset();
      var checked = 0;
      for (var i = 0; i < 100000; i++) {
        final index = random.nextInt(tree.length);
        final at = tree.slotAt(index);
        // A round trip on a tenth of them, so the inverse is held to the
        // same scale.
        if (i % 10 == 0) {
          expect(tree.indexOf(at.parent, at.position), index);
          checked++;
        }
      }
      final looked = clock.elapsedMicroseconds;
      // The numbers are the output of this test: a perf round reads them.
      // ignore: avoid_print
      print(
        'visible tree: built in ${built / 1000} ms, 100000 slotAt '
        '($checked with indexOf) in ${looked / 1000} ms',
      );
      expect(built, lessThan(2000000));
      expect(looked, lessThan(2000000));
    });
  });
}

/// One random tree, flattened the way the tree widget did before the model,
/// and held against the model for every row.
void _checkRandomTree(Random random, int round) {
  // childrenOf[folder] = the ids of its children, in order; 0 is the root.
  final childrenOf = <int, List<int>>{};
  final parentOf = <int, int>{};
  final positionOf = <int, int>{};
  final folders = <int>[];
  var nextId = 1;
  var rows = 0;

  void grow(int parent, int depth) {
    // A mix of empty, small and wide folders; the total stays in the few
    // hundred rows.
    final fanOut = switch (random.nextInt(6)) {
      0 => 0,
      1 || 2 => 1 + random.nextInt(3),
      3 || 4 => 2 + random.nextInt(6),
      _ => 8 + random.nextInt(20),
    };
    final ids = <int>[];
    for (var position = 0; position < fanOut && rows < 400; position++) {
      final id = nextId++;
      rows++;
      ids.add(id);
      parentOf[id] = parent;
      positionOf[id] = position;
    }
    childrenOf[parent] = ids;
    for (final id in ids) {
      if (depth < 5 && random.nextInt(100) < 35) {
        folders.add(id);
        grow(id, depth + 1);
      }
    }
  }

  grow(0, 0);

  // Any subset of the folders is expanded, including ones a collapsed
  // ancestor hides.
  final expanded = <int>{
    for (final id in folders)
      if (random.nextInt(100) < 60) id,
  };

  // The old flatten: each child, then an expanded folder's own children.
  final flat = <TreeSlot>[];
  void walk(int parent, int depth) {
    final children = childrenOf[parent] ?? const <int>[];
    for (var position = 0; position < children.length; position++) {
      flat.add((parent: parent, position: position, depth: depth));
      final id = children[position];
      if (expanded.contains(id)) walk(id, depth + 1);
    }
  }

  walk(0, 0);

  final tree = VisibleTree(
    rootCount: childrenOf[0]!.length,
    // Shuffled: the model sorts by rank itself.
    expanded: [
      for (final id in expanded.toList()..shuffle(random))
        folder(
          id,
          parentOf[id]!,
          positionOf[id]!,
          (childrenOf[id] ?? const <int>[]).length,
        ),
    ],
  );

  expect(tree.length, flat.length, reason: 'round $round: length');
  for (var i = 0; i < flat.length; i++) {
    expect(tree.slotAt(i), flat[i], reason: 'round $round: slotAt($i)');
    expect(
      tree.indexOf(flat[i].parent, flat[i].position),
      i,
      reason: 'round $round: indexOf at $i',
    );
  }
}
