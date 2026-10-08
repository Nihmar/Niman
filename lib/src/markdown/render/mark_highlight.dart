/// The colour `==highlighted==` text is marked with (#279): a highlighter's
/// yellow, see-through so the text keeps its own colour on it, and quieter
/// at night, where a bright wash glares.
///
/// The same in every palette, as a highlighter is: the colour says "marked"
/// the way it does on paper, whichever theme the page wears.
library;

import 'package:flutter/painting.dart';

/// The mark on a light page.
const Color markHighlightLight = Color(0x66FFD60A);

/// The mark on a dark page.
const Color markHighlightDark = Color(0x4DFFD60A);

/// The mark for a page that is [dark] or not.
Color markHighlightFor({required bool dark}) =>
    dark ? markHighlightDark : markHighlightLight;

/// The dotted line under an annotated passage (#626): a note is behind it,
/// which tells it from a yellow highlight. The amber of the palettes'
/// pictures, as the mark is the same in every palette.
Color annotationUnderlineFor({required bool dark}) =>
    dark ? const Color(0xFFD8A56B) : const Color(0xFFB26A25);

/// Paints a dotted line under [box], in [color].
void paintDottedUnderline(Canvas canvas, Rect box, Color color) {
  final paint = Paint()..color = color;
  const dot = 2.0;
  const gap = 2.0;
  for (var x = box.left; x < box.right; x += dot + gap) {
    canvas.drawRect(
      Rect.fromLTWH(x, box.bottom, (box.right - x).clamp(0, dot), dot),
      paint,
    );
  }
}

/// A highlight's colour (#626): the four a reader highlights a book or a
/// PDF with. Yellow is the `==mark==` yellow.
enum HighlightColour {
  /// The highlighter's own yellow.
  yellow(0xFFD60A),

  /// Green.
  green(0x4CD07D),

  /// Blue.
  blue(0x4FA3FF),

  /// Pink.
  pink(0xFF6FAE);

  new(this.rgb);

  /// The colour, without its alpha.
  final int rgb;

  /// How a link names the colour: `highlight=green`.
  String get id => name;

  /// The colour [id] names, or null when it names none.
  static HighlightColour? fromId(String? id) {
    for (final colour in values) {
      if (colour.id == id?.trim().toLowerCase()) return colour;
    }
    return null;
  }

  /// The colour on a page that is [dark] or not: as see-through as the
  /// mark's, so the text keeps its own colour on it.
  Color tint({required bool dark}) =>
      Color(0xFF000000 | rgb).withValues(alpha: markHighlightFor(dark: dark).a);
}
