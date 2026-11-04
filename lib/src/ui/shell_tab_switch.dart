import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/shell_compare_tab.dart';
import 'package:niman/src/ui/shell_fab.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_note_fade.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/tab_body_stack.dart';

/// The shell's moves between its destinations (#1256): a tab picked, the
/// layout placed again, the start destination, a content tab pinned in a
/// pane, the phone's note closed for the tab it came from.
///
/// What is selected lives in [selection], where the tab is in [nav]; this
/// says how one destination gives way to the next.
final class ShellTabSwitch {
  /// The moves between [nav]'s destinations, over [selection].
  new({
    required this.nav,
    required this.selection,
    required this.workspace,
    required this.reviewTab,
    required this.compare,
    required this.noteFade,
    required this.fab,
    required this.fullScreen,
    required this.shellFocus,
    required this.wide,
    required this.openQuickNote,
    required this.openSettings,
    required this.update,
    required this.mounted,
  });

  /// Where the shell is.
  final ShellNavigationState nav;

  /// What is selected and what shows.
  final ShellSelection selection;

  /// The panes, one of them focused.
  final ShellWorkspace workspace;

  /// The study beside the deck, which a page over the pane covers.
  final ReviewTab reviewTab;

  /// The version beside the note, which a page over the pane covers.
  final ShellCompareTab compare;

  /// The phone's note fading in over the tabs.
  final ShellNoteFade noteFade;

  /// The phone's new-item button, whose open menu takes a rebuild to close.
  final ShellFab fab;

  /// A book read in full screen (#621): Back steps out of it first.
  final ValueNotifier<Object?> fullScreen;

  /// Where the app's accelerators are caught when nothing else has focus.
  final FocusNode shellFocus;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// The Quick note destination: its note, or the chooser.
  final Future<void> Function() openQuickNote;

  /// Settings over the note, on a wide window (#202).
  final VoidCallback openSettings;

  /// The shell's `setState`.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// The tab the shell opens on and falls back to (#706).
  ShellTab get startTab => nav.startTab(wide: wide());

  /// Whether a content tab (Home or Todo) is what the panes show (#712).
  bool get contentTabShows =>
      wide() && nav.contentTab != null && nav.tab == nav.contentTab;

  /// Which pane draws [ShellNavigationState.contentTab]: the one it opened
  /// in, or pane 0 when the window is not split and that pane is not on
  /// screen.
  int get contentPaneShown => workspace.value.isSplit ? nav.contentPane : 0;

  /// Takes [layout] as the navigation (#536). The first one read opens
  /// the shell on its start destination ([openOnStart]). A tab it hides
  /// from under the user — the tab on screen when another device hides
  /// it — gives way to [startTab]; a note on screen stays, and its back
  /// lands there. A hidden tab opened on purpose stays.
  void setNavigation(NavigationLayout layout) {
    final first = nav.layout == null;
    final wasShown = nav.shown(nav.tab);
    update(() => nav.place(layout));
    if (first && !nav.requested) return openOnStart();
    if (!wasShown || nav.shown(nav.tab)) return;
    final home = startTab;
    nav.hiddenReturn = home;
    if (!selection.treeVisible) {
      if (!nav.shown(nav.noteFrom)) nav.noteFrom = home;
      return;
    }
    select(home);
  }

  /// A feature was switched (#1109), here or on another device: the
  /// destinations are placed again, a tab whose feature went off gives way
  /// as a hidden one does, and everything that asks the features is built
  /// again.
  void featuresChanged() {
    if (!mounted()) return;
    if (nav.layout case final layout?) return setNavigation(layout);
    update(nav.place);
  }

  /// Opens the shell on the layout's start destination (#706), where a
  /// library opens and where the app comes back to after a restart. A
  /// note already on screen — a widget's, a link's from outside — stays:
  /// a wide window keeps it on Files, a phone's back lands on the start.
  void openOnStart() {
    final start = startTab;
    nav.hiddenReturn = start;
    if (!selection.treeVisible) {
      if (!wide()) nav.noteFrom = start;
      return;
    }
    select(start);
  }

  /// Leaves the hidden tab on screen for the one it was opened from, or
  /// the start destination when that one has been hidden since: as a tap
  /// on it, so the quick note comes back as a note, not as its empty tab.
  void leaveHiddenTab() {
    destinationSelected(
      nav.shown(nav.hiddenReturn) ? nav.hiddenReturn : startTab,
    );
  }

  /// Shows [tab] in [pane] (#712), where it is already open or not; the
  /// tree and dock stay put.
  void showContentTab(ShellTab tab, int pane) {
    // The deck behind is excluded from focus while the page covers it
    // (#1074), which lets go of the editor's keys (#770).
    reviewTab.show(on: false);
    update(() {
      compare.hide();
      nav.pin(tab, pane);
      workspace.focus(pane);
      noteFade.closed();
    });
  }

  /// Closes the pinned content tab (#712): the tree keeps the rail.
  void closeContentTab() => update(nav.closeContent);

