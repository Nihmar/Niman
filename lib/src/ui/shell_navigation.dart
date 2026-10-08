/// The shell's tab navigation (issue #100, split out of `shell.dart`):
/// the same destinations in the two shapes the layouts need — a bar
/// along the bottom of a phone, a rail down the side of a wide window —
/// in the order and with the ones hidden the library's
/// [NavigationLayout] says (#536).
///
/// Both live here, against the one-class-per-file habit, precisely
/// because they are one thing said twice: a destination added to one and
/// forgotten in the other is the bug this file exists to make obvious.
/// [shellDestinations] goes further and makes it impossible — one list,
/// read by both.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/ui/strings.dart';

/// The app tabs: the bottom navigation bar on the narrow layout, the
/// fixed left rail on the wide layout (T-PP-14).
///
/// The enum's order is the bodies' slots, which never move; where a tab
/// sits in the bar is the [NavigationLayout]'s business.
enum ShellTab {
  /// The note tree plus the note-open stack (T-UI-02).
  files,

  /// Reserved tab for the todo section (T-UI-10).
  todo,

  /// Full-text search (M3 T-M3-05); the SearchScreen tab.
  search,

  /// The scratch quick note at the library root (T-UI-10).
  quickNote,

  /// The library settings (the pushed SettingsScreen on wide screens).
  settings,
}

/// One destination, as both shapes draw it.
///
/// `name` is the key suffix, so the same destination is `tab-files` in
/// the bar and `rail-files` in the rail: one name, two shapes, and a test
/// that names either one cannot drift onto the other. It is also the name
/// a [NavigationLayout] keeps it by.
typedef ShellDestination = ({
  ShellTab tab,
  String name,
  IconData icon,
  IconData selectedIcon,
  String label,
});

/// Every destination, in the default order.
///
/// Built per call rather than held as a constant: the labels come from
/// the current language, which changes under a running app.
List<ShellDestination> shellDestinations() => <ShellDestination>[
  (
    tab: ShellTab.files,
    name: 'files',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: AppStrings.tabFiles,
  ),
  (
    tab: ShellTab.todo,
    name: 'todo',
    icon: Icons.check_box_outlined,
    selectedIcon: Icons.check_box,
    label: AppStrings.todoTitle,
  ),
  (
    tab: ShellTab.search,
    name: 'search',
    icon: Icons.search,
    selectedIcon: Icons.search,
    label: AppStrings.tabSearch,
  ),
  (
    tab: ShellTab.quickNote,
    name: 'quicknote',
    icon: Icons.edit_outlined,
    selectedIcon: Icons.edit,
    label: AppStrings.quickNoteTitle,
  ),
  (
    tab: ShellTab.settings,
    name: 'settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: AppStrings.tabSettings,
  ),
];

/// Settings cannot be hidden: it is the way back to the switch that
/// hid the rest.
const Set<String> lockedDestinations = {'settings'};

/// The destinations as [layout] places them, the hidden ones included,
/// for the settings that edit it.
List<({ShellDestination destination, bool hidden})> placedDestinations(
  NavigationLayout layout,
) {
  final all = {for (final d in shellDestinations()) d.name: d};
  return [
    for (final placed in layout.place(
      all.keys.toList(),
      locked: lockedDestinations,
    ))
      (destination: all[placed.name]!, hidden: placed.hidden),
  ];
}

/// The destinations [layout] shows, in its order.
List<ShellDestination> visibleDestinations(NavigationLayout layout) => [
  for (final placed in placedDestinations(layout))
    if (!placed.hidden) placed.destination,
];

/// The bottom tab bar.
///
/// Shown by the tab shell only: an open note is a page, not a tab
/// (issue #73, item 1), so the bar no longer sits under it — going
/// anywhere else is back, and back lands where the note was opened
/// from.
final class ShellTabBar extends StatelessWidget {
  /// Creates the bar over [destinations] with [current] selected.
  const new({
    required this.destinations,
    required this.current,
    required this.onDestinationSelected,
    super.key,
  });

  /// The destinations shown, in order ([visibleDestinations]).
  final List<ShellDestination> destinations;

  /// The current tab. The shell does not show the bar while it is a
  /// hidden one (it is a page then); should it be, nothing is current
  /// and the first destination takes the selection the bar must have.
  final ShellTab current;

  /// Reports a tap; the shell decides what it means.
  final ValueChanged<ShellTab> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final index = destinations.indexWhere((d) => d.tab == current);
    return NavigationBar(
      key: const Key('shell-tabs'),
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) => onDestinationSelected(destinations[i].tab),
      destinations: [
        for (final destination in destinations)
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
/// Settings and the library switcher sit at the foot, below the gap,
/// wherever the layout puts Settings. They are not places inside the
/// library, they are ways out of it. Settings is still a destination,
/// but on a wide window the shell opens it as a floating window (#202),
/// so it does not take the selection either. The switcher is not a
/// destination at all, so it is the one control here that is not part
/// of [shellDestinations].
final class ShellRail extends StatelessWidget {
  /// Creates the rail over [destinations] with [current] selected.
  const new({
    required this.destinations,
    required this.current,
    required this.onDestinationSelected,
    required this.onSwitchLibrary,
    super.key,
  });

  /// The rail's width, and the note column's first tax on the window.
  static const double width = 48;

  /// The destinations shown, in order ([visibleDestinations]).
  final List<ShellDestination> destinations;

  /// The current tab; a hidden one leaves the rail with none selected.
  final ShellTab current;

  /// Reports a tap; the shell decides what it means.
  final ValueChanged<ShellTab> onDestinationSelected;

  /// Opens the known-library list.
  final VoidCallback onSwitchLibrary;

  @override
  Widget build(BuildContext context) {
    // Settings is locked (it is always among them) and sits at the foot.
    final settings = destinations.firstWhere((d) => d.tab == ShellTab.settings);
    final places = [
      for (final d in destinations)
        if (d != settings) d,
    ];
    return Container(
      key: const Key('shell-rail'),
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final destination in places)
            _RailButton(
              buttonKey: Key('rail-${destination.name}'),
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              label: destination.label,
              selected: current == destination.tab,
              onPressed: () => onDestinationSelected(destination.tab),
            ),
          const Spacer(),
          _RailButton(
            buttonKey: const Key('rail-library'),
            icon: Icons.layers_outlined,
            selectedIcon: Icons.layers,
            label: AppStrings.switchLibraryTitle,
            selected: false,
            onPressed: onSwitchLibrary,
          ),
          _RailButton(
            buttonKey: Key('rail-${settings.name}'),
            icon: settings.icon,
            selectedIcon: settings.selectedIcon,
            label: settings.label,
            selected: current == ShellTab.settings,
            onPressed: () => onDestinationSelected(ShellTab.settings),
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
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
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
        tooltip: label,
        onPressed: onPressed,
        isSelected: selected,
        icon: Icon(selected ? selectedIcon : icon),
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
