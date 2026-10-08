/// A downloaded page's bytes as text (#531): its byte order mark first,
/// then its `Content-Type`, then a `<meta>` in its first 1024 bytes, else
/// UTF-8.
///
/// `package:html` decodes only ASCII and UTF-8 itself, and throws on
/// Windows-1252, so the page is decoded here, always, before it is parsed.
/// UTF-8, ASCII, Latin-1 and Windows-1252 are read by the app's own rule
/// for notes ([decodeNoteText]: UTF-8, any other byte its Windows-1252
/// character), UTF-16 by hand. Any other charset is null: the capture takes
/// it for a page with too little text, and the browser — which decodes
/// everything — reads it instead.
library;

import 'dart:convert';

import 'package:niman/src/markdown/note_bytes.dart';

/// The labels read as UTF-8, or as Windows-1252 where they are not: the
/// WHATWG labels of UTF-8, of Windows-1252, which ASCII and Latin-1 are on
/// the web, and their common spellings.
const Set<String> _noteTextLabels = {
  'utf-8',
  'utf8',
  'unicode-1-1-utf-8',
  'us-ascii',
  'ascii',
  'ansi_x3.4-1968',
  'iso-8859-1',
  'iso8859-1',
  'iso_8859-1',
  'latin1',
  'l1',
  'windows-1252',
  'cp1252',
  'x-cp1252',
};

/// The charset a `Content-Type` value names, lower case, or null.
String? charsetOfContentType(String? contentType) {
  if (contentType == null) return null;
  final match = RegExp(
    r'''charset\s*=\s*["']?\s*([^\s;"']+)''',
    caseSensitive: false,
  ).firstMatch(contentType);
  return match?[1]!.toLowerCase();
}

/// The charset a `<meta>` in the first 1024 bytes of [bytes] names, lower
/// case, or null.
String? charsetOfMeta(List<int> bytes) {
  final head = latin1.decode(bytes.take(1024).toList());
  final match = RegExp(
    r'''<meta[^>]*?charset\s*=\s*["']?\s*([A-Za-z0-9_.:-]+)''',
    caseSensitive: false,
  ).firstMatch(head);
  return match?[1]!.toLowerCase();
}

/// [bytes] as text, or null when their charset is not one decoded here.
String? decodePage(List<int> bytes, {String? contentType}) {
  // A byte order mark wins over anything the page says.
  if (_startsWith(bytes, const [0xEF, 0xBB, 0xBF])) {
    return decodeNoteText(bytes.sublist(3));
  }
  if (_startsWith(bytes, const [0xFE, 0xFF])) {
    return _utf16(bytes.sublist(2), bigEndian: true);
  }
  if (_startsWith(bytes, const [0xFF, 0xFE])) {
    return _utf16(bytes.sublist(2), bigEndian: false);
  }
  final label =
      charsetOfContentType(contentType) ?? charsetOfMeta(bytes) ?? 'utf-8';
  if (_noteTextLabels.contains(label)) return decodeNoteText(bytes);
  return switch (label) {
    'utf-16be' => _utf16(bytes, bigEndian: true),
    'utf-16le' || 'utf-16' => _utf16(bytes, bigEndian: false),
    _ => null,
  };
}

bool _startsWith(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

/// [bytes] as UTF-16, a lone surrogate made U+FFFD.
String _utf16(List<int> bytes, {required bool bigEndian}) {
  final (high, low) = bigEndian ? (0, 1) : (1, 0);
  final units = <int>[
    for (var i = 0; i + 1 < bytes.length; i += 2)
      bytes[i + high] << 8 | bytes[i + low],
  ];
  // String.fromCharCodes keeps a lone surrogate as it is; a round trip
  // through UTF-8 makes it U+FFFD, as a browser shows it.
  return utf8.decode(
    utf8.encode(String.fromCharCodes(units)),
    allowMalformed: true,
  );
}
