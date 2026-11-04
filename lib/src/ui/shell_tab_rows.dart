/// The wide shell's rows of note tabs (#23; issue #100 moved them out of
/// the shell): one per pane, divided where the panes divide, with the
/// pinned chips at their far end and, where the panes head their own row,
/// the sidebar's and the dock's toggles and the history's arrows (#1134).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/pane_split.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/shell_note_history.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/tab_drag.dart';
import 'package:niman/src/ui/tab_row_lead.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The tab rows over [workspace]'s panes.
final class ShellTabRows {
  /// The rows of [workspace]'s tabs, redrawn on [changes]. A tab shown in
  /// a pane through [activate] first has [takePane] clear what covers that
  /// pane; [chipCovers] says when a pinned chip, of [chips], is what a pane
  /// shows instead. The rest is what the rows carry.
  new({
    required this.workspace,
    required this.changes,
    required this.history,
    required this.unsaved,
    required this.chipCovers,
    required this.chips,
    required this.activate,
    required this.takePane,
    required this.onTabAction,
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.dockToggle,
  });

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// What the rows redraw on: the workspace and the unsaved tracker.
  final Listenable changes;

  /// Back and forward through the notes shown (#700).
  final NoteHistoryNavigator history;

  /// The open notes holding unsaved edits, library-relative.
  final Set<String> Function() unsaved;

  /// Whether something pinned covers the notes of `pane`.
  final bool Function(int pane) chipCovers;

  /// The pinned chips at the end of `pane`'s row: a study, a version, a
  /// content tab (#712).
  final List<Widget> Function(int pane) chips;

  /// Shows the tab at `index` of `pane`.
  final void Function(int pane, int index) activate;

  /// `pane` is about to show one of its own tabs.
  final void Function(int pane) takePane;

  /// A tab menu's note action, on the note at `path` (#712).
  final void Function(String path, NoteTabAction action, Rect anchor)
  onTabAction;

  /// Whether the tree's island shows.
  final bool Function() sidebarVisible;

  /// Shows or hides the tree's island.
  final VoidCallback onToggleSidebar;

  /// The dock's button.
  final Widget Function() dockToggle;

  /// The open notes' tabs over panes [panesWidth] wide, with [filler]
  /// past them. Split right, the row divides at the same x as the panes
  /// do, so nothing moves when the window splits (the Split mockup). With
  /// [chrome] — the panes heading their own row — it carries the panels'
  /// toggles and the history's arrows too (#1134).
  Widget row(
    Widget filler, {
    required double panesWidth,
    bool chrome = false,
  }) => ListenableBuilder(
    listenable: changes,
    builder: (context, _) {
      final w = workspace.value;
      if (!w.isSplit || w.axis == SplitAxis.down) {
        return pane(0, filler, chrome: chrome);
      }
      final detail = panesWidth - PaneSplit.dividerWidth;
      return Row(
        children: [
          SizedBox(
            width: detail * w.fraction + PaneSplit.dividerWidth,
            child: pane(0, filler, chrome: chrome),
          ),
          Expanded(child: pane(1, filler, chrome: chrome)),
        ],
      );
    },
  );

  /// [index]'s tab row, headed — with [chrome] — by the sidebar's toggle
  /// and the history's arrows on the first pane, and ended by the dock's
  /// toggle on the row's last pane (#1134): where Obsidian has them, and
  /// where a thumb finds them with a note open or not.
  Widget pane(int index, Widget filler, {bool chrome = false}) {
    final tabs = _paneTabsOnly(index, filler);
    if (!chrome) return tabs;
    final w = workspace.value;
    final shown = workspace.history;
    final last = w.isSplit && w.axis == SplitAxis.right ? 1 : 0;
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          if (index == 0)
            TabRowLead(
              sidebarVisible: sidebarVisible(),
              onToggleSidebar: onToggleSidebar,
              arrows: constraints.maxWidth >= TabRowLead.arrowsRoom,
              onBack: history.backTarget == null
                  ? null
                  : () => unawaited(history.back()),
              onForward: shown.next == null
                  ? null
                  : () => unawaited(history.forward()),
            ),
          Expanded(child: tabs),
          if (index == last) dockToggle(),
        ],
      ),
    );
  }

  /// [pane]'s tabs, with the pinned chips (#712) at their end when that
  /// pane holds any.
  Widget _paneTabsOnly(int pane, Widget filler) {
    final w = workspace.value;
    final tabs = w.panes[pane];
    final bar = NoteTabBar(
      key: ValueKey('pane-tabs-$pane'),
      tabs: tabs.tabs,
      // A note tab does not read as selected while the content tab shows:
      // the chip is what the pane is showing.
      active: chipCovers(pane) ? -1 : tabs.active,
      focused: !w.isSplit || w.focused == pane,
      unsaved: unsaved(),
      onActivate: (index) => activate(pane, index),
      onClose: (index) => workspace.close(pane, index),
      onNew: () {
        takePane(pane);
        workspace
          ..focus(pane)
          ..newTab();
      },
      onSplit: w.isSplit
          ? null
          : (index, axis) => workspace.splitWith(pane, index, axis),
      onMoveToOtherPane: w.isSplit
          ? (index) => workspace.moveToOtherPane(pane, index)
          : null,
      pane: pane,
      onDrop: (drag, at) => _dropTab(drag, pane, at),
      filler: filler,
      onTabAction: (index, action, anchor) =>
          onTabAction(tabs.tabs[index].path, action, anchor),
    );
    final pinned = chips(pane);
    if (pinned.isEmpty) return bar;
    // At the row's far end, where it comes and goes without moving a note
    // tab under the pointer (#770). The chips take what the tab bar's own
    // buttons leave, no more: a narrow pane (a tablet's, beside the tree
    // and the dock) cuts the chips' names rather than squeeze the bar
    // below its buttons (#927).
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipsRoom = math.max<double>(
          0,
          constraints.maxWidth -
              NoteTabBar.minWidth(touch: thumbDense(Theme.of(context))),
        );
        return Row(
          children: [
            Expanded(child: bar),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: chipsRoom),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (final chip in pinned) Flexible(child: chip)],
              ),
            ),
          ],
        );
      },
    );
  }

  /// A tab dropped in [pane]'s row, at [at] (#204): dragged along its own
  /// row it is reordered, dragged from the other pane it moves here — and
  /// lands where it was dropped, not at the end.
  void _dropTab(TabDrag drag, int pane, int at) {
    if (drag.pane == pane) {
      // The place is read in the row as it is now, and removing the tab
      // shifts everything after it one to the left.
      workspace.reorder(pane, drag.index, at > drag.index ? at - 1 : at);
      return;
    }
    workspace.moveTabHere(drag.pane, drag.index, pane, at);
  }

  /// A tab dropped on [pane]'s body (#204): into the pane, or a split
  /// with it when the drop was near the edge of an unsplit window.
  void dropOnPane(TabDrag drag, int pane, TabDropKind kind) {
    final axis = tabDropAxis(kind);
    if (axis == null) {
      if (drag.pane == pane) return;
      workspace.moveTabHere(drag.pane, drag.index, pane, null);
      return;
    }
    workspace.splitWith(drag.pane, drag.index, axis);
  }
}
