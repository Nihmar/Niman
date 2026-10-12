/// A fenced div's fence line in `live` (#729, `docs/records/note-columns.md`,
/// "Fence lines"): out of the caret's reach a band of half an em with
/// nothing drawn in it; with the caret in its block, markers in the band's
/// own room — a column opener's hairline and a chip naming it, the outer
/// opener's chip — so nothing moves when the caret comes in.
library;

import 'package:flutter/rendering.dart';

/// What `live` draws for a fence line: the lines of the `columns` block it
/// is a fence of, `[start, end)`, which say when the caret is in the block;
/// the chip that names it, if any — and which side of the band it stands
/// at — and whether it draws a hairline across the band. And whether the
/// gutter numbers it: the outer fences of a side-by-side block, whose
/// columns' lines are not numbered — the number standing out of the band,
/// up from a closer (`numberUp`) and down from an opener.
typedef LiveFence = ({
  int start,
  int end,
  String? chip,
  bool chipLeft,
  bool hairline,
  bool numbered,
  bool numberUp,
});

/// Paints a fence band's markers: a hairline across its middle and a chip,
/// a pill a little taller than the band, centred on it.
final class FenceBandPainter extends CustomPainter {
  /// Markers for [fence], in [color] on a [chipColor] pill, its text set in
  /// [chipStyle].
  new({
    required this.fence,
    required this.color,
    required this.chipColor,
    required this.chipStyle,
  });

  /// The fence line's markers.
  final LiveFence fence;

  /// The hairline's colour, and the chip's text's.
  final Color color;

  /// The chip's pill.
  final Color chipColor;

  /// The chip's text.
  final TextStyle chipStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.height / 2;
    if (fence.hairline) {
      canvas.drawLine(
        Offset(0, middle),
        Offset(size.width, middle),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );
    }
    final chip = fence.chip;
    if (chip == null) return;
    final text = TextPainter(
      text: TextSpan(
        text: chip,
        style: chipStyle.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final padding = text.height / 2;
    final width = text.width + 2 * padding;
    final left = fence.chipLeft ? 0.0 : size.width - width;
    final pill = RRect.fromLTRBR(
      left,
      middle - text.height / 2,
      left + width,
      middle + text.height / 2,
      Radius.circular(text.height / 2),
    );
    canvas.drawRRect(pill, Paint()..color = chipColor);
    text
      ..paint(canvas, Offset(left + padding, middle - text.height / 2))
      ..dispose();
  }

  @override
  bool shouldRepaint(FenceBandPainter old) =>
      old.fence != fence ||
      old.color != color ||
      old.chipColor != chipColor ||
      old.chipStyle != chipStyle;
}
