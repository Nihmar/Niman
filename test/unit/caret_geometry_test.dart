import 'dart:ui' show TextRange;

import 'package:copist/src/editor/caret_geometry.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter/services.dart' show TextSelection;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RowModel model;
  late CaretGeometry geo;

  setUp(() {
    // 'ab' (line 0) + 'abcdef' (line 1); columns 4 → line 1 wraps to
    // 'abcd' (row 1) + 'ef' (row 2).
    final buffer = LineBuffer.fromText('ab\nabcdef');
    model = RowModel(buffer, columns: 4);
    geo = CaretGeometry(
      rowModel: model,
      charWidth: 10,
      rowHeight: 20,
      leftPadding: 5,
      caretHeight: 16,
    );
  });

  test('offsetToRowColumn maps buffer offsets to (row, col-in-row)', () {
    expect(model.offsetToRowColumn(0), (0, 0)); // 'a' (line 0)
    expect(model.offsetToRowColumn(2), (0, 2)); // end of 'ab'
    expect(model.offsetToRowColumn(3), (1, 0)); // 'a' (line 1, row 1)
    expect(model.offsetToRowColumn(6), (1, 3)); // 'd' (last of row 1)
    expect(model.offsetToRowColumn(7), (2, 0)); // 'e' (wraps to row 2)
    expect(model.offsetToRowColumn(9), (2, 2)); // end of 'abcdef'
  });

  test('caretRect spans the glyph height, centered in the row', () {
    final r = geo.caretRect(7); // (row 2, col 0).
    expect(r.left, 5); // 5 + 0 * 10.
    expect(r.top, 42); // 2 * 20 + (20 - 16) / 2.
    expect(r.width, 2);
    expect(r.height, 16); // the glyph height, not the row height.
  });

  test('composingUnderlines: single row spans the composing columns', () {
    // [3,5) = 'ab' (line 1, cols 0..2, row 1).
    final rects = geo.composingUnderlines(const TextRange(start: 3, end: 5));
    expect(rects, hasLength(1));
    final r = rects.single;
    expect(r.left, 5); // 5 + 0 * 10.
    expect(r.width, 20); // (2 - 0) * 10.
    expect(r.top, 39); // bottom of row 1: (1 + 1) * 20 - 1.
    expect(r.height, 1);
  });

  test('composingUnderlines: a collapsed range is empty', () {
    expect(
      geo.composingUnderlines(const TextRange(start: 3, end: 3)),
      isEmpty,
    );
  });

  test('selectionRects: single row hugs the glyphs with an inset (T3)', () {
    // [3,5) = 'ab' (line 1, in-row cols 0..2, row 1): grid edges would be
    // left 5, width 20; the inset hugs inside them.
    final rects = geo.selectionRects(
      const TextSelection(baseOffset: 3, extentOffset: 5),
    );
    expect(rects, hasLength(1));
    final r = rects.single;
    expect(r.left, 6); // 5 + 0 * 10 + inset 1.
    expect(r.width, 18); // (2 - 0) * 10 - 2 * inset.
    expect(r.top, 20); // full row height (row 1 * 20).
    expect(r.height, 20);
  });

  test('selectionRects: collapsed or invalid is empty', () {
    expect(
      geo.selectionRects(const TextSelection.collapsed(offset: 3)),
      isEmpty,
    );
    expect(
      geo.selectionRects(
        const TextSelection(baseOffset: -1, extentOffset: -1),
      ),
      isEmpty,
    );
  });
}
