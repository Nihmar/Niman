import 'package:copist/src/editor/folding.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const outline = [
    OutlineEntry(line: 0, level: 1, text: 'A'),
    OutlineEntry(line: 2, level: 2, text: 'A.1'),
    OutlineEntry(line: 5, level: 2, text: 'A.2'),
    OutlineEntry(line: 8, level: 1, text: 'B'),
    OutlineEntry(line: 10, level: 2, text: 'B.1'),
  ];
  const lineCount = 12; // lines 0..11

  test('no folds: every line visible', () {
    final f = FoldState(outline, lineCount);
    expect(f.visibleLines().length, lineCount);
    for (var i = 0; i < lineCount; i++) {
      expect(f.isLineVisible(i), isTrue);
    }
  });

  test('folding a top-level heading hides its section', () {
    final f = FoldState(outline, lineCount, folded: {0});
    // A (0, level 1) hides [1,8) — up to the next level<=1 heading B (8).
    expect(f.isLineVisible(0), isTrue); // the fold anchor stays visible
    for (var i = 1; i < 8; i++) {
      expect(f.isLineVisible(i), isFalse);
    }
    expect(f.isLineVisible(8), isTrue); // B
    expect(f.visibleLines(), [0, 8, 9, 10, 11]);
  });

  test('folding hides sub-headings inside the section', () {
    final f = FoldState(outline, lineCount, folded: {0});
    expect(f.isLineVisible(2), isFalse); // A.1
    expect(f.isLineVisible(5), isFalse); // A.2
  });

  test('folding a sub-heading hides only its subsection', () {
    final f = FoldState(outline, lineCount, folded: {2});
    // A.1 (2, level 2) hides [3,5) — up to A.2 (5).
    expect(f.isLineVisible(2), isTrue); // the fold anchor
    expect(f.isLineVisible(3), isFalse);
    expect(f.isLineVisible(4), isFalse);
    expect(f.isLineVisible(5), isTrue); // A.2
    expect(f.isLineVisible(0), isTrue); // A
  });

  test('folding the last heading hides to end of document', () {
    final f = FoldState(outline, lineCount, folded: {10});
    // B.1 (10, level 2) has no same-or-higher heading after → [11,12).
    expect(f.isLineVisible(10), isTrue);
    expect(f.isLineVisible(11), isFalse);
  });

  test('toggle folds and unfolds', () {
    final f = FoldState(outline, lineCount);
    expect(f.isFolded(0), isFalse);
    f.toggle(0);
    expect(f.isFolded(0), isTrue);
    expect(f.isLineVisible(1), isFalse);
    f.toggle(0);
    expect(f.isFolded(0), isFalse);
    expect(f.isLineVisible(1), isTrue);
  });

  test('nested folds merge into one hidden range', () {
    final f = FoldState(outline, lineCount, folded: {0, 2});
    // A folds [1,8), A.1 folds [3,5) → merged [1,8).
    expect(f.hiddenRanges, [(1, 8)]);
    expect(f.visibleLines(), [0, 8, 9, 10, 11]);
  });

  test('two disjoint top-level folds', () {
    final f = FoldState(outline, lineCount, folded: {0, 8});
    // A folds [1,8), B (8, level 1) folds [9,12).
    expect(f.hiddenRanges, [(1, 8), (9, 12)]);
    expect(f.visibleLines(), [0, 8]);
  });
}
