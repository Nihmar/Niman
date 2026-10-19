/// A table in the read view: its cells, each its inline nodes, fitted to the
/// pane as `live` fits it (#1108).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/live_table_grid.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/table_fit.dart';
import 'package:niman/src/markdown/render/table_measure.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// A table, drawn as a `Table`: as wide as its columns, as `live` draws it
/// (laid out on the pane's width, a table spread what its columns left over
/// evenly across them, and a two-word column stood half the pane wide).
///
/// A table wider than the pane is fitted to it by the rule `live` uses
/// (`fitTableColumns`), from the same measure of each cell
/// (`measureTableCell`): a column keeps its widest word where the pane can
/// give it, and the long cells of one column cannot squeeze another down to
/// a few characters. One that already fits keeps the columns Flutter gives
/// it — each as wide as its widest cell — and without a measured pane (an
/// export) so does every table.
final class ReadTable extends StatefulWidget {
  /// The table of [rows] — the first one the header unless [head] is false,
  /// the chunk of a table drawn on after its first — drawn in [theme].
  const new({
    required this.rows,
    required this.aligns,
    required this.head,
    required this.theme,
    required this.spansOf,
    this.footnoteNumbers = const <String, int>{},
    this.availableWidth,
    super.key,
  });

  /// The cells, a row each.
  final List<List<ReadInline>> rows;

  /// The alignment of each column, as far as the header row gave one.
  final List<TableAlign> aligns;

  /// Whether the first row is the table's header.
  final bool head;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  /// The spans of a cell's inline nodes, over a base style.
  final InlineSpans Function(TextStyle base) spansOf;

  /// The number each footnote is cited as: the text of a cell that cites one.
  final Map<String, int> footnoteNumbers;

  /// How wide the pane is; null when the table is not drawn on a pane.
  final double? availableWidth;

  @override
  State<ReadTable> createState() => _ReadTableState();
}

/// What the cells of a table ask of its columns.
typedef _Asks = ({List<double> natural, List<double> least, List<bool> widget});

final class _ReadTableState extends State<ReadTable> {
  // What the asks were measured from: the cells, the typography, the text
  // scale and the footnote numbers. A rebuild that changes none of them (a
  // selection, a search highlight) measures nothing again.
  List<List<ReadInline>>? _rows;
  MarkdownTheme? _theme;
  TextScaler? _scaler;
  Map<String, int>? _footnotes;
  bool? _head;
  _Asks? _asks;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = widget.theme;
    final head = widget.head;
    final aligns = widget.aligns;
    // A hairline: one device pixel, wherever the columns end. A table as
    // wide as its columns ends on a fraction of a pixel, and a half-pixel
    // side drawn inside that edge was split across two pixels too faint to
    // see — the table stood open on its right.
    final border = TableBorder.all(
      color: theme.tableBorder,
      width: LiveTableGridPainter.thickness,
    );
    final columns = rows.fold<int>(
      0,
      (most, row) => math.max(most, row.length),
    );
    // Each cell's spans, built once: the cell is measured and drawn from the
    // same spans, and the recognizers a link's span carries are made once.
    final headSpans = widget.spansOf(theme.tableHeader);
    final cellSpans = widget.spansOf(theme.tableCell);
    final spans = <List<TextSpan>>[
      for (var at = 0; at < rows.length; at++)
        [
          for (final cell in rows[at])
            if (at == 0 && head)
              TextSpan(children: headSpans.of(cell), style: theme.tableHeader)
            else
              TextSpan(children: cellSpans.of(cell), style: theme.tableCell),
        ],
    ];
    final widths = _columnWidths(context, spans, columns);
    return Align(
      alignment: Alignment.topLeft,
      child: Table(
        border: border,
        columnWidths: widths,
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: <TableRow>[
          for (var at = 0; at < rows.length; at++)
            TableRow(
              children: <Widget>[
                for (var column = 0; column < columns; column++)
                  // A chunk of a table can have rows of different lengths:
                  // a short one is filled up, as a Table needs it.
                  if (column >= spans[at].length)
                    const SizedBox.shrink()
                  else
                    Padding(
                      padding: theme.tableCellPadding,
                      child: Text.rich(
                        spans[at][column],
                        textAlign: column < aligns.length
                            ? _textAlignOf(aligns[column])
                            : TextAlign.start,
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  /// The columns' widths when the table is wider than the pane, else null:
  /// the columns Flutter gives a table that fits.
  Map<int, TableColumnWidth>? _columnWidths(
    BuildContext context,
    List<List<TextSpan>> spans,
    int columns,
  ) {
    final budget = widget.availableWidth;
    if (budget == null) return null;
    final asks = _asksOf(MediaQuery.textScalerOf(context), spans, columns);
    final pad = widget.theme.tableCellPadding.left;
    final total =
        asks.natural.fold<double>(0, (sum, width) => sum + width) +
        2 * pad * columns;
    if (total <= budget) return null;
    final fitted = fitTableColumns(
      natural: asks.natural,
      least: asks.least,
      pad: pad,
      budget: budget,
    );
    return {
      for (var at = 0; at < columns; at++)
        at: asks.widget[at]
            ? FittedColumnWidth(fitted[at] + 2 * pad)
            : FixedColumnWidth(fitted[at] + 2 * pad),
    };
  }

  /// What each column asks for, measured from [spans] — once, until what
  /// they were measured from changes.
  _Asks _asksOf(TextScaler scaler, List<List<TextSpan>> spans, int columns) {
    final kept = _asks;
    if (kept != null &&
        identical(_rows, widget.rows) &&
        identical(_theme, widget.theme) &&
        identical(_footnotes, widget.footnoteNumbers) &&
        _head == widget.head &&
        _scaler == scaler) {
      return kept;
    }
    final natural = List<double>.filled(columns, 0);
    final least = List<double>.filled(columns, 0);
    final holds = List<bool>.filled(columns, false);
    for (final row in spans) {
      for (var at = 0; at < row.length; at++) {
        final cell = measureTableCell(row[at], scaler);
        natural[at] = math.max(natural[at], cell.natural);
        least[at] = math.max(least[at], cell.least);
        holds[at] = holds[at] || cell.widget;
      }
    }
    _rows = widget.rows;
    _theme = widget.theme;
    _footnotes = widget.footnoteNumbers;
    _head = widget.head;
    _scaler = scaler;
    return _asks = (natural: natural, least: least, widget: holds);
  }

  static TextAlign _textAlignOf(TableAlign align) => switch (align) {
    TableAlign.center => TextAlign.center,
    TableAlign.right => TextAlign.right,
    TableAlign.none || TableAlign.left => TextAlign.start,
  };
}

/// The width of a column that holds a widget (inline math, an image): the
/// width the fit gave it, or the least its widgets can be, whichever is more.
///
/// The fit measures text; a widget is not text, and a column narrower than
/// its formula would clip it. The cells themselves are asked for the least
/// they can be (as `IntrinsicColumnWidth` asks them), so the column keeps
/// that much of the pane and the rest of the table is fitted around it.
final class FittedColumnWidth extends TableColumnWidth {
  /// A column of [width], at least as wide as its widest widget.
  const new(this.width);

  /// The width the fit gave the column, its padding included.
  final double width;

  static const IntrinsicColumnWidth _intrinsic = IntrinsicColumnWidth();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      math.max(width, _intrinsic.minIntrinsicWidth(cells, containerWidth));

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      minIntrinsicWidth(cells, containerWidth);

  @override
  String toString() => 'FittedColumnWidth($width)';
}
