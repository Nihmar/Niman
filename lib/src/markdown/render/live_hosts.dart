/// The `columns` blocks `live` draws side by side, at the width it has
/// (#729, `docs/records/note-columns.md`, "Windowing: one sliver per
/// column"): each one's rows of columns, their widths, and the height map
/// each column's sliver places its lines by.
///
/// A block whose columns would each be a row of their own is not hosted:
/// its lines are the note's rows, the engine as it was. That is the phone,
/// a narrow window, and the blocks the view keeps stacked.
library;

import 'package:niman/src/markdown/column_layout.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// A side-by-side block's layout: its rows of column indices, each
/// column's width and share, and each column's height map, over its lines.
typedef LiveLayout = ({
  LiveRun run,
  List<List<int>> rows,
  List<double> widths,
  List<double> shares,
  List<BlockHeightMap> maps,
});

/// The side-by-side `columns` blocks of the note `live` draws.
final class LiveHosts {
  List<LiveLayout> _layouts = const <LiveLayout>[];

  /// The side-by-side blocks, in order.
  List<LiveLayout> get layouts => _layouts;

  /// The openers and ends of the side-by-side blocks, for the rows.
  Map<int, int> get hosts => <int, int>{
    for (final layout in _layouts) layout.run.start: layout.run.end,
  };

  /// The block [line] opens, when it is a side-by-side block's opener.
  LiveLayout? openedOn(int line) {
    final layout = holding(line);
    return layout != null && layout.run.start == line ? layout : null;
  }

