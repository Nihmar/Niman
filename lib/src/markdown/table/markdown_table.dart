/// A GFM table as its cells, read from its lines and written back.
library;

import 'package:flutter/foundation.dart';

/// How a column's cells are aligned, as its delimiter cell says.
enum TableAlign {
  /// `---`: the renderer's default.
  none,

  /// `:---`.
  left,

  /// `:---:`.
  center,

  /// `---:`.
  right,
}

/// A table: its header, its body rows, its columns' alignments, and how it
/// was written — so what is written back looks the way the writer left it.
@immutable
final class MarkdownTable {
  /// A table of [header] and [rows], each as wide as [aligns].
  const new({
    required this.header,
    required this.rows,
    required this.aligns,
    this.padded = false,
    this.outerPipes = true,
    this.indent = '',
    this.delimiters,
    this.spaced = true,
    this.delimiterSpaced = true,
  });

  /// Reads [lines], a table's lines: its header, its delimiter row, its
  /// body. Null when they are not a table.
  static MarkdownTable? parse(List<String> lines) {
    if (lines.length < 2) return null;
    final delimiter = splitRow(lines[1]);
    if (delimiter.isEmpty ||
        !delimiter.every((cell) => _delimiterCell.hasMatch(cell.trim()))) {
      return null;
    }
    final width = delimiter.length;
    List<String> cells(String line) {
      final raw = splitRow(line).map((cell) => cell.trim()).toList();
      if (raw.length > width) return raw.sublist(0, width);
      return [...raw, for (var i = raw.length; i < width; i++) ''];
    }

    final first = lines.first;
    final indent = first.substring(0, first.length - first.trimLeft().length);
    return MarkdownTable(
      header: cells(first),
      rows: [for (final line in lines.skip(2)) cells(line)],
      aligns: [for (final cell in delimiter) _alignOf(cell.trim())],
      padded: _isPadded(lines),
      outerPipes: first.trim().startsWith('|'),
      indent: indent,
      delimiters: [for (final cell in delimiter) cell.trim()],
      spaced: _isSpaced(first),
      delimiterSpaced: _isSpaced(lines[1]),
    );
  }

  /// The header row's cells.
  final List<String> header;

  /// The body rows' cells, each row as many as [header].
  final List<List<String>> rows;

  /// Each column's alignment.
  final List<TableAlign> aligns;

  /// Whether every column was written as wide as its widest cell, the pipes
  /// under one another: written back the same way when it was, and with a
  /// space round each cell when it was not.
  final bool padded;

  /// Whether the rows start and end with a pipe.
  final bool outerPipes;

  /// What the table's lines start with, kept.
  final String indent;

  /// The delimiter cells as written, for a table that was not padded: an
  /// unpadded column keeps its own dashes until its alignment changes.
  final List<String>? delimiters;

  /// Whether its rows are written with a space either side of each cell
  /// (`| a | b |`), not tight against the pipes (`|a|b|`).
  final bool spaced;

  /// The same, for the delimiter row: `| --- |` or `|---|`, which writers
  /// choose apart from the rows.
  final bool delimiterSpaced;

  /// How many columns it has.
  int get columns => aligns.length;

  /// This table with other cells, alignments or delimiters.
  MarkdownTable copyWith({
    List<String>? header,
    List<List<String>>? rows,
    List<TableAlign>? aligns,
    List<String>? delimiters,
    bool dropDelimiters = false,
  }) => MarkdownTable(
    header: header ?? this.header,
    rows: rows ?? this.rows,
    aligns: aligns ?? this.aligns,
    padded: padded,
    outerPipes: outerPipes,
    indent: indent,
    delimiters: dropDelimiters ? null : delimiters ?? this.delimiters,
    spaced: spaced,
    delimiterSpaced: delimiterSpaced,
  );

