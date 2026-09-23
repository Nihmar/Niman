/// A table as `live` lays it out: the read view's grid, drawn over the
/// table's own source.
///
/// The read view draws a table as a `Table`: a column as wide as its widest
/// cell, a padding round every cell, the delimiter row left out. `live`
/// keeps each line the paragraph of its source, character for character, so
/// the grid is made of what is between the cells: the pipes and the spaces
/// around a cell's text are drawn as nothing as wide as it takes to put the
/// next cell's text on its column (the room a typeset formula's source is
/// given, `spacerStyleFor`), the delimiter row takes no room, and the lines
/// of the grid are painted behind (`LiveTableGridPainter`).
///
/// The caret's row stays on the grid, as Obsidian keeps a table a table
/// while it is written in: only the run the caret is in shows its marks, as
/// a word of a paragraph does, and the columns are measured from every
/// row's cells as they are drawn — that run's marks included, so a cell
/// widens while its marks are showing. The delimiter row is never drawn,
/// and the room between the cells is no place for the caret
/// (`LiveTables.cellColumn`).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A stretch of a row's source drawn as nothing `width` wide: the pipes and
/// the spaces between two cells' text.
typedef LiveTableGap = ({int start, int end, double width});

/// One line of a table, as `live` lays it out.
typedef LiveTableRow = ({
  /// Where each column starts, from the text's left edge, and where the
  /// table ends: one more than there are columns.
  List<double> edges,

  /// The stretches of the line drawn as nothing, and how wide.
  List<LiveTableGap> gaps,

  /// Whether the line is the table's header, set as the read view sets it.
  bool header,

  /// Whether the line is the delimiter row, which takes no room.
  bool delimiter,

  /// Whether the line is the table's last: the grid's bottom is under it.
  bool last,
});

/// A cell's text as it is drawn: how wide its glyphs are, how many
/// characters of hidden marks it has, and how many of them come before its
/// first glyph.
typedef _Measured = ({double visible, int hidden, int lead});

/// The tables of a note, laid out a table at a time.
final class LiveTables {
  /// Each table's rows, by its first line, and the caret's run they were
  /// laid out with (null for none of its lines).
  final Map<int, ({Object? reveal, List<LiveTableRow> rows})> _tables =
      <int, ({Object? reveal, List<LiveTableRow> rows})>{};

  SourceBuffer? _buffer;
  int _revision = -1;
  MarkdownTheme? _theme;
  TextScaler? _scaler;

  /// How line [line] of [buffer] is laid out, [block] being its block; null
  /// for a line of no table. [tokensOf] gives a line's tokens, of which the
  /// ones [hidden] says are marks are drawn as nothing and the rest in
  /// [styleOf]'s style — as the line is drawn.
  ///
  /// [reveal] is what [hidden] shows of the table, the caret's run when it
  /// is in one of the table's lines and null otherwise: the table is laid
  /// out again when it changes, and only then.
  LiveTableRow? rowOf(
    int line,
    Block? block,
    SourceBuffer buffer, {
    required List<Token> Function(int line) tokensOf,
    required bool Function(int line, Token token) hidden,
    required TextStyle? Function(Token token) styleOf,
    required MarkdownTheme theme,
    required TextScaler scaler,
    Object? reveal,
  }) {
    if (block == null || block.kind != BlockKind.table) return null;
    if (!identical(buffer, _buffer) ||
        buffer.revision != _revision ||
        !identical(theme, _theme) ||
        scaler != _scaler) {
      _tables.clear();
      _buffer = buffer;
      _revision = buffer.revision;
      _theme = theme;
      _scaler = scaler;
    }
    var table = _tables[block.startLine];
    if (table == null || table.reveal != reveal) {
      table = (
        reveal: reveal,
        rows: _layOut(block, buffer, tokensOf, hidden, styleOf, theme, scaler),
      );
      _tables[block.startLine] = table;
    }
    final rows = table.rows;
    final at = line - block.startLine;
    return at >= 0 && at < rows.length ? rows[at] : null;
  }

