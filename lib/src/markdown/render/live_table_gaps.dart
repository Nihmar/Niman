/// The gaps of a table's line in `live`: the pipes and the spaces between two
/// cells' text, drawn as nothing as wide as the grid needs.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/markdown/render/live_table_row_work.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// Works out a line's gaps, and the advances they are measured with.
abstract final class LiveTableGaps {
  /// The gaps of a line whose cells' text is [cells], [widths] wide: before
  /// the first cell's text a padding, between two cells' what is left of
  /// the first cell's column and the next one's padding, and after the last
  /// what is left of its column. A gap of no characters cannot be given a
  /// width, and is left out.
  ///
  /// The spaces a cell is written with — the writer's own, at either end of
  /// the gap between two cells' text — stand [space] wide where the gap has
  /// room for them, so a space typed at the end of a cell's text moves the
  /// caret by one space and not by its share of the whole column (#1160).
  /// What is left of the gap is the room the next cell's column takes, and
  /// it is the pipes' and the gap's middle's: the cells' text stays where
  /// the read view sets it, whichever side of a pipe it is on. A row written
  /// without its closing pipe has no pipe to take what is left: its last
  /// cell's spaces keep their width, and the room ends the line.
  ///
  /// A line's first glyph is set half its spacing in: a cell of the read
  /// view, a paragraph of its own, half the [ambient] spacing; here, when
  /// a gap opens the line, half the gap's. The first gap is spaced so that
  /// the first cell's text lands where the read view's does, and is left
  /// whole for it.
  static List<LiveTableGap> gaps(
    String text,
    List<(int, int)> cells,
    List<LiveTableMeasured> widths,
    List<double> edges,
    double pad,
    double tiny,
    double ambient,
    double space,
    List<TableAlign> aligns,
  ) {
    final gaps = <LiveTableGap>[];

    // [start, end) drawn [width] wide, its characters spaced evenly.
    void add(int start, int end, double width) {
      final count = end - start;
      if (count <= 0) return;
      // Each character keeps a hundredth of its size: the spacing is what
      // is left of the width.
      final spacing = start == 0
          ? (width + ambient / 2 - count * tiny) / (count + 0.5)
          : (width - count * tiny) / count;
      gaps.add((start: start, end: end, width: spacing * count));
    }

    void gap(int start, int end, double width) {
      if (end <= start) return;
      if (start > 0) {
        final count = end - start;
        // The spaces at the gap's ends are the writer's: the ones after the
        // cell on its left, and the ones before the cell on its right.
        var head = 0;
        while (head < count && _isGapSpace(text.codeUnitAt(start + head))) {
          head++;
        }
        var tail = 0;
        while (tail < count - head &&
            _isGapSpace(text.codeUnitAt(end - 1 - tail))) {
          tail++;
        }
        final middle = count - head - tail;
        final kept = (head + tail) * space;
        // What is left over is the room, and it needs a character to take
        // it: the pipe between the cells. A gap too narrow to give its own
        // spaces their width is spread evenly as it always was.
        if (middle > 0 && kept < width) {
          add(start, start + head, head * space);
          add(start + head, end - tail, width - kept);
          add(end - tail, end, tail * space);
          return;
        }
        // A row written without its closing pipe has no pipe to take the
        // room: its last cell's spaces keep their own width, and the room
        // ends the line, past the row's last character.
        if (middle == 0 && end == text.length && kept < width) {
          add(start, end, kept);
          return;
        }
      }
      add(start, end, width);
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

  /// Whether [char] is a space a gap's room is kept off: the whitespace
  /// `String.trim` takes off a cell's text, which is what puts it in the gap
  /// — the space and the tab above all.
  static bool _isGapSpace(int char) => String.fromCharCode(char).trim().isEmpty;

  /// How wide a space is set in [style] at [scaler]: the width a gap's own
  /// spaces keep where the room lets them — what a space typed at a cell's
  /// edge moves the caret by (#1160).
  ///
  /// Measured between two glyphs, where the engine counts it: a paragraph's
  /// own width may leave its trailing spaces out.
  static double spaceAdvance(TextStyle style, TextScaler scaler) {
    double width(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final answer = painter.width;
      painter.dispose();
      return answer;
    }

    return width('x x') - width('xx');
  }

  /// How wide one character of a gap is before its spacing: a hundredth of
  /// its size.
  static double tinyAdvance(TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'xxxxxxxxxx', style: LiveTables.gapStyle(0)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width / 10;
    painter.dispose();
    return width;
  }
}