  /// The window crossed from narrow to wide (#770). A phone keeps the
  /// Home and the Todo list as whole destinations, where a wide window
  /// pins them in a pane: the one on screen becomes that pinned tab, or
  /// the panes would show neither it nor the notes.
  void becameWide() {
    final tab = nav.tab;
    if ((tab == ShellTab.home || tab == ShellTab.todo) &&
        nav.contentTab != tab) {
      nav
        ..contentTab = tab
        ..contentPane = workspace.value.focused;
    }
  }

  /// Closes the full-screen note: returns to the tab it was opened from,
  /// with its tree/body visible (the note stays highlighted). A book read
  /// in full screen (#621) only leaves full screen: Back steps out of it
  /// first.
  void closeNote() {
    if (fullScreen.value != null) {
      fullScreen.value = null;
      return;
    }
    selection.close();
    logNextFrame('shell', 'note close first frame');
  }

  /// A tap on the rail or the bottom bar.
  void destinationSelected(ShellTab tab) {
    const AppLogger(name: 'shell').debug('tap tab: ${tab.name}');
    if (tab == ShellTab.quickNote) {
      unawaited(openQuickNote());
      return;
    }
    // A wide window opens Settings over the note instead of in its place
    // (#202); the phone keeps it as a tab.
    if (tab == ShellTab.settings && wide()) return openSettings();
    // Tapping the tab a note was opened from closes the note: the tab is
    // already selected, so nothing else would happen.
    if (tab == nav.tab && !selection.treeVisible) return closeNote();
    select(tab);
  }

  /// Selects [tab]; a full-screen note closes to its tree (the selected
  /// note stays highlighted).
  void select(ShellTab tab) {
    if (nav.tab == tab) return;
    // The switch is logged so a slow frame in an exported log can be
    // attributed to a tab rather than guessed at: the reported stutter is
    // specific to Search, and until this line existed nothing in the log
    // said when Search was entered.
    const AppLogger(name: 'shell').debug('tab: ${nav.tab.name} -> ${tab.name}');
    // A kept-alive search field would otherwise hold focus (and the
    // keyboard) on the next tab: disposing used to drop it for free.
    FocusManager.instance.primaryFocus?.unfocus();
    // Put it back on the shell so the next accelerator still reaches the
    // bindings (T-PP-10).
    shellFocus.requestFocus();
    // #46 fast path: on the phone, a plain switch (no fullscreen note in the
    // way, the FAB menu closed, the target already mounted) changes nothing
    // the kept-alive bodies read, so it only moves the visible-tab notifier
    // the chrome and the body stack listen to. The bodies keep their
    // instances and Element.update skips their subtrees, instead of a
    // shell-wide rebuild re-running every mounted body's build (12-24 ms of
    // `build` per switch in the device log). A fullscreen note to close, a
    // first mount, or the open FAB all still fall to the full setState.
    // A hidden tab on either side of the switch changes the back key's
    // meaning (#536), which only a rebuild hands the layout.
    final narrow = !wide();
    // Home and Todo are content destinations on a wide window (#712):
    // they open as a pinned tab in the focused pane and the tree, the
    // panes and the dock stay, instead of taking a whole slot.
    if (!narrow && (tab == ShellTab.home || tab == ShellTab.todo)) {
      reviewTab.show(on: false);
      update(() {
        // The page it shows covers the compare tab's: that tab stays on
        // its chip (#906).
        compare.hide();
        nav.pin(tab, workspace.value.focused);
        noteFade.closed();
      });
    } else if (narrow &&
        selection.treeVisible &&
        !fab.expanded &&
        nav.visited.contains(tab) &&
        nav.shown(nav.tab) &&
        nav.shown(tab)) {
      noteFade.closed();
      nav.tab = tab;
    } else {
      update(() {
        nav.visit(tab);
        selection.showTree();
        fab.collapse();
        // A sidebar view has no island of its own: picking Search shows
        // the sidebar island it lives in (#712).
        if (!narrow && (tab == ShellTab.search || tab == ShellTab.study)) {
          selection.showSidebar();
        }
        // Leaving any open note: the tabs show at once (issue #4).
        noteFade.closed();
      });
    }
    // Time-to-visible of the switch itself: the 'tap tab' line above is the
    // input, this is when the first new frame actually painted (with the
    // navigation-bar selection animation the user said lags on Search).
    logNextFrame('shell', 'tab ${tab.name} first frame');
    // #48: the frames after that first one, attributed to this switch. The
    // shared slow-frame log flushes in batches, so a switch could never be
    // told apart from the one before it.
    FrameProbe.watch('shell', 'tab ${tab.name} frames');
    // T-TS-09 marker: brackets the fade so a slow frame can be attributed
    // to the switch itself (before it) or to what settles after it. Only
    // the latest switch reports: a rapid double-tap's stale marker would
    // misattribute the frames.
    final settled = tab;
    unawaited(
      Future<void>.delayed(TabBodyStack.fade + const Duration(milliseconds: 20))
          .then((_) {
            if (mounted() && nav.tab == settled) {
              const AppLogger(name: 'shell')
                  .debug('tab fade settled: ${settled.name}');
            }
          }),
    );
  }
}
