import 'package:flutter/painting.dart';

/// The base direction of the line [text]: its first strong character's — a
/// Hebrew or Arabic letter makes it right-to-left, a letter of any other
/// script left-to-right — or null when it has none (an empty line, digits and
/// punctuation alone), and the surface's own direction stands (#1352).
///
/// What the recommendation of `docs/records/unified-surface.md` §6.9.11 asks
/// for: a note's direction is not the app's locale, or an English line in an
/// Arabic note, and an Arabic one in an English note, is drawn backwards
/// where it starts. Markers (`#`, `-`, `>`, `**`) are neutral, so `## שלום` is
/// right-to-left. Only the start of the line is read: a line that opens with
/// a thousand neutral characters is the surface's.
TextDirection? lineDirection(String text) {
  final end = text.length < _reach ? text.length : _reach;
  var at = 0;
  while (at < end) {
    var rune = text.codeUnitAt(at);
    var width = 1;
    if (rune >= 0xD800 && rune <= 0xDBFF && at + 1 < text.length) {
      final low = text.codeUnitAt(at + 1);
      if (low >= 0xDC00 && low <= 0xDFFF) {
        rune = 0x10000 + ((rune - 0xD800) << 10) + (low - 0xDC00);
        width = 2;
      }
    }
    at += width;
    if (rune < 0x80) {
      if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
        return TextDirection.ltr;
      }
      continue;
    }
    // The marks that say a direction in so many words.
    if (rune == 0x200F) return TextDirection.rtl;
    if (rune == 0x200E) return TextDirection.ltr;
    if (!_letter.hasMatch(String.fromCharCode(rune))) continue;
    return _isRightToLeft(rune) ? TextDirection.rtl : TextDirection.ltr;
  }
  return null;
}

/// How much of a line is read for its direction.
const int _reach = 1024;

/// Whether the letter [rune] belongs to a script written right to left: the
/// blocks of Hebrew, Arabic, Syriac, Thaana, N'Ko, Samaritan, Mandaic and
/// the Arabic extensions, their presentation forms, and the right-to-left
/// scripts of the supplementary planes (Phoenician, Adlam, ...).
bool _isRightToLeft(int rune) =>
    (rune >= 0x0590 && rune <= 0x08FF) ||
    (rune >= 0xFB1D && rune <= 0xFDFF) ||
    (rune >= 0xFE70 && rune <= 0xFEFF) ||
    (rune >= 0x10800 && rune <= 0x10FFF) ||
    (rune >= 0x1E800 && rune <= 0x1EFFF);

/// A letter of any script: marks, digits and punctuation have no direction of
/// their own.
final RegExp _letter = RegExp(r'^\p{L}$', unicode: true);
