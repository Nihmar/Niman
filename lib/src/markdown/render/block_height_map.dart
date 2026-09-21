/// How tall each block is: measured where a frame has drawn it, estimated
/// where none has.
///
/// The read view's sliver **measures** its children — `SliverList` lays each
/// one out with unbounded main-axis constraints — so nothing here decides how
/// tall a block is drawn. What this map answers is the question a scrollable
/// cannot avoid before anything is laid out: how long the whole note is, so a
/// jump, a scrollbar and `maxScrollExtent` land somewhere sensible. It answers
/// with the measurements of the blocks a frame has drawn, and with the
/// estimator's own answer for the rest.
///
/// It used to answer with a *forced* extent per block instead: the view handed
/// one to `SliverVariedExtentList`, and that class imposes it on the child, so
/// a block taller than its estimate was clipped — and the "measurement"
/// reported the imposed size straight back, which made the correction loop
/// dead code (#250, found on a device, recorded in §8.4.4). An estimator
/// cannot do that: the worst a wrong estimate costs is a jump that lands
/// slightly off.
library;

import 'package:niman/src/markdown/block.dart';

/// The height of every block of a note.
final class BlockHeightMap {
  /// Creates a map over [blocks], estimating with `estimate`.
  new({
    required List<Block> blocks,
    required double Function(Block block) estimate,
  }) : _blocks = blocks,
       _estimateOf = estimate,
       _measured = List<double>.filled(blocks.length, 0);

  final List<Block> _blocks;
  final double Function(Block block) _estimateOf;
  final List<double> _measured;

  /// How many blocks the map covers.
  int get length => _measured.length;

  /// How many blocks have a height a frame laid out.
  int get measuredCount {
    var count = 0;
    for (final value in _measured) {
      if (value > 0) count++;
    }
    return count;
  }

  /// Block [index]'s height: what a frame laid it out at, or the estimator's
  /// answer while none has.
  double extentFor(int index) {
    if (index < 0 || index >= _measured.length) return 0;
    final measured = _measured[index];
    return measured > 0 ? measured : _estimateOf(_blocks[index]);
  }

  /// The best guess at the height of everything after [index].
  ///
  /// This is the part of the note no frame has laid out, which is what a
  /// scroll estimate is made of: a layout knows its own past for real, and
  /// needs this for its future.
  double estimateAfter(int index) {
    var total = 0.0;
    for (var at = index + 1; at < _measured.length; at++) {
      total += extentFor(at);
    }
    return total;
  }

  /// Records that block [index] was drawn [height] pixels tall.
  void measured(int index, double height) {
    if (index < 0 || index >= _measured.length || height <= 0) return;
    _measured[index] = height;
  }
}
