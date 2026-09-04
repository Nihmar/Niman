/// Visual-row model: wraps the logical lines of a [LineBuffer] into visual
/// rows of at most `columns` characters each, for the virtualized editor
/// view (M2a E2).
///
/// Wrapping is a column wrap on the monospace grid: the k-th row of a line
/// holds its characters [k*columns, min((k+1)*columns, length)). That keeps
/// every offset calculation O(1) and deterministic; a word-wrap refinement is
/// a later visual milestone, not a model change.
library;

import 'package:copist/src/editor/line_buffer.dart';

/// Wraps the lines of a [LineBuffer] into visual rows of at most [columns]
/// characters.
///
/// The model is a cache over the buffer: after any edit call [sync] to
/// re-wrap from the (post-edit) buffer.
final class RowModel {
  /// Creates a model over [buffer] and wraps it immediately.
  ///
  /// [columns] is the monospace grid width in characters; must be > 0.
  RowModel(this.buffer, {required this.columns})
    : assert(columns > 0, 'columns must be positive') {
    sync();
  }

  /// The buffer whose lines this model wraps.
  final LineBuffer buffer;

  /// The grid width in characters per visual row.
  final int columns;

  /// For each line index i, the first visual row of that line;
  /// _rowStarts.last is the total row count.
  List<int> _rowStarts = const <int>[];

  /// The total number of visual rows.
  int get rowCount => _rowStarts.last;

  /// The first visual row of line [line].
  int rowOfLine(int line) {
    _requireRange(line, 0, buffer.lineCount - 1, 'line');
    return _rowStarts[line];
  }

  /// The (line, start column) of visual row [row].
  ///
  /// The start column is always a multiple of [columns].
  (int, int) lineAndStartColumn(int row) {
    _requireRange(row, 0, rowCount - 1, 'row');
    final line = _lineAtRow(row);
    return (line, (row - _rowStarts[line]) * columns);
  }

  /// Re-wraps every line of [buffer] and rebuilds the row table.
  ///
  /// O(lines) — reads line lengths only, no character scans; sub-millisecond
  /// for a 10K-line file. Call after any [LineBuffer] edit.
  void sync() {
    final count = buffer.lineCount;
    _rowStarts = List<int>.filled(count + 1, 0);
    var row = 0;
    for (var i = 0; i < count; i++) {
      final len = buffer.lineLength(i);
      row += len <= columns ? 1 : (len + columns - 1) ~/ columns;
      _rowStarts[i + 1] = row;
    }
  }

  /// The line containing visual row [row] (O(log lines)).
  int _lineAtRow(int row) {
    final starts = _rowStarts;
    var low = 0;
    var high = starts.length - 1;
    while (high - low > 1) {
      final mid = (low + high) >> 1;
      if (starts[mid] <= row) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  static void _requireRange(int value, int low, int high, String name) {
    if (value < low || value > high) {
      throw ArgumentError.value(
        value,
        name,
        'must be within $low..=$high',
      );
    }
  }
}
