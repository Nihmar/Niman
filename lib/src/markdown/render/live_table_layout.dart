/// Laying a table's rows out in `live`: its columns, fitted to the pane when
/// they want more room than it, and each line's gaps or wrapped pieces.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/live_table_counts.dart';
import 'package:niman/src/markdown/render/live_table_gaps.dart';
import 'package:niman/src/markdown/render/live_table_metrics.dart';
import 'package:niman/src/markdown/render/live_table_row.dart';
import 'package:niman/src/markdown/render/live_table_row_work.dart';
import 'package:niman/src/markdown/render/live_table_state.dart';
import 'package:niman/src/markdown/render/live_table_wrap.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/table_fit.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// Lays a table's rows out from its measurements.
abstract final class LiveTableLayout {
  /// Lays [table]'s block out from [metrics]: its columns measured from every
  /// row's cells, fitted to [budget] when they want more room than it, and
  /// each line's gaps or wrapped pieces worked out.
  ///
  /// A row's wrapped pieces are laid out only when a frame first asks for
  /// them — so a table that fits its pane lays no piece out, and a fitted
  /// table lays out the pieces of its *visible* rows alone (#494). Its
  /// columns' floors cost nothing: each cell's measure gives its widest
  /// unbreakable run with its width.
  static List<LiveTableRow> layOut(
    LiveTableState table,
    LiveTableMetrics metrics,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
    double budget,
  ) {
    final block = table.block;
    final pad = theme.tableCellPadding.left;
    final lines = metrics.lines;
    final rows = metrics.rows;
    final cells = <List<(int, int)>>[for (final row in rows) row.cells];
    final widths = <List<LiveTableMeasured>>[
      for (final row in rows) row.widths,
    ];
    final delimiters = <bool>[for (final row in rows) row.delimiter];
    // A column as wide as its widest cell, with the padding either side.
    final columns = widths.fold<int>(0, (most, row) {
      return row.length > most ? row.length : most;
    });
    final column = List<double>.filled(columns, 0);
    for (final row in widths) {
      for (var at = 0; at < row.length; at++) {
        if (row[at].visible > column[at]) column[at] = row[at].visible;
      }
    }
    // The table as it wants to be, and — when that is wider than the pane —
    // the same table fitted to it.
    final natural = <double>[0];
    for (final width in column) {
      natural.add(natural.last + width + 2 * pad);
    }
    final fits = natural.last <= budget;
    // The widest unbreakable run of each column: the room a fitted column
    // keeps, so a word is not broken where the read view would keep it
    // whole. Measured with the cell, in the one layout that measures it.
    var least = const <double>[];
    if (!fits) {
      least = List<double>.filled(columns, 0);
      for (final row in widths) {
        for (var at = 0; at < row.length; at++) {
          if (row[at].least > least[at]) least[at] = row[at].least;
        }
      }
    }
    final fitted = fits
        ? column
        : fitTableColumns(
            natural: column,
            least: least,
            pad: pad,
            budget: budget,
          );
    final edges = <double>[0];
    for (final width in fitted) {
      edges.add(edges.last + width + 2 * pad);
    }
    // A move of the reveal leaves the columns where they were unless the
    // caret's row is wider for its marks. When it does, the rows it did not
    // touch are the rows they were, and only the ones it did are laid out
    // again.
    final before = table.rows;
    final kept =
        before != null &&
            before.isNotEmpty &&
            table.fits == fits &&
            _sameEdges(before.first.edges, edges)
        ? before
        : null;
    table.fits = fits;
    late final tiny = LiveTableGaps.tinyAdvance(scaler);
    // A space's advance in a row's face, measured once a face: the spaces a
    // cell is written with are drawn as wide as a space where the room lets
    // them (`LiveTableGaps.gaps`).
    final spaces = <TextStyle, double>{};
    double spaceOf(TextStyle style) => spaces.putIfAbsent(
      style,
      () => LiveTableGaps.spaceAdvance(style, scaler),
    );
    // The columns' alignments, from the delimiter row: a right-aligned
    // column's text stands at its right edge, as the read view sets it.
    final aligns = lines.length > 1
        ? MarkdownTable.alignsOf(lines[1])
        : const <TableAlign>[];
    LiveTableRow build(int row) {
      LiveTableCounts.rowsLaid++;
      final style = row == 0 ? theme.tableHeader : theme.tableCell;
      return LiveTableRow(
        // The row's pieces are worked out the first time a frame draws it:
        // a row scrolled out of view is drawn by no frame, and is measured
        // by none (#494).
        () => fits || delimiters[row]
            ? const <LiveTableLine>[]
            : LiveTableWrap.wrappedRow(
                lines[row],
                tokensOf(block.startLine + row),
                cells[row],
                fitted,
                edges,
                pad,
                aligns,
                style,
                scaler,
                (token) => hidden(block.startLine + row, token),
                styleOf,
              ),
        edges: edges,
        gaps: fits || delimiters[row]
            ? LiveTableGaps.gaps(
                lines[row],
                cells[row],
                widths[row],
                edges,
                pad,
                tiny,
                style.letterSpacing ?? 0,
                spaceOf(style),
                aligns,
              )
            : const <LiveTableGap>[],
        header: row == 0,
        delimiter: delimiters[row],
        last: row == lines.length - 1,
      );
    }

    return <LiveTableRow>[
      for (var row = 0; row < lines.length; row++)
        if (kept != null && !table.touched.contains(row))
          kept[row]
        else
          build(row),
    ];
  }

  static bool _sameEdges(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }
}