  /// Lays [block] out: its cells measured, its columns set, each line's
  /// gaps worked out.
  static List<LiveTableRow> _layOut(
    Block block,
    SourceBuffer buffer,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
  ) {
    final pad = theme.tableCellPadding.left;
    final lines = <String>[
      for (var at = block.startLine; at < block.endLine; at++)
        buffer.lineAt(at),
    ];
    final cells = <List<(int, int)>>[];
    final widths = <List<_Measured>>[];
    final delimiters = <bool>[];
    for (var row = 0; row < lines.length; row++) {
      final text = lines[row];
      final delimiter = _isDelimiter(text);
      delimiters.add(delimiter);
      final own = delimiter ? const <(int, int)>[] : _cellsOf(text);
      cells.add(own);
      final style = row == 0 ? theme.tableHeader : theme.tableCell;
      widths.add(<_Measured>[
        for (final (start, end) in own)
          _measure(
            text,
            tokensOf(block.startLine + row),
            start,
            end,
            style,
            scaler,
            (token) => hidden(block.startLine + row, token),
            styleOf,
          ),
      ]);
    }
    // A column as wide as its widest cell, with the padding either side.
    final columns = widths.fold<int>(0, (most, row) {
      return row.length > most ? row.length : most;
    });
    final column = List<double>.filled(columns, 0);
    for (final row in widths) {
      for (var at = 0; at < row.length; at++) {
        if (row[at].visible > column[at]) column[at] = row[at].visible;
      }
    }
    final edges = <double>[0];
    for (final width in column) {
      edges.add(edges.last + width + 2 * pad);
    }
    final tiny = _tinyAdvance(scaler);
    return <LiveTableRow>[
      for (var row = 0; row < lines.length; row++)
        (
          edges: edges,
          gaps: _gaps(
            lines[row],
            cells[row],
            widths[row],
            edges,
            pad,
            tiny,
            (row == 0 ? theme.tableHeader : theme.tableCell).letterSpacing ?? 0,
          ),
          header: row == 0,
          delimiter: delimiters[row],
          last: row == lines.length - 1,
        ),
    ];
  }

  /// The gaps of a line whose cells' text is [cells], [widths] wide: before
  /// the first cell's text a padding, between two cells' what is left of
  /// the first cell's column and the next one's padding, and after the last
  /// what is left of its column. A gap of no characters cannot be given a
  /// width, and is left out.
  ///
  /// A line's first glyph is set half its spacing in: a cell of the read
  /// view, a paragraph of its own, half the [ambient] spacing; here, when
  /// a gap opens the line, half the gap's. The first gap is spaced so that
  /// the first cell's text lands where the read view's does.
  static List<LiveTableGap> _gaps(
    String text,
    List<(int, int)> cells,
    List<_Measured> widths,
    List<double> edges,
    double pad,
    double tiny,
    double ambient,
  ) {
    final gaps = <LiveTableGap>[];
    void gap(int start, int end, double width) {
      if (end <= start) return;
      final count = end - start;
      // Each character keeps a hundredth of its size: the spacing is what
      // is left of the width.
      final spacing = start == 0
          ? (width + ambient / 2 - count * tiny) / (count + 0.5)
          : (width - count * tiny) / count;
      gaps.add((start: start, end: end, width: spacing * count));
    }

    // A cell's hidden marks take a hundredth of their size each: its text
    // starts past the ones before it, so its range starts that much short
    // of its column, and ends that much past its text.
    var from = 0;
    var x = 0.0;
    for (var at = 0; at < cells.length; at++) {
      final (start, end) = cells[at];
      final cell = widths[at];
      final lead = cell.lead * tiny;
      gap(from, start, edges[at] + pad - lead - x);
      from = end;
      x = edges[at] + pad - lead + cell.visible + cell.hidden * tiny;
    }
    if (cells.isNotEmpty) {
      final last = cells.length;
      gap(from, text.length, edges[last] - x);
    }
    return gaps;
  }

