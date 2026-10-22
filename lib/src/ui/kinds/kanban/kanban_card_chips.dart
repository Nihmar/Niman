import 'package:flutter/material.dart';
import 'package:niman/src/kanban/card_text.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';

/// The tags and the due date of a card, as chips (#1167).
final class KanbanCardChips extends StatelessWidget {
  /// The chips of [card].
  const new({required this.card, super.key});

  /// The card.
  final KanbanCard card;

  @override
  Widget build(BuildContext context) {
    final due = card.due;
    if (card.tags.isEmpty && due == null) return const SizedBox.shrink();
    final palette = KanbanPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;
    final now = DateTime.now();
    final late =
        due != null && due.isBefore(DateTime(now.year, now.month, now.day));
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in card.tags)
          _Chip(
            fill: palette.chip,
            child: Text('#$tag', style: style?.copyWith(color: palette.onChip)),
          ),
        if (due != null)
          _Chip(
            key: const Key('kanban-due'),
            fill: late
                ? scheme.errorContainer
                : palette.border.withValues(alpha: 0.4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 12,
                  color: late ? scheme.onErrorContainer : palette.muted,
                ),
                const SizedBox(width: 3),
                Text(
                  cardDueText(due),
                  style: style?.copyWith(
                    color: late ? scheme.onErrorContainer : palette.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _Chip extends StatelessWidget {
  const new({required this.fill, required this.child, super.key});

  final Color fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: child,
      ),
    );
  }
}
