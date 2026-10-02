/// Text measurement shared by the diagram layout and both drawings (#530).
///
/// A canvas can measure a string exactly and an exported SVG cannot, and a
/// diagram whose layout differed between the two would put the picture on
/// screen and the picture in the PDF in different places. So both use this
/// one approximation: an advance per character class, at the style's size.
/// It is deliberately deterministic, which also makes the layout testable.
library;

/// Measures label text for the layout and the drawings.
abstract final class DiagramMetrics {
  /// The width of [text] at [fontSize], in logical pixels.
  static double textWidth(String text, double fontSize) {
    var units = 0.0;
    for (final rune in text.runes) {
      units += _advance(rune);
    }
    return units * fontSize;
  }

  /// [label] broken at explicit line breaks, ready to draw line by line.
  static List<String> lines(String label) {
    final parts = label.split(RegExp(r'<br\s*/?>|\r?\n'));
    return [for (final part in parts) part.trim()];
  }

  /// The advance, in em, of one character. Narrow punctuation and wide
  /// scripts are the two cases the average gets wrong.
  static double _advance(int rune) {
    if (rune == 0x20 || rune == 0xA0) return 0.30;
    if (_isNarrow(rune)) return 0.30;
    if (_isWide(rune)) return 1;
    return 0.58;
  }

  /// Latin letters and digits with a narrow fixed advance.
  static bool _isNarrow(int rune) => switch (rune) {
    0x2C || 0x2E || 0x3A || 0x3B || 0x27 || 0x21 || 0x7C => true, // ,.:;'!|
    0x69 || 0x6C || 0x6A || 0x74 || 0x66 || 0x49 => true, // iljtfI
    _ => false,
  };

  /// CJK, Hangul and the other full-width scripts.
  static bool _isWide(int rune) =>
      (rune >= 0x1100 && rune <= 0x115F) ||
      (rune >= 0x2E80 && rune <= 0xA4CF) ||
      (rune >= 0xAC00 && rune <= 0xD7A3) ||
      (rune >= 0xF900 && rune <= 0xFAFF) ||
      (rune >= 0xFF00 && rune <= 0xFF60) ||
      (rune >= 0x20000 && rune <= 0x3FFFD);
}
