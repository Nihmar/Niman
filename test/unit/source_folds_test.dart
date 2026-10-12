// The folded sections of the source surface (#245, phase 3): which lines are
// hidden, and the line ↔ row mapping the view draws through.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/source_edit.dart';

SourceEdit _edit(int first, int removed, int inserted) => SourceEdit(
  firstLine: first,
  removedLines: removed,
  insertedLines: inserted,
  revision: 1,
);

void main() {
  test('nothing folded is the identity', () {
    final folds = SourceFolds();
    expect(folds.isEmpty, isTrue);
    expect(folds.rowCount(10), 10);
    expect(folds.rowOf(7), 7);
    expect(folds.lineOf(7), 7);
  });

  test('a fold hides its section, and the rows close up', () {
    final folds = SourceFolds()..fold(2, 6);
    expect(folds.rowCount(10), 7);
    expect(folds.isHidden(2), isFalse, reason: 'the heading stays');
    expect(folds.isHidden(3), isTrue);
    expect(folds.isHidden(6), isFalse);
    expect(folds.lineOf(2), 2);
    expect(folds.lineOf(3), 6);
    expect(folds.rowOf(6), 3);
    expect(folds.rowOf(4), 2, reason: 'a hidden line is where its heading is');
  });

  test('a fold inside a fold is covered by it, and shows when it goes', () {
    final folds = SourceFolds()
      ..fold(1, 9)
      ..fold(3, 5);
    expect(folds.hidden, <(int, int)>[(2, 9)]);
    folds.unfold(1);
    expect(folds.hidden, <(int, int)>[(4, 5)]);
  });

  test('the two directions agree, with folds anywhere', () {
    final random = Random(7);
    for (var round = 0; round < 50; round++) {
      final folds = SourceFolds();
      const lines = 200;
      for (var fold = 0; fold < 6; fold++) {
        final at = random.nextInt(lines - 3);
        folds.fold(at, min(lines, at + 2 + random.nextInt(20)));
      }
      final visible = <int>[
        for (var line = 0; line < lines; line++)
          if (!folds.isHidden(line)) line,
      ];
      expect(folds.rowCount(lines), visible.length);
      for (var row = 0; row < visible.length; row++) {
        expect(folds.lineOf(row), visible[row]);
        expect(folds.rowOf(visible[row]), row);
      }
    }
  });

  test('reveal unfolds what hides a line', () {
    final folds = SourceFolds()
      ..fold(0, 4)
      ..fold(8, 12);
    expect(folds.reveal(10), isTrue);
    expect(folds.isFolded(8), isFalse);
    expect(folds.isFolded(0), isTrue);
    expect(folds.reveal(6), isFalse);
  });

  group('an edit', () {
    test('above a fold moves it with the lines', () {
      final folds = SourceFolds()..fold(5, 9);
      final reshaped = folds.edited(_edit(1, 1, 3), 12, (line) => line + 4);
      expect(reshaped, isFalse);
      expect(folds.anchors, <int>[7]);
      expect(folds.hidden, <(int, int)>[(8, 11)]);
    });

    test('in the folded heading keeps it, when it keeps the line count', () {
      final folds = SourceFolds()
        ..fold(5, 9)
        ..edited(_edit(5, 1, 1), 10, (line) => 9);
      expect(folds.isFolded(5), isTrue);
    });

    test('adding a line at the folded heading lets it go', () {
      final folds = SourceFolds()..fold(5, 9);
      final reshaped = folds.edited(_edit(5, 1, 2), 11, (line) => 10);
      expect(reshaped, isTrue);
      expect(folds.isEmpty, isTrue);
    });

    test('into what a fold hides lets it go', () {
      final folds = SourceFolds()..fold(5, 9);
      expect(folds.edited(_edit(7, 1, 1), 10, (line) => 9), isTrue);
      expect(folds.isEmpty, isTrue);
    });

    test('that stops the line being a heading lets it go', () {
      final folds = SourceFolds()..fold(5, 9);
      expect(folds.edited(_edit(0, 1, 1), 10, (line) => null), isTrue);
      expect(folds.isEmpty, isTrue);
    });

    test('that moves where the section ends says so', () {
      final folds = SourceFolds()..fold(5, 9);
      // The heading that ended it lost its hashes: the section runs on.
      expect(folds.edited(_edit(9, 1, 1), 20, (line) => 15), isTrue);
      expect(folds.hidden, <(int, int)>[(6, 15)]);
    });
  });

  group('a side-by-side block hosts its lines (#729)', () {
    test("its lines are its opener's row, and not hidden", () {
      final folds = SourceFolds()..setHosts({2: 7});
      expect(folds.isEmpty, isFalse);
      expect(folds.rowCount(10), 6);
      expect(folds.rowOf(2), 2);
      expect(folds.rowOf(5), 2, reason: "a hosted line is its host's row");
      expect(folds.lineOf(3), 7);
      expect(folds.isHidden(5), isFalse);
      expect(folds.hostOf(5), 2);
      expect(folds.hostOf(2), isNull);
      expect(folds.hostOf(7), isNull);
      expect(folds.isHost(2), isTrue);
      expect(folds.reveal(5), isFalse, reason: 'nothing folded to reveal');
    });

    test('a fold and a host merge their rows', () {
      final folds = SourceFolds()
        ..fold(0, 4)
        ..setHosts({6: 9});
      expect(folds.hidden, <(int, int)>[(1, 4), (7, 9)]);
      expect(folds.rowCount(12), 7);
      expect(folds.isHidden(8), isFalse);
      expect(folds.isHidden(2), isTrue);
    });

    test('an edit inside the block changes no row', () {
      final folds = SourceFolds()..setHosts({2: 7});
      // An Enter in a column: a line more, in the block.
      expect(folds.edited(_edit(4, 1, 2), 11, (_) => null), isFalse);
      expect(folds.hosts, <int, int>{2: 8});
      expect(folds.rowCount(11), 6);
    });

    test('an edit above the block moves it', () {
      final folds = SourceFolds()
        ..setHosts({2: 7})
        ..edited(_edit(0, 1, 3), 12, (_) => null);
      expect(folds.hosts, <int, int>{4: 9});
    });

    test('an edit across its edge lets it go', () {
      final folds = SourceFolds()
        ..setHosts({2: 7})
        ..edited(_edit(6, 2, 1), 9, (_) => null);
      expect(folds.hosts, isEmpty);
    });

    test('setting the same hosts again changes nothing', () {
      final folds = SourceFolds()..setHosts({2: 7});
      expect(folds.setHosts({2: 7}), isFalse);
      expect(folds.setHosts({2: 8}), isTrue);
    });
  });
}
