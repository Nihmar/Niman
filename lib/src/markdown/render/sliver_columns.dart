/// A `columns` block laid out side by side (#729,
/// `docs/records/note-columns.md`): one sliver per column, the columns of
/// a row beside each other, the rows one under the other, and the whole
/// block one entry of the note's height map.
///
/// ```text
/// SliverColumns                    records its extent in the note's map
/// └─ SliverMainAxisGroup           the rows, one under the other
///    ├─ the outer opener's band
///    ├─ SliverCrossAxisGroup       a row: a sliver per column, the gaps
///    ├─ the gap between two rows
///    ├─ SliverCrossAxisGroup       the next row, when the columns wrap
///    └─ the outer closer's band
/// ```
///
/// Each column is windowed by a sliver of its own, so a block of thousands
/// of lines builds what the viewport shows. The cross group gives each
/// column the same scroll constraints at its own width and takes the
/// tallest one's geometry: the block is as tall as its tallest column.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/block_heights.dart';

/// One column of a row: its share of the row's width after the gaps, and
/// the sliver that draws it.
typedef SliverColumn = ({double share, Widget sliver});

/// A `columns` block, its columns side by side in [rows].
final class SliverColumns extends StatelessWidget {
  /// The block that is entry [index] of [heights], the note's map.
  const new({
    required this.heights,
    required this.index,
    required this.rows,
    required this.gap,
    this.opener,
    this.closer,
    this.indent = 0,
    super.key,
  });

  /// The note's map, where the block's whole height goes.
  final BlockHeights heights;

  /// The block's entry in [heights].
  final int index;

  /// Its rows of columns, in order.
  final List<List<SliverColumn>> rows;

  /// The room between two columns, and between two rows.
  final double gap;

  /// The outer opener's band, drawn above the rows.
  final Widget? opener;

  /// The outer closer's band, drawn below them.
  final Widget? closer;

  /// How far in the block stands: the list items around it.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final opener = this.opener;
    final closer = this.closer;
    Widget group = SliverMainAxisGroup(
      slivers: [
        if (opener != null) SliverToBoxAdapter(child: opener),
        for (var at = 0; at < rows.length; at++) ...[
          if (at > 0) SliverToBoxAdapter(child: SizedBox(height: gap)),
          SliverCrossAxisGroup(slivers: _row(rows[at])),
        ],
        if (closer != null) SliverToBoxAdapter(child: closer),
      ],
    );
    if (indent > 0) {
      group = SliverPadding(
        padding: EdgeInsets.only(left: indent),
        sliver: group,
      );
    }
    return _ExtentRecorder(heights: heights, index: index, sliver: group);
  }

  /// A row's slivers: its columns, each flexed by its share, with a gap of
  /// no flex between two of them.
  List<Widget> _row(List<SliverColumn> row) => [
    for (var at = 0; at < row.length; at++) ...[
      if (at > 0)
        SliverConstrainedCrossAxis(
          maxExtent: gap,
          sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
      SliverCrossAxisExpanded(
        // Integers, a hundredth of a percent each: the shares split the
        // width after the gaps, as the CSS's `flex-grow` does.
        flex: (row[at].share * 100).round().clamp(1, 1 << 30),
        sliver: row[at].sliver,
      ),
    ],
  ];
}

/// Records its sliver's extent at [index] of [heights].
final class _ExtentRecorder extends SingleChildRenderObjectWidget {
  const new({
    required this.heights,
    required this.index,
    required Widget sliver,
  }) : super(child: sliver);

  final BlockHeights heights;
  final int index;

  @override
  _RenderExtentRecorder createRenderObject(BuildContext context) =>
      _RenderExtentRecorder(heights, index);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderExtentRecorder renderObject,
  ) {
    renderObject
      ..heights = heights
      ..index = index;
  }
}

/// The render object behind [_ExtentRecorder]: its child's geometry, its
/// scroll extent written to the note's map as a measured block's height
/// is, so the map's offsets past the block follow what it is.
final class _RenderExtentRecorder extends RenderProxySliver {
  new(this.heights, this.index);

  BlockHeights heights;
  int index;

  @override
  void performLayout() {
    super.performLayout();
    final geometry = this.geometry;
    if (geometry == null || geometry.scrollOffsetCorrection != null) return;
    heights.measured(index, geometry.scrollExtent);
  }
}
