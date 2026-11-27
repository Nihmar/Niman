import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/widgets.dart';

/// Where the desktop's panel sits: under the selection, never over the line
/// read, and above it only when there is no room below.
///
/// The panel is [width] wide (less in a narrow window) and as tall as its
/// content, up to the room the better side has and [tallest]. It aligns
/// itself near the selection's start, kept inside the window by [margin].
final class PanelPlacement extends SingleChildLayoutDelegate {
  /// Places a panel by [anchor], the selection in the window's coordinates.
  const new(
    this.anchor, {
    this.width = 380,
    this.tallest = 440,
    this.gap = 6,
    this.margin = 8,
  });

  /// The selection, in the coordinates of the window the panel is drawn in.
  final Rect anchor;

  /// The panel's width, in a window that has the room.
  final double width;

  /// The most the panel's height reaches, however much room there is.
  final double tallest;

  /// The space between the selection and the panel.
  final double gap;

  /// The space between the panel and the window's edge.
  final double margin;

  double _below(Size window) => window.height - anchor.bottom - gap - margin;

  double _above() => anchor.top - gap - margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final wide = math.min(width, constraints.maxWidth - 2 * margin);
    final room = math.max(_below(constraints.biggest), _above());
    return BoxConstraints(
      minWidth: wide,
      maxWidth: wide,
      maxHeight: math.max(0, math.min(tallest, room)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Under the selection when the panel fits there; above it when that is
    // the side it fits; else the side with more room, where the constraints
    // have already cut it to fit.
    final below = _below(size);
    final above = _above();
    final under =
        childSize.height <= below ||
        (childSize.height > above && below >= above);
    final top = under
        ? anchor.bottom + gap
        : anchor.top - gap - childSize.height;
    // Hung from where the selection starts, a little in from its edge.
    final left = clampDouble(
      anchor.left - 24,
      margin,
      math.max(margin, size.width - childSize.width - margin),
    );
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(PanelPlacement oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.width != width ||
      oldDelegate.tallest != tallest;
}
