/// A source line's table row laid out in fitted columns (split out of
/// `source_line.dart` for #100): a paragraph per piece of every visual
/// line, at its column's edge, behind the row's grid.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/render/live_inline_math.dart';
import 'package:niman/src/markdown/render/live_table_grid.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_line_layout.dart';
import 'package:niman/src/markdown/render/source_line_spans.dart';
import 'package:niman/src/markdown/render/source_line_squiggles.dart';
import 'package:niman/src/markdown/render/squiggle_painter.dart';

/// The line drawn as a table row too wide for the pane.
extension SourceLineWrappedRow on SourceLine {
  /// A table row too wide for the pane: its columns fitted to it, each cell
  /// wrapped inside its own, drawn as the read view draws the row — a
  /// paragraph per piece of every visual line, at its column's edge, behind
  /// the same grid, so every column shows and nothing is clipped.
  ///
  /// The pieces are fixed by the pane's width, so a piece is drawn at rest,
  /// its marks hidden: a mark that showed would stand the piece wider than
  /// the column it was fitted into. Editing is unchanged — the caret, a tap
  /// and the key table all work on the source, and the pieces' keys are what
  /// they are found through.
  Widget wrappedRow(
    BuildContext context,
    LiveTableRow row,
    double indent, {
    required List<SourceConcealed> concealed,
    required List<InlineFormula> formulas,
  }) {
    final pad = theme.tableCellPadding;
    final style = lineStyle(revealed: false);
    final strut = StrutStyle.fromTextStyle(style);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final children = <Widget>[];
    var y = pad.top;
    var at = 0;
    for (final visual in row.wrapped) {
      for (final piece in visual.pieces) {
        final key = pieceKey?.call(at) ?? GlobalKey();
        Widget paragraph = Text.rich(
          pieceSpan(
            piece.start,
            piece.end,
            concealed: concealed,
            formulas: formulas,
          ),
          key: key,
          style: style,
          strutStyle: strut,
          // The piece is one visual line already: wrapping it again would
          // carry its remainder under the wrong column, as the row's own
          // paragraph did before it was fitted.
          softWrap: false,
        );
        final mine = <InlineFormula>[
          for (final formula in formulas)
            if (formula.start >= piece.start && formula.end <= piece.end)
              (
                start: formula.start - piece.start,
                end: formula.end - piece.start,
                box: formula.box,
                fontSize: formula.fontSize,
                color: formula.color,
              ),
        ];
        if (mine.isNotEmpty) {
          paragraph = CustomPaint(
            foregroundPainter: InlineMathPainter(
              paragraph: key,
              formulas: mine,
              devicePixelRatio: ratio,
            ),
            child: paragraph,
          );
        }
        final squiggles = misspelledInPiece(piece.start, piece.end);
        if (squiggles.isNotEmpty) {
          paragraph = CustomPaint(
            foregroundPainter: SquigglePainter(
              paragraph: key,
              ranges: squiggles,
              color: misspelledColor,
            ),
            child: paragraph,
          );
        }
        final problems = templateProblemsInPiece(piece.start, piece.end);
        if (problems.isNotEmpty) {
          paragraph = CustomPaint(
            foregroundPainter: SquigglePainter(
              paragraph: key,
              ranges: problems,
              color: misspelledColor,
            ),
            child: paragraph,
          );
        }
        children.add(
          Positioned(left: indent + piece.x, top: y, child: paragraph),
        );
        at++;
      }
      y += visual.height;
    }
    return CustomPaint(
      painter: LiveTableGridPainter(
        row: row,
        left: indent,
        color: theme.tableBorder,
      ),
      child: SizedBox(
        width: double.infinity,
        height: y + pad.bottom,
        child: Stack(children: children),
      ),
    );
  }
}
