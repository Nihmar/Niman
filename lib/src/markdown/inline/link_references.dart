/// Link reference definitions as the inline parser looks them up: by a
/// normalized label (`cmark`'s `cmark_parse_reference_inline` and
/// `normalize_reference`).
library;

import 'package:niman/src/markdown/inline/inline_chars.dart';
import 'package:niman/src/markdown/inline/inline_scanners.dart';

/// A definition's destination and title, both resolved.
typedef LinkReference = ({String destination, String? title});

/// The rules of a link reference definition.
abstract final class LinkReferences {
  /// [label] as definitions and references are matched: case folded, its
  /// runs of white space one space, trimmed.
  ///
  /// Unicode's full case folding expands `ß` (and `ẞ`, through it) to
  /// `ss`, which Dart's `toUpperCase` leaves as it is: `[ẞ]` matches a
  /// definition of `[SS]`.
  static String normalize(String label) => label
      .trim()
      .replaceAll(_whitespace, ' ')
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .toUpperCase();

  /// The definitions at the start of [text], a paragraph's inline text,
  /// added to [into] (the first definition of a label wins); returns where
  /// the text after them starts.
  static int parseInto(String text, Map<String, LinkReference> into) {
    var at = 0;
    while (true) {
      final read = _definition(text, at);
      if (read == null) return at;
      into.putIfAbsent(read.$1, () => read.$2);
      at = read.$3;
    }
  }

  /// The definition at [at]: its normalized label, its reference and where
  /// the line after it starts.
  static (String, LinkReference, int)? _definition(String text, int at) {
    final label = InlineScanners.linkLabel(text, at);
    if (label == null) return null;
    final normalized = normalize(label.$1);
    if (normalized.isEmpty) return null;
    var i = label.$2;
    if (i >= text.length || text.codeUnitAt(i) != 0x3A) return null;
    i = InlineScanners.spaceNewline(text, i + 1);
    final destination = InlineScanners.linkDestination(text, i);
    if (destination == null) return null;
    final bracketed = i < text.length && text.codeUnitAt(i) == 0x3C;
    if (destination.$1.isEmpty && !bracketed) return null;
    i = destination.$2;
    final beforeTitle = i;
    var spaced = InlineScanners.spaceNewline(text, i);
    String? title;
    var afterTitle = beforeTitle;
    if (spaced != beforeTitle) {
      final read = InlineScanners.linkTitle(text, spaced);
      if (read != null) {
        title = read.$1;
        afterTitle = read.$2;
      }
    }
    // The line has to end after the title; if it does not, the definition
    // ends at its destination, when that ends its own line.
    var end = _lineEnd(text, title != null ? afterTitle : beforeTitle);
    if (end == null && title != null) {
      title = null;
      end = _lineEnd(text, beforeTitle);
    }
    if (end == null) return null;
    spaced = end;
    return (
      normalized,
      (
        destination: InlineScanners.unescape(destination.$1),
        title: title == null ? null : InlineScanners.unescape(title),
      ),
      spaced,
    );
  }

  /// Past the spaces at [at] and the line ending after them, or null when
  /// something else is on the line.
  static int? _lineEnd(String text, int at) {
    var i = at;
    while (i < text.length &&
        (text.codeUnitAt(i) == 0x20 || text.codeUnitAt(i) == 0x09)) {
      i++;
    }
    if (i >= text.length) return i;
    if (!InlineChars.isSpaceOrNewline(text.codeUnitAt(i))) return null;
    if (text.codeUnitAt(i) == 0x0D) i++;
    if (i < text.length && text.codeUnitAt(i) == 0x0A) i++;
    return i;
  }

  static final RegExp _whitespace = RegExp(r'[ \t\r\n]+');
}
