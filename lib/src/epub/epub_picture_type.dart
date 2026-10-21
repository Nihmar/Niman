/// What a book's picture is stored as when it is converted to notes (#1138):
/// the extension of the file in the attachments folder.
///
/// A book's own name for a picture is not to be trusted with that: it is any
/// text the zip holds. `x.md` would make an attachment the index reads as a
/// note, `a.png:stream` an alternate data stream on Windows, `a.png.` a file
/// Windows renames, a very long one a path it refuses. The extension comes
/// from the picture itself - its first bytes - and from a short list of
/// types the app shows; anything else is stored as an opaque file.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// The extension of a picture of a type the app shows and stores, or the
/// opaque [epubPictureFallback] for what is none of them.
///
/// The bytes decide first (a `.jpg` that is a PNG is stored as one); the
/// book's own name for it, [path] in the zip, decides only for a picture
/// they do not tell, and only if its extension is on the list.
String epubPictureExtension(String path, Uint8List bytes) {
  final sniffed = _sniffed(bytes);
  if (sniffed != null) return sniffed;
  final own = p.posix.extension(path).toLowerCase();
  return _stored.contains(own) ? own : epubPictureFallback;
}

/// The extension of a picture that is no type the app knows.
const String epubPictureFallback = '.bin';

/// The extensions a converted book's pictures are stored under: those the
/// capture of a page stores (`capture_pictures.dart`), the app's picture
/// types.
const Set<String> _stored = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.svg',
  '.bmp',
  '.avif',
};

String? _sniffed(Uint8List b) {
  bool at(int offset, List<int> bytes) {
    if (b.length < offset + bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (b[offset + i] != bytes[i]) return false;
    }
    return true;
  }

  if (at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return '.png';
  }
  if (at(0, const [0xFF, 0xD8, 0xFF])) return '.jpg';
  if (at(0, const [0x47, 0x49, 0x46, 0x38])) return '.gif';
  // RIFF....WEBP
  if (at(0, const [0x52, 0x49, 0x46, 0x46]) &&
      at(8, const [0x57, 0x45, 0x42, 0x50])) {
    return '.webp';
  }
  if (at(0, const [0x42, 0x4D])) return '.bmp';
  // ISO base media: ....ftypavif / ....ftypavis
  if (at(4, const [0x66, 0x74, 0x79, 0x70]) &&
      (at(8, const [0x61, 0x76, 0x69, 0x66]) ||
          at(8, const [0x61, 0x76, 0x69, 0x73]))) {
    return '.avif';
  }
  // An SVG is text: an `<svg` root, after an XML declaration, a doctype and
  // comments at most.
  final head = utf8.decode(
    b.sublist(0, b.length < 1024 ? b.length : 1024),
    allowMalformed: true,
  );
  if (_svgRoot.hasMatch(head)) return '.svg';
  return null;
}

final RegExp _svgRoot = RegExp(
  r'^﻿?\s*(<\?xml[^>]*\?>\s*)?(<!--[\s\S]*?-->\s*)*(<!DOCTYPE[^>]*>\s*)?'
  r'(<!--[\s\S]*?-->\s*)*<svg[\s>]',
  caseSensitive: false,
);
