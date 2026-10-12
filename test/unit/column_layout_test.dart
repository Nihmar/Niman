import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/column_layout.dart';

/// 16 em and 1.5 em at the 14 px body size.
const double _min = 224;
const double _gap = 21;

void main() {
  test('a width is a share; the others split what the widths leave', () {
    expect(ColumnLayout.shares([40, null]), [40, 60]);
    expect(ColumnLayout.shares([null, null, null]), [
      100 / 3,
      100 / 3,
      100 / 3,
    ]);
    expect(ColumnLayout.shares([25, null, null]), [25, 37.5, 37.5]);
    // Widths that leave nothing: the others share 100 / N each.
    expect(ColumnLayout.shares([70, 40, null]), [70, 40, 100 / 3]);
  });

  test('three equal columns in a 700 px column wrap two and one', () {
    // 3 x 224 + 2 x 21 = 714 > 700.
    expect(ColumnLayout.rows(3, width: 700, minimum: _min, gap: _gap), [
      [0, 1],
      [2],
    ]);
    expect(ColumnLayout.rows(3, width: 714, minimum: _min, gap: _gap), [
      [0, 1, 2],
    ]);
  });

  test('on a phone two columns stack', () {
    // 358 px of text; two columns need 469.
    final rows = ColumnLayout.rows(2, width: 358, minimum: _min, gap: _gap);
    expect(rows, [
      [0],
      [1],
    ]);
    expect(ColumnLayout.sideBySide(rows), isFalse);
  });

  test('a 40 / 60 pair splits the width after the gap by share', () {
    final widths = ColumnLayout.widths(
      [40, 60],
      width: 700,
      minimum: _min,
      gap: _gap,
    );
    expect(widths[0], closeTo(271.6, 0.01));
    expect(widths[1], closeTo(407.4, 0.01));
  });

  test('a column below its minimum is held there, the rest shares again', () {
    final widths = ColumnLayout.widths(
      [10, 90],
      width: 700,
      minimum: _min,
      gap: _gap,
    );
    expect(widths, [_min, 700 - _gap - _min]);
  });

  test('a column alone on its row is the row', () {
    expect(ColumnLayout.widths([40], width: 700, minimum: _min, gap: _gap), [
      700,
    ]);
    // Narrower than its minimum, it is the width there is.
    expect(ColumnLayout.widths([100], width: 150, minimum: _min, gap: _gap), [
      150,
    ]);
  });
}
