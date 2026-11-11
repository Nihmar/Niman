/// The tree's island over the panes (#1266), for a tablet without the room
/// to dock it beside the note — portrait, a page that wants the width, a
/// note being written in. The dock's overlay, on the other side.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/hidden_slot.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/strings.dart';

/// A scrim over the panes and the tree's island on their left edge, while
/// [open]; mounted and hidden while not, so the search in it keeps its
/// query and the tree its scroll.
final class TreeOverlay extends StatelessWidget {
  /// Lays [island] over its stack's area, [width] wide where it fits.
  const new({
    required this.open,
    required this.width,
    required this.onDismiss,
    required this.island,
    super.key,
  });

  /// Whether the tree shows.
  final bool open;

  /// The width the island is given, before the window clamps it.
  final double width;

  /// Closes the tree, on a press outside it.
  final VoidCallback onDismiss;

  /// The tree's island: the tree, or the sidebar view in its place.
  final Widget island;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        key: const Key('tree-overlay'),
        fit: StackFit.expand,
        children: [
          if (open)
            Semantics(
              button: true,
              label: AppStrings.hideSidebarTooltip,
              child: GestureDetector(
                key: const Key('tree-scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.28)),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: math.min(width, math.max(0, box.maxWidth - 2 * Island.gap)),
            child: HiddenSlot(
              hidden: !open,
              // The shadow lies outside the island, whose clip would cut it.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Island.radius),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: island,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
