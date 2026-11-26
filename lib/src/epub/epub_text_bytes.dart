/// An EPUB's text files, from bytes to a string (#1312).
///
/// A book's XML and XHTML files are in whatever encoding their author chose,
/// and EPUB allows UTF-16 as well as UTF-8; books in the wild also declare
/// `encoding="windows-1252"` or `ISO-8859-1`. The rule is the XML
/// specification's (appendix F), in this order:
///
/// 1. a byte order mark: UTF-8, UTF-16 little or big endian;
/// 2. a UTF-16 file without one, which starts with `<` and then `?` in the
///    two bytes of one of the orders;
/// 3. the `encoding` of the XML declaration: `ISO-8859-1` and
///    `windows-1252` (and their other names) read each byte as its
///    Windows-1252 character, as a browser reads both, whatever else is
///    UTF-8;
/// 4. UTF-8, a byte that is not part of a sequence U+FFFD.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/markdown/note_bytes.dart';

/// [bytes], a text file of an EPUB, as the string its author wrote.
String decodeEpubText(Uint8List bytes) {
  if (_startsWith(bytes, const [0xEF, 0xBB, 0xBF])) {
    return utf8.decode(Uint8List.sublistView(bytes, 3), allowMalformed: true);
  }
  if (_startsWith(bytes, const [0xFE, 0xFF])) {
    return _utf16(Uint8List.sublistView(bytes, 2), bigEndian: true);
  }
  if (_startsWith(bytes, const [0xFF, 0xFE])) {
    return _utf16(Uint8List.sublistView(bytes, 2), bigEndian: false);
  }
  // `<?` with no byte order mark: its two bytes tell the order.
  if (_startsWith(bytes, const [0x3C, 0x00, 0x3F, 0x00])) {
    return _utf16(bytes, bigEndian: false);
  }
  if (_startsWith(bytes, const [0x00, 0x3C, 0x00, 0x3F])) {
    return _utf16(bytes, bigEndian: true);
  }
  if (_singleByteLabels.contains(_declaredEncoding(bytes))) {
    return _windows1252(bytes);
  }
  return utf8.decode(bytes, allowMalformed: true);
}

/// The names of the single-byte encodings read as Windows-1252: the WHATWG
/// labels of ISO-8859-1 and Windows-1252 (which a browser makes one) and
/// their common spellings.
const Set<String> _singleByteLabels = {
  'iso-8859-1',
  'iso8859-1',
  'iso_8859-1',
  'latin1',
  'latin-1',
  'l1',
  'windows-1252',
  'cp1252',
  'x-cp1252',
};

final RegExp _declaration = RegExp(
  r'''^<\?xml\s[^>]*?\bencoding\s*=\s*["']([A-Za-z0-9._-]+)["']''',
  caseSensitive: false,
);

/// The `encoding` the XML declaration at the start of [bytes] names, lower
/// case, or null when there is no declaration or it names none.
String? _declaredEncoding(Uint8List bytes) {
  // The declaration is ASCII and opens the file: its first bytes tell it.
  final head = latin1.decode(
    Uint8List.sublistView(bytes, 0, bytes.length < 200 ? bytes.length : 200),
  );
  return _declaration.firstMatch(head)?[1]?.toLowerCase();
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

/// [bytes] as UTF-16, a lone surrogate U+FFFD and an odd last byte dropped.
String _utf16(Uint8List bytes, {required bool bigEndian}) {
  final (high, low) = bigEndian ? (0, 1) : (1, 0);
  final units = Uint16List(bytes.length ~/ 2);
  var surrogates = false;
  for (var i = 0; i < units.length; i++) {
    final unit = bytes[2 * i + high] << 8 | bytes[2 * i + low];
    units[i] = unit;
    if (unit >= 0xD800 && unit <= 0xDFFF) surrogates = true;
  }
  final text = String.fromCharCodes(units);
  if (!surrogates) return text;
  // String.fromCharCodes keeps a lone surrogate as it is; a round trip
  // through UTF-8 makes it U+FFFD, as a browser shows it.
  return utf8.decode(utf8.encode(text), allowMalformed: true);
}

/// [bytes], each one as its Windows-1252 character: Latin-1 but for
/// `0x80`–`0x9F`, which Windows gives typographic characters.
String _windows1252(Uint8List bytes) {
  final units = Uint16List(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    units[i] = byte >= 0x80 && byte <= 0x9F ? _c1[byte - 0x80] : byte;
  }
  return String.fromCharCodes(units);
}

/// The characters of `0x80`–`0x9F` in Windows-1252: what the app's own rule
/// for notes ([decodeNoteText]) makes of one such byte, so there is one table.
final List<int> _c1 = [
  for (var byte = 0x80; byte <= 0x9F; byte++)
    decodeNoteText([byte]).codeUnitAt(0),
];
