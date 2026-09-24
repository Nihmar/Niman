/// Scroll physics for a note whose extent is estimated until it is drawn.
library;

import 'package:flutter/widgets.dart';

/// Keeps the position inside the note when its extent changes under it.
///
/// A jump is planned on the height map, and far from the viewport that is
/// estimates: the frame that lands measures the rows it draws, and a note
/// whose rows come out shorter than estimated ends above where the jump
/// put the position. The platform's physics answer a position past the
/// end with a spring back to it — Ctrl+End bounced for half a second — so
/// the position is put back on the end at once, as long as nothing is
/// scrolling. A fling or a drag keeps the platform's own behaviour.
final class ContentClampPhysics extends ScrollPhysics {
  /// Creates the physics, over [parent].
  const new({super.parent});

  @override
  ContentClampPhysics applyTo(ScrollPhysics? ancestor) =>
      ContentClampPhysics(parent: buildParent(ancestor));

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final adjusted = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
    if (isScrolling) return adjusted;
    return adjusted.clamp(
      newPosition.minScrollExtent,
      newPosition.maxScrollExtent,
    );
  }
}
