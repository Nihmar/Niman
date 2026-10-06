/// The character classes the inline rules are written in
/// (`docs/dev/block-tree.md`; the GFM spec 0.29, §2.1).
library;

/// What CommonMark asks of a character.
abstract final class InlineChars {
  /// An ASCII punctuation character: what a backslash escapes.
  static bool isAsciiPunctuation(int char) =>
      (char >= 0x21 && char <= 0x2F) ||
      (char >= 0x3A && char <= 0x40) ||
      (char >= 0x5B && char <= 0x60) ||
      (char >= 0x7B && char <= 0x7E);

  /// A punctuation character: ASCII punctuation, or anything in the Unicode
  /// categories Pc, Pd, Pe, Pf, Pi, Po and Ps.
  static bool isPunctuation(int char) =>
      isAsciiPunctuation(char) ||
      (char > 0x7F && _punctuation.hasMatch(String.fromCharCode(char)));

  /// A Unicode whitespace character: category Zs, a tab, a line feed, a
  /// form feed or a carriage return. -1, a document's edge, counts as one.
  static bool isWhitespace(int char) =>
      char < 0 ||
      char == 0x20 ||
      char == 0x09 ||
      char == 0x0A ||
      char == 0x0C ||
      char == 0x0D ||
      (char > 0x7F && _space.hasMatch(String.fromCharCode(char)));

  /// A space, a tab or a line ending: what a link's parts are separated by.
  static bool isSpaceOrNewline(int char) =>
      char == 0x20 || char == 0x09 || char == 0x0A || char == 0x0D;

  /// The code point of [text] that ends just before [at], or -1 at the
  /// start.
  static int before(String text, int at) {
    if (at <= 0) return -1;
    final low = text.codeUnitAt(at - 1);
    if (at >= 2 && low >= 0xDC00 && low <= 0xDFFF) {
      final high = text.codeUnitAt(at - 2);
      if (high >= 0xD800 && high <= 0xDBFF) {
        return 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
      }
    }
    return low;
  }

  /// The code point of [text] that starts at [at], or -1 at the end.
  static int at(String text, int at) {
    if (at >= text.length) return -1;
    final high = text.codeUnitAt(at);
    if (high >= 0xD800 && high <= 0xDBFF && at + 1 < text.length) {
      final low = text.codeUnitAt(at + 1);
      if (low >= 0xDC00 && low <= 0xDFFF) {
        return 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
      }
    }
    return high;
  }

  static final RegExp _punctuation = RegExp(r'^\p{P}$', unicode: true);
  static final RegExp _space = RegExp(r'^\p{Zs}$', unicode: true);
}
