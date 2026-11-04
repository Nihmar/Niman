/// The slivers the source view's rows are laid out in (#729): one over all
/// of them, or — with side-by-side `columns` blocks — one for each run of
/// rows between two, placed by its part of the note's map, and a
/// [SliverColumns] for each block, in its host row.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/block_heights.dart';
import 'package:niman/src/markdown/render/callout_style.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/sliver_columns.dart';
import 'package:niman/src/markdown/render/sliver_segments.dart';
import 'package:niman/src/markdown/render/source_folds.dart';

/// Builds line [index] [width] wide: a row of the note, or a line of a
/// side-by-side column ([inColumn]), which has no gutter of its own, its
/// block standing [outerIndent] in and [outerQuotes] quotes deep.
typedef SourceLineBuilder = Widget Function(
  BuildContext context,
  int index, {
  required double width,
  bool inColumn,
  double outerIndent,
  int outerQuotes,
});

/// What a side-by-side block's slivers are drawn with, beyond its layout:
/// the gutter beside it, the room between its columns, a fence's band, the
/// text's width its outer fences take, and how far its list items indent it.
typedef SourceColumnsLook = ({
  double gutter,
  double gap,
  double band,
  double textWidth,
  bool numbered,
  MarkdownTheme theme,
  double Function(LiveRun run) itemsIndent,
});

/// How far from the text the bracket beside a side-by-side block stands,
/// in the gutter.
const double _bracketInset = 6;

/// The note's rows, [width] wide: one sliver over all of them, or a sliver
/// for each run of rows between two of [hosts]' side-by-side blocks and one
/// for each block. [line] builds each line.
Widget sourceRowSlivers({
  required double width,
  required BlockHeightMap heights,
  required SourceFolds folds,
  required LiveHosts hosts,
  required SourceColumnsLook look,
  required SourceLineBuilder line,
}) {
  Widget rows(int start, int end) => SliverMarkdownBlocks(
    key: start == 0 ? null : ValueKey<String>('rows-$start'),
    heights: start == 0 && end == heights.length
        ? heights
        : BlockHeightRange(heights, start, end),
    segment: hosts.layouts.isNotEmpty,
    delegate: SliverChildBuilderDelegate(
      // A row is a line nobody folded away.
      (context, row) => line(context, folds.lineOf(start + row), width: width),
      childCount: end - start,
    ),
  );
  final layouts = hosts.layouts;
  if (layouts.isEmpty) return rows(0, heights.length);
  final slivers = <Widget>[];
  final starts = <int>[];
  var from = 0;
  for (final layout in layouts) {
    final host = folds.rowOf(layout.run.start);
    if (host > from) {
      starts.add(from);
      slivers.add(rows(from, host));
    }
    starts.add(host);
    slivers.add(_columnsSliver(layout, host, heights, look, line));
    from = host + 1;
  }
  if (from < heights.length) {
    starts.add(from);
    slivers.add(rows(from, heights.length));
  }
  return SliverSegments(heights: heights, starts: starts, slivers: slivers);
}

/// [layout]'s block, its columns side by side, in row [host].
Widget _columnsSliver(
  LiveLayout layout,
  int host,
  BlockHeightMap heights,
  SourceColumnsLook look,
  SourceLineBuilder line,
) {
  final run = layout.run;
  final theme = look.theme;
  final gutter = look.gutter;
  final band = look.band;
  return SliverColumns(
    key: ValueKey<String>('columns-${run.start}'),
    heights: heights,
    index: host,
    gap: look.gap,
    indent: gutter + look.itemsIndent(run),
    // A block in a quote or a callout: their bars, and a callout's box,
    // down the block's whole height, as its rows draw them.
    quote: run.quoteDepth == 0
        ? null
        : (
            left: gutter,
            depth: run.quoteDepth,
            bar: theme.quoteBar,
            barWidth: theme.quoteBarWidth,
            indent: theme.quoteIndentPerLevel,
            callout: run.callout == null
                ? null
                : calloutStyleOf(run.callout!.type).color,
          ),
    // One gutter and several columns: the columns' lines are not
    // numbered, and a bracket down the gutter spans the block between
    // its outer fences, which are.
    bracket: look.numbered && gutter > _bracketInset
        ? (
            x: gutter - _bracketInset,
            top: band,
            bottom: run.closed ? band : 0,
            color: theme.markerDim,
          )
        : null,
    // Its outer fences are rows of its quote: the block draws the quote.
    opener: (context) => line(
      context,
      run.start,
      width: look.textWidth,
      outerQuotes: run.quoteDepth,
    ),
    closer: run.closed
        ? (context) => line(
            context,
            run.end - 1,
            width: look.textWidth,
            outerQuotes: run.quoteDepth,
          )
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
                  (context, index) => line(
                    context,
                    run.columns[at].start + index,
                    width: layout.widths[at],
                    inColumn: true,
                    outerIndent: look.itemsIndent(run),
                    outerQuotes: run.quoteDepth,
                  ),
                  childCount: layout.maps[at].length,
                ),
              ),
            ),
        ],
    ],
  );
}
