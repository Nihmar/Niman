/// What can be done to a table from its menu and its handles (#261).
library;

import 'package:niman/src/markdown/table/markdown_table.dart';

/// A cell of a table: its row — 0 the header, 1 on the body's rows, the
/// delimiter row not counted — and its column.
typedef TableSpot = ({int row, int column});

/// A table after an edit, and the cell the caret goes to.
typedef TableEdit = ({MarkdownTable table, TableSpot caret});

/// The edits a table's menu offers, each on the table and the cell the
/// menu was opened on; each null when it does not apply there (a row
/// above the header, the only column deleted).
abstract final class TableEdits {
  /// A new, empty body row above [at]'s.
  static TableEdit? addRowAbove(MarkdownTable table, TableSpot at) {
    if (at.row < 1) return null;
    return _insertRow(table, at.row, at.column);
  }

  /// A new, empty body row below [at]'s: the first body row, from the
  /// header.
  static TableEdit addRowBelow(MarkdownTable table, TableSpot at) =>
      _insertRow(table, at.row + 1, at.column);

  /// A new, empty row at the table's foot.
  static TableEdit addRowAtEnd(MarkdownTable table) =>
      _insertRow(table, table.rows.length + 1, 0);

  /// [at]'s row one up, over the body row above it.
  static TableEdit? moveRowUp(MarkdownTable table, TableSpot at) {
    if (at.row < 2) return null;
    return _swapRows(table, at.row, at.row - 1, at.column);
  }

  /// [at]'s row one down, under the body row below it.
  static TableEdit? moveRowDown(MarkdownTable table, TableSpot at) {
    if (at.row < 1 || at.row >= table.rows.length) return null;
    return _swapRows(table, at.row, at.row + 1, at.column);
  }

  /// A copy of [at]'s body row, under it.
  static TableEdit? duplicateRow(MarkdownTable table, TableSpot at) {
    if (at.row < 1) return null;
    final rows = [...table.rows]..insert(at.row, [...table.rows[at.row - 1]]);
    return (
      table: table.copyWith(rows: rows),
      caret: (row: at.row + 1, column: at.column),
    );
  }

  /// [at]'s body row, gone; the header stays.
  static TableEdit? deleteRow(MarkdownTable table, TableSpot at) {
    if (at.row < 1) return null;
    final rows = [...table.rows]..removeAt(at.row - 1);
    final row = at.row > rows.length ? rows.length : at.row;
    return (
      table: table.copyWith(rows: rows),
      caret: (row: row, column: at.column),
    );
  }

  /// A new, empty column left of [at]'s.
  static TableEdit addColumnLeft(MarkdownTable table, TableSpot at) =>
      _insertColumn(table, at.column, at.row);

  /// A new, empty column right of [at]'s.
  static TableEdit addColumnRight(MarkdownTable table, TableSpot at) =>
      _insertColumn(table, at.column + 1, at.row);

  /// A new, empty column at the table's right edge.
  static TableEdit addColumnAtEnd(MarkdownTable table) =>
      _insertColumn(table, table.columns, 0);

  /// [at]'s column one to the left.
  static TableEdit? moveColumnLeft(MarkdownTable table, TableSpot at) {
    if (at.column < 1) return null;
    return _swapColumns(table, at.column, at.column - 1, at.row);
  }

  /// [at]'s column one to the right.
  static TableEdit? moveColumnRight(MarkdownTable table, TableSpot at) {
    if (at.column >= table.columns - 1) return null;
    return _swapColumns(table, at.column, at.column + 1, at.row);
  }

  /// [at]'s column aligned [align]; null when it already is.
  static TableEdit? alignColumn(
    MarkdownTable table,
    TableSpot at,
    TableAlign align,
  ) {
    if (table.aligns[at.column] == align) return null;
    final aligns = [...table.aligns];
    aligns[at.column] = align;
    // The column's own dashes are written anew; the others keep theirs.
    final delimiters = table.delimiters == null
        ? null
        : ([...table.delimiters!]..[at.column] = _dashes(align));
    return (
      table: table.copyWith(aligns: aligns, delimiters: delimiters),
      caret: at,
    );
  }

