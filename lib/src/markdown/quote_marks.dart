/// The structural marks on the lines of a quote block — its `>`s, the list
/// markers and task boxes and the heading hashes inside it — as the block's
/// tree has them, for source mode's colours.
///
/// A quote's inside is not what its lines look like: a `# comment` in a
/// fence in it is code, `> foo` / `> 2. bar` is one paragraph, and the
/// scanner reads a quote as one block. The tree has already decided each
/// line, so the marks are taken from it, never matched again on the text.
library;

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/line_tokens.dart';
import 'package:niman/src/markdown/live_inlines.dart';

/// The marks of a quote block's lines, by the line counted from the block's
/// first: the same wherever the block moved to.
final class QuoteMarks {
  /// The marks of [root], the tree of a quote block that starts on line
  /// [first] of the note.
  factory of(BlockNode root, int first) {
    final marks = QuoteMarks._();
    final stack = <BlockNode>[root];
    while (stack.isNotEmpty) {
      switch (stack.removeLast()) {
        case ItemNode(:final marker, :final children):
          // The outermost item's, which is met first.
          marks._markers.putIfAbsent(marker.line - first, () => marker.start);
          stack.addAll(children);
        case QuoteNode(:final children) ||
            FootnoteNode(:final children) ||
            ColumnNode(:final children):
          stack.addAll(children);
        case ListNode(:final items):
          stack.addAll(items);
        case ColumnsNode(:final columns):
          stack.addAll(columns);
        case LeafNode(:final lines, :final kind):
          for (final span in lines) {
            marks._contentStart[span.line - first] = span.start;
          }
          if (kind == BlockKind.heading) {
            marks._headings.add(lines.first.line - first);
          }
      }
    }
    return marks;
  }

  new _();

  /// Where a leaf's text starts on each line a leaf holds: what is before
  /// it is the containers'.
  final Map<int, int> _contentStart = <int, int>{};

  /// The column an item's marker starts at, on the line it stands on.
  final Map<int, int> _markers = <int, int>{};

  /// The lines a heading starts on.
  final Set<int> _headings = <int>{};

  /// The marks on line [line] of the block, whose text is [text], added to
  /// [out]; answers where they end, before which no inline token is put.
  int on(int line, String text, List<InlinePiece> out) {
    final marker = _markers[line];
    // The containers' own: up to the item's marker, or the leaf's text, or
    // — a line with neither, a bare `>` or a callout's title — the line's
    // quote marks.
    var prefix =
        marker ??
        _contentStart[line] ??
        BlockParser.quotePrefixLength(text, 1 << 16);
    if (prefix > text.length) prefix = text.length;
    for (var at = 0; at < prefix; at++) {
      if (text.codeUnitAt(at) == 0x3E) {
        out.add(
          InlinePiece(TokenKind.blockquote, at, at + 1, LineTokens.structural),
        );
      }
    }
    var from = prefix;
    if (marker != null) from = LineTokens.listMarker(text, marker, out);
    if (_headings.contains(line)) {
      final heading = LineSyntax.headingMarkerOf(
        from == 0 ? text : text.substring(from),
      );
      if (heading != null) {
        final (start, hashes) = heading;
        out.add(
          InlinePiece(
            TokenKind.headingMarker,
            from + start,
            from + start + hashes,
            LineTokens.structural,
          ),
        );
        from += start + hashes;
      }
    }
    return from;
  }
}
