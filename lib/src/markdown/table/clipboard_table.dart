/// Cells copied from a spreadsheet, or the lines of a CSV file, read as a
/// Markdown table (#1248).
///
/// A spreadsheet puts its cells on the clipboard as tab-separated text:
/// Excel, LibreOffice Calc, Numbers and Google Sheets all do, one row per
/// line, a cell holding a tab, a newline or a quote written between double
/// quotes with its quotes doubled. A CSV file opened as text has the same
/// shape with commas (or, where the comma is the decimal mark, semicolons).
///
/// Text that only looks like that is the risk: prose has commas, code has
/// arguments. So the reading is strict, and a paste it turns into a table
/// always offers its plain text back:
///
/// - two rows at least, and two columns at least on the first;
/// - tab-separated: every row has a tab, and not all of them start with
///   one (indented code); a short row is filled;
/// - comma- or semicolon-separated: every row has as many cells as the
///   first, and no cell starts with a space outside quotes — the
///   `a, b` of prose and of argument lists, never of a data file.
///
/// The text is read a row at a time and refused at the first row that breaks
/// the shape, and one longer than [clipboardTableLimit] is not read at all
/// (#1356): prose is the common case, and it must cost a paste almost nothing.
library;

import 'package:niman/src/markdown/table/markdown_table.dart';

/// The longest text read as a table, in code units: a spreadsheet's copy of
/// thousands of cells is a few hundred kilobytes, and what is past this is
/// not a table anyone pastes into a note.
const int clipboardTableLimit = 2 * 1024 * 1024;

/// [text] as a table, its first row the header; null when it is not one
/// the way a spreadsheet or a CSV file writes it.
MarkdownTable? tableFromClipboard(String text) {
  if (text.length > clipboardTableLimit) return null;
  final normal = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  // A spreadsheet ends its last row with a newline; a blank line after it
  // is not a row.
  final trimmed = normal.replaceFirst(RegExp(r'\n+$'), '');
  if (trimmed.isEmpty || !trimmed.contains('\n')) return null;
  if (trimmed.contains('\t')) {
    return _table(_split(trimmed, '\t', tabs: true), tabs: true);
  }
  for (final separator in const [',', ';']) {
    if (!trimmed.contains(separator)) continue;
    final rows = _split(trimmed, separator);
    if (rows == null) continue;
    final table = _table(rows, tabs: false);
    if (table != null) return table;
  }
  return null;
}

/// One parsed cell, and whether it began with a space outside quotes.
typedef _Cell = ({String text, bool spaced});

/// [text]'s rows split at [separator], quotes read the CSV way; null when a
/// quote is never closed — not a file's cells — or, as soon as a row says so,
/// when the rows are not the shape of a table: [tabs] rows have two cells at
/// least; the others as many as the first, none starting with a space.
List<List<_Cell>>? _split(String text, String separator, {bool tabs = false}) {
  final rows = <List<_Cell>>[];
  var row = <_Cell>[];
  final cell = StringBuffer();
  var quoted = false;
  var wasQuoted = false;
  var atStart = true;

  // A prose line, an argument list: told at the first cell that is spaced
  // or the first row that is not the first's width, not after all the rest.
  var broken = false;

  void endCell() {
    final value = cell.toString();
    final spaced = !wasQuoted && value.startsWith(' ');
    if (spaced && !tabs) broken = true;
    row.add((text: wasQuoted ? value : value.trim(), spaced: spaced));
    cell.clear();
    wasQuoted = false;
    atStart = true;
  }

  // Whether [row], just ended, can still be a row of a table.
  bool fits() {
    if (broken) return false;
    if (rows.isEmpty) return row.length >= 2;
    return tabs ? row.length >= 2 : row.length == rows.first.length;
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
      continue;
    }
    if (char == '"' && atStart) {
      quoted = true;
      wasQuoted = true;
      atStart = false;
      continue;
    }
    if (char == separator) {
      endCell();
      if (broken) return null;
      continue;
    }
    if (char == '\n') {
      endCell();
      if (!fits()) return null;
      rows.add(row);
      row = <_Cell>[];
      continue;
    }
    cell.write(char);
    atStart = false;
  }
  if (quoted) return null;
  endCell();
  if (!fits()) return null;
  rows.add(row);
  return rows;
}

MarkdownTable? _table(List<List<_Cell>>? rows, {required bool tabs}) {
  if (rows == null || rows.length < 2) return null;
  final width = rows.first.length;
  if (width < 2) return null;
  if (tabs) {
    // Every row of a sheet's copy is cut at its tabs; a line without one
    // is prose pasted after the cells, not a row of them.
    if (rows.any((row) => row.length < 2)) return null;
    // Lines that all start with a tab are indented code, not a column
    // nobody would copy empty.
    if (rows.every((row) => row.first.text.isEmpty)) return null;
  } else {
    if (rows.any((row) => row.length != width)) return null;
    if (rows.any((row) => row.any((cell) => cell.spaced))) return null;
  }
  final columns = rows
      .map((row) => row.length)
      .reduce((most, length) => length > most ? length : most);
  List<String> cells(List<_Cell> row) => [
    for (final cell in row) _cellText(cell.text),
    for (var at = row.length; at < columns; at++) '',
  ];
  return MarkdownTable(
    header: cells(rows.first),
    rows: [for (final row in rows.skip(1)) cells(row)],
    aligns: List<TableAlign>.filled(columns, TableAlign.none),
  );
}

/// A cell's text as a table cell holds it: on one line, a pipe escaped so
/// it does not end the cell.
String _cellText(String text) => text
    .trim()
    .replaceAll('\r\n', '\n')
    .replaceAll('\n', '<br>')
    .replaceAll('|', r'\|');
