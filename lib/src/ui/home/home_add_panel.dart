/// The tiles waiting beside the grid being edited (#535): the hidden ones,
/// each with its settings as it left, and every kind there is to add.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/strings.dart';

/// The hidden tiles and the kinds to add.
final class HomeAddPanel extends StatelessWidget {
  /// The panel of [editing]'s Home.
  const new({required this.editing, super.key});

  /// The Home being edited.
  final HomeEditing editing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = editing.layout;
    final hidden = [
      for (final t in layout.editable)
        if (t.hidden) t,
    ];
    final header = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.4,
    );
    Widget title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(text.toUpperCase(), style: header),
    );
    return Column(
      key: const Key('home-add-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hidden.isNotEmpty) ...[
          title(AppStrings.homeHiddenTiles),
          for (final t in hidden)
            ListTile(
              key: Key('home-show-${t.id}'),
              dense: true,
              leading: Icon(homeTileIcon(t.kind!)),
              title: Text(homeTileTitle(t)),
              trailing: Tooltip(
                message: AppStrings.homeTileShow,
                child: const Icon(Icons.visibility_outlined),
              ),
              onTap: () => unawaited(
                editing.change(layout.show(t.id).settled(first: t.id)),
              ),
            ),
        ],
        title(AppStrings.homeAddTiles),
        for (final kind in HomeTileKind.values)
          _AddRow(editing: editing, kind: kind),
      ],
    );
  }
}

/// One kind to add: one a Home holds once is offered only while it holds
/// none.
final class _AddRow extends StatelessWidget {
  const new({required this.editing, required this.kind});

  final HomeEditing editing;
  final HomeTileKind kind;

  @override
  Widget build(BuildContext context) {
    final layout = editing.layout;
    final there = kind.repeats
        ? null
        : layout.tiles.where((t) => t.kind == kind).firstOrNull;
    return ListTile(
      key: Key('home-add-${kind.name}'),
      dense: true,
      enabled: there == null,
      leading: Icon(homeTileIcon(kind)),
      title: Text(homeTileName(kind)),
      trailing: there == null
          ? const Icon(Icons.add)
          : Text(
              there.hidden
                  ? AppStrings.homeHiddenTiles
                  : AppStrings.homeTileOnHome,
              style: Theme.of(context).textTheme.labelSmall,
            ),
      onTap: () {
        final next = layout.add(kind);
        final added = next.tiles.last;
        unawaited(editing.change(next.settled(first: added.id)));
      },
    );
  }
}
