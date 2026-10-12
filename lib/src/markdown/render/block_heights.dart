/// What a sliver of blocks reads its children's places from and writes
/// their measurements to: a note's whole height map, or a run of it.
library;

import 'package:niman/src/markdown/render/block_height_map.dart';

/// The heights of a run of blocks, as `RenderSliverMarkdownBlocks` asks
/// for them: where each starts from the run's own top, which one an offset
/// lands in, and where a measurement goes.
abstract interface class BlockHeights {
  /// How many blocks the run has.
  int get length;

  /// Bumped whenever the blocks change, so a layout of them is out of date.
  int get generation;

  /// The run's height.
  double get totalExtent;

  /// Where block [index] starts, from the run's top; the total one past
  /// the last.
  double offsetOf(int index);

  /// The block [offset] lands in, or null past the run's end.
  int? indexAt(double offset);

  /// Block [index]'s height.
  double extentFor(int index);

  /// Records that block [index] was drawn [height] pixels tall.
  void measured(int index, double height);
}

/// Blocks `[start, end)` of a note's [map], counted from `start`: the run
/// of ordinary blocks between two side-by-side `columns` blocks (#729),
/// each a sliver of its own. The note's map stays the one coordinate
/// system, so a jump, an anchor and a scroll bar read it as before.
final class BlockHeightRange implements BlockHeights {
  /// Blocks `[start, end)` of [map].
  new(this.map, this.start, this.end);

  /// The note's map.
  final BlockHeightMap map;

  /// The run's first block in [map].
  final int start;

  /// One past its last.
  final int end;

  @override
  int get length => end - start;

  @override
  int get generation => map.generation;

  @override
  double get totalExtent => map.offsetOf(end) - map.offsetOf(start);

  @override
  double offsetOf(int index) =>
      map.offsetOf(start + index) - map.offsetOf(start);

  @override
  int? indexAt(double offset) {
    if (offset < 0) return null;
    final index = map.indexAt(map.offsetOf(start) + offset);
    if (index == null || index >= end) return null;
    return index < start ? 0 : index - start;
  }

  @override
  double extentFor(int index) => map.extentFor(start + index);

  @override
  void measured(int index, double height) =>
      map.measured(start + index, height);
}