  /// Where the caret goes from [column] of table row [text]: [column]
  /// itself when it is in a cell's text, and otherwise — the pipes and the
  /// spaces round the cells, drawn as room nobody types in — the next
  /// cell's start going forward ([direction] above zero), the previous
  /// cell's end going back (below zero), or whichever is nearer (zero).
  ///
  /// Null when there is no cell that way, or none at all (the delimiter
  /// row): the caret leaves the line.
  static int? cellColumn(String text, int column, int direction) {
    if (_isDelimiter(text)) return null;
    final cells = _cellsOf(text);
    int? before;
    int? after;
    for (final (start, end) in cells) {
      if (column >= start && column <= end) return column;
      if (end < column) before = end;
      if (start > column) after ??= start;
    }
    if (direction > 0) return after;
    if (direction < 0) return before;
    if (before == null) return after;
    if (after == null) return before;
    return column - before <= after - column ? before : after;
  }

  /// The cell of table row [text] whose text [column] is in, from its
  /// text's start to its end; null for none (the room between cells, or the
  /// delimiter row).
  static (int, int)? cellAround(String text, int column) {
    if (_isDelimiter(text)) return null;
    for (final (start, end) in _cellsOf(text)) {
      if (column >= start && column <= end) return (start, end);
    }
    return null;
  }

  /// The ranges of [text]'s cells' text, trimmed: what is between its
  /// pipes, as the read view reads them — a pipe at either end is the
  /// row's edge, not a cell's, and an empty cell's text starts past its
  /// pipe.
  static List<(int, int)> _cellsOf(String text) {
    var start = 0;
    var end = text.length;
    while (start < end && _space(text.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _space(text.codeUnitAt(end - 1))) {
      end--;
    }
    if (start < end && text.codeUnitAt(start) == 0x7C) start++;
    if (end > start && text.codeUnitAt(end - 1) == 0x7C) end--;
    final cells = <(int, int)>[];
    var from = start;
    for (var at = start; at <= end; at++) {
      if (at < end && text.codeUnitAt(at) != 0x7C) continue;
      var left = from;
      var right = at;
      while (left < right && _space(text.codeUnitAt(left))) {
        left++;
      }
      while (right > left && _space(text.codeUnitAt(right - 1))) {
        right--;
      }
      cells.add(left == right ? (from, from) : (left, right));
      from = at + 1;
    }
    return cells;
  }

  /// Whether [text] is a delimiter row: dashes, colons and pipes.
  static bool _isDelimiter(String text) {
    final trimmed = text.trim();
    return trimmed.contains('-') && RegExp(r'^[|\s:-]+$').hasMatch(trimmed);
  }

  /// How wide `[start, end)` of [text] is drawn, its marks left out, the
  /// rest in its tokens' styles over [style]; and how many characters of
  /// marks it has, and how many of them come before its first glyph.
  static _Measured _measure(
    String text,
    List<Token> tokens,
    int start,
    int end,
    TextStyle style,
    TextScaler scaler,
    bool Function(Token token) hiddenAtRest,
    TextStyle? Function(Token token) styleOf,
  ) {
    if (end <= start) return (visible: 0, hidden: 0, lead: 0);
    final spans = <InlineSpan>[];
    var hidden = 0;
    int? lead;
    var at = start;
    for (final token in tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) {
        lead ??= hidden;
        spans.add(TextSpan(text: text.substring(at, from)));
      }
      if (hiddenAtRest(token)) {
        hidden += to - from;
      } else {
        lead ??= hidden;
        spans.add(
          TextSpan(text: text.substring(from, to), style: styleOf(token)),
        );
      }
      at = to;
    }
    if (at < end) {
      lead ??= hidden;
      spans.add(TextSpan(text: text.substring(at, end)));
    }
    final painter = TextPainter(
      text: TextSpan(children: spans, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return (visible: width, hidden: hidden, lead: lead ?? hidden);
  }

  /// How wide one character of a gap is before its spacing: a hundredth of
  /// its size.
  static double _tinyAdvance(TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'xxxxxxxxxx', style: gapStyle(0)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width / 10;
    painter.dispose();
    return width;
  }

  /// The style of a gap's characters, each given [spacing]: invisible, and
  /// no taller than nothing.
  static TextStyle gapStyle(double spacing) => TextStyle(
    fontSize: 0.01,
    height: 1,
    color: const Color(0x00000000),
    letterSpacing: spacing,
    wordSpacing: 0,
  );

  static bool _space(int unit) => unit == 0x20 || unit == 0x09;
}
