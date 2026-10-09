/// The phone's Home being edited (#535): the tiles in a list, a handle to
/// reorder each and a switch to show it — on every device: a phone that
/// wants its own picks *Only on this device* at the top.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/home/home_edit_dialogs.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/home/home_scope_switch.dart';
import 'package:niman/src/ui/home/home_tile_settings.dart';
import 'package:niman/src/ui/strings.dart';

/// Opens the editor of [editing]'s Home, in [controller]'s library, as a
/// page.
Future<void> openHomeColumnEditor(
  BuildContext context,
  HomeEditing editing,
  LibrarySession controller,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => HomeColumnEditor(editing: editing, controller: controller),
  ),
);

/// The list of tiles, as a page.
final class HomeColumnEditor extends StatelessWidget {
  /// Edits [editing]'s Home in [controller]'s library.
  const new({required this.editing, required this.controller, super.key});

  /// The Home being edited.
  final HomeEditing editing;

  /// The open library, for the tiles' settings.
  final LibrarySession controller;

  void _reorder(List<HomeTile> tiles, int from, int to) {
    final ids = [for (final t in tiles) t.id];
    ids.insert(to, ids.removeAt(from));
    unawaited(editing.change(editing.layout.ordered(ids)));
  }

  void _show(HomeTile tile, bool shown) {
    final layout = editing.layout;
    unawaited(
      editing.change(
        shown
            ? layout.show(tile.id).settled(first: tile.id)
            : layout.hide(tile.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-column-editor'),
      appBar: AppBar(
        title: Text(AppStrings.homeEdit),
        actions: [
          TextButton(
            key: const Key('home-reset'),
            onPressed: () async {
              if (await confirmHomeReset(context)) await editing.reset();
            },
            child: Text(AppStrings.homeReset),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: editing,
        builder: (context, _) {
          final tiles = editing.layout.editable;
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeScopeSwitch(editing: editing),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.homeColumnHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            footer: _AddSection(editing: editing),
            itemCount: tiles.length,
            onReorderItem: (from, to) => _reorder(tiles, from, to),
            itemBuilder: (context, i) {
              final tile = tiles[i];
              return ListTile(
                key: ValueKey(tile.id),
                contentPadding: const EdgeInsets.only(right: 4),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
                title: Row(
                  children: [
                    Icon(homeTileIcon(tile.kind!), size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(homeTileTitle(tile))),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasTileSettings(tile))
                      IconButton(
                        key: Key('home-settings-${tile.id}'),
                        tooltip: AppStrings.homeTileSettings,
                        onPressed: () => unawaited(
                          openTileSettings(
                            context,
                            editing,
                            tile,
                            controller: controller,
                          ),
                        ),
                        icon: const Icon(Icons.tune),
                      ),
                    Switch(
                      key: Key('home-switch-${tile.id}'),
                      value: !tile.hidden,
                      onChanged: (shown) => _show(tile, shown),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// The kinds to add: the ones a Home holds several of, and the ones it
/// holds none of yet.
final class _AddSection extends StatelessWidget {
  const new({required this.editing});

  final HomeEditing editing;

  @override
  Widget build(BuildContext context) {
    final layout = editing.layout;
    final kinds = [
      for (final kind in HomeTileKind.values)
        if (kind.repeats || layout.tiles.every((t) => t.kind != kind)) kind,
    ];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 4),
          child: Text(
            AppStrings.homeAddTiles.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ),
        for (final kind in kinds)
          ListTile(
            key: Key('home-add-${kind.name}'),
            leading: Icon(homeTileIcon(kind)),
            title: Text(homeTileName(kind)),
            trailing: const Icon(Icons.add),
            onTap: () {
              final next = layout.add(kind);
              unawaited(
                editing.change(next.settled(first: next.tiles.last.id)),
              );
            },
          ),
      ],
    );
  }
}
