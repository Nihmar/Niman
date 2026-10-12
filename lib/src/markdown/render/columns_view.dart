/// A `columns` block drawn as boxes (#729): inside a callout, a quote or an
/// export's page, where a block is one box and not a run of slivers. Its
/// columns sit side by side by the rule the slivers follow
/// ([ColumnLayout]), and stack where it puts each on a row of its own.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/column_layout.dart';

/// One column: its `width` share, and its drawing at a width.
typedef ColumnBox = ({double? width, Widget Function(double? width) build});

/// A `columns` block's columns, in rows, [width] wide.
final class ColumnsView extends StatelessWidget {
  /// The [columns] of a block [width] wide, whose text's em is [em]; null
  /// [width] stacks them.
  const new({
    required this.columns,
    required this.width,
    required this.em,
    this.top,
    this.bottom,
    super.key,
  });

  /// Its columns, in source order.
  final List<ColumnBox> columns;

  /// How wide it is drawn; null when unknown, and the columns stack.
  final double? width;

  /// An em of its text: what the minimum and the gap are counted in.
  final double em;

  /// The outer opener's band.
  final Widget? top;

  /// The outer closer's band.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final width = this.width;
    final gap = ColumnLayout.gapEms * em;
    final minimum = ColumnLayout.minEms * em;
    final rows = width == null
        ? [
            for (var at = 0; at < columns.length; at++) [at],
          ]
        : ColumnLayout.rows(
            columns.length,
            width: width,
            minimum: minimum,
            gap: gap,
          );
    final shares = ColumnLayout.shares([
      for (final column in columns) column.width,
    ]);
    final top = this.top;
    final bottom = this.bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?top,
        for (var at = 0; at < rows.length; at++) ...[
          if (at > 0) SizedBox(height: gap),
          if (width == null || rows[at].length == 1)
            columns[rows[at].single].build(width)
          else
            _row(rows[at], shares, width, minimum, gap),
        ],
        ?bottom,
      ],
    );
  }

  /// A row of columns side by side.
  Widget _row(
    List<int> row,
    List<double> shares,
    double width,
    double minimum,
    double gap,
  ) {
    final widths = ColumnLayout.widths(
      [for (final at in row) shares[at]],
      width: width,
      minimum: minimum,
      gap: gap,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var at = 0; at < row.length; at++) ...[
          if (at > 0) SizedBox(width: gap),
          SizedBox(
            width: widths[at],
            child: columns[row[at]].build(widths[at]),
          ),
        ],
      ],
    );
  }
}
