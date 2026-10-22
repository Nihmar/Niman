import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';

/// The line a dragged card would land on (#1167): a bar in the gap before a
/// card, and after the last one. It overlays the gap instead of taking
/// space, so nothing under the pointer moves while a drag hovers.
final class KanbanDropBars extends StatelessWidget {
  /// The bars of card [index] of [column]; [last] adds the one after it.
  const new({
    required this.spot,
    required this.column,
    required this.index,
    required this.last,
    super.key,
  });

  /// Where the dragged card would land, if anywhere.
  final ValueListenable<DropSpot?> spot;

  /// The column's index.
  final int column;

  /// The card's index in its column.
  final int index;

  /// Whether the card is the last of its column.
  final bool last;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DropSpot?>(
      valueListenable: spot,
      builder: (context, spot, _) {
        if (spot == null || spot.column != column) {
          return const SizedBox.shrink();
        }
        final before = spot.slot == index;
        final after = last && spot.slot == index + 1;
        if (!before && !after) return const SizedBox.shrink();
        return Positioned(
          left: 0,
          right: 0,
          top: before ? -5 : null,
          bottom: before ? null : 1,
          child: const KanbanDropBar(),
        );
      },
    );
  }
}

/// The bar itself.
final class KanbanDropBar extends StatelessWidget {
  /// A bar in the theme's primary colour.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('kanban-drop-bar'),
      height: 3,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
