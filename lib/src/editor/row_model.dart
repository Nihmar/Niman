/// Visual-row model: wraps the logical lines of a [LineBuffer] into visual
/// rows of at most `columns` characters each, for the virtualized editor
/// view (M2a E2, fold-aware since E6b).
///
/// Wrapping is a column wrap on the monospace grid: the k-th row of a line
/// holds its characters [k*columns, min((k+1)*columns, length)). That keeps
/// every offset calculation O(1) and deterministic; a word-wrap refinement is
/// a later visual milestone, not a model change.
///
/// The model wraps a *subset* of the buffer's lines — the **visible** lines.
/// By default every line is visible; the `setLines` method restricts the set
/// (folding omits the folded lines). Rows are laid out over the visible lines
/// only, so
/// the view renders nothing for a folded range.
library;

import 'package:copist/src/editor/line_buffer.dart';

/// Wraps the lines of a [LineBuffer] into visual rows of at most [columns]
/// characters, over a (default: all) set of visible lines.
///
/// The model is a cache over the buffer: after any edit or fold change, call
/// [sync] (no folds) or [setLines] (with folds) to re-wrap.
final class RowModel {
  /// Creates a model over [buffer] and wraps it.
  ///
  /// [columns] is the monospace grid width in characters; must be > 0. If
  /// [lines] is omitted every line of [buffer] is visible; otherwise only the
  /// given (strictly increasing) visible lines are wrapped.
  RowModel(this.buffer, {required this.columns, Iterable<int>? lines})
    : assert(columns > 0, 'columns must be positive') {
    if (lines == null) {
      sync();
    } else {
      setLines(lines);
    }
  }

  /// The buffer whose lines this model wraps.
  final LineBuffer buffer;

  /// The grid width in characters per visual row.
  final int columns;

  /// The visible logical lines, in order (a strictly increasing subsequence
  /// of `0..buffer.lineCount - 1`); folded lines are absent. `null` means
  /// every line is visible — the common no-fold case, kept as a null sentinel
  /// so [sync] does not materialize an identity list.
  List<int>? _lines;

  /// For each visible position p, the first visual row of line `_lines[p]`;
  /// `_rowStarts.last` is the total row count.
  List<int> _rowStarts = const <int>[];

  /// The total number of visual rows (over the visible lines).
  int get rowCount => _rowStarts.last;

  /// The visible logical lines, in order. Materializes an identity list when
  /// every line is visible (the common case); otherwise an unmodifiable view.
  List<int> get lines => _lines == null
      ? List<int>.generate(buffer.lineCount, (i) => i)
      : List.unmodifiable(_lines!);

  /// The number of visible lines.
  int get visibleLineCount => _lines?.length ?? buffer.lineCount;

  /// The first visual row of logical line [line], which must be visible.
  int rowOfLine(int line) {
    final p = _posOfLine(line);
    if (p < 0) {
      throw ArgumentError.value(line, 'line', 'not visible (folded)');
    }
    return _rowStarts[p];
  }

  /// The (line, start column) of visual row [row].
  ///
  /// The line is the *logical* line; the start column is always a multiple of
  /// [columns].
  (int, int) lineAndStartColumn(int row) {
    _requireRange(row, 0, rowCount - 1, 'row');
    final p = _posAtRow(row);
    final lines = _lines;
    final line = lines == null ? p : lines[p];
    return (line, (row - _rowStarts[p]) * columns);
  }

  /// The (visual row, column-in-row) of buffer [offset] — the inverse of the
  /// row/column-to-offset mapping, for placing the caret and the composing
  /// underline. The line containing [offset] must be visible (a caret never
  /// sits on a folded line).
  (int, int) offsetToRowColumn(int offset) {
    final (line, col) = buffer.locationOf(offset);
    return (rowOfLine(line) + col ~/ columns, col % columns);
  }

  /// Re-wraps, treating every line of [buffer] as visible (clears any
  /// [setLines] restriction). O(lines) — reads line lengths only, with a
  /// single allocation (the row layout); the all-visible state is the null
  /// sentinel, not a materialized list. Call after a [LineBuffer] edit when
  /// there are no folds.
  void sync() {
    _lines = null;
    _wrap();
  }

  /// Restricts the model to the visible logical [lines] (a strictly
  /// increasing subsequence of `0..buffer.lineCount - 1`) and re-wraps only
  /// those. Folded lines are simply absent. Call after a fold change or a
  /// [LineBuffer] edit.
  void setLines(Iterable<int> lines) {
    final list = lines.toList();
    for (var i = 0; i < list.length; i++) {
      assert(
        list[i] >= 0 && list[i] < buffer.lineCount,
        'line ${list[i]} out of range 0..${buffer.lineCount - 1}',
      );
      if (i > 0) {
        assert(list[i] > list[i - 1], 'lines must be strictly increasing');
      }
    }
    _lines = list;
    _wrap();
  }

  void _wrap() {
    final lines = _lines;
    final n = lines == null ? buffer.lineCount : lines.length;
    _rowStarts = List<int>.filled(n + 1, 0);
    var row = 0;
    for (var p = 0; p < n; p++) {
      final line = lines == null ? p : lines[p];
      final len = buffer.lineLength(line);
      row += len <= columns ? 1 : (len + columns - 1) ~/ columns;
      _rowStarts[p + 1] = row;
    }
  }

  /// The visible position of logical line [line], or -1 if the line is
  /// folded. O(1) when every line is visible, O(log lines) otherwise.
  int _posOfLine(int line) {
    final lines = _lines;
    if (lines == null) {
      return line >= 0 && line < buffer.lineCount ? line : -1;
    }
    var lo = 0;
    var hi = lines.length;
    while (hi - lo > 0) {
      final mid = (lo + hi) >> 1;
      if (lines[mid] <= line) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final p = lo - 1;
    return p >= 0 && p < lines.length && lines[p] == line ? p : -1;
  }

  /// The visible position of the line containing visual row [row] (O(log
  /// lines)).
  int _posAtRow(int row) {
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