  /// The table's lines: header, delimiter row, body.
  List<String> toLines() {
    final widths = List<int>.filled(columns, 3);
    if (padded) {
      for (final row in [header, ...rows]) {
        for (var at = 0; at < columns; at++) {
          final width = _widthOf(row[at]);
          if (width > widths[at]) widths[at] = width;
        }
      }
    }
    String cell(String text, int at) {
      if (!padded) return text;
      final room = widths[at] - _widthOf(text);
      return switch (aligns[at]) {
        TableAlign.right => '${' ' * room}$text',
        TableAlign.center =>
          '${' ' * (room ~/ 2)}$text${' ' * (room - room ~/ 2)}',
        _ => '$text${' ' * room}',
      };
    }

    String delimiterCell(int at) {
      final kept = delimiters;
      if (!padded && kept != null && at < kept.length) return kept[at];
      final dashes = padded ? widths[at] : 3;
      return switch (aligns[at]) {
        TableAlign.none => '-' * dashes,
        TableAlign.left => ':${'-' * (dashes - 1)}',
        TableAlign.center => ':${'-' * (dashes - 2)}:',
        TableAlign.right => '${'-' * (dashes - 1)}:',
      };
    }

    String line(List<String> cells, {required bool spaced}) {
      final inner = cells
          .map((text) => spaced || padded ? ' $text ' : text)
          .join('|');
      final row = outerPipes ? '|$inner|' : inner.trim();
      return '$indent$row';
    }

    return [
      line([
        for (var at = 0; at < columns; at++) cell(header[at], at),
      ], spaced: spaced),
      line([
        for (var at = 0; at < columns; at++) delimiterCell(at),
      ], spaced: delimiterSpaced),
      for (final row in rows)
        line([
          for (var at = 0; at < columns; at++) cell(row[at], at),
        ], spaced: spaced),
    ];
  }

  /// The cells of a table row, as written between its pipes: a pipe at
  /// either end is the row's edge, and an escaped one (`\|`) is a cell's
  /// text, not an edge.
  static List<String> splitRow(String line) {
    var text = line.trim();
    if (text.startsWith('|')) text = text.substring(1);
    if (text.endsWith('|') && !text.endsWith(r'\|')) {
      text = text.substring(0, text.length - 1);
    }
    final cells = <String>[];
    final cell = StringBuffer();
    for (var at = 0; at < text.length; at++) {
      final unit = text[at];
      if (unit == r'\' && at + 1 < text.length && text[at + 1] == '|') {
        cell.write(r'\|');
        at++;
      } else if (unit == '|') {
        cells.add(cell.toString());
        cell.clear();
      } else {
        cell.write(unit);
      }
    }
    cells.add(cell.toString());
    return cells;
  }

  /// The alignments a delimiter row [line] gives its columns; empty when
  /// it is not one.
  static List<TableAlign> alignsOf(String line) {
    final cells = splitRow(line).map((cell) => cell.trim()).toList();
    if (!cells.every(_delimiterCell.hasMatch)) return const <TableAlign>[];
    return [for (final cell in cells) _alignOf(cell)];
  }

  /// The index of the cell [column] of row [line] is in: the pipes before
  /// it, the row's opening one not counted, and never past [columns].
  static int columnAt(String line, int column, int columns) {
    final lead = line.length - line.trimLeft().length;
    var cell = 0;
    for (var at = 0; at < column && at < line.length; at++) {
      if (line[at] == '|' && (at == 0 || line[at - 1] != r'\')) cell++;
    }
    if (lead < line.length && line[lead] == '|') cell--;
    if (cell < 0) return 0;
    return cell >= columns ? columns - 1 : cell;
  }

  static final RegExp _delimiterCell = RegExp(r'^:?-+:?$');

  static TableAlign _alignOf(String cell) {
    final left = cell.startsWith(':');
    final right = cell.endsWith(':');
    if (left && right) return TableAlign.center;
    if (left) return TableAlign.left;
    if (right) return TableAlign.right;
    return TableAlign.none;
  }

  /// Whether [lines] were padded by their writer: a cell with more than a
  /// space either side of its text, or a delimiter cell longer than three
  /// dashes. What padding looks like, rather than whether the pipes line
  /// up — a padded table one cell of which has since grown is still one
  /// to pad, and a table of one-letter cells lines up by chance.
  static bool _isPadded(List<String> lines) {
    for (final (index, line) in lines.indexed) {
      for (final raw in splitRow(line)) {
        final text = raw.trim();
        if (index == 1) {
          if (text.replaceAll(':', '').length > 3) return true;
          continue;
        }
        if (text.isEmpty) {
          if (raw.length > 2) return true;
          continue;
        }
        final lead = raw.length - raw.trimLeft().length;
        final trail = raw.length - raw.trimRight().length;
        if (lead > 1 || trail > 1) return true;
      }
    }
    return false;
  }

  /// Whether [line]'s cells stand a space off their pipes: a row with no
  /// cell tight against one.
  static bool _isSpaced(String line) {
    final text = line.trim();
    for (var at = 0; at < text.length; at++) {
      if (text[at] != '|' || (at > 0 && text[at - 1] == r'\')) continue;
      if (at + 1 < text.length && text[at + 1] != ' ') return false;
      if (at > 0 && text[at - 1] != ' ') return false;
    }
    return true;
  }

  /// How many columns [text] takes: its characters, not its UTF-16 units.
  static int _widthOf(String text) => text.runes.length;
}
