import 'dart:math' show min;

import 'package:copist/src/editor/row_model.dart';

/// Maps a pointer position (a pixel offset in the editor view) to a buffer
/// position (M2a E8a), over a fold-aware [RowModel] with a fixed monospace
/// row height and character width.
///
/// Pure math: the view supplies the pixel dimensions and the [RowModel]; the
/// "real tap/drag on Android + Linux" AC is the on-device half. The row is
/// chosen by the pointer's y (clamped to the last row), and the column is the
/// character boundary nearest the pointer's x (clamped to the row's length).
final class HitTest {
  /// Creates a hit-test over [rows] with [rowHeight] px per row and
  /// [charWidth] px per character.
  HitTest({
    required this.rows,
    required this.rowHeight,
    required this.charWidth,
  })  : assert(rowHeight > 0, 'rowHeight must be positive'),
        assert(charWidth > 0, 'charWidth must be positive');

  /// The visual-row model (already synced to the buffer / folds).
  final RowModel rows;

  /// The pixel height of one visual row.
  final double rowHeight;

  /// The pixel width of one monospace character.
  final double charWidth;

  /// The buffer (line, column) at pixel offset (x, y), clamped to the buffer.
  (int line, int col) positionAt(double x, double y) {
    final row = _clamp((y / rowHeight).floor(), 0, rows.rowCount - 1);
    final (line, startCol) = rows.lineAndStartColumn(row);
    final lineLen = rows.buffer.lineLength(line);
    final rowLen = min(rows.columns, lineLen - startCol);
    final col = _clamp((x / charWidth).round(), 0, rowLen);
    return (line, startCol + col);
  }

  /// The buffer offset (caret position) at pixel offset (x, y), clamped.
  int offsetAt(double x, double y) {
    final (line, col) = positionAt(x, y);
    return rows.buffer.offsetOf(line, col);
  }

  static int _clamp(int v, int lo, int hi) {
    return v < lo ? lo : (v > hi ? hi : v);
  }
}
