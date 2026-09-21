/// How tall each block is, measured where it has been drawn and estimated
/// where it has not.
///
/// A viewport cannot know the height of a block it has never laid out, and a
/// scrollable must answer "how tall is the whole document" anyway. So every
/// block gets an extent — an estimate until it is drawn, its own measurement
/// after — and the two rules that make this work are the ones the preview's
/// `ScrollMap` learned the hard way (`docs/dev/unified-surface.md` §8.4.2):
///
/// * **an extent is frozen the first time it is asked for.** Letting a shared
///   average re-estimate a block that has already been placed is what makes
///   the sliver assert: offsets move under the scroll position;
/// * **a measurement replaces only that block's own extent**, applied between
///   frames rather than during layout, because a widget's size is not known
///   until after it has been laid out.
///
/// Measured extents arrive after the frame that laid the block out, so a
/// document scrolled quickly shows estimates for the blocks it passes — which
/// is what estimates are for. A block that has been seen keeps its real height
/// for as long as the height map lives.
library;

import 'package:niman/src/markdown/block.dart';

/// The height of every block of a note.
final class BlockHeightMap {
  /// Creates a map over [blocks], estimating with [estimate].
  new({
    required List<Block> blocks,
    required double Function(Block block) estimate,
  }) : _blocks = blocks,
       _estimateOf = estimate {
    _extents = List<double>.filled(blocks.length, 0);
    _measured = List<double>.filled(blocks.length, 0);
  }

  /// How much a measurement must differ before it replaces an estimate.
  ///
  /// Half a logical pixel: below that the change is not visible, and replacing
  /// an extent for it would invalidate a layout for nothing.
  static const double epsilon = 0.5;

  List<Block> _blocks;
  final double Function(Block block) _estimateOf;
  late List<double> _extents;
  late List<double> _measured;
  double _extentSum = 0;
  int _measuredLines = 0;
  double _measuredPixels = 0;
  final Set<int> _dirty = <int>{};

  /// How many blocks the map covers.
  int get length => _extents.length;

  /// The document's total height, from the extents it has.
  double get totalExtent => _extentSum;

  /// The average height of one line, once anything has been measured.
  ///
  /// The estimator's cheapest input, and the reason it improves as a note is
  /// read: a note whose lines are longer than assumed corrects itself.
  double get pixelsPerLine =>
      _measuredLines == 0 ? 0 : _measuredPixels / _measuredLines;

  /// How many blocks have a measured height.
  int get measuredCount => _measured.length - _missing(_measured);

  /// Rebuilds the map for a new block list.
  void reset(List<Block> blocks) {
    _blocks = blocks;
    _extents = List<double>.filled(blocks.length, 0);
    _measured = List<double>.filled(blocks.length, 0);
    _extentSum = 0;
    _dirty.clear();
  }

  /// Block [index]'s extent: its measurement once it has one, else its frozen
  /// estimate.
  double extentFor(int index) {
    if (index < 0 || index >= _extents.length) return 0;
    final frozen = _extents[index];
    if (frozen > 0) return frozen;
    final measured = _measured[index];
    final estimate = measured > 0 ? measured : _estimateOf(_blocks[index]);
    _extents[index] = estimate;
    _extentSum += estimate;
    return estimate;
  }

  /// Records that block [index] was drawn [height] pixels tall.
  ///
  /// The value is applied by [applyMeasurements] between frames, never during
  /// layout: an extent that moved while the sliver was walking its children is
  /// the assert this class exists to avoid.
  void measured(int index, double height, int lines) {
    if (index < 0 || index >= _measured.length) return;
    if (height <= 0) return;
    final previous = _measured[index];
    if (previous > 0 && (previous - height).abs() < epsilon) return;
    _measured[index] = height;
    _measuredPixels += height - (previous > 0 ? previous : 0);
    if (previous == 0) _measuredLines += lines;
    _dirty.add(index);
  }

  /// Whether a measurement is waiting to be applied.
  bool get hasPending => _dirty.isNotEmpty;

  /// Applies what has been measured, and answers whether anything moved.
  ///
  /// Call it after a frame. Only the blocks measured since the last call are
  /// touched, and only their own extents.
  bool applyMeasurements() {
    if (_dirty.isEmpty) return false;
    var moved = false;
    for (final index in _dirty) {
      final height = _measured[index];
      final current = _extents[index];
      if (current > 0 && (current - height).abs() < epsilon) continue;
      if (current > 0) {
        _extentSum += height - current;
      } else {
        _extentSum += height;
      }
      _extents[index] = height;
      moved = true;
    }
    _dirty.clear();
    return moved;
  }

  static int _missing(List<double> values) {
    var count = 0;
    for (final value in values) {
      if (value <= 0) count++;
    }
    return count;
  }
}
