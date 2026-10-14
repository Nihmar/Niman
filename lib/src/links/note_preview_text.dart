import 'dart:convert' show utf8;

import 'package:niman/src/links/preview_limits.dart';

/// The beginning of a note, as a preview shows it.
final class NotePreviewText {
  /// A note's [text] — all of it, or the first [PreviewLimits.bytes] bytes of
  /// it when [truncated].
  const new({required this.text, required this.truncated});

  /// The beginning of a note whose whole text is [text] — an open note's
  /// buffer — cut as a read off the disk is: its first [PreviewLimits.bytes]
  /// bytes of UTF-8, its line endings `\n`.
  // The lint reads the dot shorthand into a named factory's declaration; a
  // `factory .of` is not a declaration Dart parses.
  // ignore: unnecessary_type_name_in_constructor
  factory NotePreviewText.of(String text) {
    const limit = PreviewLimits.bytes;
    // A UTF-16 unit is at most three bytes of UTF-8: a text this short fits
    // whole, and a longer one is measured only as far as the cut.
    if (text.length * 3 <= limit) {
      return NotePreviewText(text: _lineFeeds(text), truncated: false);
    }
    // No character is cut in two: not a pair of UTF-16 units here, not the
    // bytes of one below.
    var units = text.length > limit ? limit : text.length;
    if (units < text.length && _isLead(text.codeUnitAt(units - 1))) units--;
    final bytes = utf8.encode(text.substring(0, units));
    if (bytes.length <= limit && units == text.length) {
      return NotePreviewText(text: _lineFeeds(text), truncated: false);
    }
    var cut = bytes.length < limit ? bytes.length : limit;
    while (cut < bytes.length && cut > 0 && bytes[cut] & 0xC0 == 0x80) {
      cut--;
    }
    final head = utf8.decode(bytes.sublist(0, cut));
    return NotePreviewText(text: _lineFeeds(head), truncated: true);
  }

  static bool _isLead(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static String _lineFeeds(String text) =>
      text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  /// The text, its line endings `\n`.
  final String text;

  /// Whether the note goes on past [text].
  final bool truncated;
}
