/// The caret's rectangle — and a span's — as the source view measures it:
/// in the paragraph its line — or its piece of a wrapped table row — is
/// drawn in, the quantity `EditableText` computes for you and a surface
/// that paints its own text has to compute itself.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:niman/src/markdown/render/source_line.dart';

/// The caret's rectangle in [paragraph] at [position], in the paragraph's
/// own coordinates, [width] wide; [length] is the paragraph's text's.
///
/// The horizontal offset is the painter's, over the run the caret is really
/// over. Its *row* — the top and the height — comes from the paragraph's own
/// line metrics, not from the glyph the caret stands by: the space at the
/// end of a line is measured from a fallback face and answers a shorter box
/// than the line, so the caret shrank and the typewriter light over it
/// shrank with it (#509). An empty paragraph has no line metrics, and the
/// glyph's own height is all there is there.
Rect sourceCaretRectIn(
  RenderParagraph paragraph,
  TextPosition position,
  int length,
  double width,
) {
  final at = paragraph.getOffsetForCaret(
    position,
    Rect.fromLTWH(0, 0, width, 0),
  );
  // The line the caret stands on, as the paragraph bounds it: a box as tall
  // as the tallest run on its visual line ([ui.BoxHeightStyle.max]). Only
  // the characters either side of the caret are asked for, so a paragraph
  // the length of a chapter costs the same as a word; at a soft wrap the two
  // sit on different lines, and the one the caret's own offset is on wins.
  // That row is what makes a normal glyph and the trailing fallback space
  // answer alike, where the glyph's own box is shorter.
  final offset = position.offset;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(
      baseOffset: math.max(0, offset - 1),
      extentOffset: math.min(length, offset + 1),
    ),
    boxHeightStyle: ui.BoxHeightStyle.max,
  );
  // The row whose top is nearest the caret's, not the one that contains
  // it: at a text size off 100 % the rows' edges are fractions, and the
  // caret at a soft wrap came back a hair above the next row's top — so
  // it was drawn on the row before, and Down from there landed on the
  // same offset again, for ever (#620).
  Rect? nearest;
  for (final box in boxes) {
    final row = box.toRect();
    if (nearest == null ||
        (row.top - at.dy).abs() < (nearest.top - at.dy).abs()) {
      nearest = row;
    }
  }
  if (nearest != null) {
    return Rect.fromLTWH(at.dx, nearest.top, width, nearest.height);
  }
  // An empty paragraph bounds no line: the glyph's own height is all there.
  return Rect.fromLTWH(
    at.dx,
    at.dy,
    width,
    paragraph.getFullHeightForCaret(position),
  );
}

/// The caret rectangle at [local] of a line in global coordinates, from
/// [piece] of the line the offset is drawn in and its [paragraph].
///
/// A wrapped table row is drawn as one paragraph per piece, so the rectangle
/// is measured in that piece's own coordinates and shifted by where it
/// stands of the line's box.
Rect sourcePieceCaretRect(
  SourcePiece piece,
  RenderParagraph paragraph,
  int local,
) {
  final position = TextPosition(
    offset: (local - piece.start).clamp(0, paragraph.text.toPlainText().length),
  );
  final at = paragraph.getOffsetForCaret(
    position,
    const Rect.fromLTWH(0, 0, 1.5, 0),
  );
  return Rect.fromLTWH(
    at.dx,
    at.dy,
    1.5,
    paragraph.getFullHeightForCaret(position),
  ).shift(paragraph.localToGlobal(Offset.zero));
}

/// The rectangle `[start, end)` of a line covers — offsets local to the
/// line — in global coordinates, measured in [piece], the piece of the line
/// its text ends in, and its [paragraph]; null when it covers no box.
///
/// As the caret's, the span is measured in the piece it is drawn in and
/// shifted by where that piece stands of the line's box.
Rect? sourcePieceSpanRect(
  SourcePiece piece,
  RenderParagraph paragraph,
  int start,
  int end,
) {
  final length = paragraph.text.toPlainText().length;
  final from = (start - piece.start).clamp(0, length);
  final to = (end - piece.start).clamp(from, length);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: from, extentOffset: to),
  );
  if (boxes.isEmpty) return null;
  var left = boxes.first.left;
  var right = boxes.first.right;
  for (final box in boxes) {
    if (box.left < left) left = box.left;
    if (box.right > right) right = box.right;
  }
  return Rect.fromLTRB(
    left,
    boxes.first.top,
    right,
    boxes.first.bottom,
  ).shift(paragraph.localToGlobal(Offset.zero));
}
