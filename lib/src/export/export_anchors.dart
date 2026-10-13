/// Where a link into a heading lands on an exported page (#845).
///
/// A page gives each heading an id of its own text ([headingAnchor], made
/// unique in document order), and a link to `Note#Heading` points at it. A
/// `#` inside the fragment is ambiguous — `Issue #12` is a path of two levels
/// or one heading — and only the target's own headings can say which, the way
/// they do in the app ([headingLineOf]: the path first, then the whole
/// fragment). So for the links whose fragment holds a `#`, the exporter reads
/// the target's outline and resolves it the same way.
library;

import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/export/html_spans.dart';
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/parser.dart';

/// The page ids of the headings links name.
abstract final class ExportAnchors {
  /// The key a link to [target] with the fragment [heading] is found by.
  static String keyOf(String target, String heading) => '$target#$heading';

  /// The ids for the links of [text] whose heading holds a `#`, by
  /// [keyOf]; [textOf] reads the note a link's target names, or null when
  /// the page has no such note. An empty id is a heading the target lacks:
  /// the link then goes to the page, not to an id nothing carries.
  static Map<String, String> of(
    String text,
    String? Function(String target) textOf,
  ) {
    final out = <String, String>{};
    final texts = <String, String?>{};
    for (final link in parseLinks(text)) {
      if (link is! WikiLink) continue;
      final ref = link.ref;
      final heading = ref.heading;
      if (heading == null || !heading.contains('#')) continue;
      final key = keyOf(ref.target, heading);
      if (out.containsKey(key)) continue;
      final target = texts.putIfAbsent(ref.target, () => textOf(ref.target));
      if (target == null) continue;
      final anchor = parseAnchor(heading);
      out[key] = anchor is HeadingAnchor ? idOf(target, anchor) : '';
    }
    return out;
  }

  /// The id the heading [anchor] names has on the page of [text], or an
  /// empty one when no heading does.
  static String idOf(String text, HeadingAnchor anchor) {
    final outline = outlineOfText(text);
    final line = headingLineOf(outline, anchor);
    if (line == null) return '';
    final taken = <String>{};
    for (final entry in outline) {
      final id = uniqueHeadingId(taken, headingAnchor(entry.text));
      if (entry.line == line) return id;
    }
    return '';
  }
}
