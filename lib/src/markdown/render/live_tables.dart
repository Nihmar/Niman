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
/// A table whose natural width is the pane's or less is laid out that way,
/// unchanged. One wider than the pane is *fitted* to it instead, as the read
/// view fits it (`fitTableColumns`, #1108): every column keeps its widest
/// word where the pane can give it and the rest of the room is shared by
/// what the columns want; where even the words do not fit, they share it by
/// those words. Each cell's text wraps inside its column, and the row takes
/// as many visual lines as its tallest cell does. Nothing is clipped and
/// every column shows.
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
import 'package:meta/meta.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/live_table_counts.dart';
import 'package:niman/src/markdown/render/live_table_layout.dart';
import 'package:niman/src/markdown/render/live_table_metrics.dart';
import 'package:niman/src/markdown/render/live_table_row.dart';
import 'package:niman/src/markdown/render/live_table_row_work.dart';
import 'package:niman/src/markdown/render/live_table_spans.dart';
import 'package:niman/src/markdown/render/live_table_state.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

export 'package:niman/src/markdown/render/live_table_row.dart';

/// The tables of a note, laid out a table at a time.
///
/// A row's cells are measured once and kept while the theme and the scaler
/// stand, under the row's text: a revision measures the rows whose text it
/// changed, and a caret move the rows the reveal touched, and keeps the rest.
/// The pieces of a fitted row wait for a frame to draw the row, so a table
/// scrolled out of view is not laid out at all (#494).
final class LiveTables {
  /// Each table's measurements and rows, by its first line.
  final Map<int, LiveTableState> _tables = <int, LiveTableState>{};

  SourceBuffer? _buffer;
  int _revision = -1;
  MarkdownTheme? _theme;
  TextScaler? _scaler;
  Object? _tokensFrom;

  /// The rows measured at rest, by whether they are a header and by their
  /// text — the ones a frame asked for since the buffer last changed — and
  /// the ones the revision before it kept, which a row still standing is
  /// taken back from. A row no revision asks for is forgotten after one more.
  Map<(bool, String), LiveTableRowWork> _kept =
      <(bool, String), LiveTableRowWork>{};
  Map<(bool, String), LiveTableRowWork> _prior =
      <(bool, String), LiveTableRowWork>{};

  /// How many times a cell's text has been laid out for a table, for the test
  /// that holds a revision and a caret move to the work they may do (#494):
  /// a table that fits is measured one painter a cell, a fitted one one
  /// painter a word, and a wrapped row only when a frame draws its pieces.
  @visibleForTesting
  static int get measurements => LiveTableCounts.measurements;
  @visibleForTesting
  static set measurements(int value) => LiveTableCounts.measurements = value;

  /// How many rows have been laid out — their gaps worked out, their pieces
  /// made ready — for the test that holds a caret move to the rows it touched
  /// (#494).
  @visibleForTesting
  static int get rowsLaid => LiveTableCounts.rowsLaid;
  @visibleForTesting
  static set rowsLaid(int value) => LiveTableCounts.rowsLaid = value;

