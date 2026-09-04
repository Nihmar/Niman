import 'package:copist/src/editor/hit_test.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // "ab\ncdefgh\nij": line 0 "ab" (1 row), line 1 "cdefgh" (2 rows at
  // columns 4), line 2 "ij" (1 row). Offsets: a0 b1 \n2 c3 d4 e5 f6 g7 h8
  // \n9 i10 j11 (length 12).
  HitTest build({Iterable<int>? lines}) {
    final buffer = LineBuffer.fromText('ab\ncdefgh\nij');
    final rows = lines == null
        ? RowModel(buffer, columns: 4)
        : RowModel(buffer, columns: 4, lines: lines);
    return HitTest(rows: rows, rowHeight: 10, charWidth: 5);
  }

  test('tap at the origin is (0,0)', () {
    expect(build().positionAt(0, 0), (0, 0));
  });

  test('tap within a row lands on the nearest column', () {
    final hit = build();
    expect(hit.positionAt(2.5, 0), (0, 1)); // x 2.5/5 = 0.5 -> col 1
    expect(hit.offsetAt(2.5, 0), 1);
  });

  test('tap past the row end clamps to the line end', () {
    final hit = build();
    expect(hit.positionAt(1000, 0), (0, 2)); // line 0 len 2
    expect(hit.offsetAt(1000, 0), 2);
  });

  test('tap on a later logical line', () {
    final hit = build();
    expect(hit.positionAt(0, 15), (1, 0)); // row 1 = line 1 start
    expect(hit.offsetAt(0, 15), 3);
    expect(hit.positionAt(2.5, 15), (1, 1)); // col 1 of line 1
    expect(hit.offsetAt(2.5, 15), 4);
  });

  test('tap on a wrapped row maps into the line at the wrapped column', () {
    final hit = build();
    // row 2 = line 1, columns 4..5 ("gh").
    expect(hit.positionAt(0, 25), (1, 4));
    expect(hit.offsetAt(0, 25), 7);
    expect(hit.positionAt(1000, 25), (1, 6)); // clamped to line 1 end
    expect(hit.offsetAt(1000, 25), 9);
  });

  test('tap on the last line', () {
    final hit = build();
    expect(hit.positionAt(0, 35), (2, 0));
    expect(hit.offsetAt(0, 35), 10);
    expect(hit.offsetAt(1000, 35), 12); // clamped to buffer end
  });

  test('negative or far positions clamp to the buffer', () {
    final hit = build();
    expect(hit.offsetAt(-100, -100), 0);
    expect(hit.offsetAt(1000, 1000), 12);
  });

  test('folding omits the folded rows from the mapping', () {
    // Fold line 1: visible lines [0, 2]. Row 0 = line 0, row 1 = line 2.
    final hit = build(lines: [0, 2]);
    expect(hit.positionAt(0, 15), (2, 0)); // row 1 is now line 2
    expect(hit.offsetAt(0, 15), 10);
  });
}
