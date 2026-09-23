/// The lines of a table's grid, painted behind one of its rows in `live`,
/// where the read view's `Table` draws its border.
library;

import 'package:flutter/rendering.dart';
import 'package:niman/src/markdown/render/live_tables.dart';

/// Paints [row]'s part of its table's grid: the line above it, the lines
/// between its columns, and, under the table's last row, the line below.
///
/// The row's text starts [left] into what this paints over. The caret's
/// row is drawn as written, its cells off their columns, so it gets the
/// lines across it and not the ones between the columns ([revealed]).
final class LiveTableGridPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.row,
    required this.left,
    required this.color,
    required this.revealed,
  });

  /// The row, and its table's columns.
  final LiveTableRow row;

  /// Where the table starts, from the painter's left edge.
  final double left;

  /// The grid's colour: the read view's border.
  final Color color;

  /// Whether the caret is on the row.
  final bool revealed;

  /// The grid's thickness, the read view's (`BlockView._table`).
  static const double thickness = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;
    final edges = row.edges;
    final right = left + edges.last;
    canvas.drawLine(Offset(left, 0), Offset(right, 0), paint);
    if (row.last) {
      canvas.drawLine(
        Offset(left, size.height),
        Offset(right, size.height),
        paint,
      );
    }
    for (var at = 0; at < edges.length; at++) {
      // The table's own sides stay across the caret's row.
      if (revealed && at != 0 && at != edges.length - 1) continue;
      final x = left + edges[at];
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(LiveTableGridPainter oldDelegate) =>
      !identical(oldDelegate.row, row) ||
      oldDelegate.left != left ||
      oldDelegate.color != color ||
      oldDelegate.revealed != revealed;
}
