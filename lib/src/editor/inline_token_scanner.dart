import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/editor/token.dart';
import 'package:niman/src/editor/token_kind.dart';

/// Whether [c] is an ASCII whitespace code unit.
bool isSpaceChar(int c) =>
    c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0B || c == 0x0C || c == 0x0D;

/// The highlighter's inline scan: the inline constructs of a line, as tokens.
abstract final class InlineTokenScanner {
  // A destination holds no parentheses; a title after it may be one in
  // parentheses, `[x](a.md (Title))`.
  static final RegExp _image = RegExp(
    r'!\[[^\]\n]*\]\([^()\n]*(?:[ \t]\([^()\n]*\))?\)',
  );
  static final RegExp _link = RegExp(
    r'\[[^\[\]\n]*\]\([^()\n]*(?:[ \t]\([^()\n]*\))?\)',
  );
  static final RegExp _wiki = RegExp(r'\[\[[^\[\]\n]*\]\]');
  static final RegExp _boldStar = RegExp(r'\*\*[^*\n]+\*\*');
  static final RegExp _boldUnder = RegExp('__(?:[^_]|_(?:[^_]))+__');
  static final RegExp _strike = RegExp(r'~~[^~\n]+~~');
  static final RegExp _highlight = RegExp(r'==[^\s=](?:[^=\n]*[^\s=])?==');
  static final RegExp _italicStar = RegExp(r'\*[^*\n]+\*');
  static final RegExp _italicUnder = RegExp('_(?:[^_]|_(?:[^_]))+_');

  /// `#tag`: unicode letters and digits plus the `_`, `/` and `-` a tag has
  /// always allowed — the same class `AppSyntax` reads, so `#città`
  /// is one tag here and one tag in the index.
  static final RegExp _tag = RegExp(r'#([\p{L}\p{N}_/-]+)', unicode: true);

  /// The first match of [re] in [line] at/after [pos] (or null).
  static RegExpMatch? _first(RegExp re, String line, int pos) {
    final it = re.allMatches(line, pos).iterator;
    return it.moveNext() ? it.current : null;
  }

  /// Adds to [out] the tokens of the inline constructs of [line] from offset
  /// [from] on, in order and disjoint.
  static void scan(List<Token> out, String line, int from) {
    var pos = from;
    while (pos < line.length) {
      var bestKind = TokenKind.plain;
      var bestStart = -1;
      var bestEnd = -1;
      void consider(TokenKind kind, int start, int end) {
        if (start < pos || end <= start) return;
        if (bestStart == -1 || start < bestStart) {
          bestKind = kind;
          bestStart = start;
          bestEnd = end;
        }
      }

      final code = _findCode(line, pos);
      if (code != null) {
        consider(TokenKind.codeInline, code.$1, code.$2);
      }
      final math = findInlineMath(line, pos);
      if (math != null) {
        consider(TokenKind.mathInline, math.$1, math.$2);
      }
      final image = _first(_image, line, pos);
      if (image != null) {
        consider(TokenKind.image, image.start, image.end);
      }
      final wiki = _first(_wiki, line, pos);
      if (wiki != null) {
        consider(TokenKind.wikilink, wiki.start, wiki.end);
      }
      final link = _first(_link, line, pos);
      if (link != null) {
        consider(TokenKind.link, link.start, link.end);
      }
      final boldStar = _first(_boldStar, line, pos);
      if (boldStar != null) {
        consider(TokenKind.bold, boldStar.start, boldStar.end);
      }
      final boldUnder = _first(_boldUnder, line, pos);
      if (boldUnder != null) {
        consider(TokenKind.bold, boldUnder.start, boldUnder.end);
      }
      final strike = _first(_strike, line, pos);
      if (strike != null) {
        consider(TokenKind.strike, strike.start, strike.end);
      }
      final highlight = _first(_highlight, line, pos);
      if (highlight != null) {
        consider(TokenKind.highlight, highlight.start, highlight.end);
      }
      final italicStar = _findItalicStar(line, pos);
      if (italicStar != null) {
        consider(TokenKind.italic, italicStar.$1, italicStar.$2);
      }
      final italicUnder = _findItalicUnder(line, pos);
      if (italicUnder != null) {
        consider(TokenKind.italic, italicUnder.$1, italicUnder.$2);
      }
      final tag = _first(_tag, line, pos);
      if (tag != null) {
        final precededBySpace =
            tag.start == 0 || isSpaceChar(line.codeUnitAt(tag.start - 1));
        if (precededBySpace) {
          consider(TokenKind.tag, tag.start, tag.end);
        }
      }

      if (bestStart == -1) break;
      out.add(Token(bestKind, bestStart, bestEnd));
      pos = bestEnd;
    }
  }

  /// `` `code` `` at/after [from]: the backtick run must close with a run of
  /// the same length (a maximal run). Returns (start, end) or null.
  static (int, int)? _findCode(String line, int from) {
    var i = from;
    while (i < line.length && line.codeUnitAt(i) != 0x60) {
      i++;
    }
    if (i >= line.length) return null;
    final runStart = i;
    var run = 0;
    while (i < line.length && line.codeUnitAt(i) == 0x60) {
      run++;
      i++;
    }
    var k = i;
    while (k < line.length) {
      final next = line.indexOf('`', k);
      if (next == -1) return null;
      var len2 = 0;
      var m = next;
      while (m < line.length && line.codeUnitAt(m) == 0x60) {
        len2++;
        m++;
      }
      if (len2 == run) {
        return (runStart, m);
      }
      k = m;
    }
    return null;
  }

  /// `*…*` not part of `**`; validated because Dart regex has no lookbehind.
  static (int, int)? _findItalicStar(String line, int from) {
    var pos = from;
    while (pos < line.length) {
      final m = _first(_italicStar, line, pos);
      if (m == null) return null;
      final okBefore = m.start == 0 || line.codeUnitAt(m.start - 1) != 0x2A;
      final okAfter = m.end >= line.length || line.codeUnitAt(m.end) != 0x2A;
      if (okBefore && okAfter) return (m.start, m.end);
      pos = m.start + 1;
    }
    return null;
  }

  /// `_…_` not intra-word.
  static (int, int)? _findItalicUnder(String line, int from) {
    var pos = from;
    while (pos < line.length) {
      final m = _first(_italicUnder, line, pos);
      if (m == null) return null;
      final okBefore =
          m.start == 0 ||
          !(_isWord(line.codeUnitAt(m.start - 1)) ||
              line.codeUnitAt(m.start - 1) == 0x5F);
      final afterCh = m.end < line.length ? line.codeUnitAt(m.end) : -1;
      final okAfter = afterCh == -1 || (!_isWord(afterCh) && afterCh != 0x5F);
      if (okBefore && okAfter) return (m.start, m.end);
      pos = m.start + 1;
    }
    return null;
  }

  static bool _isWord(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0x30 && c <= 0x39);
}
