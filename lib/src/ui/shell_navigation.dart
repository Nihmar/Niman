/// The shell's tab navigation (issue #100, split out of `shell.dart`):
/// the same five destinations in the two shapes the layouts need — a bar
/// along the bottom of a phone, a rail down the side of a wide window.
///
/// Both live here, against the one-class-per-file habit, precisely
/// because they are one thing said twice: a destination added to one and
/// forgotten in the other is the bug this file exists to make obvious.
/// [shellDestinations] goes further and makes it impossible — one list,
/// read by both.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// One destination, as both shapes draw it.
///
/// `name` is the key suffix, so the same destination is `tab-files` in
/// the bar and `rail-files` in the rail: one name, two shapes, and a test
/// that names either one cannot drift onto the other.
typedef ShellDestination = ({
  String name,
  IconData icon,
  IconData selectedIcon,
  String label,
});

/// The five destinations, in order.
///
/// Built per call rather than held as a constant: the labels come from
/// the current language, which changes under a running app.
List<ShellDestination> shellDestinations() => <ShellDestination>[
  (
    name: 'files',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: AppStrings.tabFiles,
  ),
  (
    name: 'todo',
    icon: Icons.check_box_outlined,
    selectedIcon: Icons.check_box,
    label: AppStrings.todoTitle,
  ),
  (
    name: 'search',
    icon: Icons.search,
    selectedIcon: Icons.search,
    label: AppStrings.tabSearch,
  ),
  (
    name: 'quicknote',
    icon: Icons.edit_outlined,
    selectedIcon: Icons.edit,
    label: AppStrings.quickNoteTitle,
  ),
  (
    name: 'settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: AppStrings.tabSettings,
  ),
];

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
        for (final destination in shellDestinations())
          NavigationDestination(
            key: Key('tab-${destination.name}'),
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ],
    );
  }
}

/// The wide layout's navigation rail: the same destinations down the
/// side, 48 px wide and icons only (#170).
///
/// The labels are gone because the width they cost is the width the
/// note's centred column needs (#171), and an icon with a tooltip is
/// what every editor with a rail settles on. The icons stay outline and
/// the filled one marks the active destination, which is the rule in
/// `AGENTS.md`.
///
/// Settings and the library switcher sit at the foot, below the gap.
/// They are not places inside the library, they are ways out of it.
/// Settings is still a destination by index, but on a wide window the
/// shell opens it as a floating window (#202), so it does not take the
/// selection either. The switcher is not a destination at all, so it is
/// the one control here that is not part of [shellDestinations].
final class ShellRail extends StatelessWidget {
  /// Creates the rail with [selectedIndex] current.
  const new({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onSwitchLibrary,
    super.key,
  });

  /// The rail's width, and the note column's first tax on the window.
  static const double width = 48;

  /// The current tab's index.
  final int selectedIndex;

  /// Reports a tap by index; the shell decides what it means.
  final ValueChanged<int> onDestinationSelected;

  /// Opens the known-library list.
  final VoidCallback onSwitchLibrary;

  @override
  Widget build(BuildContext context) {
    final destinations = shellDestinations();
    final settings = destinations.length - 1;
    return Container(
      key: const Key('shell-rail'),
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < settings; i++)
            _RailButton(
              buttonKey: Key('rail-${destinations[i].name}'),
              destination: destinations[i],
              selected: selectedIndex == i,
              onPressed: () => onDestinationSelected(i),
            ),
          const Spacer(),
          _RailButton(
            buttonKey: const Key('rail-library'),
            destination: (
              name: 'library',
              icon: Icons.layers_outlined,
              selectedIcon: Icons.layers,
              label: AppStrings.switchLibraryTitle,
            ),
            selected: false,
            onPressed: onSwitchLibrary,
          ),
          _RailButton(
            buttonKey: Key('rail-${destinations[settings].name}'),
            destination: destinations[settings],
            selected: selectedIndex == settings,
            onPressed: () => onDestinationSelected(settings),
          ),
        ],
      ),
    );
  }
}

/// One 38 px square in the rail: the icon, its tooltip, and the pill the
/// active one sits on.
final class _RailButton extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final ShellDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: IconButton(
        key: buttonKey,
        // The label is the tooltip now that it is not on screen: without
        // it the rail is five unexplained glyphs, and the accessible name
        // goes with it.
        tooltip: destination.label,
        onPressed: onPressed,
        isSelected: selected,
        icon: Icon(selected ? destination.selectedIcon : destination.icon),
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        style: IconButton.styleFrom(
          backgroundColor: selected ? scheme.surfaceContainerHigh : null,
          foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
          minimumSize: const Size.square(38),
          fixedSize: const Size.square(38),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}
