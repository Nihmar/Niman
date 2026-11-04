import 'package:flutter/rendering.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_paragraphs.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The pieces the source view draws a line in: the line's own paragraph,
/// or — a table row `live` lays out in fitted columns — one paragraph per
/// piece of its cells, and the table's rows as `live` lays them out.
///
/// The caret, a tap and the table's grid all ask here which piece a line's
/// offset or a point is in, so they agree with the painter by construction.
final class SourcePieces {
  /// The pieces of [_buffer]'s lines, drawn in [_paragraphs].
  new({
    required this._buffer,
    required this._live,
    required this._styler,
    required this._caretSpot,
    required this._paragraphs,
    required this._tokensOf,
    required this._syntax,
    required this._dark,
    required this._theme,
    required this._scaler,
    required this._widthOf,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// Whether the view draws `live`, where a table is a grid.
  final bool Function() _live;

  /// The colours, whose scan says where the tables are.
  final SourceStyler? Function() _styler;

  /// Where the caret is, as the lines that draw it care.
  final CaretSpot Function() _caretSpot;

  /// The paragraphs the lines are drawn in.
  final SourceParagraphs _paragraphs;

  /// The runs a line is drawn with.
  final List<Token> Function(int line) _tokensOf;

  /// The syntax colours of the last frame that laid the note out, or null.
  final SyntaxColors? Function() _syntax;

  /// Whether the note is drawn dark.
  final bool Function() _dark;

  /// The theme the lines are drawn with.
  final MarkdownTheme Function() _theme;

  /// The text scaler of the last frame that laid the note out.
  final TextScaler Function() _scaler;

  /// The width a line is drawn at.
  final double Function(int line) _widthOf;

  /// The note's tables, laid out as the read view lays them out.
  final LiveTables _tables = LiveTables();

  /// How line [index] of table [block] is laid out with the caret at [at]:
  /// as every line of it is at rest, but for the run the caret is in, whose
  /// marks show as a paragraph's word does — and widen its column.
  ///
  /// Null outside `live`: source draws a table's line as the one paragraph
  /// it is, so the caret, a tap and the grid are not to look for pieces of a
  /// fitted row there.
  LiveTableRow? tableRowAt(int index, Block block, CaretSpot at) {
    if (!_live()) return null;
    final inside = at.line >= block.startLine && at.line < block.endLine;
    return _tables.rowOf(
      index,
      block,
      _buffer(),
      tokensOf: _tokensOf,
      hidden: (line, token) {
        if (!token.marker && !isSourceMarker(token.kind)) return false;
        if (isSourceMarker(token.kind) || line != at.line) return true;
        return token.start < at.runStart || token.end > at.runEnd;
      },
      styleOf: (token) => nestedTokenStyle(
        token,
        _syntax() ??
            (_dark() ? SyntaxColors.fallbackDark : SyntaxColors.fallbackLight),
        dark: _dark(),
      ),
      theme: _theme(),
      scaler: _scaler(),
      // A table in a side-by-side column is fitted to the column (#729).
      budget: _widthOf(index),
      reveal: inside ? at : null,
      revealLine: inside ? at.line : null,
      tokensFrom: _styler(),
    );
  }

  /// The paragraphs line [line] is drawn in: the line's own, or a table row
  /// laid out in fitted columns. Each says where its source starts on the
  /// line and where it stands in the line's box — below the table's cell
  /// padding for a wrapped row, so the caret's shift and the grid agree.
  List<SourcePiece> of(int line) {
    SourcePiece one(int start, int end, [double x = 0, double y = 0]) =>
        (key: _paragraphs.keyFor(line), start: start, end: end, x: x, y: y);
    final length = _buffer().lineLengthAt(line);
    final single = <SourcePiece>[one(0, length)];
    final block = _styler()?.blockOf(line);
    if (block == null || block.kind != BlockKind.table) return single;
    final row = tableRowAt(line, block, _caretSpot());
    final wrapped = row?.wrapped;
    if (wrapped == null || wrapped.isEmpty) return single;
    final pad = _theme().tableCellPadding.top;
    final pieces = <SourcePiece>[];
    var y = pad;
    for (final visualLine in wrapped) {
      for (final piece in visualLine.pieces) {
        pieces.add((
          key: _paragraphs.fragmentKey(line, pieces.length),
          start: piece.start,
          end: piece.end,
          x: piece.x,
          y: y,
        ));
      }
      y += visualLine.height;
    }
    return pieces.isEmpty ? single : pieces;
  }

  /// The fragment of line [line] a caret at [local] of the line is drawn in,
  /// and its paragraph when a frame has built it.
  (SourcePiece?, RenderParagraph?) fragmentAt(int line, int local) {
    final piece = SourceParagraphs.pieceHolding(
      of(line),
      () => _buffer().lineAt(line),
      local,
    );
    return (piece, piece == null ? null : SourceParagraphs.renderOf(piece.key));
  }

  /// How tall the line [line] is drawn: its paragraph's height, or the sum
  /// of a wrapped table row's visual lines.
  double drawnHeightOf(int line) {
    final block = _styler()?.blockOf(line);
    if (block != null && block.kind == BlockKind.table) {
      final row = tableRowAt(line, block, _caretSpot());
      final wrapped = row?.wrapped;
      if (wrapped != null && wrapped.isNotEmpty) {
        return wrapped.fold<double>(0, (sum, one) => sum + one.height);
      }
    }
    return _paragraphs.paragraphAt(line)?.size.height ?? 0;
  }
}
