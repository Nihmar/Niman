import 'dart:math' show max;
import 'dart:ui' show Rect, TextRange;

import 'package:copist/src/editor/row_model.dart';
import 'package:copist/src/editor/row_text_metrics.dart';
import 'package:flutter/services.dart' show TextSelection;

/// The pixel geometry of the caret and the composing underline, given the
/// buffer layout ([RowModel]) and the monospace font metrics (character
/// width, row height, left padding).
///
/// Pure — it only computes [Rect]s, no painting — so it is
/// headless-verifiable; the caret painter just draws these rects.
///
/// The caret x comes from [textMetrics] when given (a painter over the
/// row's exact slice — M2a round-4 R2, so the caret lands on the glyphs);
/// otherwise it falls back to the monospace grid. The multi-row spans
/// ([selectionRects], [composingUnderlines]) always stay on the grid: they
/// run on the per-frame paint path, where a painter layout per spanned row
/// would cost O(selection) per frame.
final class CaretGeometry {
  /// Creates the geometry over [rowModel] with the given font metrics,
  /// optionally measuring the caret x with [textMetrics].
  const CaretGeometry({
    required this.rowModel,
    required this.charWidth,
    required this.rowHeight,
    required this.leftPadding,
    required this.caretHeight,
    this.textMetrics,
  });

  /// The wrapped buffer layout (row/column mapping).
  final RowModel rowModel;

  /// The advance width of one monospace character, in px.
  final double charWidth;

  /// The height of one visual row, in px.
  final double rowHeight;

  /// The left inset of the text, in px.
  final double leftPadding;

  /// The caret height: one glyph's strut box
  /// ([`VirtualizedTextView.measureCaretHeight`]).
  final double caretHeight;

  /// The per-row painter metrics for the caret x, or null for the grid.
  final RowTextMetrics? textMetrics;

  /// The caret rect for buffer [offset]: a 2px-wide vertical line at the
  /// caret's column (2px — 1px read as flimsy on device, M2a on-device
  /// round 2), [caretHeight] tall, centered in the row — the full row
  /// height read as too tall (M2a on-device round 3).
  Rect caretRect(int offset) {
    // offsetToRowColumn's column is already the column within the row.
    final (row, colInRow) = rowModel.offsetToRowColumn(offset);
    final metrics = textMetrics;
    final x = metrics == null
        ? leftPadding + colInRow * charWidth
        : leftPadding + metrics.caretX(rowModel.rowSliceText(row), colInRow);
    return Rect.fromLTWH(
      x,
      row * rowHeight + (rowHeight - caretHeight) / 2,
      2,
      caretHeight,
    );
  }

  /// The composing-underline rects for [range] (empty when collapsed): a
  /// 1px horizontal bar under the composing characters, one per visual row
  /// the range spans.
  List<Rect> composingUnderlines(TextRange range) {
    if (range.isCollapsed) {
      return const <Rect>[];
    }
    final (startRow, startCol) = rowModel.offsetToRowColumn(range.start);
    final (endRow, endCol) = rowModel.offsetToRowColumn(range.end);
    final rects = <Rect>[];
    for (var row = startRow; row <= endRow; row++) {
      final from = row == startRow ? startCol : 0;
      final to = row == endRow ? endCol : rowModel.columns;
      if (to <= from) {
        continue;
      }
      rects.add(
        Rect.fromLTWH(
          leftPadding + from * charWidth,
          (row + 1) * rowHeight - 1,
          (to - from) * charWidth,
          1,
        ),
      );
    }
    return rects;
  }

  /// The selection-highlight rects for [selection] (empty when collapsed):
  /// full row-height rects covering the selected characters, one per visual
  /// row the selection spans. Edges hug the glyphs (~1 px inset) instead of
  /// the full advances (round-6 T3 — full-advance washes read too wide).
  List<Rect> selectionRects(TextSelection selection) {
    if (!selection.isValid || selection.isCollapsed) {
      return const <Rect>[];
    }
    final (startRow, startCol) = rowModel.offsetToRowColumn(selection.start);
    final (endRow, endCol) = rowModel.offsetToRowColumn(selection.end);
    final rects = <Rect>[];
    for (var row = startRow; row <= endRow; row++) {
      final from = row == startRow ? startCol : 0;
      final to = row == endRow ? endCol : rowModel.columns;
      if (to <= from) {
        continue;
      }
      rects.add(_selectionSpan(row, from, to));
    }
    return rects;
  }

  /// The horizontal wash inset, px per side, so the highlight hugs glyphs.
  static const double _highlightInset = 1;

  /// One highlight span over visual [row]'s columns [fromCol, toCol): the
  /// start/end edges come from the painter over the row's exact slice when
  /// metrics are present (at most two painter layouts per paint — bounded),
  /// grid otherwise; middle rows span the full row width either way.
  Rect _selectionSpan(int row, int fromCol, int toCol) {
    final metrics = textMetrics;
    final double left;
    final double right;
    if (metrics == null) {
      left = leftPadding + fromCol * charWidth;
      right = leftPadding + toCol * charWidth;
    } else {
      final slice = rowModel.rowSliceText(row);
      left = leftPadding + metrics.caretX(slice, fromCol);
      right = leftPadding + metrics.caretX(slice, toCol);
    }
    return Rect.fromLTWH(
      left + _highlightInset,
      row * rowHeight,
      max(0, right - left - 2 * _highlightInset).toDouble(),
      rowHeight,
    );
  }
}
