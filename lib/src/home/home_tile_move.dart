/// A tile moved or sized one cell at a time (#535): what the grid editor's
/// menu does without a pointer.
library;

import 'package:niman/src/home/home_tile.dart';

/// One step on the grid.
enum HomeTileMove {
  /// One column left.
  left,

  /// One column right.
  right,

  /// One row up.
  up,

  /// One row down.
  down,

  /// One column wider.
  wider,

  /// One column narrower.
  narrower,

  /// One row taller.
  taller,

  /// One row shorter.
  shorter;

  /// [cell] after this step, kept on the grid; the same cell when the
  /// step would leave it.
  HomeCell apply(HomeCell cell) {
    const max = HomeTile.columns;
    final (:x, :y, :w, :h) = cell;
    return switch (this) {
      left => (x: x > 0 ? x - 1 : x, y: y, w: w, h: h),
      right => (x: x + w < max ? x + 1 : x, y: y, w: w, h: h),
      up => (x: x, y: y > 0 ? y - 1 : y, w: w, h: h),
      down => (x: x, y: y + 1, w: w, h: h),
      wider => (x: x, y: y, w: x + w < max ? w + 1 : w, h: h),
      narrower => (x: x, y: y, w: w > 1 ? w - 1 : w, h: h),
      taller => (x: x, y: y, w: w, h: h < max ? h + 1 : h),
      shorter => (x: x, y: y, w: w, h: h > 1 ? h - 1 : h),
    };
  }
}
