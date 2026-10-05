/// A GFM table's lines, as `package:markdown` — the read view's parser —
/// reads them: its delimiter row, its columns, the cells of a row.
library;

/// The rows of a GFM table.
abstract final class TableLineSyntax {
  /// Whether [text] is a table's delimiter row: up to three spaces in, and
  /// cells of dashes with an optional colon either side, a pipe after each
  /// but perhaps the last (GFM's `tablePattern`).
  ///
  /// A line followed by one is a table's head row to the parser, which
  /// tries it before a paragraph goes on: it ends a list, a quote's lazy
  /// run and a paragraph, whether or not the head's cells fit.
  static bool isDelimiter(String text) {
    // Nearly every line is answered here, without the expression.
    if (!text.contains('|') || !text.contains('-')) return false;
    return _delimiter.hasMatch(text);
  }

  static final RegExp _delimiter = RegExp(
    r'^[ ]{0,3}\|?([ \t]*:?\-+:?[ \t]*\|[ \t]*)+([ \t]|[ \t]*:?\-+:?[ \t]*)?$',
  );

  /// Whether [text], followed by [next], is a table's head row: [next] is a
  /// delimiter row with as many columns as [text] has cells.
  static bool heads(String text, String? next) =>
      next != null && isDelimiter(next) && cellsOf(text) == columnsOf(next);

  /// How many columns the delimiter row [text] gives its table.
  static int columnsOf(String text) {
    var columns = 0;
    var started = false;
    var dashes = false;
    for (var at = 0; at < text.length; at++) {
      final char = text.codeUnitAt(at);
      if (char == 0x20 || char == 0x09 || (!started && char == 0x7C)) {
        continue;
      }
      started = true;
      if (char == 0x7C) {
        columns++;
        dashes = false;
      } else {
        dashes = true;
      }
    }
    return dashes ? columns + 1 : columns;
  }

  /// How many cells the row [text] has: split at its pipes, past an
  /// opening one, a trailing one closing the last cell rather than opening
  /// another; `\|` is a pipe in a cell.
  static int cellsOf(String text) {
    var at = 0;
    while (at < text.length) {
      final char = text.codeUnitAt(at);
      if (char == 0x7C) {
        at = _pastSpace(text, at + 1);
        break;
      }
      if (char != 0x20 && char != 0x09) break;
      at++;
    }
    var cells = 0;
    while (true) {
      if (at >= text.length) return cells + 1;
      final char = text.codeUnitAt(at);
      if (char == 0x5C) {
        if (at == text.length - 1) return cells + 1;
        at += 2;
      } else if (char == 0x7C) {
        cells++;
        at = _pastSpace(text, at + 1);
        if (at >= text.length) return cells;
      } else {
        at++;
      }
    }
  }

  static int _pastSpace(String text, int from) {
    var at = from;
    while (at < text.length &&
        (text.codeUnitAt(at) == 0x20 || text.codeUnitAt(at) == 0x09)) {
      at++;
    }
    return at;
  }
}
