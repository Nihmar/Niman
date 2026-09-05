import 'dart:math';

import 'package:copist/src/editor/row_model.dart';

/// The pixel geometry of the composing (pre-edit) underline, computed over a
/// fold-aware [RowModel]: a composing region (a buffer offset range) becomes
/// one rectangle per visual row it spans. Pure — the view's paint draws these;
/// no painting happens here.
///
/// The region is assumed to lie over visible (unfolded) lines: the IME only
/// ever composes text that is on screen, so `rowOfLine` below never throws for
/// a live composing region.
final class ComposingUnderline {
  /// Wraps [rows] with the monospace grid metrics — [rowHeight] pixels per
  /// visual row and [charWidth] pixels per column — the underline is drawn in.
  ComposingUnderline({
    required this.rows,
    required this.rowHeight,
    required this.charWidth,
  });

  /// The fold-aware row model the region is laid out over.
  final RowModel rows;

  /// The pixel height of one visual row.
  final double rowHeight;

  /// The pixel width of one monospace column.
  final double charWidth;

  /// The underline rectangles for the composing region [start, end), one per
  /// visual row it spans (empty when `start >= end`). Each record is
  /// `(x, y, width, height)` in pixels. A line break inside the region simply
  /// ends the underline at that row — the next row starts a fresh rectangle.
  List<(double x, double y, double width, double height)> rectsFor(
    int start,
    int end,
  ) {
    if (end <= start) return const <(double, double, double, double)>[];
    final (startRow, startCol) = _rowAndCol(start);
    final (endRow, endCol) = _rowAndCol(end);
    final rects = <(double, double, double, double)>[];
    for (var row = startRow; row <= endRow; row++) {
      final rowLen = _rowLength(row);
      final cs = row == startRow ? startCol : 0;
      final ce = row == endRow ? endCol : rowLen;
      final w = ce - cs;
      if (w <= 0) continue;
      rects.add((
        cs * charWidth,
        row * rowHeight,
        w * charWidth,
        rowHeight,
      ));
    }
    return rects;
  }

  /// Maps a full-text [offset] to its (visual row, column on that row).
  (int, int) _rowAndCol(int offset) {
    final (line, col) = rows.buffer.locationOf(offset);
    final row = rows.rowOfLine(line) + col ~/ rows.columns;
    return (row, col % rows.columns);
  }

  /// The number of columns the visual [row] occupies (its wrap width, or the
  /// remainder of its line if the line is shorter).
  int _rowLength(int row) {
    final (line, startCol) = rows.lineAndStartColumn(row);
    return min(rows.columns, rows.buffer.lineLength(line) - startCol);
  }
}
