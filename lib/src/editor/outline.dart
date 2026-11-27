/// The heading outline of a document (M2a E6 / T-M2-07): one entry per
/// heading line, in line order, used for the outline panel, fold anchors and
/// "outline click → jump".
///
/// The outline is read off the block scan ([outlineOfBlocks]), the engine
/// the editor, the read view and the index all read a note with, so a `#`
/// line is a heading wherever they say it is one: not in a code fence or
/// indented code, a math block, an HTML block or comment, or the frontmatter
/// (#1373).
library;

import 'package:niman/src/links/block_anchors.dart' show withoutTrailingBlockId;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_list.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// One heading in the outline.
final class OutlineEntry {
  /// Creates an outline entry for the heading on logical line [line].
  const new({required this.line, required this.level, required this.text});

  /// The logical line the heading is on.
  final int line;

  /// The heading level (number of `#`), 1..6.
  final int level;

  /// The heading text (the line with the `#` markers stripped, trimmed, and
  /// the ` ^id` a block id ends it with taken off: the id names the block for
  /// a link, it is not part of what the heading says, #912).
  final String text;
}

/// [heading], the text after a heading's `#`s, as an [OutlineEntry] holds it:
/// trimmed, the trailing block id off — the one rule every outline path
/// ([outlineOfText], [outlineOfBlocks]) shares with the block scanner
/// (`withoutTrailingBlockId`), so a heading reads the same whichever way it
/// was found.
String _headingText(String heading) =>
    withoutTrailingBlockId(heading.trim()).trim();

/// The headings of [text], read off its block scan ([outlineOfBlocks]).
///
/// The answer the editor's outline and the index's headings share: the
/// engine's own, whatever a heading is inside — a quote's or an item's `#`
/// line is no heading of the note's outline, as it never was.
List<OutlineEntry> outlineOfText(String text) {
  final buffer = SourceBuffer.fromText(text);
  return outlineOfBlocks(BlockScanner(buffer).index, buffer.lineAt);
}

/// The headings of a scanned note, one per heading block, in line order.
///
/// Read off the [index] the editor's own scan already produced, instead of
/// scanning the text again: on a 246 MB note that is most of a second per
/// refresh, and the blocks are on screen already (0.0.9 stress test). A
/// heading is an ATX block, which is what the scanner calls
/// [BlockKind.heading]; the level is its `#` count, and the text is the rest
/// of its line, trimmed.
///
/// A setext heading is a heading block too, but its paragraph's lines and
/// an underline, with no marker to count: it is left out of the outline, as
/// it always was, rather than listed by one path and not the other (#361).
///
/// [line] reads a line's text by its index; the caller holds the buffer.
List<OutlineEntry> outlineOfBlocks(
  BlockIndex index,
  String Function(int line) line,
) {
  final out = <OutlineEntry>[];
  // One line is an ATX heading, whose text starts past its `#`s, which is how
  // the entry's text is read below.
  bool isHeading(Block block) =>
      block.kind == BlockKind.heading &&
      block.headingLevel > 0 &&
      block.lineCount == 1;
  final blocks = index.blocks;
  // A scanner's list packs its blocks, and reading one makes a block: only
  // the headings are asked for there.
  final headings = blocks is BlockList
      ? blocks.matching(isHeading, kind: BlockKind.heading)
      : blocks.where(isHeading);
  for (final block in headings) {
    final text = line(block.startLine);
    // The text starts past the `#`s where they stand: a heading may be
    // indented, and cutting its level off the line's start left `# ` in it.
    final marker = LineSyntax.headingMarkerOf(text);
    final after = marker == null ? text.length : marker.$1 + marker.$2;
    out.add(
      OutlineEntry(
        line: block.startLine,
        level: block.headingLevel,
        text: _headingText(text.substring(after)),
      ),
    );
  }
  return out;
}