  /// The side-by-side block holding [line], or null.
  LiveLayout? holding(int line) {
    var low = 0;
    var high = _layouts.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_layouts[middle].run.start <= line) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low == 0) return null;
    final layout = _layouts[low - 1];
    return layout.run.contains(line) ? layout : null;
  }

  /// Lays [runs] out, each in the width [widthOf] gives it — the text's,
  /// less the list items it stands in — text of [em]: the ones whose
  /// columns sit side by side there and that [allowed] lets, each column's
  /// map estimating line `l` at `estimate(l, columnWidth)`. A column whose
  /// lines and width are the ones it had keeps its map, and the heights a
  /// frame measured in it.
  void layOut(
    List<LiveRun> runs, {
    required double Function(LiveRun run) widthOf,
    required double em,
    required double Function(int line, double width) estimate,
    required bool Function(LiveRun run) allowed,
  }) {
    final minimum = ColumnLayout.minEms * em;
    final gap = ColumnLayout.gapEms * em;
    final old = <int, LiveLayout>{
      for (final layout in _layouts) layout.run.start: layout,
    };
    final next = <LiveLayout>[];
    for (final run in runs) {
      if (run.columns.length < 2 || !allowed(run)) continue;
      final width = widthOf(run);
      final rows = ColumnLayout.rows(
        run.columns.length,
        width: width,
        minimum: minimum,
        gap: gap,
      );
      if (!ColumnLayout.sideBySide(rows)) continue;
      final shares = ColumnLayout.shares([
        for (final column in run.columns) column.width,
      ]);
      final widths = List<double>.filled(run.columns.length, 0);
      for (final row in rows) {
        final inRow = ColumnLayout.widths(
          [for (final at in row) shares[at]],
          width: width,
          minimum: minimum,
          gap: gap,
        );
        for (var at = 0; at < row.length; at++) {
          widths[row[at]] = inRow[at];
        }
      }
      final before = old[run.start];
      next.add((
        run: run,
        rows: rows,
        widths: widths,
        shares: shares,
        maps: [
          for (var at = 0; at < run.columns.length; at++)
            _kept(before, run.columns[at], widths[at]) ??
                BlockHeightMap(
                  count: run.columns[at].end - run.columns[at].start,
                  estimate: (line) =>
                      estimate(run.columns[at].start + line, widths[at]),
                ),
        ],
      ));
    }
    _layouts = next;
  }

  /// [before]'s map of the column over [column]'s lines at [width], when
  /// it had one.
  static BlockHeightMap? _kept(
    LiveLayout? before,
    LiveColumn column,
    double width,
  ) {
    if (before == null) return null;
    for (var at = 0; at < before.run.columns.length; at++) {
      final had = before.run.columns[at];
      if (had.start == column.start &&
          had.end == column.end &&
          before.widths[at] == width &&
          before.maps[at].length == column.end - column.start) {
        return before.maps[at];
      }
    }
    return null;
  }

  /// Follows [edit]: a block after it moves with the lines, and an edit
  /// inside one column splices that column's map — its other lines keep
  /// their heights, so typing in a column moves nothing else. An edit
  /// across a fence lets the block's maps go; the next layout makes them.
  void edited(
    SourceEdit edit,
    double Function(int line, double width) estimate,
  ) {
    if (_layouts.isEmpty) return;
    final first = edit.firstLine;
    final untouched = edit.firstUntouchedLine;
    final delta = edit.lineDelta;
    final next = <LiveLayout>[];
    for (final layout in _layouts) {
      final run = layout.run;
      if (untouched <= run.start) {
        next.add(_moved(layout, delta, from: 0));
        continue;
      }
      if (first >= run.end) {
        next.add(layout);
        continue;
      }
      final column = run.columnOf(first);
      if (column < 0) continue;
      final lines = run.columns[column];
      // Inside the column's own lines, past its opener and short of its
      // closer when it has them: the fences are the column's edges.
      if (first <= lines.start || untouched >= lines.end) continue;
      layout.maps[column].splice(
        first - lines.start,
        edit.removedLines,
        edit.insertedLines,
        (line) => estimate(lines.start + line, layout.widths[column]),
      );
      next.add(_moved(layout, delta, from: column));
    }
    _layouts = next;
  }

  /// [layout] with its lines from column [from] on — its end, the start
  /// of the columns after it — moved [delta] lines; from 0, all of it.
  static LiveLayout _moved(LiveLayout layout, int delta, {required int from}) {
    if (delta == 0) return layout;
    final run = layout.run;
    return (
      run: LiveRun(
        start: from == 0 ? run.start + delta : run.start,
        end: run.end + delta,
        closed: run.closed,
        items: run.items,
        columns: [
          for (var at = 0; at < run.columns.length; at++)
            if (at < from)
              run.columns[at]
            else
              (
                start: at == from && from > 0
                    ? run.columns[at].start
                    : run.columns[at].start + delta,
                end: run.columns[at].end + delta,
                width: run.columns[at].width,
              ),
        ],
      ),
      rows: layout.rows,
      widths: layout.widths,
      shares: layout.shares,
      maps: layout.maps,
    );
  }

  /// [layout]'s height before a frame has drawn it: [bands] for its outer
  /// fences, and per row of columns its tallest column, [gap] between two.
  static double estimateOf(LiveLayout layout, double gap, double bands) {
    var total = bands;
    for (var at = 0; at < layout.rows.length; at++) {
      if (at > 0) total += gap;
      var tallest = 0.0;
      for (final column in layout.rows[at]) {
        final extent = layout.maps[column].totalExtent;
        if (extent > tallest) tallest = extent;
      }
      total += tallest;
    }
    return total;
  }

  /// Where column [column] of [layout] starts across its row, from the
  /// columns' left edge, [gap] between two.
  static double leftOf(LiveLayout layout, int column, double gap) {
    for (final row in layout.rows) {
      var left = 0.0;
      for (final at in row) {
        if (at == column) return left;
        left += layout.widths[at] + gap;
      }
    }
    return 0;
  }

  /// Where the row of columns holding [column] starts, down from the
  /// opener's band, [gap] between two rows.
  static double topOf(LiveLayout layout, int column, double gap) {
    var top = 0.0;
    for (final row in layout.rows) {
      if (row.contains(column)) return top;
      var tallest = 0.0;
      for (final at in row) {
        final extent = layout.maps[at].totalExtent;
        if (extent > tallest) tallest = extent;
      }
      top += tallest + gap;
    }
    return top;
  }
}
