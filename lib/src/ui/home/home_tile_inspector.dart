/// A tile's settings beside the Home being edited, on a desktop (#712):
/// its fields in a panel in place of the add panel, each change written
/// at once — no dialog over the grid. A saved search's name and query, an
/// actions tile's buttons.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/home/home_actions_editor.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/strings.dart';

/// The inspector of [tile], in [editing]'s Home.
final class HomeTileInspector extends StatelessWidget {
  /// Inspects [tile]; [onClose] gives the panel back to the add panel.
  const new({
    required this.tile,
    required this.editing,
    required this.controller,
    required this.onClose,
    super.key,
  });

  /// The tile shown.
  final HomeTile tile;

  /// The Home being edited, written through.
  final HomeEditing editing;

  /// The open library, for the actions' editor.
  final LibrarySession controller;

  /// Back to the add panel.
  final VoidCallback onClose;

  /// Writes [change] of the tile as it is now in the layout.
  Future<void> _put(HomeTile Function(HomeTile tile) change) {
    final current = editing.layout[tile.id] ?? tile;
    return editing.change(editing.layout.put(change(current)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final search = tile.kind == HomeTileKind.search;
    return Material(
      key: const Key('home-tile-inspector'),
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    search
                        ? AppStrings.homeTileSearch
                        : AppStrings.homeTileActions,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  key: const Key('home-tile-inspector-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: search
                  ? _SearchFields(
                      // Another tile is another pair of fields.
                      key: ValueKey(tile.id),
                      tile: tile,
                      onChanged: (title, query) =>
                          _put((t) => t.copyWith(title: title, query: query)),
                    )
                  : HomeActionsEditor(
                      key: ValueKey(tile.id),
                      actions: tile.actions,
                      controller: controller,
                      onChanged: (actions) =>
                          _put((t) => t.copyWith(actions: actions)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A saved search's name and query, written as each is left or submitted.
final class _SearchFields extends StatefulWidget {
  const new({required this.tile, required this.onChanged, super.key});

  final HomeTile tile;
  final void Function(String title, String query) onChanged;

  @override
  State<_SearchFields> createState() => _SearchFieldsState();
}

final class _SearchFieldsState extends State<_SearchFields> {
  late final TextEditingController _title = TextEditingController(
    text: widget.tile.title,
  );
  late final TextEditingController _query = TextEditingController(
    text: widget.tile.query,
  );

  @override
  void dispose() {
    _title.dispose();
    _query.dispose();
    super.dispose();
  }

  void _write() {
    final title = _title.text.trim();
    final query = _query.text.trim();
    if (title == widget.tile.title && query == widget.tile.query) return;
    widget.onChanged(title, query);
  }

  Widget _field(
    TextEditingController text,
    Key key,
    String label, {
    String? hint,
  }) => Focus(
    onFocusChange: (focused) {
      if (!focused) _write();
    },
    child: TextField(
      key: key,
      controller: text,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onSubmitted: (_) => _write(),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _field(_title, const Key('home-search-title'), AppStrings.homeSearchName),
      const SizedBox(height: 12),
      _field(
        _query,
        const Key('home-search-query'),
        AppStrings.homeSearchQuery,
        hint: AppStrings.homeSearchQueryHint,
      ),
    ],
  );
}
