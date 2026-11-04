/// One table's lines and their measurements, as `live` keeps them.
library;

import 'package:niman/src/markdown/render/live_table_row_work.dart';

/// One table's lines and their measurements, read once per revision.
///
/// The measurements outlive a reveal change: the caret's run shows marks on
/// the caret's own row and on no other, so a move measures that row again —
/// and the one it left — and keeps the rest (#494).
final class LiveTableMetrics {
  /// Creates a table's measurements: its [lines] and their [rows].
  new(this.lines, this.rows);

  /// The table's lines, top to bottom, without their terminators.
  final List<String> lines;

  /// Each line's measurements.
  final List<LiveTableRowWork> rows;

  /// The line the reveal stood on when the table's cells were last measured —
  /// null for a table measured at rest — and the reveal itself: together they
  /// tell the next move which row to measure again.
  int? revealedLine;

  /// The reveal [revealedLine] showed.
  Object? revealedWith;
}
