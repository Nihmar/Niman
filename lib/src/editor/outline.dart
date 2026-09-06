/// The heading outline of a document (M2a E6 / T-M2-07): one entry per
/// heading line, in line order, used for the outline panel, fold anchors and
/// "outline click → jump".
///
/// The outline is derived from the tokenizer (T-M2-02) via its
/// [TokenKind.headingMarker] token, so it matches the highlighted headings
/// exactly — in particular a `#` line inside a code fence, a math block or
/// the frontmatter is not a heading.
library;

import 'package:copist/src/editor/highlighting.dart';

/// One heading in the outline.
final class OutlineEntry {
  /// Creates an outline entry for the heading on logical line [line].
  const OutlineEntry({
    required this.line,
    required this.level,
    required this.text,
  });

  /// The logical line the heading is on.
  final int line;

  /// The heading level (number of `#`), 1..6.
  final int level;

  /// The heading text (the line with the `#` markers stripped, trimmed).
  final String text;
}

/// The headings of a tokenized document, one per heading line, in line order.
///
/// [lines] is the tokenizer's styled lines (e.g. `HighlightDocument.lines`),
/// index `i` being logical line `i`.
List<OutlineEntry> outlineOf(Iterable<StyledLine> lines) {
  final out = <OutlineEntry>[];
  var line = 0;
  for (final l in lines) {
    final tokens = l.tokens;
    if (tokens.isNotEmpty &&
        tokens.first.kind == TokenKind.headingMarker &&
        tokens.first.start == 0) {
      final marker = tokens.first;
      out.add(
        OutlineEntry(
          line: line,
          // The level is the marker's length (number of `#`), not its end
          // offset — the two only coincide because the marker starts at 0
          // (checked above).
          level: marker.end - marker.start,
          text: l.text.substring(marker.end).trim(),
        ),
      );
    }
    line++;
  }
  return out;
}
