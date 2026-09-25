/// Percent-decoding for what a person writes in a link: a Markdown href
/// (`My%20Note.md`, as Obsidian writes it) or a place in a book (#282).
///
/// [Uri.decodeComponent] is for URIs, and throws on the text around the
/// escapes when it is not ASCII (`città%20note.md`), and on a `%` that
/// begins none (`100%.md`). A link is a person's text: its escapes are
/// decoded and the rest is kept as written.
library;

import 'dart:convert';

/// [s] with its `%XX` escapes decoded, runs of them read as UTF-8 (a byte
/// that is not reads as U+FFFD); a `%` that begins no escape, and every
/// other character, kept as written.
String percentDecoded(String s) {
  if (!s.contains('%')) return s;
  final out = StringBuffer();
  final bytes = <int>[];
  void flush() {
    if (bytes.isEmpty) return;
    out.write(utf8.decode(bytes, allowMalformed: true));
    bytes.clear();
  }

  var i = 0;
  while (i < s.length) {
    if (s.codeUnitAt(i) == 0x25 &&
        i + 2 < s.length &&
        _isHex(s.codeUnitAt(i + 1)) &&
        _isHex(s.codeUnitAt(i + 2))) {
      bytes.add(int.parse(s.substring(i + 1, i + 3), radix: 16));
      i += 3;
      continue;
    }
    flush();
    out.writeCharCode(s.codeUnitAt(i));
    i++;
  }
  flush();
  return out.toString();
}

bool _isHex(int unit) =>
    (unit >= 0x30 && unit <= 0x39) || // 0-9
    (unit >= 0x41 && unit <= 0x46) || // A-F
    (unit >= 0x61 && unit <= 0x66); // a-f
