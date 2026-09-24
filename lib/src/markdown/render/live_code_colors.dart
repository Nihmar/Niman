/// The colours of a code block's rows in `live`, as the read view colours
/// the block.
///
/// The read view highlights a fenced block whole, by the language its fence
/// names; `live` draws a row at a time, and drew every row of code in one
/// muted colour. Here a block is highlighted once, as the read view does it
/// — whole, or in the same pieces when it is long enough for the read view
/// to cut it (`MarkdownReadViewState.pieceLines`) — and each row is handed
/// its own runs, so a string or a comment over several rows is coloured on
/// all of them, and the colours agree across a pane flip.
///
/// Kept until the note or the palette changes: a keystroke in a block
/// highlights that block again the next time a row of it is drawn, and no
/// other.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/code_highlight.dart';

/// Highlighted code blocks, by the first line of the stretch highlighted.
final class LiveCodeColors {
  /// The stretches highlighted since the note or the palette last changed:
  /// each one's rows, their runs.
  final Map<int, List<List<CodeRun>>> _stretches = <int, List<List<CodeRun>>>{};

  SourceBuffer? _buffer;
  int _revision = -1;
  Map<String, TextStyle>? _palette;

  /// The runs line [line] of [buffer] is coloured with, [block] being the
  /// block it is in; null for a line that is not the code of a fenced block
  /// naming its language — a fence, an indented block, a block with no
  /// language — which the read view does not colour either.
  List<CodeRun>? of(
    int line,
    Block? block,
    SourceBuffer buffer,
    Map<String, TextStyle> palette,
  ) {
    _follow(buffer, palette);
    return _runs(_stretches, line, block, buffer.lineAt, palette);
  }

  /// The runs a line of a quote is coloured with, [quoted] saying what it
  /// is inside the quote that starts on line [quote] — its runs' offsets
  /// the line's own past the quote marks. Null as for [of].
  List<CodeRun>? ofQuoted(
    QuotedLine quoted,
    int quote,
    SourceBuffer buffer,
    Map<String, TextStyle> palette,
  ) {
    _follow(buffer, palette);
    // A block inside a quote is keyed by the quote and its place there.
    final stretches = _quoted.putIfAbsent(
      quote,
      () => <int, List<List<CodeRun>>>{},
    );
    return _runs(
      stretches,
      quoted.line,
      quoted.block,
      (at) => quoted.lines[at],
      palette,
    );
  }

  /// The stretches of the blocks inside each quote, by the quote's first
  /// line.
  final Map<int, Map<int, List<List<CodeRun>>>> _quoted =
      <int, Map<int, List<List<CodeRun>>>>{};

  /// Forgets every stretch when [buffer] or [palette] is not the one they
  /// were highlighted for.
  void _follow(SourceBuffer buffer, Map<String, TextStyle> palette) {
    if (identical(buffer, _buffer) &&
        buffer.revision == _revision &&
        identical(palette, _palette)) {
      return;
    }
    _stretches.clear();
    _quoted.clear();
    _buffer = buffer;
    _revision = buffer.revision;
    _palette = palette;
  }

  /// Line [line]'s runs, [block] being its block and [lineAt] its lines,
  /// highlighted into [stretches].
  static List<CodeRun>? _runs(
    Map<int, List<List<CodeRun>>> stretches,
    int line,
    Block? block,
    String Function(int line) lineAt,
    Map<String, TextStyle> palette,
  ) {
    if (block == null || block.kind != BlockKind.fencedCode) return null;
    final language = block.fenceInfo;
    if (language == null || language.isEmpty) return null;
    // The code between the fences: the closing one, when the note closed
    // the block, is not code.
    final first = block.startLine + 1;
    final closing = lineAt(block.endLine - 1).trimLeft();
    final closed =
        block.endLine - 1 > block.startLine &&
        (closing.startsWith('```') || closing.startsWith('~~~'));
    final last = closed ? block.endLine - 1 : block.endLine;
    if (line < first || line >= last) return null;
    // The stretch the read view highlights together: the block, or its
    // piece when it cuts the block.
    const piece = MarkdownReadViewState.pieceLines;
    var from = first;
    var to = last;
    if (block.lineCount > 2 * piece) {
      final start = block.startLine + (line - block.startLine) ~/ piece * piece;
      from = start < first ? first : start;
      to = start + piece < last ? start + piece : last;
    }
    final rows = stretches.putIfAbsent(from, () {
      final code = <String>[for (var at = from; at < to; at++) lineAt(at)]
          .join('\n');
      return CodeHighlighter(language: language, theme: palette).lines(code);
    });
    final row = line - from;
    return row < rows.length ? rows[row] : null;
  }
}