  /// How line [line] of [buffer] is laid out, [block] being its block; null
  /// for a line of no table. [tokensOf] gives a line's tokens, of which the
  /// ones [hidden] says are marks are drawn as nothing and the rest in
  /// [styleOf]'s style — as the line is drawn.
  ///
  /// [budget] is the width the row's text has: a table that wants more than
  /// that is fitted to it, its cells wrapped, where one that fits is laid
  /// out as it always was.
  ///
  /// [reveal] is what [hidden] shows of the table, the caret's run when it is
  /// in one of the table's lines ([revealLine]) and null otherwise: the two
  /// travel together, and a call with no line is a table measured at rest. It
  /// widens the columns measured for its own row alone, so a move measures
  /// that row again — and the row it left — and keeps the rest of the table's
  /// work (#494).
  ///
  /// [tokensFrom] is whatever [tokensOf] reads its answers from — the view's
  /// tokenizer: the colours of a long note land after its first frame, and a
  /// row measured before then was measured as plain text. When it changes the
  /// tokens may have, without the text having moved, so every measurement is
  /// dropped and taken again as the rows are asked for (#494).
  LiveTableRow? rowOf(
    int line,
    Block? block,
    SourceBuffer buffer, {
    required List<Token> Function(int line) tokensOf,
    required bool Function(int line, Token token) hidden,
    required TextStyle? Function(Token token) styleOf,
    required MarkdownTheme theme,
    required TextScaler scaler,
    required double budget,
    Object? reveal,
    int? revealLine,
    Object? tokensFrom,
  }) {
    if (block == null || block.kind != BlockKind.table) return null;
    // A theme, a scaler or a tokenizer rebuilt with the values they had is
    // what measured the rows: the caches below stand (#722).
    final same =
        identical(buffer, _buffer) &&
        theme == _theme &&
        scaler == _scaler &&
        tokensFrom == _tokensFrom;
    if (!same || buffer.revision != _revision) {
      _tables.clear();
      // What the measurements are made with stands: a revision moves the text
      // and nothing else, and a row of the same text measures the same.
      _prior = same ? _kept : <(bool, String), LiveTableRowWork>{};
      _kept = <(bool, String), LiveTableRowWork>{};
      _buffer = buffer;
      _revision = buffer.revision;
      _theme = theme;
      _scaler = scaler;
      _tokensFrom = tokensFrom;
    }
    final at = line - block.startLine;
    if (at < 0 || at >= block.endLine - block.startLine) return null;
    final table = _tables.putIfAbsent(
      block.startLine,
      () => LiveTableState(block),
    );
    final metrics = _metricsFor(
      table,
      buffer,
      tokensOf,
      hidden,
      styleOf,
      theme,
      scaler,
      reveal,
      revealLine,
    );
    if (table.rows == null ||
        table.reveal != reveal ||
        table.budget != budget) {
      table
        ..rows = LiveTableLayout.layOut(
          table,
          metrics,
          tokensOf,
          hidden,
          styleOf,
          theme,
          scaler,
          budget,
        )
        ..reveal = reveal
        ..budget = budget
        ..touched.clear();
    }
    return table.rows![at];
  }

  /// The table's measurements: read at once, then only touched where a reveal
  /// moved — its own row, and the row it left.
  LiveTableMetrics _metricsFor(
    LiveTableState table,
    SourceBuffer buffer,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
    Object? reveal,
    int? revealLine,
  ) {
    final block = table.block;
    final shown =
        reveal != null &&
            revealLine != null &&
            revealLine >= block.startLine &&
            revealLine < block.endLine
        ? revealLine
        : null;
    final metrics = table.metrics;
    if (metrics == null) {
      return table.metrics = _read(
        block,
        buffer,
        tokensOf,
        hidden,
        styleOf,
        theme,
        scaler,
        shown,
        reveal,
      );
    }
    if (metrics.revealedLine != shown ||
        (shown != null && metrics.revealedWith != reveal)) {
      if (metrics.revealedLine != null && metrics.revealedLine != shown) {
        _measureRow(
          table,
          metrics,
          metrics.revealedLine! - block.startLine,
          false,
          tokensOf,
          hidden,
          styleOf,
          theme,
          scaler,
        );
      }
      if (shown != null) {
        _measureRow(
          table,
          metrics,
          shown - block.startLine,
          true,
          tokensOf,
          hidden,
          styleOf,
          theme,
          scaler,
        );
      }
      metrics
        ..revealedLine = shown
        ..revealedWith = reveal;
    }
    return metrics;
  }

