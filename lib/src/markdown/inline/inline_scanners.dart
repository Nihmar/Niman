/// The pieces an inline is made of, each read from a position in the text:
/// what `cmark`'s `scanners.re` and the link scanning in `inlines.c` read,
/// by the GFM spec 0.29.
library;

import 'package:niman/src/markdown/inline/html5_entities.dart';
import 'package:niman/src/markdown/inline/inline_chars.dart';

/// Where a construct read at a position ends, and what it says.
abstract final class InlineScanners {
  /// The character reference at [at] (`&`) — what it stands for and where
  /// it ends — or null: a known HTML5 name, a decimal or a hexadecimal
  /// number, each closed by `;`.
  static (String, int)? entity(String text, int at) {
    final match = _entity.matchAsPrefix(text, at);
    if (match == null) return null;
    final name = match.group(1);
    if (name != null) {
      final characters = html5Entities[name];
      return characters == null ? null : (characters, match.end);
    }
    final decimal = match.group(2);
    final code = decimal != null
        ? int.parse(decimal)
        : int.parse(match.group(3)!, radix: 16);
    final valid =
        code > 0 && code <= 0x10FFFF && !(code >= 0xD800 && code <= 0xDFFF);
    return (String.fromCharCode(valid ? code : 0xFFFD), match.end);
  }

  /// The autolink at [at] (`<`) — its destination as written, whether it
  /// is an email address, and where it ends — or null.
  static (String, bool, int)? autolink(String text, int at) {
    final uri = _uriAutolink.matchAsPrefix(text, at);
    if (uri != null) return (uri.group(1)!, false, uri.end);
    final email = _emailAutolink.matchAsPrefix(text, at);
    if (email != null) return (email.group(1)!, true, email.end);
    return null;
  }

  /// Where the raw HTML at [at] (`<`) ends, or null: an open or closing
  /// tag, a comment, a processing instruction, a declaration or a CDATA
  /// section.
  static int? rawHtml(String text, int at) {
    for (final pattern in _html) {
      final match = pattern.matchAsPrefix(text, at);
      if (match != null) return match.end;
    }
    return null;
  }

  /// The link label at [at] (`[`) — what is between its brackets, as
  /// written, and where it ends — or null: no unescaped bracket inside,
  /// at most 999 characters.
  static (String, int)? linkLabel(String text, int at) {
    if (at >= text.length || text.codeUnitAt(at) != 0x5B) return null;
    var i = at + 1;
    while (i < text.length) {
      final char = text.codeUnitAt(i);
      if (char == 0x5C &&
          i + 1 < text.length &&
          InlineChars.isAsciiPunctuation(text.codeUnitAt(i + 1))) {
        i += 2;
      } else if (char == 0x5B) {
        return null;
      } else if (char == 0x5D) {
        if (i - at - 1 > 999) return null;
        return (text.substring(at + 1, i), i + 1);
      } else {
        i++;
      }
      if (i - at - 1 > 999) return null;
    }
    return null;
  }

  /// The link destination at [at] — as written, and where it ends — or
  /// null: `<…>` without a line ending or an unescaped `<`, or a run
  /// without spaces or control characters whose parentheses balance.
  static (String, int)? linkDestination(String text, int at) {
    if (at < text.length && text.codeUnitAt(at) == 0x3C) {
      var i = at + 1;
      while (i < text.length) {
        final char = text.codeUnitAt(i);
        if (char == 0x3E) return (text.substring(at + 1, i), i + 1);
        if (char == 0x5C &&
            i + 1 < text.length &&
            InlineChars.isAsciiPunctuation(text.codeUnitAt(i + 1))) {
          i += 2;
        } else if (char == 0x0A || char == 0x0D || char == 0x3C) {
          return null;
        } else {
          i++;
        }
      }
      return null;
    }
    var parens = 0;
    var i = at;
    while (i < text.length) {
      final char = text.codeUnitAt(i);
      if (char == 0x5C &&
          i + 1 < text.length &&
          InlineChars.isAsciiPunctuation(text.codeUnitAt(i + 1))) {
        i += 2;
        continue;
      }
      if (char == 0x28) {
        parens++;
        if (parens > 32) return null;
      } else if (char == 0x29) {
        if (parens == 0) break;
        parens--;
      } else if (char <= 0x20 || char == 0x7F) {
        break;
      }
      i++;
    }
    if (parens != 0) return null;
    return (text.substring(at, i), i);
  }

