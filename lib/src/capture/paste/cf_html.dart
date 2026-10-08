/// Windows' `HTML Format` clipboard block (CF_HTML), read (#531).
///
/// The block is a header of `Key:Value` lines, then the HTML:
///
/// ```text
/// Version:0.9
/// StartHTML:0000000163
/// EndHTML:0000000310
/// StartFragment:0000000199
/// EndFragment:0000000274
/// SourceURL:https://example.com/page
/// <html><body><!--StartFragment-->…<!--EndFragment--></body></html>
/// ```
///
/// Every offset counts **bytes** of the UTF-8 block from its start, not
/// characters: a page with an accented letter or a CJK character before
/// the fragment moves it by more than one. So the block is cut as bytes
/// and only then decoded. `StartHTML` and `EndHTML` may be `-1` — no
/// context, the fragment alone — and an application that writes the
/// offsets wrong still has its HTML read, from the first `<` after the
/// header.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/capture/paste/clipboard_html.dart';

/// A CF_HTML block, read.
typedef CfHtml = ({
  /// The HTML with its context — the elements around the selection, a
  /// list around its items — or the fragment alone when there is none.
  String html,

  /// The selection itself, between `StartFragment` and `EndFragment`.
  String fragment,

  /// The `SourceURL` header, when it is a web page's address.
  Uri? source,
});

/// [bytes] of an `HTML Format` block, read; null when it holds no HTML.
CfHtml? parseCfHtml(Uint8List bytes) {
  var length = bytes.length;
  // The block is a C string, in an allocation that may be larger.
  final nul = bytes.indexOf(0);
  if (nul >= 0) length = nul;
  final header = <String, String>{};
  var at = 0;
  while (at < length && bytes[at] != _lessThan) {
    var end = at;
    while (end < length && bytes[end] != _lf && bytes[end] != _cr) {
      end++;
    }
    final line = utf8.decode(bytes.sublist(at, end), allowMalformed: true);
    final colon = line.indexOf(':');
    if (colon <= 0) break;
    header[line.substring(0, colon).trim()] = line.substring(colon + 1).trim();
    at = end;
    while (at < length && (bytes[at] == _lf || bytes[at] == _cr)) {
      at++;
    }
  }
  if (header.isEmpty) return null;
  final body = at;

  int? offset(String key) {
    final value = int.tryParse(header[key] ?? '');
    return value == null || value < 0 || value > length ? null : value;
  }

  String? slice(int? start, int? end) {
    if (start == null || end == null || end < start || start < body) {
      return null;
    }
    return utf8.decode(bytes.sublist(start, end), allowMalformed: true);
  }

  final rest = utf8.decode(bytes.sublist(body, length), allowMalformed: true);
  final fragment =
      slice(offset('StartFragment'), offset('EndFragment')) ??
      _betweenMarkers(rest) ??
      rest;
  final html = slice(offset('StartHTML'), offset('EndHTML')) ?? rest;
  if (html.trim().isEmpty && fragment.trim().isEmpty) return null;
  return (
    html: html.trim().isEmpty ? fragment : html,
    fragment: fragment,
    source: clipboardSourceUrl(header['SourceURL']),
  );
}

/// The block as the clipboard's HTML: its context kept, so list items
/// stay in their list.
ClipboardHtml clipboardHtmlOf(CfHtml block) =>
    ClipboardHtml(block.html, source: block.source);

/// What is between the fragment's comment markers in [html], when they
/// are there and the offsets were not usable.
String? _betweenMarkers(String html) {
  const open = '<!--StartFragment-->';
  const close = '<!--EndFragment-->';
  final start = html.indexOf(open);
  final end = html.indexOf(close);
  if (start < 0 || end < start) return null;
  return html.substring(start + open.length, end);
}

const int _lessThan = 0x3C;
const int _lf = 0x0A;
const int _cr = 0x0D;
