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
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// The command a destination runs on a key, if any.
AppCommand? _tabCommand(ShellTab tab) => switch (tab) {
  ShellTab.files => AppCommand.tabFiles,
  ShellTab.todo => AppCommand.tabTodo,
  ShellTab.search => AppCommand.tabSearch,
  ShellTab.quickNote => AppCommand.tabQuickNote,
  ShellTab.settings => AppCommand.tabSettings,
  ShellTab.home => AppCommand.tabHome,
  ShellTab.study => AppCommand.tabStudy,
};

/// [destination]'s label, with the key that selects it when a keyboard is
/// there to press it (#712).
String _railLabel(ShellDestination destination) {
  final command = _tabCommand(destination.tab);
  return tooltipWithKeys(
    destination.label,
    command == null ? null : AppKeyMap.current.value.bindingOf(command),
  );
}

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

  /// The library's Home (#535): its tiles and action buttons. The bar
  /// puts it after Search.
  home,

  /// The decks to study (#533). Last in the enum, which is the bodies'
  /// slots; hidden until asked for ([defaultHiddenDestinations]).
  study,
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
    tab: ShellTab.home,
    name: 'home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: AppStrings.tabHome,
  ),
  (
    tab: ShellTab.study,
    name: 'study',
    icon: Icons.style_outlined,
    selectedIcon: Icons.style,
    label: AppStrings.tabStudy,
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

/// The destinations a library starts without (#533): a library with no
/// deck does not grow a Study it has no use for; the first deck made
/// offers it.
const Set<String> defaultHiddenDestinations = {'study'};

/// The destinations as [layout] places them, the hidden ones included,
/// for the settings that edit it.
List<({ShellDestination destination, bool hidden})> placedDestinations(
  NavigationLayout layout,
) {
  final all = {for (final d in shellDestinations()) d.name: d};
  final placed = layout.place(
    all.keys.toList(),
    defaultHidden: defaultHiddenDestinations,
    locked: lockedDestinations,
  );
  // A bar needs two destinations (`NavigationBar` asserts it, #667): a
  // layout that hides all but Settings — a file edited by hand, a build
  // that dropped one — shows the first hidden ones back.
  var missing = minShownDestinations - placed.where((p) => !p.hidden).length;
  return [
    for (final p in placed)
      (destination: all[p.name]!, hidden: p.hidden && missing-- <= 0),
  ];
}

/// The fewest destinations the bar and the rail show.
const int minShownDestinations = 2;

/// The destinations [layout] shows, in its order.
List<ShellDestination> visibleDestinations(NavigationLayout layout) => [
  for (final placed in placedDestinations(layout))
    if (!placed.hidden) placed.destination,
];

/// What cannot be a start (#706): Settings, and the quick note — a note,
/// not a place.
const Set<ShellTab> _notStarts = {ShellTab.settings, ShellTab.quickNote};

/// The destinations [layout] shows that the app can open on, in its
/// order: what the Navigation area offers as the start.
List<ShellDestination> startDestinations(NavigationLayout layout) => [
  for (final d in visibleDestinations(layout))
    if (!_notStarts.contains(d.tab)) d,
];

/// The destination [layout] opens on (#706): its start when that is shown
/// and can be one; Files otherwise, as before a start could be chosen;
/// and with Files hidden too, the first shown that can be. Null when no
/// destination shown can be a start.
ShellTab? startDestination(NavigationLayout layout) {
  final starts = startDestinations(layout);
  for (final d in starts) {
    if (d.name == layout.start) return d.tab;
  }
  for (final d in starts) {
    if (d.tab == ShellTab.files) return d.tab;
  }
  return starts.firstOrNull?.tab;
}

/// The name of the destination [layout] opens on, for the settings that
/// show it; null when none can be a start.
String? startLabel(NavigationLayout layout) {
  final start = startDestination(layout);
  for (final d in shellDestinations()) {
    if (d.tab == start) return d.label;
  }
  return null;
}

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

  /// The rail's width, and the note column's first tax on the window: a
  /// button and the margin left of it, no margin right. The islands' own
  /// gap is the space on that side, so the glyph sits as far from the
  /// panel as from the window's edge, and the active pill stands off the
  /// panel as one island does off the next (#749).
  static const double width = _margin + _RailButton.pointerSize;

  /// Where the panels start, from the window's left edge: past the rail
  /// and the islands' gap. The title bar's name starts here, so it stands
  /// over the panel's edge (#708).
  static const double panelStart = width + Island.gap;

  /// The centre of the buttons' glyphs, from the window's left edge: the
  /// title bar's sidebar toggle is centred on it (#708).
  static const double glyphCentre = _margin + _RailButton.pointerSize / 2;

  /// The space between the window's edge and the buttons: the same the
  /// islands keep from the edge beside it (#749).
  static const double _margin = 4;

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
    // A mouse's 38 px button, or a thumb's 48 on a touch device (#849):
    // the rail widens by the difference. The statics above are the
    // desktop's, which the title bar lines up with.
    final side = thumbDense(Theme.of(context))
        ? thumbTarget
        : _RailButton.pointerSize;
    return Container(
      key: const Key('shell-rail'),
      width: _margin + side,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.only(left: _margin, top: 6, bottom: 6),
      // Scrolls when the window is shorter than the buttons are tall: a
      // tablet with its keyboard up leaves the rail 130 dp (#849), and
      // Settings and the library switch are not to be lost under the
      // overflow. At its full height the column fills the rail as before,
      // the library and Settings at the foot.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: _column(places, settings, side)),
          ),
        ),
      ),
    );
  }

  Widget _column(
    List<ShellDestination> places,
    ShellDestination settings,
    double side,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final destination in places)
          _RailButton(
            buttonKey: Key('rail-${destination.name}'),
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
            label: _railLabel(destination),
            selected: current == destination.tab,
            onPressed: () => onDestinationSelected(destination.tab),
            size: side,
          ),
        const Spacer(),
        _RailButton(
          buttonKey: const Key('rail-library'),
          icon: Icons.layers_outlined,
          selectedIcon: Icons.layers,
          label: AppStrings.switchLibraryTitle,
          selected: false,
          onPressed: onSwitchLibrary,
          size: side,
        ),
        _RailButton(
          buttonKey: Key('rail-${settings.name}'),
          icon: settings.icon,
          selectedIcon: settings.selectedIcon,
          label: _railLabel(settings),
          selected: current == ShellTab.settings,
          onPressed: () => onDestinationSelected(ShellTab.settings),
          size: side,
        ),
      ],
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
    required this.size,
  });

  /// The button's side.
  static const double pointerSize = 38;

  /// The button's side on this surface: [pointerSize] for a mouse, a thumb's
  /// target on a touch device (#849).
  final double size;

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
        constraints: BoxConstraints.tightFor(width: size, height: size),
        style: IconButton.styleFrom(
          backgroundColor: selected ? scheme.surfaceContainerHigh : null,
          foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
          minimumSize: Size.square(size),
          fixedSize: Size.square(size),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}