  /// The link title at [at] — between its delimiters, as written, and
  /// where it ends — or null: `"…"`, `'…'` or `(…)`, escapes allowed, no
  /// unescaped `(` in the last.
  static (String, int)? linkTitle(String text, int at) {
    if (at >= text.length) return null;
    final open = text.codeUnitAt(at);
    final close = switch (open) {
      0x22 => 0x22,
      0x27 => 0x27,
      0x28 => 0x29,
      _ => -1,
    };
    if (close < 0) return null;
    var i = at + 1;
    while (i < text.length) {
      final char = text.codeUnitAt(i);
      if (char == 0x5C && i + 1 < text.length) {
        i += 2;
        continue;
      }
      if (char == close) return (text.substring(at + 1, i), i + 1);
      if (open == 0x28 && char == 0x28) return null;
      i++;
    }
    return null;
  }

  /// [at] past spaces and tabs, at most one line ending, and the spaces
  /// and tabs after it.
  static int spaceNewline(String text, int at) {
    var i = _spaces(text, at);
    if (i < text.length && text.codeUnitAt(i) == 0x0D) i++;
    if (i < text.length && text.codeUnitAt(i) == 0x0A) i++;
    return _spaces(text, i);
  }

  static int _spaces(String text, int at) {
    var i = at;
    while (i < text.length &&
        (text.codeUnitAt(i) == 0x20 || text.codeUnitAt(i) == 0x09)) {
      i++;
    }
    return i;
  }

  /// [raw] with its backslash escapes and character references resolved:
  /// what a link's destination and title, and a code fence's info string,
  /// stand for.
  static String unescape(String raw) {
    if (!raw.contains(r'\') && !raw.contains('&')) return raw;
    final out = StringBuffer();
    var i = 0;
    while (i < raw.length) {
      final char = raw.codeUnitAt(i);
      if (char == 0x5C &&
          i + 1 < raw.length &&
          InlineChars.isAsciiPunctuation(raw.codeUnitAt(i + 1))) {
        out.writeCharCode(raw.codeUnitAt(i + 1));
        i += 2;
        continue;
      }
      if (char == 0x26) {
        final reference = entity(raw, i);
        if (reference != null) {
          out.write(reference.$1);
          i = reference.$2;
          continue;
        }
      }
      out.writeCharCode(char);
      i++;
    }
    return out.toString();
  }

  static final RegExp _entity = RegExp(
    '&(?:([A-Za-z][A-Za-z0-9]{0,31})|#([0-9]{1,7})|#[xX]([0-9A-Fa-f]{1,6}));',
  );

  static final RegExp _uriAutolink = RegExp(
    r'<([A-Za-z][A-Za-z0-9.+-]{1,31}:[^\x00-\x20<>]*)>',
  );

  static final RegExp _emailAutolink = RegExp(
    r"<([a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]"
    '(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>',
  );

  static const String _space = r'[ \t\x0B\x0C\r\n]';
  static const String _attribute =
      '$_space+[a-zA-Z_:][a-zA-Z0-9:._-]*'
      '(?:$_space*=$_space*'
      '(?:[^ \\t\\r\\n\\x0B\\x0C"\'=<>`\\x00]+|\'[^\']*\'|"[^"]*"))?';

  static final List<RegExp> _html = <RegExp>[
    RegExp('<[A-Za-z][A-Za-z0-9-]*(?:$_attribute)*$_space*/?>'),
    RegExp('</[A-Za-z][A-Za-z0-9-]*$_space*>'),
    RegExp(r'<!---->|<!--(?:-?[^\x00>-])(?:-?[^\x00-])*-->'),
    RegExp(r'<\?(?:[^?>\x00]+|\?[^>\x00]|>)*\?>'),
    RegExp('<![A-Z]+$_space+[^>\\x00]*>'),
    RegExp(r'<!\[CDATA\[(?:[^\]\x00]+|\][^\]\x00]|\]\][^>\x00])*\]\]>'),
  ];
}
