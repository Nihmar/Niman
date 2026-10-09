import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Lights the caret's row across the line, behind the text: typewriter mode's
/// row being written. The row is the caret's own — its top and its height —
/// so a wrapped paragraph lights the row the caret is on, not the paragraph.
///
/// A table row laid out in fitted columns is drawn a piece at a time, and the
/// caret is measured inside the piece it is in: the light takes the piece's
/// own shift, the way the caret does (`CaretPainter`), so it stands on the
/// visual line being written rather than a piece's height too high (#494).
final class CaretRowPainter extends CustomPainter {
  /// A light in [color] across the row of [rect], moved with [pieceShift].
  new({required this.rect, required this.color, this.pieceShift})
    : super(repaint: Listenable.merge(<Listenable?>[rect, pieceShift]));

  /// The caret, in its line's paragraph's coordinates.
  final ValueListenable<Rect?> rect;

  /// What the row is lit with.
  final Color color;

  /// Where the *piece* the caret is in sits in the same box, for a table row
  /// laid out in fitted columns: its `y` is what the light has to move by.
  final ValueListenable<Offset>? pieceShift;

  /// The rectangle the row is lit across, in the box this paints over: the
  /// caret's own row, shifted with the piece the caret is in — the same
  /// answer `CaretPainter` draws from.
  Rect? drawnRect(Size size) {
    final value = rect.value;
    if (value == null) return null;
    final dy = pieceShift?.value.dy ?? 0;
    return Rect.fromLTRB(0, value.top + dy, size.width, value.bottom + dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = drawnRect(size);
    if (drawn == null) return;
    canvas.drawRect(drawn, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CaretRowPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.color != color ||
      oldDelegate.pieceShift != pieceShift;
}

/// Draws the caret: a thin vertical bar at the rectangle the line's own layout
/// answered with.
///
/// It reads the rectangle and the blink at *paint* time and repaints when
/// either changes, so neither rebuilds the line it is drawn over.
final class CaretPainter extends CustomPainter {
  /// The caret at [rect], drawn while [on], moved by [shift] and
  /// [pieceShift].
  new({
    required this.rect,
    required this.on,
    this.shift = Offset.zero,
    this.pieceShift,
  }) : super(repaint: Listenable.merge(<Listenable?>[rect, on, pieceShift]));

  /// The caret, in its line's *paragraph's* coordinates.
  final ValueListenable<Rect?> rect;

  /// Whether the caret is drawn: it blinks.
  final ValueListenable<bool> on;

  /// Where the paragraph sits in the box this paints over: `live` indents a
  /// list item or a quote, and the caret drawn without it stood that far to
  /// the left of the character it was at.
  final Offset shift;

  /// Where the *piece* the caret is in sits in the same box, for a table row
  /// laid out in fitted columns: the caret is measured in the piece's own
  /// coordinates, so it is drawn from theirs.
  final ValueListenable<Offset>? pieceShift;

  @override
  void paint(Canvas canvas, Size size) {
    final value = rect.value;
    if (!on.value || value == null) return;
    canvas.drawRect(
      value.shift(shift + (pieceShift?.value ?? Offset.zero)),
      Paint()..color = const Color(0xFF7AA2F7),
    );
  }

  @override
  bool shouldRepaint(CaretPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.on != on ||
      oldDelegate.shift != shift ||
      oldDelegate.pieceShift != pieceShift;
}
