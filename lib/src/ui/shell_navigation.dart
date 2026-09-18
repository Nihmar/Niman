/// The shell's tab navigation (issue #100, split out of `shell.dart`):
/// the same five destinations in the two shapes the layouts need — a bar
/// along the bottom of a phone, a rail down the side of a wide window.
///
/// Both live here, against the one-class-per-file habit, precisely
/// because they are one thing said twice: a destination added to one and
/// forgotten in the other is the bug this file exists to make obvious.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The bottom tab bar.
///
/// Shown by the tab shell only: an open note is a page, not a tab
/// (issue #73, item 1), so the bar no longer sits under it — going
/// anywhere else is back, and back lands where the note was opened
/// from.
final class ShellTabBar extends StatelessWidget {
  /// Creates the bar with [selectedIndex] current.
  const new({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// The current tab's index.
  final int selectedIndex;

  /// Reports a tap by index; the shell decides what it means.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('shell-tabs'),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          key: const Key('tab-files'),
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder),
          label: AppStrings.tabFiles,
        ),
        NavigationDestination(
          icon: const Icon(Icons.check_box_outlined),
          selectedIcon: const Icon(Icons.check_box),
          label: AppStrings.todoTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search),
          label: AppStrings.tabSearch,
        ),
        NavigationDestination(
          icon: const Icon(Icons.edit_outlined),
          selectedIcon: const Icon(Icons.edit),
          label: AppStrings.quickNoteTitle,
        ),
        NavigationDestination(
          key: const Key('tab-settings'),
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: AppStrings.tabSettings,
        ),
      ],
    );
  }
}

/// The wide layout's navigation rail: the same destinations down the side.
final class ShellRail extends StatelessWidget {
  /// Creates the rail with [selectedIndex] current.
  const new({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// The current tab's index.
  final int selectedIndex;

  /// Reports a tap by index; the shell decides what it means.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      key: const Key('shell-rail'),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder),
          label: Text(AppStrings.tabFiles),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.check_box_outlined),
          selectedIcon: const Icon(Icons.check_box),
          label: Text(AppStrings.todoTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.search),
          label: Text(AppStrings.tabSearch),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.edit_outlined),
          selectedIcon: const Icon(Icons.edit),
          label: Text(AppStrings.quickNoteTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(AppStrings.tabSettings),
        ),
      ],
    );
  }
}