  /// Reads [block]'s lines and measures every cell of it, [reveal] being the
  /// run the line [shown] of the table shows — null for a table measured at
  /// rest. A row already measured under its text is not measured again.
  LiveTableMetrics _read(
    Block block,
    SourceBuffer buffer,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
    int? shown,
    Object? reveal,
  ) {
    final lines = <String>[
      for (var line = block.startLine; line < block.endLine; line++)
        buffer.lineAt(line),
    ];
    final rows = <LiveTableRowWork>[
      for (var row = 0; row < lines.length; row++)
        _work(
          block,
          row,
          lines[row],
          block.startLine + row == shown,
          tokensOf,
          hidden,
          styleOf,
          theme,
          scaler,
        ),
    ];
    return LiveTableMetrics(lines, rows)
      ..revealedLine = shown
      ..revealedWith = reveal;
  }

  /// Measures row [row] again, after a reveal moved: the row it is on
  /// ([revealed]) shows a run's marks, and the row it left shows them as they
  /// stand at rest.
  void _measureRow(
    LiveTableState table,
    LiveTableMetrics metrics,
    int row,
    bool revealed,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
  ) {
    table.touched.add(row);
    metrics.rows[row] = _work(
      table.block,
      row,
      metrics.lines[row],
      revealed,
      tokensOf,
      hidden,
      styleOf,
      theme,
      scaler,
    );
  }

  /// Row [row]'s measurements: the ones kept under its text when it is at
  /// rest, measured otherwise. The row that shows a run's marks ([revealed])
  /// is measured as it is drawn and shared with no other.
  LiveTableRowWork _work(
    Block block,
    int row,
    String text,
    bool revealed,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
  ) {
    final key = (row == 0, text);
    if (!revealed) {
      final kept = _kept[key] ?? _prior[key];
      if (kept != null) return _kept[key] = kept;
    }
    final delimiter = _isDelimiter(text);
    final cells = delimiter ? const <(int, int)>[] : cellsOf(text);
    final work = LiveTableRowWork(
      cells,
      _measureCells(
        block,
        row,
        text,
        cells,
        tokensOf,
        hidden,
        styleOf,
        theme,
        scaler,
      ),
      delimiter: delimiter,
    );
    if (!revealed) _kept[key] = work;
    return work;
  }

  /// Every cell of row [row] measured: how wide its text draws.
  static List<LiveTableMeasured> _measureCells(
    Block block,
    int row,
    String text,
    List<(int, int)> cells,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
  ) {
    final line = block.startLine + row;
    final style = row == 0 ? theme.tableHeader : theme.tableCell;
    return <LiveTableMeasured>[
      for (final (start, end) in cells)
        LiveTableSpans.measure(
          text,
          tokensOf(line),
          start,
          end,
          style,
          scaler,
          (token) => hidden(line, token),
          styleOf,
        ),
    ];
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
    final cells = cellsOf(text);
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
    for (final (start, end) in cellsOf(text)) {
      if (column >= start && column <= end) return (start, end);
    }
    return null;
  }

  /// The ranges of [text]'s cells' text, trimmed: the cells the table model
  /// splits the row into (`MarkdownTable.cellRangesOf`) — a pipe at either
  /// end is the row's edge, not a cell's, and an escaped pipe (`\|`) is a
  /// cell's text rather than an edge, `| a \| b | c |` two cells, not three
  /// (#361) — so live draws the cells an edit works on, trimmed as the
  /// model trims them. An empty cell's text starts past its pipe.
  static List<(int, int)> cellsOf(String text) {
    final cells = <(int, int)>[];
    for (final (from, to) in MarkdownTable.cellRangesOf(text)) {
      final cell = text.substring(from, to);
      final trimmed = cell.trim();
      if (trimmed.isEmpty) {
        cells.add((from, from));
        continue;
      }
      final left = from + cell.length - cell.trimLeft().length;
      cells.add((left, left + trimmed.length));
    }
    return cells;
  }

  /// Whether [text] is a delimiter row: dashes, colons and pipes.
  static bool _isDelimiter(String text) {
    final trimmed = text.trim();
    return trimmed.contains('-') && RegExp(r'^[|\s:-]+$').hasMatch(trimmed);
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
}
