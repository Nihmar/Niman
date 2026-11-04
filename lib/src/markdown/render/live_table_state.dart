/// One table's kept work in `live`: its measurements and its rows.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/live_table_metrics.dart';
import 'package:niman/src/markdown/render/live_table_row.dart';

/// One table's kept work: the lines it measured ([LiveTableMetrics]), and the
/// rows it laid out with the reveal and the pane's width those came from.
///
/// The measurements stand across a reveal change; the rows are laid out again
/// when the reveal or the pane's width moves, which is where the caret's
/// row's columns widen.
final class LiveTableState {
  /// Creates the kept work of the table [block] covers, nothing kept yet.
  new(this.block);

  /// The block the table covers.
  final Block block;

  /// The table's measurements, or null before the first read.
  LiveTableMetrics? metrics;

  /// The rows laid out for [reveal] and [budget], or null before the first
  /// lay-out.
  List<LiveTableRow>? rows;

  /// The reveal [rows] were laid out for.
  Object? reveal;

  /// The width [rows] were laid out for.
  double? budget;

  /// Whether the columns fitted the pane when [rows] were laid out.
  bool? fits;

  /// The rows measured again since [rows] were laid out: the ones a reveal
  /// moved onto or off, which are the only ones a lay-out over columns that
  /// stood has to make again.
  final Set<int> touched = <int>{};
}
