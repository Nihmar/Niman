/// Where a block's caret and selection are drawn
/// (`docs/dev/unified-surface.md` §8.7.2).
///
/// The block owns a laid-out `TextPainter`; the document owns a
/// [SelectionModel] in source offsets. This is the seam between them: the
/// caret's rectangle, a selection's boxes, and the offset a tap lands on —
/// every one of them asked of the painter, never computed from metrics
/// this file keeps for itself.
///
/// That distinction is why the file exists at all. The hand-built editor this
/// repo replaced had its own `caret_geometry.dart` and `row_text_metrics.dart`,
/// and the caret's *rendered* position is what it was replaced over (`12d9f4a`;
/// §10.4 spike 2). Nothing here is allowed to guess: the geometry comes from
/// `getOffsetForCaret` and `getFullHeightForCaret`, whose behaviour was
/// measured in `test/unit/caret_rectangle_test.dart`.
library;

import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';

/// The caret and the selection of one block, in the block's own coordinates.
@immutable
final class CaretGeometry {
  /// The geometry of the block laid out as [painter], whose first character is
  /// document offset [sourceStart].
  ///
  /// [hidden] are the block's own hidden ranges — `hiddenRangesOf` of the
  /// parsed block — as offsets into its text. [ownsTrailingEdge] is true for
  /// the last block of the document, which is the one that draws the caret
  /// sitting at the very end: without it a caret at the end of the last
  /// block would belong to no block at all.
  const new({
    required this.painter,
    required this.sourceStart,
    required this.selection,
    this.hidden = const [],
    this.ownsTrailingEdge = false,
    this.caretWidth = 1.5,
  });

  /// The block, laid out. Its text is the block's source text, which is the
  /// invariant approach B keeps (§8.6.0).
  final TextPainter painter;

  /// The document offset of the block's first character.
  final int sourceStart;

  /// The document's caret and selection, in source offsets.
  final SelectionModel selection;

  /// The block's hidden ranges, as offsets into its own text.
  final List<(int, int)> hidden;

  /// Whether this block draws a caret at its own end.
  final bool ownsTrailingEdge;

  /// How wide the caret is drawn.
  ///
  /// It is the prototype's width, and the prototype's width is the one part of
  /// it that is not inert: it is folded into the offset for a right-to-left run
  /// and does nothing for a left-to-right one (measured in
  /// `test/unit/caret_rectangle_test.dart`).
  final double caretWidth;

  /// How many characters the block has.
  int get length => painter.plainText.length;

  /// The document offset one past the block's last character.
  int get sourceEnd => sourceStart + length;

  /// The caret's offset inside the block's own text, or null when the caret is
  /// not this block's to draw.
  int? caretLocal() {
    if (!selection.isCollapsed) return null;
    final local = selection.caret - sourceStart;
    if (local < 0 || local > length) return null;
    if (local == length && !ownsTrailingEdge) return null;
    return local;
  }

  /// The part of the document's selection this block paints, as offsets into
  /// its own text, or null when there is none: a collapsed selection is the
  /// caret's business, and the two blocks either side of a boundary each
  /// paint their own half.
  (int, int)? selectionLocal() {
    final first = selection.start > sourceStart ? selection.start : sourceStart;
    final last = selection.end < sourceEnd ? selection.end : sourceEnd;
    if (first >= last) return null;
    return (first - sourceStart, last - sourceStart);
  }

  /// The caret's rectangle, in the block's own coordinates, or null when the
  /// caret is not this block's.
  ///
  /// The prototype's height is deliberately zero: measured, the painter takes
  /// the caret's height from the line and ignores the prototype's, so computing
  /// a line height here would be inventing a number nothing reads.
  Rect? caretRect() {
    final local = caretLocal();
    if (local == null) return null;
    final prototype = Rect.fromLTWH(0, 0, caretWidth, 0);
    final position = TextPosition(offset: local);
    final at = painter.getOffsetForCaret(position, prototype);
    final height = painter.getFullHeightForCaret(position, prototype);
    return Rect.fromLTWH(at.dx, at.dy, caretWidth, height);
  }

  /// The selection's boxes, in the block's own coordinates, empty when this
  /// block paints none of it.
  List<Rect> selectionBoxes() {
    final local = selectionLocal();
    if (local == null) return const [];
    final (first, last) = local;
    return [
      for (final box in painter.getBoxesForSelection(
        TextSelection(baseOffset: first, extentOffset: last),
      ))
        box.toRect(),
    ];
  }

  /// The document offset a tap at [local] lands on.
  ///
  /// A tap inside a hidden marker snaps out of it — a caret the reader cannot
  /// see is a caret they cannot place — and which edge it leaves by is
  /// [SelectionModel.snap]'s rule, the same one the arrow keys use.
  int offsetAt(Offset local) {
    final at = painter.getPositionForOffset(local).offset;
    return sourceStart + SelectionModel.snap(from: at, to: at, runs: hidden);
  }

  @override
  String toString() =>
      'CaretGeometry($sourceStart..$sourceEnd, caret ${selection.caret})';
}
