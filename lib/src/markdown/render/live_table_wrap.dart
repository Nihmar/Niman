/// A row of a table `live` fitted to the pane, its cells' text wrapped inside
/// their columns.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/live_table_counts.dart';
import 'package:niman/src/markdown/render/live_table_row.dart';
import 'package:niman/src/markdown/render/live_table_spans.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// Wraps a fitted row's cells into visual lines.
abstract final class LiveTableWrap {
  /// The visual lines of a row laid out in [fitted] columns: each cell's
  /// text wrapped inside its column — measured with the same spans it is
  /// drawn with, so a piece's range is exactly the source it shows — and
  /// placed on the line its piece falls on, at its column's own [edges].
  static List<LiveTableLine> wrappedRow(
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
      final spans = LiveTableSpans.spans(
        text,
        tokens,
        start,
        end,
        hiddenAtRest,
        styleOf,
      );
      LiveTableCounts.measurements++;
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
        // was made of (`LiveTableSpans.sourceOf`) — adding the cell's start
        // would put every break short of its word by the marks before it.
        final shown = LiveTableSpans.shownOf(tokens, start, end, hiddenAtRest);
        var from = start;
        var drawn = 0;
        for (var line = 0; line < metrics.length; line++) {
          // The last visual line takes the cell's own end: the ranges are
          // contiguous, so they cut the cell's source into what each line
          // shows and nothing falls between them.
          var to = end;
          if (line < metrics.length - 1) {
            drawn = painter.getLineBoundary(TextPosition(offset: drawn)).end;
            to = LiveTableSpans.sourceOf(shown, start, drawn);
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
    LiveTableCounts.measurements++;
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
}
