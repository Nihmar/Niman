import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/source_folds.dart';

/// Where the source view draws its lines, in the scroll view's coordinates:
/// a row's place from the note's height map, and a line of a side-by-side
/// `columns` block's from its host row, its row of columns and its
/// column's own map (#729) — and the other way, which line a point is on.
///
/// Arithmetic over the view's map and layouts, which it reads through the
/// narrow callbacks it is handed: nothing here asks a drawn line.
final class SourceGeometry {
  /// The geometry of the rows [_heights] places, as [_folds] and [_hosts]
  /// leave them.
  new({
    required this._heights,
    required this._folds,
    required this._hosts,
    required this._padding,
    required this._band,
    required this._gap,
    required this._columnsLeft,
  });

  /// The heights the rows are placed with.
  final BlockHeightMap Function() _heights;

  /// The folded sections, and the blocks hosted side by side.
  final SourceFolds _folds;

  /// The blocks drawn side by side at the pane's width.
  final LiveHosts _hosts;

  /// The note's padding.
  final EdgeInsets Function() _padding;

  /// A fence line's band, as drawn.
  final double Function() _band;

  /// The room between two columns, and between two rows of them.
  final double Function() _gap;

  /// The note box's x where a side-by-side block's columns start.
  final double Function(LiveLayout layout) _columnsLeft;

  /// Where line [line] is drawn, in the scroll view's coordinates: its top
  /// and its height (#729). A row's, from the note's map; a line of a
  /// side-by-side column's, from its host row, its row of columns and its
  /// column's own map.
  ({double top, double height}) lineBox(int line) {
    final heights = _heights();
    final top0 = _padding().top;
    final host = _folds.hostOf(line);
    final layout = host == null ? null : _hosts.openedOn(host);
    if (host == null || layout == null) {
      final row = _folds.rowOf(line);
      return (
        top: top0 + heights.offsetOf(row),
        height: heights.extentFor(row),
      );
    }
    final band = _band();
    final hostRow = _folds.rowOf(host);
    final top = top0 + heights.offsetOf(hostRow);
    final run = layout.run;
    final column = run.columnOf(line);
    if (column < 0) {
      // The closer is the block's bottom band; a blank line between two
      // columns is drawn nowhere, and stands at the block's top.
      final closing = run.closed && line == run.end - 1;
      final extent = heights.extentFor(hostRow);
      return closing
          ? (top: top + extent - band, height: band)
          : (top: top, height: 0);
    }
    final map = layout.maps[column];
    final local = line - run.columns[column].start;
    return (
      top:
          top +
          band +
          LiveHosts.topOf(layout, column, _gap()) +
          map.offsetOf(local),
      height: map.extentFor(local),
    );
  }

  /// Line [line] as the scroll view sees it: its top and its bottom, in the
  /// view's coordinates ([lineBox]) — the map starts below the top
  /// padding, and the last row takes the bottom padding with it. A line of
  /// a side-by-side column is its own line, not its block's row, which can
  /// be taller than the screen.
  ({double top, double bottom}) lineBounds(int line) {
    final box = lineBox(line);
    final last =
        _folds.hostOf(line) == null &&
        _folds.rowOf(line) == _heights().length - 1;
    return (
      top: box.top,
      bottom: box.top + box.height + (last ? _padding().bottom : 0),
    );
  }

  /// The line drawn at [y], in the scroll view's coordinates, and at [x],
  /// the note box's, when a side-by-side block is there: its column's line
  /// at that height, the first column's when [x] is null.
  int lineAtY(double y, [double? x]) {
    final heights = _heights();
    final local = y - _padding().top;
    final row = local < 0
        ? 0
        : heights.indexAt(local) ?? math.max(0, heights.length - 1);
    final line = _folds.lineOf(row);
    final layout = _folds.isHost(line) ? _hosts.openedOn(line) : null;
    if (layout == null) return line;
    final run = layout.run;
    final inside = local - heights.offsetOf(row) - _band();
    if (inside < 0) return run.start;
    final gap = _gap();
    // The row of columns at that height, and the column nearest [x].
    var top = 0.0;
    for (final columns in layout.rows) {
      var tallest = 0.0;
      for (final at in columns) {
        tallest = math.max(tallest, layout.maps[at].totalExtent);
      }
      if (inside < top + tallest + gap) {
        final column = _columnNearest(layout, columns, x);
        final map = layout.maps[column];
        final at = map.indexAt(inside - top) ?? math.max(0, map.length - 1);
        return run.columns[column].start + at;
      }
      top += tallest + gap;
    }
    return run.closed ? run.end - 1 : run.columns.last.end - 1;
  }

  /// Which column of [columns], a row of [layout]'s, [x] — the note box's —
  /// is nearest; the first when [x] is null. The gap between two is split
  /// between them.
  int _columnNearest(LiveLayout layout, List<int> columns, double? x) {
    if (x == null) return columns.first;
    final left = _columnsLeft(layout);
    final gap = _gap();
    for (var at = 0; at < columns.length; at++) {
      final column = columns[at];
      final right =
          left +
          LiveHosts.leftOf(layout, column, gap) +
          layout.widths[column] +
          gap / 2;
      if (x < right) return column;
    }
    return columns.last;
  }

  /// Whether [x], the note box's, is across the column line [line] is
  /// drawn in, when it is a side-by-side column's: the gap between two
  /// columns is split between them, and a row's first and last columns
  /// reach its edges.
  bool inColumnOf(int line, double x) {
    final layout = columnLayoutOf(line);
    if (layout == null) return true;
    final column = layout.run.columnOf(line);
    if (column < 0) return true;
    final gap = _gap();
    final row = layout.rows.firstWhere((row) => row.contains(column));
    final left = _columnsLeft(layout) + LiveHosts.leftOf(layout, column, gap);
    final from = column == row.first ? double.negativeInfinity : left - gap / 2;
    final to = column == row.last
        ? double.infinity
        : left + layout.widths[column] + gap / 2;
    return x >= from && x < to;
  }

  /// The side-by-side block line [line] is hosted in, or null.
  LiveLayout? columnLayoutOf(int line) {
    final host = _folds.hostOf(line);
    return host == null ? null : _hosts.openedOn(host);
  }

  /// The side-by-side block and column line [line] is drawn in, or null.
  ({LiveLayout layout, int column})? columnOfLine(int line) {
    final layout = columnLayoutOf(line);
    if (layout == null) return null;
    final column = layout.run.columnOf(line);
    return column < 0 ? null : (layout: layout, column: column);
  }
}