  /// A copy of [at]'s column, right of it.
  static TableEdit duplicateColumn(MarkdownTable table, TableSpot at) {
    List<String> copy(List<String> cells) =>
        [...cells]..insert(at.column + 1, cells[at.column]);
    final delimiters = table.delimiters;
    return (
      table: table.copyWith(
        header: copy(table.header),
        rows: [for (final row in table.rows) copy(row)],
        aligns: [...table.aligns]
          ..insert(at.column + 1, table.aligns[at.column]),
        delimiters: delimiters == null ? null : copy(delimiters),
      ),
      caret: (row: at.row, column: at.column + 1),
    );
  }

  /// [at]'s column, gone; null for a table's only column.
  static TableEdit? deleteColumn(MarkdownTable table, TableSpot at) {
    if (table.columns < 2) return null;
    List<String> without(List<String> cells) => [...cells]..removeAt(at.column);
    final delimiters = table.delimiters;
    final column = at.column >= table.columns - 1
        ? table.columns - 2
        : at.column;
    return (
      table: table.copyWith(
        header: without(table.header),
        rows: [for (final row in table.rows) without(row)],
        aligns: [...table.aligns]..removeAt(at.column),
        delimiters: delimiters == null ? null : without(delimiters),
      ),
      caret: (row: at.row, column: column),
    );
  }

  /// The body rows sorted by [at]'s column, A to Z or ([descending]) Z to
  /// A: numbers as numbers, the rest ignoring case, and rows that tie in
  /// the order they had. Null for fewer than two rows.
  static TableEdit? sortByColumn(
    MarkdownTable table,
    TableSpot at, {
    bool descending = false,
  }) {
    if (table.rows.length < 2) return null;
    final indexed = [for (final (i, row) in table.rows.indexed) (i, row)]
      ..sort((a, b) {
        final order = compareCells(a.$2[at.column], b.$2[at.column]);
        if (order != 0) return descending ? -order : order;
        return a.$1.compareTo(b.$1);
      });
    return (
      table: table.copyWith(rows: [for (final (_, row) in indexed) row]),
      caret: at,
    );
  }

  /// How two cells sort: numerically when both are numbers, otherwise by
  /// their text, ignoring case.
  static int compareCells(String a, String b) {
    final x = num.tryParse(a.trim().replaceAll(',', '.'));
    final y = num.tryParse(b.trim().replaceAll(',', '.'));
    if (x != null && y != null) return x.compareTo(y);
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static TableEdit _insertRow(MarkdownTable table, int row, int column) {
    final rows = [...table.rows]
      ..insert(row - 1, List<String>.filled(table.columns, ''));
    return (
      table: table.copyWith(rows: rows),
      caret: (row: row, column: column),
    );
  }

  static TableEdit _swapRows(MarkdownTable table, int from, int to, int col) {
    final rows = [...table.rows];
    final moved = rows[from - 1];
    rows[from - 1] = rows[to - 1];
    rows[to - 1] = moved;
    return (table: table.copyWith(rows: rows), caret: (row: to, column: col));
  }

  static TableEdit _insertColumn(MarkdownTable table, int column, int row) {
    List<String> widen(List<String> cells) => [...cells]..insert(column, '');
    final delimiters = table.delimiters;
    return (
      table: table.copyWith(
        header: widen(table.header),
        rows: [for (final cells in table.rows) widen(cells)],
        aligns: [...table.aligns]..insert(column, TableAlign.none),
        delimiters: delimiters == null
            ? null
            : ([...delimiters]..insert(column, '---')),
      ),
      caret: (row: row, column: column),
    );
  }

  static TableEdit _swapColumns(
    MarkdownTable table,
    int from,
    int to,
    int row,
  ) {
    List<T> swap<T>(List<T> cells) {
      final out = [...cells];
      final moved = out[from];
      out[from] = out[to];
      out[to] = moved;
      return out;
    }

    final delimiters = table.delimiters;
    return (
      table: table.copyWith(
        header: swap(table.header),
        rows: [for (final cells in table.rows) swap(cells)],
        aligns: swap(table.aligns),
        delimiters: delimiters == null ? null : swap(delimiters),
      ),
      caret: (row: row, column: to),
    );
  }

  static String _dashes(TableAlign align) => switch (align) {
    TableAlign.none => '---',
    TableAlign.left => ':---',
    TableAlign.center => ':---:',
    TableAlign.right => '---:',
  };
}
