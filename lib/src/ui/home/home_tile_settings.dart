/// A tile's own settings, from either editor (#535).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/home/actions_tile_dialog.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/home/search_tile_dialog.dart';

/// Whether [tile] has settings of its own.
bool hasTileSettings(HomeTile tile) =>
    tile.kind == HomeTileKind.search || tile.kind == HomeTileKind.actions;

/// Opens [tile]'s settings and writes what was chosen through [editing].
Future<void> openTileSettings(
  BuildContext context,
  HomeEditing editing,
  HomeTile tile, {
  required LibrarySession controller,
}) async {
  if (tile.kind == HomeTileKind.actions) {
    final actions = await showActionsTileDialog(
      context,
      actions: tile.actions,
      controller: controller,
    );
    if (actions == null) return;
    final current = editing.layout[tile.id] ?? tile;
    await editing.change(
      editing.layout.put(current.copyWith(actions: actions)),
    );
    return;
  }
  if (tile.kind != HomeTileKind.search) return;
  final picked = await showSearchTileDialog(
    context,
    title: tile.title,
    query: tile.query,
  );
  if (picked == null) return;
  final current = editing.layout[tile.id] ?? tile;
  await editing.change(
    editing.layout.put(
      current.copyWith(title: picked.title, query: picked.query),
    ),
  );
}
