/// What a quote's lines are *inside* the quote, for `live`.
///
/// The read view draws a quote's content as the tree reads it — its marks
/// off each line, a callout's title apart — each block as any block is
/// drawn: a heading at its size, a list's next lines under its item's text,
/// a code block in its box (`BlockView`). `live` saw one quote block and
/// drew every line of it as quoted prose. Here the same content is read
/// the same way ([QuoteContent]), a quote at a time, so a line of a quote
/// can say what block it is in there — and `live` draws it as that block,
/// inside the quote's bar.
///
/// A quote inside the quote is read again in turn, down to the block that
/// is not a quote: that is the one a line is drawn as.
///
/// Kept until the note changes: the scan is the quote's, and a quote is a
/// few lines, so a keystroke in one scans that one again the next time a
/// line of it is drawn.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/quote_content.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A line's block inside the quotes it is in: the block, the line's index
/// in the content the block was scanned from, and that content's lines —
/// the quote marks off them — which `block`'s lines index.
typedef QuotedLine = ({Block block, int line, List<String> lines});

/// The quotes' contents scanned, by the quote's first line.
final class LiveQuoteContent {
  /// Each quote's content, read.
  final Map<int, QuoteContent> _quotes = <int, QuoteContent>{};

  SourceBuffer? _buffer;
  int _revision = -1;

  /// The block line [line] of [buffer] is in inside [quote], the quote it
  /// is a line of, with the line's index and text in that block's content;
  /// null for a line of no quote, a callout's title line, or one the
  /// content has no block for.
  QuotedLine? of(int line, Block? quote, SourceBuffer buffer) {
    if (quote == null || quote.kind != BlockKind.quote) return null;
    var content = _contentOf(quote, buffer);
    var local = line - quote.startLine - content.skipped;
    // Down through the quotes inside the quote, to the block that is not one.
    for (var depth = 0; depth < _maxDepth; depth++) {
      if (local < 0) return null;
      final block = content.blockAt(local);
      if (block == null) return null;
      if (block.kind != BlockKind.quote) {
        return (block: block, line: local, lines: content.lines);
      }
      final inner = content.inner(block);
      local -= block.startLine + inner.skipped;
      content = inner;
    }
    return null;
  }

  /// The callout [quote] is, when its first line says it is one (#279);
  /// null for a quote that is only a quote, and for anything else.
  Callout? calloutOf(Block? quote, SourceBuffer buffer) {
    if (quote == null || quote.kind != BlockKind.quote) return null;
    return _contentOf(quote, buffer).callout;
  }

  /// [quote]'s content, read, kept until the note changes.
  QuoteContent _contentOf(Block quote, SourceBuffer buffer) {
    if (!identical(buffer, _buffer) || buffer.revision != _revision) {
      _quotes.clear();
      _buffer = buffer;
      _revision = buffer.revision;
    }
    return _quotes.putIfAbsent(
      quote.startLine,
      () => QuoteContent.of(quote, buffer),
    );
  }

  /// How many quotes inside one another are read again, as the read view
  /// draws them (`BlockView._maxNesting`).
  static const int _maxDepth = 8;
}
