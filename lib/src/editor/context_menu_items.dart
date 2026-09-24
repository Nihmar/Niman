/// The entries an editor adds to its context menu: actions, and groups of
/// them opened as submenus (#260, #261).
library;

import 'package:flutter/widgets.dart';

/// An entry of the menu: an action, or a group of actions.
@immutable
sealed class ContextMenuItem {
  const new({required this.id, required this.label, required this.icon});

  /// What tests and the menu's rows are keyed by: `<id>` as given.
  final String id;

  /// Its name in the menu.
  final String label;

  /// Its icon, outline as the menu's are.
  final IconData icon;
}

/// One action: what it does — null when it cannot be done here, where it
/// stays greyed out rather than leaving a hole — and whether what it
/// stands for is on at the caret.
final class ContextMenuAction extends ContextMenuItem {
  /// Creates an action.
  const new({
    required super.id,
    required super.label,
    required super.icon,
    required this.onPressed,
    this.active = false,
  });

  /// What it does, or null when it does not apply.
  final VoidCallback? onPressed;

  /// Whether its format is on at the caret.
  final bool active;
}

/// A submenu: its actions, in sections set apart.
final class ContextMenuGroup extends ContextMenuItem {
  /// Creates a group.
  const new({
    required super.id,
    required super.label,
    required super.icon,
    required this.sections,
  });

  /// Its actions, each list a section of its own.
  final List<List<ContextMenuAction>> sections;
}

/// A part of the menu: sections of entries, a divider between two.
typedef ContextMenuPart = List<List<ContextMenuItem>>;
