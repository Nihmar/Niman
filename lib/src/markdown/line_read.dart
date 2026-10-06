/// One line as the block scan reads it, everything it needs at once.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/container_walk.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';

/// What the scan makes of one line, entered in a state: what it is, the
/// containers it stands in, and the state it leaves.
final class LineRead {
  /// A read of a line.
  const new({
    required this.kind,
    required this.walk,
    required this.items,
    required this.quoteDepth,
    required this.carried,
    required this.exit,
    this.heads = false,
  });

  /// What the line is.
  final BlockKind kind;

  /// The line walked through the containers open before it.
  final ContainerWalk walk;

  /// The list items the line stands in after it is read, outermost first —
  /// the ones it stays in and the one it opens, if it opens one; never the
  /// items inside a quote, which the quote's content is read again for.
  final List<OpenItem> items;

  /// How many quote levels the line's quote has: the open quote's when the
  /// line is in it, the new one's when it opens one, 0 otherwise.
  final int quoteDepth;

  /// Whether the line was read with what was open in its container before
  /// it — the same items, no quote ending — so it may go on with the block
  /// before it: a paragraph, a fence, a code block.
  final bool carried;

  /// The state after the line.
  final LineState exit;

  /// Whether the line is a table's head to the parser: the next line is a
  /// delimiter row in its container. It ends a paragraph the line would
  /// have gone on with, and is no setext underline, whether or not its
  /// cells fit the table.
  final bool heads;

  /// The line as its innermost item reads it ([ContainerWalk.text]), its
  /// leading tabs four columns each, as the parser's patterns count them.
  String get text => LineSyntax.expandIndent(walk.text);
}
