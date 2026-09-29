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
/// view fits it: the columns are shrunk together in proportion to what
/// their widest cells want, each cell's text wraps inside its column, and
/// the row takes as many visual lines as its tallest cell does. Nothing is
/// clipped and every column shows.
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
import 'package:niman/src/markdown/table/markdown_table.dart';

/// A stretch of a row's source drawn as nothing `width` wide: the pipes and
/// the spaces between two cells' text.
typedef LiveTableGap = ({int start, int end, double width});

/// One cell's text on one visual line of a row laid out in fitted columns:
/// the stretch of the row's source it holds, and where its left edge stands
/// from the row's text's left edge.
typedef LiveTablePiece = ({int start, int end, double x});

/// One visual line of a row laid out in fitted columns: the cells' pieces on
/// it, left to right, and how tall it is.
typedef LiveTableLine = ({List<LiveTablePiece> pieces, double height});

/// One line of a table, as `live` lays it out.
typedef LiveTableRow = ({
  /// Where each column starts, from the text's left edge, and where the
  /// table ends: one more than there are columns.
  List<double> edges,

  /// The stretches of the line drawn as nothing, and how wide.
  List<LiveTableGap> gaps,

  /// The line's visual lines when the table was too wide for the pane and
  /// its columns were fitted to it: one entry a visual line, top to bottom.
  /// Empty for a line drawn as one paragraph — a table that fits, or the
  /// delimiter row, which takes no room either way.
  List<LiveTableLine> wrapped,

  /// Whether the line is the table's header, set as the read view sets it.
  bool header,

  /// Whether the line is the delimiter row, which takes no room.
  bool delimiter,

  /// Whether the line is the table's last: the grid's bottom is under it.
  bool last,
});

/// How narrow a fitted column's text may get: two characters of the prose,
/// which is a floor rather than a target — every column is given room in
/// proportion to what its widest cell wants.
const double _minCellWidth = 12;

/// A cell's text as it is drawn: how wide its glyphs are, how many
/// characters of hidden marks it has, and how many of them come before its
/// first glyph.
typedef _Measured = ({double visible, int hidden, int lead, double least});

/// The tables of a note, laid out a table at a time.
final class LiveTables {
  /// Each table's rows, by its first line, and the caret's run and the
  /// pane's width they were laid out with (null for no run of its lines).
  final Map<int, ({Object? reveal, double budget, List<LiveTableRow> rows})>
  _tables = <int, ({Object? reveal, double budget, List<LiveTableRow> rows})>{};

  SourceBuffer? _buffer;
  int _revision = -1;
  MarkdownTheme? _theme;
  TextScaler? _scaler;

