import 'package:flutter/material.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_chips.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_text.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';

/// What a card looks like (#1167): its box, [title] (the text, or the field
/// that edits it), the first line of its body, its chips and, in the corner,
/// its [menu]. The one face is drawn at rest, lifted under the pointer, and
/// while it is edited.
final class KanbanCardFace extends StatelessWidget {
  /// The face of [card].
  const new({
    required this.card,
    required this.title,
    required this.onToggle,
    this.menu,
    super.key,
  });

  /// The card.
  final KanbanCard card;

  /// The title, as text or as the field that edits it.
  final Widget title;

  /// Flips the box.
  final VoidCallback onToggle;

  /// The ⋮ menu; null where the face is a copy.
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final palette = KanbanPalette.of(context);
    final theme = Theme.of(context);
    final preview = cardPreview(card.body);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 2, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.hasBox)
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                key: const Key('kanban-card-box'),
                value: card.checked,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => onToggle(),
              ),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (preview != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      key: const Key('kanban-card-preview'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                  if (card.tags.isNotEmpty || card.due != null) ...[
                    const SizedBox(height: 6),
                    KanbanCardChips(card: card),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 32, height: 32, child: menu),
        ],
      ),
    );
  }
}
