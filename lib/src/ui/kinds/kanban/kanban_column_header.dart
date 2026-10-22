import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_board_controller.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/strings.dart';

/// The head of a column (#1167): its name, how many cards it holds and the
/// ⋮ menu — rename, delete. Renaming turns the name into a field: `Enter`
/// or leaving it renames, `Esc` keeps the name.
final class KanbanColumnHeader extends StatefulWidget {
  /// The header of column [column], named [name], holding [count] cards.
  const new({
    required this.controller,
    required this.column,
    required this.name,
    required this.count,
    super.key,
  });

  /// What the board shares.
  final KanbanBoardController controller;

  /// The column's index.
  final int column;

  /// The column's name.
  final String name;

  /// How many cards it holds.
  final int count;

  @override
  State<KanbanColumnHeader> createState() => _KanbanColumnHeaderState();
}

enum _Action { rename, delete }

final class _KanbanColumnHeaderState extends State<KanbanColumnHeader> {
  final FocusNode _focus = FocusNode(debugLabel: 'kanban-column-name');
  final TextEditingController _text = TextEditingController();
  bool _renaming = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KanbanColumnHeader old) {
    super.didUpdateWidget(old);
    // The column under the field is another one (a column was deleted): the
    // name being typed belonged to the old one.
    if (_renaming && old.name != widget.name) _renaming = false;
  }

  void _onFocus() {
    if (_renaming && !_focus.hasFocus) _finish(save: true);
  }

  void _begin() {
    _text.value = TextEditingValue(
      text: widget.name,
      selection: TextSelection(baseOffset: 0, extentOffset: widget.name.length),
    );
    setState(() => _renaming = true);
  }

  void _finish({required bool save}) {
    if (!_renaming) return;
    final name = _text.text.trim();
    setState(() => _renaming = false);
    if (save && name.isNotEmpty) {
      widget.controller.edits.renameColumn(widget.column, name);
    }
  }

  void _run(_Action action) {
    switch (action) {
      case _Action.rename:
        _begin();
      case _Action.delete:
        widget.controller.edits.deleteColumn(widget.column);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = KanbanPalette.of(context);
    final scheme = theme.colorScheme;
    final title = _renaming
        ? CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  _finish(save: false),
            },
            child: TextField(
              key: const Key('kanban-column-field'),
              controller: _text,
              focusNode: _focus,
              autofocus: true,
              style: theme.textTheme.titleSmall,
              decoration: InputDecoration(
                isDense: true,
                hintText: AppStrings.kanbanColumnHint,
                border: const UnderlineInputBorder(),
              ),
              onSubmitted: (_) => _finish(save: true),
            ),
          )
        : Semantics(
            header: true,
            child: Text(
              widget.name,
              key: const Key('kanban-column-name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 4),
      child: Row(
        children: [
          Expanded(child: title),
          const SizedBox(width: 8),
          Text(
            '${widget.count}',
            key: const Key('kanban-column-count'),
            style: theme.textTheme.labelMedium?.copyWith(color: palette.muted),
          ),
          PopupMenuButton<_Action>(
            key: const Key('kanban-column-menu'),
            tooltip: AppStrings.kanbanColumnActions,
            icon: Icon(Icons.more_vert, size: 18, color: palette.muted),
            onSelected: _run,
            itemBuilder: (context) => [
              menuItem<_Action>(
                context,
                key: const Key('kanban-column-rename'),
                value: _Action.rename,
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(AppStrings.actionRename),
                  ],
                ),
              ),
              menuItem<_Action>(
                context,
                key: const Key('kanban-column-delete'),
                value: _Action.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: scheme.error),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.kanbanDeleteColumn,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
