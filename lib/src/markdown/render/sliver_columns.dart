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

/// A bracket down a block's gutter (#729): at `x`, from `top` below the
/// block's top to `bottom` above its end — its outer fences' bands — in
/// `color`. What `live` draws beside a side-by-side block, whose columns'
/// lines are not numbered.
typedef ColumnsBracket = ({double x, double top, double bottom, Color color});

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
    this.bracket,
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

  /// The bracket down the block's gutter, if any.
  final ColumnsBracket? bracket;

  /// How far in the columns stand: the list items around the block, or
  /// the gutter beside them. The fences are as wide as the block's row.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final opener = this.opener;
    final closer = this.closer;
    Widget rowsOf(Widget sliver) => indent > 0
        ? SliverPadding(
            padding: EdgeInsets.only(left: indent),
            sliver: sliver,
          )
        : sliver;
    final group = SliverMainAxisGroup(
      slivers: [
        if (opener != null) SliverToBoxAdapter(child: opener),
        for (var at = 0; at < rows.length; at++) ...[
          if (at > 0) SliverToBoxAdapter(child: SizedBox(height: gap)),
          rowsOf(SliverCrossAxisGroup(slivers: _row(rows[at]))),
        ],
        if (closer != null) SliverToBoxAdapter(child: closer),
      ],
    );
    return _ExtentRecorder(
      heights: heights,
      index: index,
      bracket: bracket,
      sliver: group,
    );
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
    required this.bracket,
    required Widget sliver,
  }) : super(child: sliver);

  final BlockHeights heights;
  final int index;
  final ColumnsBracket? bracket;

  @override
  _RenderExtentRecorder createRenderObject(BuildContext context) =>
      _RenderExtentRecorder(heights, index)..bracket = bracket;

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderExtentRecorder renderObject,
  ) {
    renderObject
      ..heights = heights
      ..index = index
      ..bracket = bracket;
  }
}

/// The render object behind [_ExtentRecorder]: its child's geometry, its
/// scroll extent written to the note's map as a measured block's height
/// is, so the map's offsets past the block follow what it is.
final class _RenderExtentRecorder extends RenderProxySliver {
  new(this.heights, this.index);

  BlockHeights heights;
  int index;

  ColumnsBracket? get bracket => _bracket;
  ColumnsBracket? _bracket;
  set bracket(ColumnsBracket? value) {
    if (value == _bracket) return;
    _bracket = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final bracket = _bracket;
    final geometry = this.geometry;
    if (bracket == null || geometry == null || !geometry.visible) return;
    final scroll = constraints.scrollOffset;
    final visible = geometry.paintExtent;
    double clamped(double y) => y.clamp(0.0, visible);
    final top = bracket.top - scroll;
    final bottom = geometry.scrollExtent - bracket.bottom - scroll;
    final from = clamped(top);
    final to = clamped(bottom);
    if (to <= from) return;
    final paint = Paint()
      ..color = bracket.color
      ..strokeWidth = 1;
    final x = offset.dx + bracket.x;
    final canvas = context.canvas
      ..drawLine(Offset(x, offset.dy + from), Offset(x, offset.dy + to), paint);
    // Its ends, where they are on screen: a `[` the block's height.
    const tick = 3.0;
    if (top >= 0 && top <= visible) {
      canvas.drawLine(
        Offset(x, offset.dy + top),
        Offset(x + tick, offset.dy + top),
        paint,
      );
    }
    if (bottom >= 0 && bottom <= visible) {
      canvas.drawLine(
        Offset(x, offset.dy + bottom),
        Offset(x + tick, offset.dy + bottom),
        paint,
      );
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    final geometry = this.geometry;
    if (geometry == null || geometry.scrollOffsetCorrection != null) return;
    heights.measured(index, geometry.scrollExtent);
  }
}
