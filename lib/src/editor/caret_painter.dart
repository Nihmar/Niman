import 'package:copist/src/editor/caret_geometry.dart';
import 'package:flutter/rendering.dart';

/// Paints the caret (a 1px vertical line) and the IME composing underline
/// (1px horizontal bars). The rects come from a [CaretGeometry]; this painter
/// only draws them, so its correctness reduces to the (separately tested)
/// geometry plus these two draw passes.
final class CaretPainter extends CustomPainter {
  /// Creates the painter. [caretVisible] gates the caret (the blink); the
  /// underline is always drawn when [composing] is non-collapsed.
  const CaretPainter({
    required this.geometry,
    required this.caretOffset,
    required this.composing,
    required this.caretVisible,
    required this.selection,
    this.scrollOffset = 0,
  });

  /// The rect source (caret + composing underline + selection).
  final CaretGeometry geometry;

  /// The caret's buffer offset.
  final int caretOffset;

  /// The IME composing range (the underlined region).
  final TextRange composing;

  /// Whether the caret is in the visible (on) blink phase.
  final bool caretVisible;

  /// The current selection (the highlighted region; a collapsed selection is
  /// the caret, not a highlight).
  final TextSelection selection;

  /// The scroll offset of the text; the content-space rects are translated up
  /// by this much so the overlay (viewport-sized) tracks the scrolled text.
  final double scrollOffset;

  static const Color _caretColor = Color(0xFF000000);
  static const Color _underlineColor = Color(0xFF1A73E8);
  static const Color _selectionColor = Color(0x331A73E8);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(0, -scrollOffset);
    // The selection highlight goes behind everything.
    for (final r in geometry.selectionRects(selection)) {
      canvas.drawRect(r, Paint()..color = _selectionColor);
    }
    for (final r in geometry.composingUnderlines(composing)) {
      canvas.drawRect(r, Paint()..color = _underlineColor);
    }
    if (caretVisible) {
      canvas.drawRect(
        geometry.caretRect(caretOffset),
        Paint()..color = _caretColor,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CaretPainter old) =>
      old.geometry != geometry ||
      old.caretOffset != caretOffset ||
      old.composing != composing ||
      old.caretVisible != caretVisible ||
      old.selection != selection ||
      old.scrollOffset != scrollOffset;
}
