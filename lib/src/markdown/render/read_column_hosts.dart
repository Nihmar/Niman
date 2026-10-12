/// Which `columns` blocks of the read view sit side by side at the width
/// it has, and what that makes of the note's height map (#729,
/// `docs/records/note-columns.md`, "The read view").
///
/// A side-by-side block is one entry of the note's map — its opener's, the
/// host — as tall as the block; its other blocks are entries of no height,
/// drawn in their columns' slivers. A block whose columns would each be a
/// row of their own is not hosted at all: its blocks are the note's, one
/// under the other, as on a phone. So which entries are hosted depends on
/// the width, and on the blocks: this keeps a flag an entry, and says
/// which ones a new width or an edit changed.
library;

import 'dart:typed_data';

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/column_layout.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/columns_run.dart';

/// How a hosted run is laid out: its rows of column indices, each column's
/// width, and the height map each column's sliver places its blocks by.
typedef RunLayout = ({
  List<List<int>> rows,
  List<double> widths,
  List<double> shares,
  List<BlockHeightMap> maps,
});

/// The side-by-side `columns` blocks of a block list.
final class ReadColumnHosts {
  /// An entry drawn in the note's run of blocks.
  static const int ordinary = 0;

  /// An entry of a side-by-side block past its host: no height of its own.
  static const int hosted = 1;

  /// A side-by-side block's own entry, as tall as the block.
  static const int host = 2;

  List<ColumnsRun> _runs = const <ColumnsRun>[];

  /// The runs side by side at the last width, in order.
  List<ColumnsRun> get sideBySide => _sideBySide;
  List<ColumnsRun> _sideBySide = const <ColumnsRun>[];

  final Map<int, RunLayout> _layouts = <int, RunLayout>{};

  /// Each entry's flag: [ordinary], [hosted] or [host]; null while no run
  /// is side by side. Set to the flags an edit moved ([spliced]), or to
  /// null for a new map, which assumes no block side by side.
  Uint8List? flags;

  /// Whether no run is side by side: the note is one run of blocks.
  bool get isEmpty => _sideBySide.isEmpty;

  /// Entry [index]'s flag.
  int flagOf(int index) {
    final current = flags;
    if (current == null || index < 0 || index >= current.length) {
      return ordinary;
    }
    return current[index];
  }

  /// The run hosted at [index], its opener's entry.
  ColumnsRun? runAt(int index) =>
      flagOf(index) == host ? _sideBySide[_runIndexOf(index)] : null;

  /// The entry of the block [index] is drawn in: its host when it is a
  /// side-by-side block's, itself otherwise.
  int entryOf(int index) {
    if (flagOf(index) != hosted) return index;
    return _sideBySide[_runIndexOf(index)].start;
  }

  /// [run]'s layout.
  RunLayout layoutOf(ColumnsRun run) => _layouts[run.start]!;

  int _runIndexOf(int index) {
    var low = 0;
    var high = _sideBySide.length - 1;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_sideBySide[middle].start <= index) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  /// Reads the runs of [blocks] again, and lays them out in [width]: the
  /// note's text, [em] the body's size, [listIndent] how far an item
  /// indents. With [enabled] off — a selectable view, whose selection
  /// follows the screen's order and not the source's — none is side by
  /// side.
  ///
  /// [rawEstimate] is an entry's estimate as an ordinary block, which the
  /// columns' maps start from. Returns the entries whose flag changed,
  /// counted against [previous] — the flags before, moved by the edit
  /// that made [blocks], or null for none.
  List<int> layOut(
    List<Block> blocks,
    String Function(int line) lineAt, {
    required double width,
    required double em,
    required double listIndent,
    required bool enabled,
    required double Function(int index) rawEstimate,
    Uint8List? previous,
  }) {
    _runs = ColumnsRun.of(blocks, lineAt);
    final old = Map<int, RunLayout>.of(_layouts);
    _layouts.clear();
    final side = <ColumnsRun>[];
    if (enabled) {
      for (final run in _runs) {
        final inner = width - run.items * listIndent;
        final layout = _layout(run, inner, em, rawEstimate, old);
        if (layout != null) {
          side.add(run);
          _layouts[run.start] = layout;
        }
      }
    }
    _sideBySide = side;
    final laid = side.isEmpty ? null : Uint8List(blocks.length);
    if (laid != null) {
      for (final run in side) {
        laid[run.start] = host;
        laid.fillRange(run.start + 1, run.end, hosted);
      }
    }
    flags = laid;
    if (laid == null && previous == null) return const <int>[];
    return [
      for (var at = 0; at < blocks.length; at++)
        if ((laid?[at] ?? ordinary) !=
            (previous != null && at < previous.length
                ? previous[at]
                : ordinary))
          at,
    ];
  }

  /// The flags, moved by an edit that replaced [removed] entries from
  /// [start] with [inserted] ones, which are ordinary until laid out.
  Uint8List? spliced(int start, int removed, int inserted) {
    final current = flags;
    if (current == null) return null;
    final end = (start + removed).clamp(start, current.length);
    return Uint8List(current.length - (end - start) + inserted)
      ..setRange(0, start, current)
      ..setRange(
        start + inserted,
        current.length - end + start + inserted,
        current,
        end,
      );
  }

  /// [run]'s layout in [width], or null when its columns would each be a
  /// row of their own.
  RunLayout? _layout(
    ColumnsRun run,
    double width,
    double em,
    double Function(int index) rawEstimate,
    Map<int, RunLayout> old,
  ) {
    if (run.columns.length < 2) return null;
    final minimum = ColumnLayout.minEms * em;
    final gap = ColumnLayout.gapEms * em;
    final rows = ColumnLayout.rows(
      run.columns.length,
      width: width,
      minimum: minimum,
      gap: gap,
    );
    if (!ColumnLayout.sideBySide(rows)) return null;
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
    return (
      rows: rows,
      widths: widths,
      shares: shares,
      maps: [
        for (var at = 0; at < run.columns.length; at++)
          _mapOf(
            run.columns[at].blocks,
            wrap: widths[at] > 0 ? width / widths[at] : 1,
            rawEstimate: rawEstimate,
            before:
                before != null &&
                    at < before.maps.length &&
                    before.widths[at] == widths[at]
                ? before.maps[at]
                : null,
          ),
      ],
    );
  }

  /// The height map of a column of [blocks], each estimated as an ordinary
  /// block made [wrap] times as tall by the narrower width; [before], the
  /// column's map before the edit, when it holds as many blocks.
  static BlockHeightMap _mapOf(
    List<int> blocks, {
    required double wrap,
    required double Function(int index) rawEstimate,
    BlockHeightMap? before,
  }) {
    if (before != null && before.length == blocks.length) return before;
    final factor = wrap.clamp(1.0, 4.0);
    return BlockHeightMap(
      count: blocks.length,
      estimate: (at) => rawEstimate(blocks[at]) * factor,
    );
  }

  /// [run]'s height before any frame has drawn it: per row, its tallest
  /// column; the rows and the gaps between them summed, and [bands] for
  /// its outer fences.
  double estimateOf(ColumnsRun run, double gap, double bands) {
    final layout = _layouts[run.start];
    if (layout == null) return 0;
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
}
