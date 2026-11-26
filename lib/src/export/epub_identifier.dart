/// A book's identifier (#1307): the one `unique-identifier` the package
/// names, which a reader — Apple Books, Kobo, KOReader, Calibre — takes to
/// be the book.
///
/// A random one on every export made the same note or folder a new book each
/// time, with its reading position and highlights left on the old one. The
/// identifier is the frontmatter's own when it gives one, and otherwise a
/// name-based UUID (version 5) of the exported note's or folder's
/// library-relative path: the same on every export, rebuilt from disk.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:niman/src/export/epub_package.dart';

/// The namespace Niman's book identifiers are named in: the URL namespace of
/// RFC 4122, `6ba7b811-9dad-11d1-80b4-00c04fd430c8`, and the project's own
/// address, as a version-5 UUID of the two.
final String epubNamespace = uuidV5(
  '6ba7b811-9dad-11d1-80b4-00c04fd430c8',
  'https://github.com/Nihmar/Niman',
);

/// The identifier of the book exported from [libraryPath] (a note's or a
/// folder's path in the library, relative to its root): the frontmatter's
/// `identifier:` or `isbn:` in [metadata] when it gives one, and a UUID
/// named by [libraryPath] when it does not.
///
/// An ISBN — whichever key it is under — is `urn:isbn:` and its digits, the
/// form EPUB readers and catalogues know it by.
String epubIdentifierOf(EpubMetadata metadata, String libraryPath) {
  final written = metadata.identifier?.trim();
  if (written != null && written.isNotEmpty) {
    return epubIsbnUrn(written) ?? written;
  }
  return 'urn:uuid:${uuidV5(epubNamespace, _name(libraryPath))}';
}

/// `urn:isbn:` and the digits of [text] when it is an ISBN-10 or an ISBN-13
/// (hyphens and spaces aside, `urn:isbn:` already in front or not) whose
/// check digit holds; null for anything else, which a book keeps as written.
String? epubIsbnUrn(String text) {
  var value = text.trim();
  if (value.toLowerCase().startsWith('urn:isbn:')) {
    value = value.substring('urn:isbn:'.length);
  }
  final digits = value.replaceAll(RegExp(r'[-\s]'), '').toUpperCase();
  final valid = switch (digits.length) {
    10 => _isbn10(digits),
    13 => _isbn13(digits),
    _ => false,
  };
  return valid ? 'urn:isbn:$digits' : null;
}

/// Whether [digits], ten characters, hold an ISBN-10's check digit.
bool _isbn10(String digits) {
  var sum = 0;
  for (var at = 0; at < 10; at++) {
    final char = digits[at];
    final value = char == 'X' && at == 9 ? 10 : int.tryParse(char);
    if (value == null) return false;
    sum += value * (10 - at);
  }
  return sum % 11 == 0;
}

/// Whether [digits], thirteen characters, hold an ISBN-13's check digit.
bool _isbn13(String digits) {
  var sum = 0;
  for (var at = 0; at < 13; at++) {
    final value = int.tryParse(digits[at]);
    if (value == null) return false;
    sum += value * (at.isEven ? 1 : 3);
  }
  return sum % 10 == 0;
}

/// [libraryPath] as the name a UUID is made of: `/` for a separator, none at
/// either end.
String _name(String libraryPath) =>
    libraryPath.replaceAll(r'\', '/').replaceAll(RegExp(r'^/+|/+$'), '');

/// The version-5 UUID of [name] in [namespace] (RFC 4122 §4.3): SHA-1 of the
/// namespace's bytes and the name's UTF-8, cut to 128 bits.
String uuidV5(String namespace, String name) {
  final hex = namespace.replaceAll('-', '');
  final bytes = <int>[
    for (var at = 0; at < 32; at += 2)
      int.parse(hex.substring(at, at + 2), radix: 16),
  ];
  final digest = sha1.convert(<int>[...bytes, ...utf8.encode(name)]).bytes;
  final id = digest.sublist(0, 16)
    ..[6] = (digest[6] & 0x0f) | 0x50
    ..[8] = (digest[8] & 0x3f) | 0x80;
  String byte(int at) => id[at].toRadixString(16).padLeft(2, '0');
  return '${byte(0)}${byte(1)}${byte(2)}${byte(3)}-${byte(4)}${byte(5)}-'
      '${byte(6)}${byte(7)}-${byte(8)}${byte(9)}-'
      '${byte(10)}${byte(11)}${byte(12)}${byte(13)}${byte(14)}${byte(15)}';
}
