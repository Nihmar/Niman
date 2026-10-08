/// What a browser puts on the clipboard beside the plain text of a
/// selection (#531): its HTML, and — on the desktop — the page it was
/// copied from.
///
/// Each platform hands it over in its own shape: Windows as one `HTML
/// Format` block of bytes (`cf_html.dart`), GTK as the bytes of each
/// target, Android as a string with no page. What they come to is this.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The clipboard's HTML, and the page it came from when the browser said.
@immutable
final class ClipboardHtml {
  /// [html] copied from the page at [source], when it is known.
  const new(this.html, {this.source});

  /// The HTML: a whole document or a fragment of one.
  final String html;

  /// The page the selection was copied from; null when the platform does
  /// not say (Android) or the browser did not.
  final Uri? source;
}

/// Reads the HTML the clipboard holds now.
abstract interface class ClipboardHtmlReader {
  /// The clipboard's HTML, or null when it holds none.
  Future<ClipboardHtml?> read();
}

/// A reader for a platform with no HTML on its clipboard: always none.
final class NoClipboardHtml implements ClipboardHtmlReader {
  /// The reader.
  const new();

  @override
  Future<ClipboardHtml?> read() async => null;
}

/// [bytes] of a clipboard target as text: UTF-16 when a byte-order mark
/// says so, or when the text is plainly UTF-16 without one (Firefox has
/// put `text/html` and its URL targets on the X11 clipboard that way),
/// UTF-8 otherwise. A trailing NUL — a C string's end — is not text.
String decodeClipboardText(Uint8List bytes) {
  var end = bytes.length;
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return _utf8(bytes.sublist(3));
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _utf16(bytes.sublist(2), bigEndian: false);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _utf16(bytes.sublist(2), bigEndian: true);
  }
  // Without a mark: text whose every second byte is zero is UTF-16 — no
  // UTF-8 text has a NUL in it.
  if (bytes.length >= 2 && bytes[0] != 0 && bytes[1] == 0) {
    return _utf16(bytes, bigEndian: false);
  }
  while (end > 0 && bytes[end - 1] == 0) {
    end--;
  }
  return _utf8(bytes.sublist(0, end));
}

String _utf8(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

String _utf16(List<int> bytes, {required bool bigEndian}) {
  final units = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    final unit = bigEndian
        ? bytes[i] << 8 | bytes[i + 1]
        : bytes[i + 1] << 8 | bytes[i];
    units.add(unit);
  }
  while (units.isNotEmpty && units.last == 0) {
    units.removeLast();
  }
  return String.fromCharCodes(units);
}

/// The page a source-URL target names: its first line, when that is a
/// web address — `text/x-moz-url-priv` is the URL alone, `text/x-moz-url`
/// the URL then the title. Null for anything else.
Uri? clipboardSourceUrl(String? text) {
  if (text == null) return null;
  final line = text.split(RegExp(r'[\r\n]')).first.trim();
  final uri = Uri.tryParse(line);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  return uri.host.isEmpty ? null : uri;
}
