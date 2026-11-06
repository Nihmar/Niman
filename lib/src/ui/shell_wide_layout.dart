import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/dock/right_dock.dart';
import 'package:niman/src/ui/hidden_slot.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/resize_divider.dart';
import 'package:niman/src/ui/shell_compare_tab.dart';
import 'package:niman/src/ui/shell_dock.dart';
import 'package:niman/src/ui/shell_files_pane.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_quick_note.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_tab_bodies.dart';
import 'package:niman/src/ui/shell_tab_rows.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/shell_wide_body.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/shell_zen.dart';
import 'package:niman/src/ui/tab_body_stack.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The wide window's layout (#1256): its kept-alive slots, the tabs'
/// place in the title bar, the dividers and the widths they leave the
/// panes, where a study opens beside its deck, and what Back steps out of
/// first.
final class ShellWideLayout {
  /// The layout of the wide shell.
  new({
    required this.nav,
    required this.tabs,
    required this.quickNote,
    required this.wideBody,
    required this.bodies,
    required this.settings,
    required this.selection,
    required this.dock,
    required this.immersive,
    required this.reviewTab,
    required this.compare,
    required this.workspace,
    required this.files,
    required this.tabRows,
    required this.wide,
    required this.context,
  });

  /// Where the shell is: the tab on screen.
  final ShellNavigationState nav;

  /// The moves between destinations, and the content tab pinned.
  final ShellTabSwitch tabs;

  /// The quick note's chooser.
  final ShellQuickNote quickNote;

  /// The wide shell's body: the islands of Files.
  final ShellWideBody Function() wideBody;

  /// The other tabs' bodies.
  final ShellTabBodies bodies;

  /// The library's settings: the tree's and the dock's widths.
  final ShellSettings settings;

  /// Whether the sidebar shows.
  final ShellSelection selection;

  /// The right dock.
  final ShellDock dock;

  /// The book read in full screen.
  final ShellImmersive immersive;

  /// The study beside the deck (#533).
  final ReviewTab reviewTab;

  /// A version beside the note (#712).
  final ShellCompareTab compare;

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// The Files pane, whose grid Back steps up.
  final ShellFilesPane files;

  /// The rows of note tabs.
  final ShellTabRows tabRows;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// Where the window is measured.
  final BuildContext Function() context;

  /// The wide layout's tab slots: the tree + detail split for Files (and
  /// for an open quick note, which lives in the detail pane — its tab
  /// body is empty by design), then one slot per remaining tab.
  ///
  /// Bodies are kept mounted exactly like the narrow stack
  /// ([TabBodyStack]): the tree/detail pair shares ONE slot across Files
  /// and the open quick note, so a tab switch never re-runs the tree's
  /// per-level queries or re-inflates the open editor. The 2026-09-10
  /// desktop log showed the cost of the old swap-in/swap-out: 6-9 ms tree
  /// flattens, 28 ms Search and 62 ms Settings first builds, every switch.
  List<Widget> slots(LibrarySession controller) {
    return [
      _slot(
        visible: filesSlotVisible,
        child: wideBody().build(context(), controller),
      ),
      // One slot per remaining tab, in tab order so a slot's identity
      // never moves. Unvisited tabs build the empty placeholder
      // [ShellTabBodies.bodyFor] returns. Search has no slot on a wide
      // window: it lives in the sidebar island (#712).
      for (final tab in ShellTab.values)
        if (tab != ShellTab.files &&
            tab != ShellTab.quickNote &&
            !(tab == ShellTab.search && wide()) &&
            // So has Study (#533).
            !(tab == ShellTab.study && wide()) &&
            // Home and Todo are content destinations on a wide window
            // (#712): they live in a pane, not in a slot of their own.
            !(wide() && (tab == ShellTab.home || tab == ShellTab.todo)))
          _slot(
            visible: nav.tab == tab,
            retainLayout: tab == ShellTab.search,
            child: _islandSlot(bodies.bodyFor(tab, controller)),
          ),
      // The quick-note chooser: empty while its note is open in the slot
      // above, the choose/create screen otherwise.
      _slot(
        visible: nav.tab == ShellTab.quickNote && quickNote.choosing,
        child: _islandSlot(bodies.bodyFor(ShellTab.quickNote, controller)),
      ),
    ];
  }

  /// Whether the wide layout shows the tree and the panes: Files, an open
  /// quick note, which lives in the panes, or the search sidebar, which
  /// swaps what the left island shows and leaves the panes in place
  /// (#712).
  bool get filesSlotVisible =>
      nav.tab == ShellTab.files ||
      (wide() && nav.tab == ShellTab.search) ||
      sidebarShowsStudy ||
      tabs.contentTabShows ||
      (nav.tab == ShellTab.quickNote && !quickNote.choosing);

  /// Whether the left island shows the search in place of the tree
  /// (#712): Search is a sidebar view on a wide window, so the panes and
  /// the dock stay beside it. A phone keeps Search as a destination.
  bool get sidebarShowsSearch => wide() && nav.tab == ShellTab.search;

  /// Whether the left island shows the Study tree in place of the tree
  /// (#533), as it shows the search.
  bool get sidebarShowsStudy => wide() && nav.tab == ShellTab.study;

  /// Whether a sidebar view holds the left island instead of the tree.
  bool get sidebarShowsView => sidebarShowsSearch || sidebarShowsStudy;

  /// A tab's screen on the wide layout: one island on the base, as the
  /// tree, the panes and the dock are on Files. No band above it: the
  /// title bar sits on the islands, its own room under the tab the 4 px
  /// the tab row shows there (#749).
  Widget _islandSlot(Widget body) => Padding(
    padding: const EdgeInsets.fromLTRB(Island.gap, 0, Island.gap, Island.gap),
    child: Island(child: body),
  );

  /// One kept-alive wide-layout slot. Hidden slots skip layout, paint and
  /// tickers (see [TabBodyStack], [HiddenSlot]); [retainLayout] keeps an
  /// expensive one laid out, so showing it is paint-only.
  Widget _slot({
    required bool visible,
    required Widget child,
    bool retainLayout = false,
  }) {
    final slot = TickerMode(enabled: visible, child: child);
    if (retainLayout) {
      return Visibility(
        visible: visible,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: ExcludeFocus(excluding: !visible, child: slot),
      );
    }
    return HiddenSlot(hidden: !visible, child: slot);
  }

  /// The tabs in the title bar (#23), with the unsaved dot of every note
  /// whose editor holds edits the disk does not have yet.
  Widget tabsRow(Widget dragArea) {
    // The panes end where the dock begins, when it shows (#175), and
    // short of the window's edge by the base around the islands.
    final docked = dock.shown ? dockWidth + ResizeDivider.width : 0;
    return tabRows.row(
      dragArea,
      panesWidth:
          MediaQuery.sizeOf(context()).width - tabsStart - docked - Island.gap,
    );
  }

  /// Where the tabs start in the title bar: the panes' island's left
  /// edge, past the base and the tree's island.
  double get tabsStart =>
      ShellRail.panelStart +
      (selection.sidebarVisible
          ? settings.editor.treeWidth + ResizeDivider.width
          : 0);

  /// Puts a new study beside its deck: in the other pane of a split; in a
  /// pane split off to the right where the window has room for two; over
  /// the deck where it has not, as the compare tab opens.
  void placeReview() {
    final w = workspace.value;
    final docked = dock.shown ? dockWidth + ResizeDivider.width : 0;
    final panes =
        MediaQuery.sizeOf(context()).width - tabsStart - docked - Island.gap;
    if (w.isSplit) {
      reviewTab.pane = 1 - w.focused;
    } else if (panes >= 2 * RightDock.minPanesWidth) {
      // Placed first: the split that follows is no note shown over it.
      reviewTab.pane = 1;
      workspace.controller.update(
        (w) => w.split(SplitAxis.right).focus(w.focused),
      );
    } else {
      reviewTab.pane = w.focused;
    }
  }

  /// The draggable tree/detail divider (T-PP-21). Moves apply live; the
  /// lift persists the width to the library.
  Widget treeDivider({required bool touch}) => ResizeDivider(
    touch: touch,
    key: const Key('tree-divider'),
    onDrag: (dx) => settings.setTreeWidth(settings.editor.treeWidth + dx),
    onDragEnd: () => unawaited(settings.keepTreeWidth()),
  );

  /// The draggable panes/dock divider (#297): the tree's divider on the
  /// dock's edge, so a move to the left widens the dock.
  Widget dockDivider({required bool touch}) => ResizeDivider(
    touch: touch,
    key: const Key('dock-divider'),
    onDrag: (dx) => settings.setDockWidth(_fitDock(dockWidth - dx)),
    onDragEnd: () => unawaited(settings.keepDockWidth()),
  );

  /// The dock's width on screen: the library's, shrunk as far as its
  /// minimum when the window leaves the panes less than their share.
  double get dockWidth => _fitDock(settings.editor.dockWidth);

  /// [width] within the dock's range and within what the window can spare
  /// beside the tree and [RightDock.minPanesWidth] of panes.
  double _fitDock(double width) {
    final room =
        MediaQuery.sizeOf(context()).width -
        tabsStart -
        ResizeDivider.width -
        Island.gap -
        RightDock.minPanesWidth;
    return width.clamp(minDockWidth, room.clamp(minDockWidth, maxDockWidth));
  }

  /// Whether the Files pane shows the grid inside a folder, which Back
  /// steps out of (#727).
  bool get _gridCanStepUp => nav.tab == ShellTab.files && files.gridInFolder;

  /// Whether the system Back has a step to take in the wide shell (#849):
  /// what the phone's Back does in its layout, in the wide one's terms.
  bool get backAvailable =>
      wide() &&
      (dock.overlayShown ||
          tabs.contentTabShows ||
          sidebarShowsView ||
          compare.shows ||
          reviewTab.shows ||
          !workspace.value.focusedPane.isEmpty ||
          _gridCanStepUp);

  /// The wide shell's Back (#849): the topmost thing on screen goes
  /// first — the side panel lying over the note (#977), a book out of full
  /// screen, a pinned Home or Todo, the search sidebar, the open note —
  /// and the grid steps up a folder last. With none of them left Back
  /// leaves the app.
  void back() {
    if (dock.overlayShown) {
      dock.closeOverlay();
    } else if (immersive.fullScreen.value != null) {
      immersive.fullScreen.value = null;
    } else if (reviewTab.shows) {
      reviewTab.close();
    } else if (compare.shows) {
      // The compare page covers the note: it goes before the note (#906).
      compare.close();
    } else if (tabs.contentTabShows) {
      tabs.closeContentTab();
    } else if (sidebarShowsView) {
      tabs.destinationSelected(ShellTab.files);
    } else if (!workspace.value.focusedPane.isEmpty) {
      // A new tab too: it goes as a note's tab does.
      workspace.closeActive();
    } else if (_gridCanStepUp) {
      files.gridUp();
    }
  }
}
