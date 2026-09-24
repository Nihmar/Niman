/// What a quote's lines are *inside* the quote, for `live`.
///
/// The read view reads a quote's content again as blocks of its own — its
/// marks off each line — and draws each as any block is drawn: a heading at
/// its size, a list's next lines under its item's text, a code block in its
/// box (`BlockView._quote`). `live` saw one quote block and drew every line
/// of it as quoted prose. Here the same content is scanned the same way, a
/// quote at a time, so a line of a quote can say what block it is in there
/// — and `live` draws it as that block, inside the quote's bar.
///
/// A quote inside the quote is read again in turn, down to the block that
/// is not a quote: that is the one a line is drawn as.
///
/// Kept until the note changes: the scan is the quote's, and a quote is a
/// few lines, so a keystroke in one scans that one again the next time a
/// line of it is drawn.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A line's block inside the quotes it is in: the block, the line's index
/// in the content the block was scanned from, and that content's lines —
/// the quote marks off them — which `block`'s lines index.
typedef QuotedLine = ({Block block, int line, List<String> lines});

/// A quote's content: its lines, marks off, and the blocks they make.
typedef _Scanned = ({List<String> lines, List<Block> blocks});

/// The quotes' contents scanned, by the quote's first line.
final class LiveQuoteContent {
  /// Each quote's content as blocks: its lines, marks off, and the blocks.
  final Map<int, _Scanned> _quotes = <int, _Scanned>{};

  SourceBuffer? _buffer;
  int _revision = -1;

  /// The block line [line] of [buffer] is in inside [quote], the quote it
  /// is a line of, with the line's index and text in that block's content;
  /// null for a line of no quote, or one the content has no block for.
  QuotedLine? of(int line, Block? quote, SourceBuffer buffer) {
    if (quote == null || quote.kind != BlockKind.quote) return null;
    if (!identical(buffer, _buffer) || buffer.revision != _revision) {
      _quotes.clear();
      _buffer = buffer;
      _revision = buffer.revision;
    }
    var scanned = _quotes.putIfAbsent(quote.startLine, () {
      final lines = <String>[
        for (var at = quote.startLine; at < quote.endLine; at++)
          _unquoted(buffer.lineAt(at), quote.quoteDepth),
      ];
      return _scan(lines);
    });
    var local = line - quote.startLine;
    // Down through the quotes inside the quote, to the block that is not one.
    for (var depth = 0; depth < _maxDepth; depth++) {
      final block = _blockAt(scanned.blocks, local);
      if (block == null) return null;
      if (block.kind != BlockKind.quote) {
        return (block: block, line: local, lines: scanned.lines);
      }
      final inner = <String>[
        for (var at = block.startLine; at < block.endLine; at++)
          _unquoted(scanned.lines[at], block.quoteDepth),
      ];
      local -= block.startLine;
      scanned = _scan(inner);
    }
    return null;
  }

  /// How many quotes inside one another are read again, as the read view
  /// reads them (`BlockView._maxQuoteNesting`).
  static const int _maxDepth = 8;

  /// [lines], scanned into blocks.
  static _Scanned _scan(List<String> lines) => (
    lines: lines,
    blocks: BlockScanner(SourceBuffer.fromText(lines.join('\n'))).index.blocks,
  );

  /// The block of [blocks] line [line] is in, or null.
  static Block? _blockAt(List<Block> blocks, int line) {
    for (final block in blocks) {
      if (line >= block.startLine && line < block.endLine) return block;
    }
    return null;
  }

  /// [line] without its first [depth] quote marks.
  static String _unquoted(String line, int depth) =>
      line.substring(BlockParser.quotePrefixLength(line, depth));
}
