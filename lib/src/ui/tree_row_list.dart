import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, ScrollCacheExtent;
import 'package:niman/src/ui/tree_rows_delegate.dart';

/// The note tree's scrolling list (#1200): the pinned block's items, then
/// the tree's rows, every one the same height, drawn by index.
final class TreeRowList extends StatelessWidget {
  /// A list of [pinnedCount] pinned items over [rowCount] rows.
  const new({
    required this.controller,
    required this.pinnedCount,
    required this.pinnedItem,
    required this.rowCount,
    required this.rowHeight,
    required this.row,
    required this.onLaidOut,
    super.key,
  });

  /// The tree's scroll.
  final ScrollController controller;

  /// How many items the pinned block draws: none when nothing is pinned.
  final int pinnedCount;

  /// The pinned block's item at an index.
  final IndexedWidgetBuilder pinnedItem;

  /// How many rows the tree draws below the pinned block.
  final int rowCount;

  /// The height of every row.
  final double rowHeight;

  /// The tree's row at a list index.
  final IndexedWidgetBuilder row;

  /// Called with the first and the last row index the list laid out.
  final void Function(int first, int last) onLaidOut;

  @override
  Widget build(BuildContext context) {
    // What a list does for the system's insets when it is given no
    // padding of its own: the main axis's go around the slivers, and
    // the rows below see the cross axis's alone.
    final media = MediaQuery.of(context);
    return CustomScrollView(
      key: const Key('note-tree-list'),
      controller: controller,
      // The cache extent the pages are read for, named: the list and
      // the window of rows kept agree on it.
      scrollCacheExtent: const ScrollCacheExtent.pixels(
        RenderAbstractViewport.defaultCacheExtent,
      ),
      semanticChildCount: pinnedCount + rowCount,
      slivers: [
        SliverPadding(
          padding: media.padding.copyWith(left: 0, right: 0),
          sliver: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: 0, bottom: 0),
            ),
            child: SliverMainAxisGroup(
              slivers: [
                if (pinnedCount > 0)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      pinnedItem,
                      childCount: pinnedCount,
                    ),
                  ),
                // Every row of the tree is the same height, so the
                // list lays out and jumps by arithmetic, however
                // many rows there are.
                SliverFixedExtentList(
                  itemExtent: rowHeight,
                  delegate: TreeRowsDelegate(
                    row,
                    childCount: rowCount,
                    onLaidOut: onLaidOut,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
