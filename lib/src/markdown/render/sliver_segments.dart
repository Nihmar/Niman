/// A note cut at its side-by-side `columns` blocks (#729), drawn as one
/// sliver: each run of rows between two blocks, and each block, a sliver
/// of its own, laid out only where it meets the cache area.
///
/// A group of slivers (`SliverMainAxisGroup`) lays every child out every
/// frame, to sum their extents. A note of 500 blocks is a thousand
/// children, and a frame scrolled past them laid each one out — a scroll
/// frame twice a note's without columns (`columns_scroll_test`). The
/// note's height map already says where each child starts and how tall it
/// is: the children found from it at the cache area's edges are the only
/// ones laid out, as `SliverMarkdownBlocks` lays out the rows it shows.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/block_heights.dart';

/// `slivers`, each the entries of [heights] from its entry in [starts]
/// up to the next one's, one after the other.
final class SliverSegments extends MultiChildRenderObjectWidget {
  /// The [slivers] of a note whose map is [heights], child `i` starting at
  /// entry `starts[i]`.
  const new({
    required this.heights,
    required this.starts,
    required List<Widget> slivers,
    super.key,
  }) : super(children: slivers);

  /// The note's map: where each child starts, and the note's height.
  final BlockHeights heights;

  /// Each child's first entry in [heights], ascending.
  final List<int> starts;

  @override
  MultiChildRenderObjectElement createElement() => _SegmentsElement(this);

  @override
  RenderSliverSegments createRenderObject(BuildContext context) =>
      RenderSliverSegments(heights: heights, starts: starts);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverSegments renderObject,
  ) {
    renderObject
      ..heights = heights
      ..starts = starts;
  }
}

/// [SliverSegments]' element: its children on stage are the ones the last
/// layout drew, as a group of slivers says of its own — a child no layout
/// has reached has no geometry to ask.
final class _SegmentsElement extends MultiChildRenderObjectElement {
  new(SliverSegments super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children
        .where((child) {
          final geometry = (child.renderObject! as RenderSliver).geometry;
          return geometry != null && geometry.visible;
        })
        .forEach(visitor);
  }
}

/// The render object behind [SliverSegments].
final class RenderSliverSegments extends RenderSliver
    with
        ContainerRenderObjectMixin<
          RenderSliver,
          SliverPhysicalContainerParentData
        > {
  /// Children placed by [_heights], child `i` from entry `starts[i]`.
  new({required this._heights, required this._starts});

  BlockHeights _heights;

  /// The note's map.
  BlockHeights get heights => _heights;
  set heights(BlockHeights value) {
    if (identical(value, _heights)) return;
    _heights = value;
    markNeedsLayout();
  }

  List<int> _starts;

  /// Each child's first entry.
  List<int> get starts => _starts;
  set starts(List<int> value) {
    if (identical(value, _starts)) return;
    _starts = value;
    markNeedsLayout();
  }

  /// The children laid out by the last layout, in order: the ones painted,
  /// hit and read for semantics.
  final List<RenderSliver> _laidOut = <RenderSliver>[];

  /// Where each laid-out child starts, in the note's scroll offsets.
  final Map<RenderSliver, double> _offsets =
      Map<RenderSliver, double>.identity();

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData) {
      child.parentData = SliverPhysicalContainerParentData();
    }
  }

  /// Where child [index] starts, in the note's scroll offsets.
  double _startOf(int index) => index >= _starts.length
      ? heights.totalExtent
      : heights.offsetOf(_starts[index]);

  @override
  void performLayout() {
    final constraints = this.constraints;
    final before = List<RenderSliver>.of(_laidOut);
    _laidOut.clear();
    _offsets.clear();
    final children = <RenderSliver>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      children.add(child);
    }
    assert(children.length == _starts.length, 'a start for every child');
    final from = constraints.scrollOffset + constraints.cacheOrigin;
    final to = from + constraints.remainingCacheExtent;
    // The first child that ends past the cache area's top.
    var low = 0;
    var high = children.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_startOf(middle + 1) <= from) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    var paintEnd = 0.0;
    for (var at = low; at < children.length; at++) {
      // Read after the children before it measured themselves: the map
      // moves with them, as the rows of one sliver do.
      final start = _startOf(at);
      if (start >= to && at > low) break;
      final child = children[at];
      final childScrollOffset = math.max<double>(
        0,
        constraints.scrollOffset - start,
      );
      final above = calculatePaintOffset(constraints, from: 0, to: start);
      final cacheOrigin = math.max<double>(
        constraints.cacheOrigin,
        -childScrollOffset,
      );
      final cacheBefore = calculateCacheOffset(constraints, from: 0, to: start);
      child.layout(
        constraints.copyWith(
          scrollOffset: childScrollOffset,
          cacheOrigin: cacheOrigin,
          overlap: 0,
          remainingPaintExtent: math.max<double>(
            0,
            constraints.remainingPaintExtent - above,
          ),
          remainingCacheExtent: math.max<double>(
            0,
            constraints.remainingCacheExtent - cacheBefore,
          ),
          precedingScrollExtent: constraints.precedingScrollExtent + start,
        ),
        parentUsesSize: true,
      );
      final geometry = child.geometry!;
      final correction = geometry.scrollOffsetCorrection;
      if (correction != null) {
        this.geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return;
      }
      final paintOffset = above + geometry.paintOrigin;
      (child.parentData! as SliverPhysicalParentData).paintOffset = Offset(
        0,
        paintOffset,
      );
      _laidOut.add(child);
      _offsets[child] = start;
      paintEnd = math.max(paintEnd, paintOffset + geometry.paintExtent);
    }
    // The children the last layout drew and this one did not: laid out
    // once more outside the cache area, so they let their lines go, as a
    // sliver of rows lets go of the rows it no longer shows.
    final drawn = Set<RenderSliver>.identity()..addAll(_laidOut);
    for (final child in before) {
      if (drawn.contains(child) || child.parent != this) continue;
      child.layout(
        constraints.copyWith(
          scrollOffset: 0,
          cacheOrigin: 0,
          overlap: 0,
          remainingPaintExtent: 0,
          remainingCacheExtent: 0,
        ),
        parentUsesSize: true,
      );
    }
    final total = heights.totalExtent;
    final paintExtent = math.min(
      calculatePaintOffset(constraints, from: 0, to: total),
      constraints.remainingPaintExtent,
    );
    geometry = SliverGeometry(
      scrollExtent: total,
      paintExtent: paintExtent,
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: total),
      maxPaintExtent: total,
      hasVisualOverflow: paintEnd > paintExtent || constraints.scrollOffset > 0,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _laidOut) {
      if (!child.geometry!.visible) continue;
      final data = child.parentData! as SliverPhysicalParentData;
      context.paintChild(child, offset + data.paintOffset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    for (final child in _laidOut.reversed) {
      if (!child.geometry!.visible) continue;
      final hit = child.hitTest(
        result,
        mainAxisPosition: mainAxisPosition - childMainAxisPosition(child),
        crossAxisPosition: crossAxisPosition,
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderSliver child) =>
      (child.parentData! as SliverPhysicalParentData).paintOffset.dy;

  @override
  double childCrossAxisPosition(RenderSliver child) => 0;

  @override
  double? childScrollOffset(RenderObject child) => _offsets[child] ?? 0;

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    (child.parentData! as SliverPhysicalParentData).applyPaintTransform(
      transform,
    );
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in _laidOut) {
      if (child.geometry!.visible) visitor(child);
    }
  }
}
