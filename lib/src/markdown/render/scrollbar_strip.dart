/// Where the editor's scrollbar takes the mouse (#1106).
///
/// The bar is Flutter's own, built by the surrounding `ScrollBehavior`: on a
/// desktop platform a Material `Scrollbar`, on a phone none at all, and a
/// theme, a margin or a `MediaQuery` inset moves it. The editor does not guess
/// any of that; it asks the bar's painter, which is the object the bar itself
/// hit-tests with, and takes the same region from the values the painter was
/// given.
library;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Whether [global], a position in the window, is over the track of the
/// scrollbar that [scrollView] carries, so the pointer there is the
/// scrollbar's and not the text's.
///
/// False when no scrollbar is shown: the platform's `ScrollBehavior` builds
/// none, the bar ignores pointers, or [metrics] have nothing to scroll — the
/// bar paints and hit-tests nothing then, so the strip is plain text.
///
/// [scrollView] is the render object of the `CustomScrollView` the bar wraps.
bool pointerOnScrollbar({
  required RenderObject? scrollView,
  required ScrollMetrics? metrics,
  required Offset global,
}) {
  if (scrollView == null || metrics == null) return false;
  // The painter's own test for "there is something to scroll".
  if (metrics.maxScrollExtent - metrics.minScrollExtent <=
      precisionErrorTolerance) {
    return false;
  }
  final paint = _barPaint(scrollView);
  if (paint == null || !paint.hasSize) return false;
  final painter = paint.foregroundPainter! as ScrollbarPainter;
  if (painter.ignorePointer) return false;
  final side =
      painter.scrollbarOrientation ??
      (painter.textDirection == TextDirection.rtl
          ? ScrollbarOrientation.left
          : ScrollbarOrientation.right);
  if (side != ScrollbarOrientation.left && side != ScrollbarOrientation.right) {
    return false;
  }
  final inset = painter.padding.resolve(painter.textDirection);
  final size = paint.size;
  // The track is the thumb's thickness and a margin on each side, set against
  // the edge by the inset: the rectangle `ScrollbarPainter` paints and
  // hit-tests.
  final width = painter.thickness + 2 * painter.crossAxisMargin;
  final track = side == ScrollbarOrientation.right
      ? Rect.fromLTRB(
          size.width - inset.right - width,
          inset.top,
          size.width - inset.right,
          size.height - inset.bottom,
        )
      : Rect.fromLTRB(
          inset.left,
          inset.top,
          inset.left + width,
          size.height - inset.bottom,
        );
  return track.contains(paint.globalToLocal(global));
}

/// The scrollbar's paint box under [root], or null when there is none.
///
/// The bar wraps the viewport (`RawScrollbar` paints in a `CustomPaint` above
/// it), so the walk stops at the viewport: it never reaches a note's own
/// painters.
RenderCustomPaint? _barPaint(RenderObject root) {
  RenderCustomPaint? found;
  void visit(RenderObject node) {
    if (found != null || node is RenderAbstractViewport) return;
    if (node is RenderCustomPaint &&
        node.foregroundPainter is ScrollbarPainter) {
      found = node;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  return found;
}
