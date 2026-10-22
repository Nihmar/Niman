import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/kanban_column.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_add_field.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_phone_card.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// The page of one column on the phone's board (#1168): its cards in a
/// vertical list, **+ Add a card** at the end of it and, under the cards, a
/// hint about the long press. An empty column says so and keeps the add
/// control: there is no dead end.
final class KanbanColumnPage extends StatefulWidget {
  /// The page of [column], the [index]th of the board.
  const new({
    required this.index,
    required this.column,
    required this.host,
    required this.mathCache,
    required this.onToggle,
    required this.onEdit,
    required this.onMenu,
    required this.onMove,
    required this.onDelete,
    required this.onAdd,
    super.key,
  });

  /// The column's index on the board.
  final int index;

  /// The column.
  final KanbanColumn column;

  /// The note's window, which follows the links of the titles.
  final NoteKindHost host;

  /// The formulas of the titles.
  final MathCache mathCache;

  /// Flips the box of a card of the column.
  final ValueChanged<int> onToggle;

  /// Edits the title of a card.
  final ValueChanged<int> onEdit;

  /// Opens the sheet of a card.
  final ValueChanged<int> onMenu;

  /// Moves a card one place within the column.
  final void Function(int card, KanbanDirection direction) onMove;

  /// Deletes a card.
  final ValueChanged<int> onDelete;

  /// Adds a card titled so at the end of the column.
  final ValueChanged<String> onAdd;

  @override
  State<KanbanColumnPage> createState() => _KanbanColumnPageState();
}

final class _KanbanColumnPageState extends State<KanbanColumnPage> {
  final ScrollController _scroll = ScrollController();
  bool _scrollToEnd = false;

  @override
  void didUpdateWidget(KanbanColumnPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrollToEnd &&
        widget.column.cards.length > oldWidget.column.cards.length) {
      _scrollToEnd = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _foot(BuildContext context) {
    final muted = KanbanPalette.of(context).muted;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: muted);
    final empty = widget.column.cards.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (empty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppStrings.kanbanEmptyColumn,
              key: const Key('kanban-column-empty'),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        KanbanAddField(
          label: AppStrings.kanbanAddCard,
          hint: AppStrings.kanbanCardHint,
          keepOpen: true,
          onAdd: (title) {
            _scrollToEnd = true;
            widget.onAdd(title);
          },
        ),
        if (!empty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              AppStrings.kanbanLongPressHint,
              key: const Key('kanban-long-press-hint'),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final column = widget.column;
    final cards = column.cards;
    return ListView.builder(
      key: PageStorageKey<int>(widget.index),
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: cards.length + 1,
      itemBuilder: (context, i) {
        if (i == cards.length) return _foot(context);
        return Padding(
          key: ValueKey(i),
          padding: const EdgeInsets.only(bottom: 8),
          child: KanbanPhoneCard(
            card: cards[i],
            index: i,
            count: cards.length,
            columnName: column.name,
            host: widget.host,
            mathCache: widget.mathCache,
            onToggle: () => widget.onToggle(i),
            onEdit: () => widget.onEdit(i),
            onMenu: () => widget.onMenu(i),
            onMove: (direction) => widget.onMove(i, direction),
            onDelete: () => widget.onDelete(i),
          ),
        );
      },
    );
  }
}