  /// How line [line] of [buffer] is laid out, [block] being its block; null
  /// for a line of no table. [tokensOf] gives a line's tokens, of which the
  /// ones [hidden] says are marks are drawn as nothing and the rest in
  /// [styleOf]'s style — as the line is drawn.
  ///
  /// [budget] is the width the row's text has: a table that wants more than
  /// that is fitted to it, its cells wrapped, where one that fits is laid
  /// out as it always was.
  ///
  /// [reveal] is what [hidden] shows of the table, the caret's run when it
  /// is in one of the table's lines and null otherwise: the table is laid
  /// out again when it changes — or when the pane's width does — and only
  /// then.
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
    if (table == null || table.reveal != reveal || table.budget != budget) {
      table = (
        reveal: reveal,
        budget: budget,
        rows: _layOut(
          block,
          buffer,
          tokensOf,
          hidden,
          styleOf,
          theme,
          scaler,
          budget,
        ),
      );
      _tables[block.startLine] = table;
    }
    final rows = table.rows;
    final at = line - block.startLine;
    return at >= 0 && at < rows.length ? rows[at] : null;
  }

  /// Lays [block] out: its cells measured, its columns set — fitted to
  /// [budget] when they want more room than it — and each line's gaps or
  /// wrapped pieces worked out.
  static List<LiveTableRow> _layOut(
    Block block,
    SourceBuffer buffer,
    List<Token> Function(int line) tokensOf,
    bool Function(int line, Token token) hidden,
    TextStyle? Function(Token token) styleOf,
    MarkdownTheme theme,
    TextScaler scaler,
    double budget,
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
      final own = delimiter ? const <(int, int)>[] : cellsOf(text);
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
    // The table as it wants to be, and — when that is wider than the pane —
    // the same table fitted to it.
    final natural = <double>[0];
    for (final width in column) {
      natural.add(natural.last + width + 2 * pad);
    }
    // The widest word of each column: the room a fitted column keeps, so a
    // word is not broken where the read view would keep it whole.
    final least = List<double>.filled(columns, 0);
    for (final row in widths) {
      for (var at = 0; at < row.length; at++) {
        if (row[at].least > least[at]) least[at] = row[at].least;
      }
    }
    final fits = natural.last <= budget;
    final fitted = fits ? column : _fitColumns(column, least, pad, budget);
    final edges = <double>[0];
    for (final width in fitted) {
      edges.add(edges.last + width + 2 * pad);
    }
    final tiny = _tinyAdvance(scaler);
    // The columns' alignments, from the delimiter row: a right-aligned
    // column's text stands at its right edge, as the read view sets it.
    final aligns = lines.length > 1
        ? MarkdownTable.alignsOf(lines[1])
        : const <TableAlign>[];
    return <LiveTableRow>[
      for (var row = 0; row < lines.length; row++)
        (
          edges: edges,
          gaps: fits || delimiters[row]
              ? _gaps(
                  lines[row],
                  cells[row],
                  widths[row],
                  edges,
                  pad,
                  tiny,
                  (row == 0 ? theme.tableHeader : theme.tableCell)
                          .letterSpacing ??
                      0,
                  aligns,
                )
              : const <LiveTableGap>[],
          wrapped: fits || delimiters[row]
              ? const <LiveTableLine>[]
              : _wrappedRow(
                  lines[row],
                  tokensOf(block.startLine + row),
                  cells[row],
                  fitted,
                  edges,
                  pad,
                  aligns,
                  row == 0 ? theme.tableHeader : theme.tableCell,
                  scaler,
                  (token) => hidden(block.startLine + row, token),
                  styleOf,
                ),
          header: row == 0,
          delimiter: delimiters[row],
          last: row == lines.length - 1,
        ),
    ];
  }

  /// The natural cell [column] widths of a table wider than [budget]: the
  /// columns shrunk together, each in proportion to what its widest cell
  /// wants, so the table ends exactly on the pane — every column keeping the
  /// [pad] either side of it and its widest word at least, as far as the
  /// pane can give it.
  static List<double> _fitColumns(
    List<double> column,
    List<double> least,
    double pad,
    double budget,
  ) {
    final count = column.length;
    final fit = List<double>.filled(count, 0);
    if (count == 0) return fit;
    final room = budget - 2 * pad * count;
    final total = column.fold<double>(0, (sum, width) => sum + width);
    if (total <= 0 || room <= 0) {
      // Nothing to go round: the pane is all padding, so the cells take none.
      return fit;
    }
    // Each column keeps at least its widest word, where the pane can give
    // it: a fitted table breaks a line between words, as the read view
    // does, and only a word wider than its whole column is broken itself.
    // The floor is the column's own — capping it at an even share would
    // break the words of a column the pane gave more room to than the
    // others — and the branch below is what answers for floors that do not
    // fit together at all.
    final floor = <double>[
      for (var at = 0; at < count; at++)
        if (least[at] > 0) least[at] else _minCellWidth,
    ];
    final words = floor.fold<double>(0, (sum, width) => sum + width);
    if (words > room) {
      // Even the words do not fit: the columns share the pane in proportion
      // to what their widest cells want, and the longest words break.
      for (var at = 0; at < count; at++) {
        fit[at] = room * column[at] / total;
      }
      return fit;
    }
    final pinned = List<bool>.filled(count, false);
    var taken = 0.0;
    var pool = total;
    for (var pass = 0; pass < count; pass++) {
      var pinnedNow = false;
      for (var at = 0; at < count; at++) {
        if (pinned[at] || pool <= 0) continue;
        if ((room - taken) * column[at] / pool < floor[at]) {
          pinned[at] = true;
          fit[at] = floor[at];
          taken += floor[at];
          pool -= column[at];
          pinnedNow = true;
        }
      }
      if (!pinnedNow) break;
    }
    for (var at = 0; at < count; at++) {
      if (pinned[at]) continue;
      fit[at] = pool <= 0 ? 0 : (room - taken) * column[at] / pool;
    }
    return fit;
  }

  /// The visual lines of a row laid out in [fitted] columns: each cell's
  /// text wrapped inside its column — measured with the same spans it is
  /// drawn with, so a piece's range is exactly the source it shows — and
  /// placed on the line its piece falls on, at its column's own [edges].
  static List<LiveTableLine> _wrappedRow(
    String text,
    List<Token> tokens,
    List<(int, int)> cells,
    List<double> fitted,
    List<double> edges,
    double pad,
    List<TableAlign> aligns,
    TextStyle style,
    TextScaler scaler,
    bool Function(Token token) hiddenAtRest,
    TextStyle? Function(Token token) styleOf,
  ) {
    final lines = <List<LiveTablePiece>>[];
    final heights = <double>[];
    final fallback = _lineHeight(style, scaler);
    for (var at = 0; at < cells.length; at++) {
      final (start, end) = cells[at];
      final width = at < fitted.length ? fitted[at] : fitted.last;
      final spans = _spans(text, tokens, start, end, hiddenAtRest, styleOf);
      final painter = TextPainter(
        text: TextSpan(children: spans, style: style),
        strutStyle: StrutStyle.fromTextStyle(style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final metrics = painter.computeLineMetrics();
      final ranges = <(int, int)>[];
      if (metrics.isEmpty) {
        ranges.add((start, end));
      } else {
        // The painter measures the cell as it is drawn, its hidden marks
        // left out: a line boundary comes back as an offset of that drawn
        // text, and is read back into the source through the stretches it
        // was made of (`_sourceOf`) — adding the cell's start would put
        // every break short of its word by the marks before it.
        final shown = _shownOf(tokens, start, end, hiddenAtRest);
        var from = start;
        var drawn = 0;
        for (var line = 0; line < metrics.length; line++) {
          // The last visual line takes the cell's own end: the ranges are
          // contiguous, so they cut the cell's source into what each line
          // shows and nothing falls between them.
          var to = end;
          if (line < metrics.length - 1) {
            drawn = painter.getLineBoundary(TextPosition(offset: drawn)).end;
            to = _sourceOf(shown, start, drawn);
          }
          if (to < from || to > end) to = to < from ? from : end;
          ranges.add((from, to));
          from = to;
        }
      }
      final left = edges[at] + pad;
      final align = at < aligns.length ? aligns[at] : TableAlign.none;
      for (var line = 0; line < ranges.length; line++) {
        while (lines.length <= line) {
          lines.add(<LiveTablePiece>[]);
          heights.add(0);
        }
        final (from, to) = ranges[line];
        final pieceWidth = line < metrics.length
            ? metrics[line].width
            : _textWidth(text.substring(from, to), style, scaler);
        // A right- or centred column sets each of its visual lines off its
        // own left edge, as the read view aligns every one of them.
        final room = width - pieceWidth;
        final shift = switch (align) {
          TableAlign.right when room > 0 => room,
          TableAlign.center when room > 0 => room / 2,
          _ => 0.0,
        };
        lines[line].add((start: from, end: to, x: left + shift));
        final pieceHeight = line < metrics.length
            ? metrics[line].height
            : fallback;
        if (pieceHeight > heights[line]) heights[line] = pieceHeight;
      }
      painter.dispose();
    }
    return <LiveTableLine>[
      for (var at = 0; at < lines.length; at++)
        (pieces: lines[at], height: heights[at] <= 0 ? fallback : heights[at]),
    ];
  }

  /// How wide [text] is set in [style], no room to wrap into: a piece's own
  /// width, for a column that sets its pieces off its right or centre.
  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// How tall a line of [style] is at [scaler]: a cell of no text at all is
  /// still a line of the row.
  static double _lineHeight(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'x', style: style),
      strutStyle: StrutStyle.fromTextStyle(style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
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
    List<TableAlign> aligns,
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
      // The room its column leaves beside its text: before it for a
      // right-aligned column, half of it for a centred one.
      final room = edges[at + 1] - edges[at] - 2 * pad - cell.visible;
      // The read view's paragraph measures its text with the trailing half
      // of its last glyph's spacing, and sets the first half before it: a
      // text moved off its column's start stands half a spacing short of
      // the room it was given.
      final shift = at >= aligns.length || room <= 0
          ? 0.0
          : switch (aligns[at]) {
              TableAlign.right => room - ambient / 2,
              TableAlign.center => room / 2 - ambient / 2,
              TableAlign.none || TableAlign.left => 0.0,
            };
      gap(from, start, edges[at] + pad + shift - lead - x);
      from = end;
      x = edges[at] + pad + shift - lead + cell.visible + cell.hidden * tiny;
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
    if (end <= start) return (visible: 0, hidden: 0, lead: 0, least: 0);
    final spans = _spans(text, tokens, start, end, hiddenAtRest, styleOf);
    var hidden = 0;
    int? lead;
    var at = start;
    for (final token in tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) lead ??= hidden;
      if (hiddenAtRest(token)) {
        hidden += to - from;
      } else {
        lead ??= hidden;
      }
      at = to;
    }
    if (at < end) lead ??= hidden;
    final painter = TextPainter(
      text: TextSpan(children: spans, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return (
      visible: width,
      hidden: hidden,
      lead: lead ?? hidden,
      least: _leastWidth(
        text,
        tokens,
        start,
        end,
        style,
        scaler,
        hiddenAtRest,
        styleOf,
      ),
    );
  }

  /// How wide the widest word of `[start, end)` of [text] is: the room a
  /// column fitted to a pane is never given less than, so a word is not
  /// broken across two of its lines where the read view would keep it whole.
  static double _leastWidth(
    String text,
    List<Token> tokens,
    int start,
    int end,
    TextStyle style,
    TextScaler scaler,
    bool Function(Token token) hiddenAtRest,
    TextStyle? Function(Token token) styleOf,
  ) {
    var most = 0.0;
    var at = start;
    while (at < end) {
      while (at < end && _space(text.codeUnitAt(at))) {
        at++;
      }
      var to = at;
      while (to < end && !_space(text.codeUnitAt(to))) {
        to++;
      }
      if (to <= at) break;
      final painter = TextPainter(
        text: TextSpan(
          children: _spans(text, tokens, at, to, hiddenAtRest, styleOf),
          style: style,
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      if (painter.width > most) most = painter.width;
      painter.dispose();
      at = to;
    }
    return most;
  }

  /// The spans `[start, end)` of [text] is drawn in: its tokens' styles, and
  /// the ones [hiddenAtRest] says are marks left out — the same spans
  /// [_measure] measures, so a cell's measured width and its wrapped pieces
  /// are the same text.
  static List<InlineSpan> _spans(
    String text,
    List<Token> tokens,
    int start,
    int end,
    bool Function(Token token) hiddenAtRest,
    TextStyle? Function(Token token) styleOf,
  ) {
    return <InlineSpan>[
      for (final (from, to, token) in _segments(tokens, start, end))
        if (token == null)
          TextSpan(text: text.substring(from, to))
        else if (!hiddenAtRest(token))
          TextSpan(text: text.substring(from, to), style: styleOf(token)),
    ];
  }

  /// The stretches of source `[start, end)` is drawn from, in order: what
  /// [_spans] draws of it, its hidden marks left out.
  static List<(int, int)> _shownOf(
    List<Token> tokens,
    int start,
    int end,
    bool Function(Token token) hiddenAtRest,
  ) => <(int, int)>[
    for (final (from, to, token) in _segments(tokens, start, end))
      if (token == null || !hiddenAtRest(token)) (from, to),
  ];

  /// The source offset the drawn text's offset [drawn] stands for, [shown]
  /// being the stretches of source that text is made of, from [start]: the
  /// [drawn]-th character of them laid end to end. An offset between two
  /// stretches, where hidden marks sit, is the earlier one's end — a line
  /// broken there ends on its text, and the marks open the next line, with
  /// the word they belong to.
  static int _sourceOf(List<(int, int)> shown, int start, int drawn) {
    var left = drawn;
    for (final (from, to) in shown) {
      if (left <= to - from) return from + left;
      left -= to - from;
    }
    return shown.isEmpty ? start : shown.last.$2;
  }

  /// `[start, end)` cut at [tokens]' edges: each token's stretch, clipped to
  /// it, and the stretches between them, which have no token.
  static List<(int, int, Token?)> _segments(
    List<Token> tokens,
    int start,
    int end,
  ) {
    if (end <= start) return const <(int, int, Token?)>[];
    final segments = <(int, int, Token?)>[];
    var at = start;
    for (final token in tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) segments.add((at, from, null));
      segments.add((from, to, token));
      at = to;
    }
    if (at < end) segments.add((at, end, null));
    return segments;
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
