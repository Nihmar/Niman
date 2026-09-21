/// How tall each block is: measured where a frame has drawn it, estimated
/// where none has.
///
/// Two readers, with different questions. The read view's sliver asks **where a
/// block starts** before anything at that offset has been laid out, so a jump
/// costs a viewport instead of the note (#251); a scrollbar asks how long the
/// note is, so `maxScrollExtent` means something on a 934 KB file. Both are
/// answered from the same list: the measurements of the blocks a frame has
/// drawn, and the estimator's answer for the rest.
///
/// It used to answer with a *forced* extent per block instead: the view handed
/// one to `SliverVariedExtentList`, and that class imposes it on the child, so
/// a block taller than its estimate was clipped — and the "measurement"
/// reported the imposed size straight back, which made the correction loop
/// dead code (#250, found on a device, recorded in §8.4.4). An estimator
/// cannot do that: the worst a wrong estimate costs is a viewport that lands
/// slightly off, and one frame's measurements fixing it.
///
/// The sums are a Fenwick tree (§8.4.1): a frame measures dozens of blocks and
/// asks for an offset for each of them, and a pass over 7 530 blocks per
/// question is exactly the shape of cost this engine exists to avoid.
library;

import 'package:niman/src/markdown/block.dart';

/// The height of every block of a note.
final class BlockHeightMap {
  /// Creates a map over [blocks], estimating with `estimate`.
  new({
    required List<Block> blocks,
    required double Function(Block block) estimate,
  }) : _measured = List<double>.filled(blocks.length, 0),
       _extent = List<double>.filled(blocks.length, 0),
       _tree = List<double>.filled(blocks.length + 1, 0) {
    // The estimator is asked **once**, here. Asking it again when a block is
    // measured would compute today's answer against a map seeded with an
    // earlier one — the read view builds this in `initState`, before the theme
    // arrives, so the two answers differ — and the tree and the extents would
    // drift by whatever changed.
    for (var at = 0; at < blocks.length; at++) {
      final value = estimate(blocks[at]);
      _extent[at] = value;
      _add(at, value);
    }
  }

  /// The height a frame laid each block out at, or 0 while none has.
  final List<double> _measured;

  /// The best height known for each block: the estimate until a frame measures
  /// it, the measurement after. Kept alongside the tree because a measurement
  /// is a *difference* from this, and `_measured` cannot answer that for the
  /// blocks no frame has drawn.
  final List<double> _extent;

  /// The Fenwick tree over the extents: `_tree[i]` is the sum of the extents in
  /// the range that ends at `i`, so a prefix sum and a single update are both
  /// O(log n).
  final List<double> _tree;

  /// How many blocks the map covers.
  int get length => _measured.length;

  /// How many blocks have a height a frame laid out.
  int get measuredCount => _measuredCount;
  int _measuredCount = 0;

  /// The height of the whole note: what has been drawn for real, and the
  /// estimator's answer for the rest.
  double get totalExtent => _prefix(_measured.length);

  /// Where block [index] starts, from the note's own top.
  ///
  /// One past the last block is the total, which is what a layout asks when it
  /// wants to know where the note ends.
  double offsetOf(int index) {
    if (index <= 0) return 0;
    if (index >= _measured.length) return totalExtent;
    return _prefix(index);
  }

  /// The block an offset lands in, or null when it is past the note's end.
  ///
  /// The boundary belongs to the block that starts there: an offset exactly at
  /// a block's top is inside that block, not the one above it.
  int? indexAt(double offset) {
    if (_measured.isEmpty || offset < 0) return null;
    if (offset >= totalExtent) return null;
    var low = 0;
    var high = _measured.length - 1;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_prefix(middle) <= offset) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  /// Block [index]'s height: what a frame laid it out at, or the estimator's
  /// answer while none has.
  double extentFor(int index) {
    if (index < 0 || index >= _extent.length) return 0;
    return _extent[index];
  }

  /// Records that block [index] was drawn [height] pixels tall.
  ///
  /// Everything after it moves by the difference, which is what the sliver
  /// reads on its next layout — and, for the blocks it lays out after this one
  /// in the same pass, right away.
  void measured(int index, double height) {
    if (index < 0 || index >= _measured.length || height <= 0) return;
    if (_measured[index] <= 0) _measuredCount++;
    _measured[index] = height;
    _add(index, height - _extent[index]);
    _extent[index] = height;
  }

  /// The sum of the extents of the first [count] blocks.
  double _prefix(int count) {
    var total = 0.0;
    for (var at = count; at > 0; at -= at & -at) {
      total += _tree[at];
    }
    return total;
  }

  /// Adds [delta] to block [index]'s extent, in O(log n).
  void _add(int index, double delta) {
    if (delta == 0) return;
    for (var at = index + 1; at <= _measured.length; at += at & -at) {
      _tree[at] += delta;
    }
  }
}
