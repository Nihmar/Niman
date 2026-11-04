/// The long code blocks of the read view, cut into pieces the sliver lays
/// out one by one.
library;

import 'package:niman/src/markdown/block.dart';

/// Where in a longer code block a piece of it is: the first carries the
/// opening fence, the last the closing one; and the whole block's lines,
/// which each piece's copy button copies (#541).
typedef CodePiece = ({bool first, bool last, int start, int end});

/// Which entries of the read view's block list are pieces of a longer code
/// block.
final class ReadCodePieces {
  /// The lines a code block is drawn in pieces of, past twice as many.
  ///
  /// A block is the sliver's unit of layout, and a code block is one
  /// paragraph: a fence of 12 000 lines — a log pasted in, or a note whose
  /// fence never closes — was laid out whole the moment any of it scrolled
  /// into view, and one such frame took 74 s (0.0.9 stress test). Pieces of
  /// this many lines are laid out as the viewport reaches them, like any
  /// other block.
  static const int pieceLines = 200;

  /// Which entries of the block list are pieces of a longer code block, and
  /// where in it.
  final Map<int, CodePiece> _pieces = <int, CodePiece>{};

  /// Whether any entry is a piece.
  bool get isNotEmpty => _pieces.isNotEmpty;

  /// Entry [index]'s place in the code block it is a piece of, or null when
  /// it is a block of its own.
  CodePiece? operator [](int index) => _pieces[index];

  /// Forgets every piece.
  void clear() => _pieces.clear();

  /// [blocks] with every code block longer than twice [pieceLines] cut into
  /// pieces of that many lines, each an entry of its own.
  List<Block> pieced(List<Block> blocks) {
    _pieces.clear();
    if (!blocks.any(isLongCode)) return blocks;
    final out = <Block>[];
    for (final block in blocks) {
      if (!isLongCode(block)) {
        out.add(block);
        continue;
      }
      for (var at = block.startLine; at < block.endLine; at += pieceLines) {
        final end = at + pieceLines < block.endLine
            ? at + pieceLines
            : block.endLine;
        _pieces[out.length] = (
          first: at == block.startLine,
          last: end == block.endLine,
          start: block.startLine,
          end: block.endLine,
        );
        out.add(
          Block(
            kind: block.kind,
            startLine: at,
            endLine: end,
            quoteDepth: block.quoteDepth,
            listDepth: block.listDepth,
            fenceInfo: block.fenceInfo,
            footnote: block.footnote,
            divDepth: block.divDepth,
          ),
        );
      }
    }
    return out;
  }

  /// Whether [block] is a code block long enough to be cut into pieces.
  static bool isLongCode(Block block) =>
      (block.kind == BlockKind.fencedCode ||
          block.kind == BlockKind.indentedCode) &&
      block.lineCount > 2 * pieceLines;
}
