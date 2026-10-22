import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_face.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_menu.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_title.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// One card of the phone's board (#1168): a rounded tile at least 48 px
/// tall, with the card's box, title, chips and first line of body.
///
/// A tap edits the title, a long press opens the move sheet; the box ticks
/// the card. A screen reader reads the card's place ("Card 2 of 5, column
/// Doing") and gets the moves and the delete as actions of the card, beside
/// the long press.
final class KanbanPhoneCard extends StatelessWidget {
  /// The tile of [card], the [index]th of the [count] of column [columnName].
  const new({
    required this.card,
    required this.index,
    required this.count,
    required this.columnName,
    required this.host,
    required this.mathCache,
    required this.onToggle,
    required this.onEdit,
    required this.onMenu,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  /// The card.
  final KanbanCard card;

  /// Its place in its column.
  final int index;

  /// How many cards the column holds.
  final int count;

  /// The column's name, for the screen reader.
  final String columnName;

  /// The note's window, which follows the links of the title.
  final NoteKindHost host;

  /// The formulas of the titles.
  final MathCache mathCache;

  /// Flips the box.
  final VoidCallback onToggle;

  /// Edits the title.
  final VoidCallback onEdit;

  /// Opens the card's sheet.
  final VoidCallback onMenu;

  /// Moves the card one place within its column.
  final ValueChanged<KanbanDirection> onMove;

  /// Deletes the card.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = KanbanPalette.of(context);
    return Semantics(
      container: true,
      label: AppStrings.kanbanCardLabel(index + 1, count, columnName),
      customSemanticsActions: {
        if (index > 0)
          CustomSemanticsAction(
            label: KanbanCardMenu.label(KanbanDirection.up),
          ): () =>
              onMove(KanbanDirection.up),
        if (index < count - 1)
          CustomSemanticsAction(
            label: KanbanCardMenu.label(KanbanDirection.down),
          ): () =>
              onMove(KanbanDirection.down),
        CustomSemanticsAction(label: AppStrings.actionDelete): onDelete,
      },
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('kanban-phone-card'),
          onTap: onEdit,
          onLongPress: onMenu,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: KanbanCardFace(
              card: card,
              title: KanbanCardTitle(
                card: card,
                host: host,
                mathCache: mathCache,
              ),
              onToggle: onToggle,
              boxExtent: 44,
              reserveMenu: false,
            ),
          ),
        ),
      ),
    );
  }
}
