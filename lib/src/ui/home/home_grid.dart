/// The Home on a wide screen (#535): the tiles on a grid of four columns,
/// each where its cell puts it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';

/// The grid's measures, shared by the view and the editor.
abstract final class HomeGridMetrics {
  /// A row's height.
  static const double rowHeight = 112;

  /// The space between two tiles.
  static const double gap = 12;

  /// The narrowest width the grid is drawn at; under it the Home is the
  /// phone's column.
  static const double minWidth = 640;

  /// A column's width when the grid is [width] wide.
  static double cellWidth(double width) =>
      (width - gap * (HomeTile.columns - 1)) / HomeTile.columns;

  /// Where [cell] sits on a grid [width] wide.
  static Rect rectOf(HomeCell cell, double width) {
    final column = cellWidth(width);
    return Rect.fromLTWH(
      cell.x * (column + gap),
      cell.y * (rowHeight + gap),
      cell.w * column + (cell.w - 1) * gap,
      cell.h * rowHeight + (cell.h - 1) * gap,
    );
  }

  /// The grid's height for [rows] rows.
  static double heightOf(int rows) =>
      rows <= 0 ? 0 : rows * rowHeight + (rows - 1) * gap;
}

/// The shown tiles of [layout] on the grid.
final class HomeGrid extends StatelessWidget {
  /// Places [layout]'s tiles (settled already), each drawn by [tile].
  const new({required this.layout, required this.tile, super.key});

  /// The Home, settled.
  final HomeLayout layout;

  /// Draws one tile.
  final Widget Function(HomeTile tile, {bool fit}) tile;

  @override
  Widget build(BuildContext context) {
    final tiles = layout.column;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        return SizedBox(
          height: HomeGridMetrics.heightOf(layout.bottom),
          child: Stack(
            children: [
              for (final t in tiles)
                Positioned.fromRect(
                  key: ValueKey(t.id),
                  rect: HomeGridMetrics.rectOf(t.cell, width),
                  child: tile(t),
                ),
            ],
          ),
        );
      },
    );
  }
}
