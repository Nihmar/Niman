import 'package:copist/src/editor/composing_underline.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // "ab\ncdefgh\nij": offsets a0 b1 \n2 c3 d4 e5 f6 g7 h8 \n9 i10 j11.
  // Rows (columns 4): row0 = line 0 "ab"; row1 = line 1 cols 0-3 "cdef";
  // row2 = line 1 cols 4-5 "gh"; row3 = line 2 "ij".
  ComposingUnderline build() => ComposingUnderline(
    rows: RowModel(LineBuffer.fromText('ab\ncdefgh\nij'), columns: 4),
    rowHeight: 10,
    charWidth: 5,
  );

  test('empty region has no rectangles', () {
    expect(build().rectsFor(0, 0), isEmpty);
    expect(build().rectsFor(3, 3), isEmpty);
  });

  test('single character is one rectangle', () {
    expect(build().rectsFor(0, 1), [(0.0, 0.0, 5.0, 10.0)]); // "a"
  });

  test('region spanning three rows gets one rectangle per row', () {
    expect(
      build().rectsFor(0, 8),
      [
        (0.0, 0.0, 10.0, 10.0), // "ab" on row 0
        (0.0, 10.0, 20.0, 10.0), // "cdef" on row 1
        (0.0, 20.0, 5.0, 10.0), // "g" on row 2
      ],
    );
  });

  test('region within one row is one rectangle', () {
    expect(build().rectsFor(3, 6), [(0.0, 10.0, 15.0, 10.0)]); // "cde"
  });

  test('region on the last line', () {
    expect(build().rectsFor(10, 12), [(0.0, 30.0, 10.0, 10.0)]); // "ij"
  });

  test('a newline-only region has no rectangle', () {
    expect(build().rectsFor(2, 3), isEmpty); // just "\n"
  });
}
