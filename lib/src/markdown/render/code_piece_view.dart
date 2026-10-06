/// A code block too long to lay out whole, drawn a piece at a time.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/code_highlight.dart';

/// One piece of a code block too long to lay out whole (see
/// `MarkdownReadViewState.pieceLines`): its lines, in the block's box, with the
/// box's rounded ends and padding only where the block starts and ends, so
/// the pieces read as one block.
///
/// Each piece is highlighted on its own: a construct that spans two pieces
/// (a long string, a block comment) is coloured from where the piece
/// starts. Only blocks hundreds of lines long are cut, where that is the
/// price of drawing them at all.
final class CodePieceView extends StatelessWidget {
  /// Draws lines `[block.startLine, block.endLine)` of [buffer], a piece of
  /// a longer code block: the [first] carries its opening fence, the [last]
  /// its closing one.
  const new({
    required this.buffer,
    required this.block,
    required this.first,
    required this.last,
    required this.theme,
    super.key,
  });

  /// The note.
  final SourceBuffer buffer;

  /// The piece's line range and the block's kind and language.
  final Block block;

  /// Whether this piece starts the block.
  final bool first;

  /// Whether this piece ends the block.
  final bool last;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  @override
  Widget build(BuildContext context) {
    final language = block.fenceInfo;
    final radius = Radius.circular(first || last ? 4 : 0);
    final text = _text();
    // The fences' rows, as the whole block has them (`LeafView._code`).
    final fenced = block.kind == BlockKind.fencedCode;
    final row = MediaQuery.textScalerOf(context).scale(theme.lineHeight);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.codeBackground,
        borderRadius: BorderRadius.only(
          topLeft: first ? radius : Radius.zero,
          topRight: first ? radius : Radius.zero,
          bottomLeft: last ? radius : Radius.zero,
          bottomRight: last ? radius : Radius.zero,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        theme.codePadding,
        fenced && first ? row : 0,
        theme.codePadding,
        fenced && last && _closed ? row : 0,
      ),
      child: language == null || language.isEmpty
          ? Text(text, style: theme.code)
          : Text.rich(
              CodeHighlighter(
                language: language,
                theme: theme.codeHighlight,
              ).format(text),
              style: theme.code,
            ),
    );
  }

  /// Whether the block ends on its closing fence: the note may never close
  /// it.
  bool get _closed {
    final closing = buffer.lineAt(block.endLine - 1).trim();
    return closing.startsWith('```') || closing.startsWith('~~~');
  }

  /// The piece's code: its lines, without a fence line, without an indented
  /// block's four spaces.
  String _text() {
    final fenced = block.kind == BlockKind.fencedCode;
    var from = block.startLine;
    var to = block.endLine;
    if (fenced && first) from++;
    if (fenced && last && _closed) to--;
    final lines = <String>[];
    for (var at = from; at < to; at++) {
      final line = buffer.lineAt(at);
      lines.add(!fenced && line.startsWith('    ') ? line.substring(4) : line);
    }
    return lines.join('\n');
  }
}
