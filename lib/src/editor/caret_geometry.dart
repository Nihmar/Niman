import 'dart:ui' show Rect, TextRange;

import 'package:copist/src/editor/row_model.dart';
import 'package:flutter/services.dart' show TextSelection;

/// The pixel geometry of the caret and the composing underline, given the
/// buffer layout ([RowModel]) and the monospace font metrics (character
/// width, row height, left padding).
///
/// Pure — it only computes [Rect]s, no painting — so it is
/// headless-verifiable; the caret painter just draws these rects.
final class CaretGeometry {
  /// Creates the geometry over [rowModel] with the given font metrics.
  const CaretGeometry({
    required this.rowModel,
    required this.charWidth,
    required this.rowHeight,
    required this.leftPadding,
    required this.caretHeight,
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

  /// The caret rect for buffer [offset]: a 2px-wide vertical line at the
  /// caret's column (2px — 1px read as flimsy on device, M2a on-device
  /// round 2), [caretHeight] tall, centered in the row — the full row
  /// height read as too tall (M2a on-device round 3).
  Rect caretRect(int offset) {
    final (row, col) = rowModel.offsetToRowColumn(offset);
    return Rect.fromLTWH(
      leftPadding + col * charWidth,
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
  /// row the selection spans.
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
      rects.add(
        Rect.fromLTWH(
          leftPadding + from * charWidth,
          row * rowHeight,
          (to - from) * charWidth,
          rowHeight,
        ),
      );
    }
    return rects;
  }
}
