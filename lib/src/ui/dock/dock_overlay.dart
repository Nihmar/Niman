/// The right dock over the note, for a window without room to dock it
/// beside the note.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/island.dart';

/// A scrim over the note's area and the dock on its right edge, full
/// height, in the width it has when docked (as far as the window leaves).
///
/// It lies over the body, so the note under it is neither resized nor
/// moved. A press on the scrim, outside the dock, calls [onDismiss].
final class DockOverlay extends StatelessWidget {
  /// Shows [dock] over its stack's area, [width] wide where it fits.
  const new({
    required this.dock,
    required this.width,
    required this.onDismiss,
    super.key,
  });

  /// The dock to show.
  final Widget dock;

  /// The width the dock is given, before the window's own clamps it.
  final double width;

  /// Closes the overlay, on a press outside the dock.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        key: const Key('dock-overlay'),
        fit: StackFit.expand,
        children: [
          GestureDetector(
            key: const Key('dock-scrim'),
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.28)),
          ),
          Positioned(
            right: Island.gap,
            top: 0,
            bottom: Island.gap,
            width: math.min(width, math.max(0, box.maxWidth - 2 * Island.gap)),
            // The shadow lies outside the island, whose clip would cut it.
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Island.radius),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(-2, 2),
                  ),
                ],
              ),
              child: Island(key: const Key('dock-overlay-island'), child: dock),
            ),
          ),
        ],
      ),
    );
  }
}
