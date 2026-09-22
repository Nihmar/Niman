/// The heading outline of a document (M2a E6 / T-M2-07): one entry per
/// heading line, in line order, used for the outline panel, fold anchors and
/// "outline click → jump".
///
/// The outline is derived from the tokenizer (T-M2-02) via its
/// [TokenKind.headingMarker] token, so it matches the highlighted headings
/// exactly — in particular a `#` line inside a code fence, a math block or
/// the frontmatter is not a heading.
library;

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_index.dart';

/// One heading in the outline.
final class OutlineEntry {
  /// Creates an outline entry for the heading on logical line [line].
  const new({required this.line, required this.level, required this.text});

  /// The logical line the heading is on.
  final int line;

  /// The heading level (number of `#`), 1..6.
  final int level;

  /// The heading text (the line with the `#` markers stripped, trimmed).
  final String text;
}

/// The headings of [text], without tokenizing it.
///
/// Same answer as [outlineOf] over `HighlightDocument.fromText(text).lines`
/// — `outline_test` pins them together — but it walks only the block state
/// machine, skipping the inline scan. That scan is the whole cost on a
/// maths-dense note: collecting 84 headings from a 931K one took ~1 s
/// through the tokenizer and a few ms this way (device report,
/// 2026-09-11).
///
/// For a caller that already holds a tokenized document, [outlineOf] is
/// free — use that instead of re-walking the text.
List<OutlineEntry> outlineOfText(String text) {
  final out = <OutlineEntry>[];
  HighlightDocument.forEachHeading(
    text,
    (line, level, heading) =>
        out.add(OutlineEntry(line: line, level: level, text: heading)),
  );
  return out;
}

/// The headings of a scanned note, one per heading block, in line order.
///
/// The answer [outlineOfText] gives, read off the [index] the editor's own
/// scan already produced instead of walking the text again: on a 246 MB note
/// that walk is most of a second per refresh, and the blocks are on screen
/// already (0.0.9 stress test). A heading is an ATX block, which is what the
/// scanner calls [BlockKind.heading]; the level is its `#` count, and the
/// text is the rest of its line, trimmed — the same three things the
/// tokenizer reports.
///
/// [line] reads a line's text by its index; the caller holds the buffer.
List<OutlineEntry> outlineOfBlocks(
  BlockIndex index,
  String Function(int line) line,
) {
  final out = <OutlineEntry>[];
  for (final block in index.blocks) {
    if (block.kind != BlockKind.heading || block.headingLevel <= 0) continue;
    final text = line(block.startLine);
    out.add(
      OutlineEntry(
        line: block.startLine,
        level: block.headingLevel,
        text: text.length > block.headingLevel
            ? text.substring(block.headingLevel).trim()
            : '',
      ),
    );
  }
  return out;
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
