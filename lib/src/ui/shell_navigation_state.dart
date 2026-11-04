/// Where the shell is (issue #100 moved it out of the shell): the tab on
/// screen, the tabs the bar and the rail show, the ones visited, where Back
/// goes from a note or a hidden tab, and the content tab pinned in a pane.
/// The bar and the rail themselves are `shell_navigation.dart`'s.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/ui/shell_navigation.dart';

/// The shell's tabs, as plain state: the shell changes it inside its own
/// `setState`, except for a plain tab switch, which [tabListenable]
/// carries alone (#46).
final class ShellNavigationState {
  /// The tabs of a library whose [features] say which of them exist.
  new({required this.features});

  /// The library's features (#1109): a tab whose feature is off is not
  /// placed.
  final Features Function() features;

  /// The currently selected bottom tab (narrow layout).
  ///
  /// A [ValueNotifier] rather than a plain field so a plain tab switch can
  /// refresh the chrome and the visible slot through a
  /// `ValueListenableBuilder` *without* a shell-wide `setState`: the
  /// kept-alive bodies do not depend on which tab is current, so rebuilding
  /// all of them on every switch was 12-24 ms of wasted `build` (device log,
  /// #46). Read and written through [tab], so every call site is the same;
  /// the full-`setState` paths still fire where the switch also changes
  /// state the bodies do read.
  final ValueNotifier<ShellTab> tabListenable = ValueNotifier(ShellTab.files);

  /// The tab on screen.
  ShellTab get tab => tabListenable.value;
  set tab(ShellTab value) {
    requested = true;
    // Every way into a hidden tab passes here, so this is where the way
    // back out of it is remembered (#536).
    if (shown(tabListenable.value) && !shown(value)) {
      hiddenReturn = tabListenable.value;
    }
    tabListenable.value = value;
  }

  /// The library's navigation on this device (#536), read with the
  /// editor settings; null until the first read.
  NavigationLayout? layout;

  /// The tabs the bar and the rail show, in order: placed once per
  /// layout and per change of features, not on every frame and every tab
  /// switch that asks.
  late List<ShellTab> _shownTabs = _placed(const NavigationLayout());

  /// The tabs [layout] places, for the library's features.
  List<ShellTab> _placed(NavigationLayout layout) => [
    for (final d in visibleDestinations(layout, features: features())) d.tab,
  ];

  /// Places the tabs again: for [layout] when one is given, which becomes
  /// the navigation, else for the default one — the features changed
  /// before any layout was read.
  void place([NavigationLayout? layout]) {
    if (layout != null) this.layout = layout;
    _shownTabs = _placed(layout ?? const NavigationLayout());
  }

  /// The destinations the bar and the rail show.
  List<ShellDestination> get destinations {
    final all = {for (final d in shellDestinations()) d.tab: d};
    return [for (final tab in _shownTabs) all[tab]!];
  }

  /// Whether [tab] has a place in the bar and the rail.
  bool shown(ShellTab tab) => _shownTabs.contains(tab);

  /// Whether something chose the tab before the layout was read: a
  /// widget, a notification, a shared item, a reminder, the palette. What
  /// a request names wins over the start destination (#706).
  bool requested = false;

  /// The tab the shell opens on and falls back to (#706): the layout's
  /// start destination ([startDestination]), or [homeTab] when the
  /// layout leaves none.
  ShellTab startTab({required bool wide}) => switch (layout) {
    final layout? =>
      startDestination(layout, features: features()) ?? homeTab(wide: wide),
    null => homeTab(wide: wide),
  };

  /// The last fallback: the first shown that is a place of its own — not
  /// the quick note, a note rather than a place, nor Settings on a [wide]
  /// window, where it floats (#202). Files when there is none, which a
  /// wide window shows with nothing selected.
  ShellTab homeTab({required bool wide}) {
    for (final tab in _shownTabs) {
      if (tab == ShellTab.quickNote) continue;
      if (tab == ShellTab.settings && wide) continue;
      return tab;
    }
    return ShellTab.files;
  }

  /// The tab a hidden one was opened from (the palette, a widget, a
  /// reminder): its back arrow returns there.
  ShellTab hiddenReturn = ShellTab.files;

  /// Every tab visited so far: bodies mount on first visit and stay
  /// mounted afterwards, so a switch only flips visibility instead of
  /// disposing one state and inflating another mid-animation (the
  /// 2026-09-08 device log put that inflate at 14-17 ms of frame build).
  /// Query, results, and scroll therefore survive a switch, by choice.
  final Set<ShellTab> visited = <ShellTab>{ShellTab.files};

  /// Makes [tab] the one on screen, and mounts its body.
  void visit(ShellTab tab) {
    this.tab = tab;
    visited.add(tab);
  }

  /// The tab active when the full-screen note opened (back returns there).
  ShellTab noteFrom = ShellTab.files;

  /// The content destination pinned in a pane (#712): Home or Todo on a
  /// wide window, shown in [contentPane] with the tree, the panes and
  /// the dock beside it. Null when none is open; a phone keeps both as
  /// full-screen destinations.
  ShellTab? contentTab;

  /// Which pane holds [contentTab]: the focused one when it opened.
  int contentPane = 0;

  /// Shows [tab] pinned in [pane] (#712).
  void pin(ShellTab tab, int pane) {
    visit(tab);
    contentTab = tab;
    contentPane = pane;
  }

  /// Closes the pinned content tab (#712): the tree keeps the rail.
  void closeContent() {
    contentTab = null;
    if (tab == ShellTab.home || tab == ShellTab.todo) tab = ShellTab.files;
  }

  /// Lets go of the tab's notifier.
  void dispose() => tabListenable.dispose();
}
