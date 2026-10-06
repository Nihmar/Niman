/// What a quote holds, as the tree reads it (`BlockTree`): its lines inside
/// its marks, a callout's title left out, scanned — each line's laziness
/// and the columns of a tab its marks ended inside handed to the scan — so
/// a surface that draws a quote a line at a time, as `live` does, reads the
/// blocks the read view draws.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A quote's content, scanned.
final class QuoteContent {
  new _({
    required this.callout,
    required this.skipped,
    required this.lines,
    required this.origins,
    required this.blocks,
    required this.buffer,
  });

  /// The content of [quote], a quote block of [buffer] whose line `i`
  /// starts in the note at `origins(i)`: [BlockTree.inNote] for a note's
  /// own.
  factory of(
    Block quote,
    SourceBuffer buffer, {
    LineOrigin Function(int line) origins = BlockTree.inNote,
    bool appSyntax = true,
  }) {
    final (lines, starts) = BlockTree.contentOf(quote, buffer, origins);
    // A callout's title is no line of what it says (`BlockTree._quote`).
    final callout = appSyntax ? Callout.of(lines.first) : null;
    final skipped = callout == null ? 0 : 1;
    final body = lines.sublist(skipped);
    final from = starts.sublist(skipped);
    final content = SourceBuffer.fromText(body.join('\n'));
    return QuoteContent._(
      callout: callout,
      skipped: skipped,
      lines: body,
      origins: from,
      blocks: body.isEmpty
          ? const <Block>[]
          : BlockScanner(
              content,
              leftOver: [for (final origin in from) origin.leftOver],
              lazy: [for (final origin in from) origin.lazy],
              appSyntax: appSyntax,
            ).index.blocks,
      buffer: content,
    );
  }

  /// What the quote's first line says when it is a callout's (#279); null
  /// for a quote.
  final Callout? callout;

  /// How many of the quote's lines come before its content: a callout's
  /// title line, or none.
  final int skipped;

  /// The content's lines, inside the quote's marks.
  final List<String> lines;

  /// Where each of them starts in the note.
  final List<LineOrigin> origins;

  /// The blocks they make.
  final List<Block> blocks;

  /// The content as a text of its own, which [blocks] are of.
  final SourceBuffer buffer;

  /// The block line [line] of the content is in, or null.
  Block? blockAt(int line) {
    for (final block in blocks) {
      if (line >= block.startLine && line < block.endLine) return block;
    }
    return null;
  }

  /// The content of [quote], a quote among [blocks].
  QuoteContent inner(Block quote) =>
      QuoteContent.of(quote, buffer, origins: (line) => origins[line]);
}
