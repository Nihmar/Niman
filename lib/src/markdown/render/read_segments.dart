/// The read view's note cut at its side-by-side `columns` blocks (#729,
/// `docs/records/note-columns.md`, "The read view").
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/block_heights.dart';
import 'package:niman/src/markdown/render/columns_run.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/read_column_hosts.dart';
import 'package:niman/src/markdown/render/sliver_columns.dart';
import 'package:niman/src/markdown/render/sliver_segments.dart';

/// Draws the read view's entry [index] in [width].
///
/// [outerItems] is how many list items the sliver drawing it already
/// stands in: a column of a `columns` block opened in an item.
typedef ReadBlockBuilder = Widget Function(
  BuildContext context,
  int index,
  double width, {
  int outerItems,
});

/// The note cut at its side-by-side `columns` blocks ([hosts]): a sliver
/// for each run of blocks between two of them, placed by its part of the
/// note's map, and a [SliverColumns] for each of them, [gap] between its
/// columns and indented [listIndent] an item it stands in.
Widget readSegments({
  required BlockHeightMap heights,
  required ReadColumnHosts hosts,
  required double width,
  required double gap,
  required double listIndent,
  required ReadBlockBuilder blockAt,
}) {
  final slivers = <Widget>[];
  final starts = <int>[];
  void run(int start, int end) {
    if (end <= start) return;
    starts.add(start);
    slivers.add(
      SliverMarkdownBlocks(
        key: ValueKey<String>('blocks-$start'),
        heights: BlockHeightRange(heights, start, end),
        segment: true,
        delegate: SliverChildBuilderDelegate(
          (context, index) => blockAt(context, start + index, width),
          childCount: end - start,
        ),
      ),
    );
  }

  var from = 0;
  for (final columns in hosts.sideBySide) {
    run(from, columns.start);
    starts.add(columns.start);
    slivers.add(
      _columns(
        heights,
        columns,
        hosts.layoutOf(columns),
        width: width,
        gap: gap,
        listIndent: listIndent,
        blockAt: blockAt,
      ),
    );
    from = columns.end;
  }
  run(from, heights.length);
  return SliverSegments(heights: heights, starts: starts, slivers: slivers);
}

/// [run], its columns side by side in [width] as [layout] places them.
Widget _columns(
  BlockHeightMap heights,
  ColumnsRun run,
  RunLayout layout, {
  required double width,
  required double gap,
  required double listIndent,
  required ReadBlockBuilder blockAt,
}) {
  return SliverColumns(
    key: ValueKey<String>('columns-${run.start}'),
    heights: heights,
    index: run.start,
    gap: gap,
    indent: run.items * listIndent,
    opener: (context) =>
        blockAt(context, run.start, width, outerItems: run.items),
    closer: run.closed
        ? (context) =>
              blockAt(context, run.end - 1, width, outerItems: run.items)
        : null,
    rows: [
      for (final row in layout.rows)
        [
          for (final at in row)
            (
              share: layout.shares[at],
              sliver: SliverMarkdownBlocks(
                heights: layout.maps[at],
                segment: true,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => blockAt(
                    context,
                    run.columns[at].blocks[index],
                    layout.widths[at],
                    outerItems: run.items,
                  ),
                  childCount: run.columns[at].blocks.length,
                ),
              ),
            ),
        ],
    ],
  );
}
