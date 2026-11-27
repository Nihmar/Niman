/// The text encoding a note's file is written in, which a save keeps (#1332).
///
/// A note is UTF-8 unless its file begins with a UTF-16 or UTF-32 byte order
/// mark: Windows Notepad's "Unicode" writes UTF-16 LE, and a UTF-16 file in
/// a script with no NUL bytes (Cyrillic, CJK) was read as Windows-1252 — it
/// opened as mojibake, and one keystroke saved the mojibake as UTF-8. A file
/// that begins with such a mark is decoded by it ([NoteEncoding.decode]) and
/// written back in it ([NoteEncoding.encode]), mark included, so changing one
/// character of the note changes one character of the file.
///
/// Only a mark says a file is UTF-16 or UTF-32: with none, UTF-16 is
/// indistinguishable from binary, and a file the rules below do not accept is
/// left to the rest of the loader (UTF-8, Windows-1252, or not text).
library;

import 'dart:convert';
import 'dart:typed_data';

/// How a note's text is turned into the bytes of its file.
enum NoteEncoding {
  /// UTF-8, with or without a byte order mark (`NoteFraming.bom`): the
  /// default, and every note a library creates.
  utf8,

  /// UTF-16, little endian, with its byte order mark (`FF FE`).
  utf16le,

  /// UTF-16, big endian, with its byte order mark (`FE FF`).
  utf16be,

  /// UTF-32, little endian, with its byte order mark (`FF FE 00 00`).
  utf32le,

  /// UTF-32, big endian, with its byte order mark (`00 00 FE FF`).
  utf32be;

  /// Whether this is a UTF-16 or UTF-32 encoding.
  bool get isWide => this != utf8;

  /// The encoding [bytes] declare with a byte order mark, when it is UTF-16
  /// or UTF-32 and the bytes can be read as that: an even number of bytes
  /// for UTF-16, a multiple of four for UTF-32 holding only code points
  /// (none past U+10FFFF, none a surrogate). Null for everything else —
  /// UTF-8, with or without its mark, included.
  static NoteEncoding? wideOf(List<int> bytes) {
    if (bytes.length < 2) return null;
    final a = bytes[0];
    final b = bytes[1];
    if (a == 0xFF && b == 0xFE) {
      // `FF FE 00 00` is UTF-32 LE, unless the file is UTF-16 LE whose first
      // character is U+0000: the bytes after it say which they are read as.
      if (bytes.length >= 4 && bytes[2] == 0 && bytes[3] == 0) {
        if (_isUtf32(bytes, Endian.little)) return utf32le;
      }
      return bytes.length.isEven ? utf16le : null;
    }
    if (a == 0xFE && b == 0xFF) return bytes.length.isEven ? utf16be : null;
    if (a == 0 &&
        b == 0 &&
        bytes.length >= 4 &&
        bytes[2] == 0xFE &&
        bytes[3] == 0xFF &&
        _isUtf32(bytes, Endian.big)) {
      return utf32be;
    }
    return null;
  }

  /// Whether [bytes] begin with a UTF-16 or UTF-32 byte order mark: the
  /// first bytes alone, for a reader that has no more of the file yet and
  /// will judge it whole with [wideOf].
  static bool hasWideMark(List<int> bytes) =>
      bytes.length >= 4 &&
      ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
          (bytes[0] == 0xFE && bytes[1] == 0xFF) ||
          (bytes[0] == 0 &&
              bytes[1] == 0 &&
              bytes[2] == 0xFE &&
              bytes[3] == 0xFF));

  /// The text of [bytes], which begin with this wide encoding's byte order
  /// mark (what [wideOf] answered for them): the mark itself is not part of
  /// the text. A lone surrogate is kept as it is, so it is written back as
  /// it was.
  String decode(List<int> bytes) {
    assert(isWide, 'only a wide encoding decodes here');
    final data = bytes is Uint8List
        ? ByteData.sublistView(bytes)
        : ByteData.sublistView(Uint8List.fromList(bytes));
    final width = this == utf16le || this == utf16be ? 2 : 4;
    final endian = this == utf16le || this == utf32le
        ? Endian.little
        : Endian.big;
    final units = data.lengthInBytes ~/ width;
    final out = StringBuffer();
    // A piece at a time: the list of a whole 246 MB note's code units is a
    // second copy of it.
    const piece = 1 << 16;
    for (var from = 1; from < units; from += piece) {
      final to = from + piece < units ? from + piece : units;
      out.write(
        width == 2
            ? String.fromCharCodes(<int>[
                for (var i = from; i < to; i++) data.getUint16(i * 2, endian),
              ])
            : String.fromCharCodes(<int>[
                for (var i = from; i < to; i++) data.getUint32(i * 4, endian),
              ]),
      );
    }
    return out.toString();
  }

  /// [text] as the bytes of a file in this encoding. A byte order mark is
  /// part of the text (U+FEFF), where there is one to write.
  Uint8List encode(String text) {
    switch (this) {
      case utf8:
        return const Utf8Encoder().convert(text);
      case utf16le || utf16be:
        final endian = this == utf16le ? Endian.little : Endian.big;
        final data = ByteData(text.length * 2);
        for (var i = 0; i < text.length; i++) {
          data.setUint16(i * 2, text.codeUnitAt(i), endian);
        }
        return data.buffer.asUint8List();
      case utf32le || utf32be:
        final endian = this == utf32le ? Endian.little : Endian.big;
        final runes = text.runes.toList(growable: false);
        final data = ByteData(runes.length * 4);
        for (var i = 0; i < runes.length; i++) {
          data.setUint32(i * 4, runes[i], endian);
        }
        return data.buffer.asUint8List();
    }
  }

  /// Whether [bytes] are a run of UTF-32 code points: a multiple of four,
  /// each a scalar value. A UTF-16 file that happens to begin `FF FE 00 00`
  /// does not pass: the second character of an ASCII text would be one
  /// code point past U+10FFFF.
  static bool _isUtf32(List<int> bytes, Endian endian) {
    if (bytes.length % 4 != 0) return false;
    final data = bytes is Uint8List
        ? ByteData.sublistView(bytes)
        : ByteData.sublistView(Uint8List.fromList(bytes));
    for (var at = 4; at < bytes.length; at += 4) {
      final point = data.getUint32(at, endian);
      if (point > 0x10FFFF || (point >= 0xD800 && point <= 0xDFFF)) {
        return false;
      }
    }
    return true;
  }
}
