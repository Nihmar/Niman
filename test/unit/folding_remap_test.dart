// Tests for FoldState.applyEdit (M2a E8c core): remapping the folded set
// through a line edit, over a recomputed outline.
//
// A fold is transient view state indexed by heading line number: an edit
// above it shifts it, and an edit that removes its heading line (or turns
// that line into a non-heading) drops it.

import 'package:copist/src/editor/folding.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:flutter_test/flutter_test.dart';

OutlineEntry _h(int line, [int level = 1]) =>
    OutlineEntry(line: line, level: level, text: 'h$line');

void main() {
  group('FoldState.applyEdit', () {
    test('insertion above a fold shifts it down', () {
      final before = FoldState([_h(0), _h(2)], 4, folded: {2});
      // Insert 2 lines at line 0 (replace [0,0) with 2).
      final after = before.applyEdit(
        start: 0,
        end: 0,
        inserted: 2,
        newOutline: [_h(2), _h(4)],
        newLineCount: 6,
      );
      expect(after.foldedLines, {4});
      expect(after.lineCount, 6);
    });

    test('insertion below a fold leaves it', () {
      final before = FoldState([_h(0), _h(2)], 4, folded: {2});
      final after = before.applyEdit(
        start: 4,
        end: 4,
        inserted: 1,
        newOutline: [_h(0), _h(2)],
        newLineCount: 5,
      );
      expect(after.foldedLines, {2});
    });

    test('deleting the heading line drops the fold', () {
      final before = FoldState([_h(0), _h(2)], 4, folded: {2});
      final after = before.applyEdit(
        start: 2,
        end: 3,
        inserted: 0,
        newOutline: [_h(0)],
        newLineCount: 3,
      );
      expect(after.foldedLines, isEmpty);
    });

    test('deletion above a fold shifts it up', () {
      final before = FoldState([_h(0), _h(2)], 4, folded: {2});
      final after = before.applyEdit(
        start: 0,
        end: 1,
        inserted: 0,
        newOutline: [_h(1)],
        newLineCount: 3,
      );
      expect(after.foldedLines, {1});
    });

    test('renaming a heading (1:1 content edit) keeps the fold', () {
      final before = FoldState([_h(0), _h(2)], 4, folded: {2});
      final after = before.applyEdit(
        start: 2,
        end: 3,
        inserted: 1,
        newOutline: [_h(0), _h(2)],
        newLineCount: 4,
      );
      expect(after.foldedLines, {2});
    });

    test('un-heading a folded line drops the fold', () {
      final before = FoldState([_h(0), _h(2)], 4, folded: {2});
      // The line is still there (1:1) but no longer a heading.
      final after = before.applyEdit(
        start: 2,
        end: 3,
        inserted: 1,
        newOutline: [_h(0)],
        newLineCount: 4,
      );
      expect(after.foldedLines, isEmpty);
    });

    test('insertion inside a folded range keeps the fold (heading above)', () {
      final before = FoldState([_h(0), _h(2)], 5, folded: {2});
      final after = before.applyEdit(
        start: 3,
        end: 3,
        inserted: 1,
        newOutline: [_h(0), _h(2)],
        newLineCount: 6,
      );
      expect(after.foldedLines, {2});
    });

    test('replacement remaps folds around the replaced range', () {
      final before = FoldState([_h(0), _h(2), _h(5)], 7, folded: {0, 5});
      // Replace [2,4) with 1 line: net delta -1. Fold A (0) is above, fold C
      // (5) shifts to 4.
      final after = before.applyEdit(
        start: 2,
        end: 4,
        inserted: 1,
        newOutline: [_h(0), _h(4)],
        newLineCount: 6,
      );
      expect(after.foldedLines, {0, 4});
    });

    test('no-op edit keeps folds', () {
      final before = FoldState([_h(0), _h(2), _h(5)], 8, folded: {2, 5});
      final after = before.applyEdit(
        start: 0,
        end: 0,
        inserted: 0,
        newOutline: [_h(0), _h(2), _h(5)],
        newLineCount: 8,
      );
      expect(after.foldedLines, {2, 5});
    });

    test('a fold surviving an edit still hides its (recomputed) range', () {
      // doc: 0 #A, 1 x, 2 #B, 3 x, 4 x. Fold B (2) hides [3,5).
      final before = FoldState([_h(0), _h(2)], 5, folded: {2});
      expect(before.hiddenRanges, [(3, 5)]);
      // Insert 1 line at line 0: everything shifts down by 1.
      final after = before.applyEdit(
        start: 0,
        end: 0,
        inserted: 1,
        newOutline: [_h(1), _h(3)],
        newLineCount: 6,
      );
      expect(after.foldedLines, {3});
      // The folded range is recomputed from the new outline: [4,6).
      expect(after.hiddenRanges, [(4, 6)]);
    });
  });
}
