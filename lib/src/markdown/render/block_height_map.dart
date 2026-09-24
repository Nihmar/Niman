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
/// The sums are [PrefixSums] (§8.4.1): a frame measures dozens of blocks and
/// asks for an offset for each of them, and a pass over 7 530 blocks per
/// question is exactly the shape of cost this engine exists to avoid. And an
/// edit that adds or removes lines splices them, where a Fenwick tree had to be
/// rebuilt — 59 ms per Enter at a million lines.
library;

import 'dart:typed_data';

import 'package:niman/src/markdown/prefix_sums.dart';

/// The height of every block of a note.
final class BlockHeightMap {
  /// Creates a map over [count] items, estimating item `index` with
  /// `estimate`.
  new({required int count, required double Function(int index) estimate})
    : _measured = Uint8List(count),
      // The estimator is asked **once**, here. Asking it again when a block is
      // measured would compute today's answer against a map seeded with an
      // earlier one — the read view builds this in `initState`, before the
      // theme arrives, so the two answers differ — and the sums would drift by
      // whatever changed.
      _extents = PrefixSums.generate(count, estimate);

  /// A map over [count] items that asks `estimate` for an item's height
  /// only when a frame first reaches the chunk of items it is in, and until
  /// then counts the chunk at `estimateSpan(first, end)`: the heights of
  /// items `[first, end)` as best known without asking each of them.
  ///
  /// O(chunks) to make where the map above is O(count): a map over every
  /// line of a note is built on the frame that opens it, and on the 246 MB
  /// stress note that was 2.9 M estimates, most of that frame (profile
  /// build, 2026-09-24). Each item is still asked once — the index it is
  /// asked with is the one it has then, after whatever [splice]s came
  /// before, so `estimate` reads the note as it is.
  new lazy({
    required int count,
    required double Function(int index) estimate,
    required double Function(int first, int end) estimateSpan,
  }) : _measured = Uint8List(count),
       _extents = PrefixSums.lazy(count, estimate, estimate: estimateSpan);

  /// Replaces [removed] blocks from [first] on with [inserted] new ones,
  /// estimated by [estimate] (asked with the blocks' *new* indices), and keeps
  /// every other block's measurement.
  ///
  /// What an edit that adds or removes lines needs: rebuilding the map instead
  /// forgot every height a frame had measured, so the lines on screen moved by
  /// the difference between the estimates and the truth for every line above
  /// them — on each Enter, each line joined, each paste and each undo.
  void splice(
    int first,
    int removed,
    int inserted,
    double Function(int index) estimate,
  ) {
    final start = first.clamp(0, _measured.length);
    final end = (start + removed).clamp(start, _measured.length);
    var gone = 0;
    for (var at = start; at < end; at++) {
      if (_measured[at] != 0) gone++;
    }
    _measuredCount -= gone;
    if (end - start == inserted) {
      _measured.fillRange(start, end, 0);
    } else {
      // A byte a block, copied into a new list: 2 MB for 2 M blocks, where a
      // growable list of doubles moved 16 MB of pointers, and grew by
      // reallocating all of them on the first block an edit added (140 ms
      // on the 246 MB note, AOT).
      final next = Uint8List(_measured.length - (end - start) + inserted)
        ..setRange(0, start, _measured)
        ..setRange(
          start + inserted,
          _measured.length - end + start + inserted,
          _measured,
          end,
        );
      _measured = next;
    }
    _extents.splice(start, end - start, <double>[
      for (var at = 0; at < inserted; at++) estimate(start + at),
    ]);
    _generation++;
  }

  /// Bumped whenever the blocks themselves change (a [splice]), so a sliver
  /// holding this same map knows its layout is out of date.
  int get generation => _generation;
  int _generation = 0;

  /// 1 for each block a frame has laid out, 0 while none has; the height
  /// itself is in [_extents].
  Uint8List _measured;

  /// The best height known for each block, summed: the estimate until a frame
  /// measures it, the measurement after.
  final PrefixSums _extents;

  /// How many blocks the map covers.
  int get length => _measured.length;

  /// How many blocks have a height a frame laid out.
  int get measuredCount => _measuredCount;
  int _measuredCount = 0;

  /// The height of the whole note: what has been drawn for real, and the
  /// estimator's answer for the rest.
  double get totalExtent => _extents.total;

  /// Where block [index] starts, from the note's own top.
  ///
  /// One past the last block is the total, which is what a layout asks when it
  /// wants to know where the note ends.
  double offsetOf(int index) {
    if (index <= 0) return 0;
    if (index >= _measured.length) return totalExtent;
    return _extents.offsetOf(index);
  }

  /// The block an offset lands in, or null when it is past the note's end.
  ///
  /// The boundary belongs to the block that starts there: an offset exactly at
  /// a block's top is inside that block, not the one above it.
  int? indexAt(double offset) {
    if (_measured.isEmpty || offset < 0) return null;
    if (offset >= totalExtent) return null;
    return _extents.indexOf(offset);
  }

  /// Block [index]'s height: what a frame laid it out at, or the estimator's
  /// answer while none has.
  double extentFor(int index) {
    if (index < 0 || index >= _measured.length) return 0;
    return _extents.valueAt(index);
  }

  /// Records that block [index] was drawn [height] pixels tall.
  ///
  /// Everything after it moves by the difference, which is what the sliver
  /// reads on its next layout — and, for the blocks it lays out after this one
  /// in the same pass, right away.
  ///
  /// Nothing tall is a height like any other: a typeset formula's lines past
  /// its first take no room in `live`, and a definition none in the read
  /// view. Refused, as it was when 0 meant "not measured", each kept its
  /// estimate — a row of nothing apiece on the page.
  void measured(int index, double height) {
    if (index < 0 || index >= _measured.length || !(height >= 0)) return;
    if (_measured[index] == 0) _measuredCount++;
    _measured[index] = 1;
    _extents.setValue(index, height);
  }
}
