/// What a table's cell adds to the editor's context menu (#261).
library;

import 'package:flutter/widgets.dart';

/// One action on the table: its name, its icon, what it does — null when
/// it does not apply to the cell (a row above the header).
@immutable
final class TableMenuAction {
  /// Creates an action.
  const new({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  /// What tests and the menu's rows are keyed by: `table-<id>`.
  final String id;

  /// Its name in the menu.
  final String label;

  /// Its icon.
  final IconData icon;

  /// What it does, or null when it cannot be done here.
  final VoidCallback? onPressed;
}

/// A submenu of actions — the row's, the column's — in sections set apart.
@immutable
final class TableMenuGroup {
  /// Creates a group.
  const new({
    required this.id,
    required this.label,
    required this.icon,
    required this.sections,
  });

  /// What it is keyed by: `table-<id>`.
  final String id;

  /// Its name, the entry that opens it.
  final String label;

  /// Its icon.
  final IconData icon;

  /// Its actions, each list a section of its own.
  final List<List<TableMenuAction>> sections;
}

/// The table's part of the menu: its submenus, then its own actions (the
/// sorts).
@immutable
final class TableMenu {
  /// Creates the table's part.
  const new({required this.groups, required this.actions});

  /// The row's and the column's submenus.
  final List<TableMenuGroup> groups;

  /// The actions on the table as a whole, straight in the menu.
  final List<TableMenuAction> actions;
}
