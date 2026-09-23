/// The spelling's wavy underline, painted over a line rather than written into
/// its style.
///
/// A text style has one decoration, in one style and one colour: a misspelled
/// word drawn with a wavy red underline *as its style* lost whatever
/// decoration it already had — a struck-through word showed no strike, and
/// `live` mode, where the strike is the only thing left of `~~`, showed
/// nothing at all. Painted from the paragraph's own boxes, the squiggle is
/// drawn under whatever the text is.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Paints a wavy line under each of [ranges] of the paragraph [paragraph]
/// lays out. The painter must share the paragraph's origin: it is meant for
/// a `CustomPaint` whose child is that paragraph.
final class SquigglePainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.paragraph,
    required this.ranges,
    required this.color,
  });

  /// The key of the text whose paragraph is underlined.
  final GlobalKey paragraph;

  /// The ranges to underline, as offsets in the paragraph's text.
  final List<TextRange> ranges;

  /// The squiggle's colour.
  final Color color;

  /// How far the wave rises and falls, and how long one rise is.
  static const double _amplitude = 1.2;
  static const double _halfWave = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (ranges.isEmpty) return;
    final box = paragraph.currentContext?.findRenderObject();
    if (box is! RenderParagraph || !box.hasSize) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final range in ranges) {
      final boxes = box.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );
      for (final word in boxes) {
        if (word.right - word.left < 1) continue;
        canvas.drawPath(_wave(word.left, word.right, word.bottom - 2), paint);
      }
    }
  }

  /// A wave from [left] to [right] around [y].
  static Path _wave(double left, double right, double y) {
    final path = Path()..moveTo(left, y);
    var x = left;
    var up = true;
    while (x < right) {
      final next = x + _halfWave > right ? right : x + _halfWave;
      path.quadraticBezierTo(
        (x + next) / 2,
        up ? y - _amplitude * 2 : y + _amplitude * 2,
        next,
        y,
      );
      x = next;
      up = !up;
    }
    return path;
  }

  @override
  bool shouldRepaint(SquigglePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.paragraph != paragraph ||
      !_sameRanges(oldDelegate.ranges, ranges);

  static bool _sameRanges(List<TextRange> a, List<TextRange> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }
}
