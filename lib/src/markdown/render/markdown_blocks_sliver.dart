/// A sliver that places its children from a height map and measures the ones it
/// draws (#251).
///
/// The read view's first sliver **forced** an extent on every child
/// (`SliverVariedExtentList`), which clipped every block taller than its
/// estimate (#250); the second **measured** every child (`SliverList`), which
/// draws a long note correctly and makes a far jump cost the note — 2 772 ms
/// and 3 156 of 7 530 blocks built on the geometry note, because a list cannot
/// place a child it has not laid out. This one does both halves of the job the
/// way §8.4.4 says they belong together: **positions come from the map, heights
/// from the layout**.
///
/// So a jump lays out the blocks the viewport shows and nothing else, and a
/// block the map mis-estimated is drawn at its own height — the one thing the
/// forcing sliver could not do. The price is what the map does not know: a jump
/// into a region no frame has reached lands where the *estimates* say it is,
/// and the frame that lands there corrects the map. The scroll position is not
/// corrected with it: content moves by a few pixels as estimates become
/// measurements, and the alternative — a scroll offset that jumps under a
/// finger already on the screen — is worse (§8.4.3).
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';

/// The read view's sliver: children placed by [heights], measured as they are
/// laid out.
final class SliverMarkdownBlocks extends SliverMultiBoxAdaptorWidget {
  /// Creates the sliver; [delegate] builds the blocks lazily.
  const new({required super.delegate, required this.heights, super.key});

  /// The heights: the positions this sliver places its children at, and where
  /// the heights it measures go.
  final BlockHeightMap heights;

  @override
  RenderSliverMarkdownBlocks createRenderObject(BuildContext context) {
    return RenderSliverMarkdownBlocks(
      childManager: context as SliverMultiBoxAdaptorElement,
      heights: heights,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverMarkdownBlocks renderObject,
  ) {
    if (identical(renderObject.heights, heights)) return;
    renderObject
      ..heights = heights
      ..markNeedsLayout();
  }
}

/// The render object behind [SliverMarkdownBlocks].
final class RenderSliverMarkdownBlocks extends RenderSliverMultiBoxAdaptor {
  /// Creates the render object.
  new({required super.childManager, required this.heights});

  /// The heights this layout places its children by, and the record of what it
  /// measured — set from [SliverMarkdownBlocks.updateRenderObject], which also
  /// asks for the layout that reads it.
  BlockHeightMap heights;

  @override
  void performLayout() {
    final constraints = this.constraints;
    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final count = heights.length;
    if (count == 0) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final childConstraints = constraints.asBoxConstraints();
    // The cache area, not the viewport: a block that starts above the viewport
    // is laid out from its own top, so a partially visible paragraph shows its
    // beginning rather than its middle.
    final rangeStart = constraints.scrollOffset + constraints.cacheOrigin;
    final rangeEnd =
        constraints.scrollOffset + constraints.remainingCacheExtent;

    final first = heights.indexAt(rangeStart) ?? count - 1;
    final last = heights.indexAt(rangeEnd) ?? count - 1;

    // Whatever is outside the range is not this frame's business, and dropping
    // it first is what makes a jump cheap in *both* directions: a sliver that
    // walks to the target pays for every block it passes (the 2 772 ms above),
    // and one that only grows at its ends pays for the blocks between here and
    // there.
    _keepRange(first, last);

    if (firstChild == null) {
      final added = addInitialChild(
        index: first,
        layoutOffset: heights.offsetOf(first),
      );
      if (!added) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }
    // Anything missing above what survived: created one at a time, which the
    // range bounds — not the note.
    while (indexOf(firstChild!) > first) {
      final inserted = insertAndLayoutLeadingChild(
        childConstraints,
        parentUsesSize: true,
      );
      if (inserted == null) break;
    }

    // The walk: every block in the range, each placed where the map says and
    // measured where the layout puts it.
    var child = firstChild!;
    var index = indexOf(child);
    var endOffset = heights.offsetOf(index);
    var lastLaidOut = index;
    while (index < count) {
      child.layout(childConstraints, parentUsesSize: true);
      final top = heights.offsetOf(index);
      final height = child.size.height;
      // The measurement goes in *before* the next block is placed, so the rest
      // of this frame already follows the height this one really has.
      heights.measured(index, height);
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = top;
      endOffset = top + height;
      lastLaidOut = index;
      if (endOffset >= rangeEnd) break;
      final next =
          childAfter(child) ??
          insertAndLayoutChild(
            childConstraints,
            after: child,
            parentUsesSize: true,
          );
      if (next == null) break;
      child = next;
      index++;
    }

    _keepRange(first, lastLaidOut);

    // A sliver can never paint more than its own maximum, and an estimate is
    // allowed to be wrong in both directions — so what this frame really laid
    // out is the floor. At the note's end it is the truth, and the estimate
    // steps aside entirely (the framework's list does the same, which is why
    // `maxScrollExtent` stops creeping once the reader has been to the end).
    final total = lastLaidOut == count - 1
        ? endOffset
        : math.max(heights.totalExtent, endOffset);
    final firstTop = heights.offsetOf(first);
    geometry = SliverGeometry(
      // The note's estimated height: a scrollbar and `maxScrollExtent` need a
      // number for the part no frame has reached, and the estimates are what
      // there is. It converges on the truth as the reader scrolls.
      scrollExtent: total,
      paintExtent: calculatePaintOffset(
        constraints,
        from: firstTop,
        to: endOffset,
      ),
      cacheExtent: calculateCacheOffset(
        constraints,
        from: firstTop,
        to: endOffset,
      ),
      maxPaintExtent: total,
      // Conservative, as the framework's own list is: flickering a clip away
      // mid-scroll shows a block outside the viewport for a frame.
      hasVisualOverflow:
          endOffset >
              constraints.scrollOffset + constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0,
    );
    if (lastLaidOut == count - 1) childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }

  /// Keeps only the children in `[first, last]`, and drops the rest.
  ///
  /// `collectGarbage` counts from the two ends, which is exactly where the
  /// stale children are: the range is contiguous, so anything below `first` is
  /// at the front and anything above `last` is at the back.
  void _keepRange(int first, int last) {
    var leading = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (indexOf(child) < first) {
        leading++;
      } else {
        break;
      }
    }
    var trailing = 0;
    for (var child = lastChild; child != null; child = childBefore(child)) {
      if (indexOf(child) > last) {
        trailing++;
      } else {
        break;
      }
    }
    if (leading > 0 || trailing > 0) collectGarbage(leading, trailing);
  }

  @override
  double? childScrollOffset(RenderObject child) {
    final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    return parentData.layoutOffset;
  }
}
