/// The Home on a phone (#535): the tiles one under the other, in the
/// column's order, each as tall as its grid cell — but the actions, as
/// tall as their buttons need: a button cut off is a button lost.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/ui/home/home_grid.dart';

/// The shown tiles of [layout] in a column.
final class HomeColumn extends StatelessWidget {
  /// Lists [layout]'s tiles, each drawn by [tile].
  const new({required this.layout, required this.tile, super.key});

  /// The Home.
  final HomeLayout layout;

  /// Draws one tile; `fit` asks it to take its content's height.
  final Widget Function(HomeTile tile, {bool fit}) tile;

  @override
  Widget build(BuildContext context) {
    final tiles = layout.column;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, t) in tiles.indexed) ...[
          if (i > 0) const SizedBox(height: HomeGridMetrics.gap),
          if (t.kind == HomeTileKind.actions)
            KeyedSubtree(key: ValueKey(t.id), child: tile(t, fit: true))
          else
            SizedBox(
              key: ValueKey(t.id),
              height: HomeGridMetrics.heightOf(t.cell.h),
              child: tile(t),
            ),
        ],
      ],
    );
  }
}
