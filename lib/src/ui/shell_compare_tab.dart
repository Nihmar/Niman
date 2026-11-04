/// A version of a note compared with the note, as a tab of a pane (#712;
/// issue #100 moved it out of the shell): the history's compare on a
/// desktop, beside the dock that lists it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/history/history_flow.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/history/note_version_screen.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/pinned_tab_chip.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// The compare tab: which version, in which pane, and whether it is what
/// that pane shows.
final class ShellCompareTab {
  /// The compare tab of [workspace]'s panes. [unsaved] is saved before a
  /// version opens, so the note is what is on screen; a page opened over
  /// a pane lets [reviewTab]'s study there go, [reviewPane] saying which
  /// pane draws it. Every change goes through [update], the shell's
  /// `setState`, while [mounted] holds.
  new({
    required this.workspace,
    required this.unsaved,
    required this.reviewTab,
    required this.reviewPane,
    required this.update,
    required this.mounted,
  });

  /// The panes the tab sits in.
  final ShellWorkspace workspace;

  /// The open notes' buffers, saved before a version opens.
  final UnsavedTracker unsaved;

  /// The study beside the deck (#533), which a compare page covers.
  final ReviewTab reviewTab;

  /// Which pane draws the study.
  final int Function() reviewPane;

  /// The shell's `setState`: the panes are drawn from this tab.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// The version open, its note, and the pane it opened in.
  ({String path, HistoryVersion version, int pane})? _open;

  /// Whether [_open] is what its pane shows, rather than a note tab.
  bool _shows = false;

  /// The pane that draws the compare tab and the note it shows, when
  /// [coveredByWorkspace] last looked (#906).
  ({int pane, String? path})? _lastPane;

  /// Whether a version is open, shown or behind its chip.
  bool get isOpen => _open != null;

  /// Whether the open version is what its pane shows.
  bool get shows => _shows && _open != null;

  /// Which pane draws the compare tab: the one it opened in, or pane 0
  /// when the window is not split any more.
  int get paneShown => workspace.value.isSplit ? _open?.pane ?? 0 : 0;

  /// Whether [pane] shows the compare tab now.
  bool shownIn(int pane) => shows && pane == paneShown;

  /// Whether [pane] holds the compare tab, shown or behind its chip.
  bool heldIn(int pane) => _open != null && pane == paneShown;

  /// Lets the pane show its note again, the version kept on its chip: in
  /// the `setState` of the caller, which shows something else there.
  void hide() => _shows = false;

  /// Opens [version] of the note at [path] compared with it, in the
  /// focused pane, the open notes saved first so the note is what is on
  /// screen.
  Future<void> open(String path, HistoryVersion version) async {
    try {
      await unsaved.saveAll();
    } on Object catch (e) {
      const AppLogger(name: 'history')
          .warning('compare "$path": saving open notes failed: $e');
    }
    if (!mounted()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    reviewTab.show(on: false);
    update(() {
      _open = (path: path, version: version, pane: workspace.value.focused);
      _shows = true;
    });
  }

  /// Closes the compare tab.
  void close() => update(() {
    _open = null;
    _shows = false;
  });

  /// Whether a note shown in the pane the compare tab covers takes the
  /// pane back (#906), whichever way it was opened: the tree, the search,
  /// a link. A note shown in the other pane of a split leaves it alone.
  /// Asked on every move of the workspace, which this remembers.
  bool coveredByWorkspace() {
    final panes = workspace.value.panes;
    final pane = paneShown;
    final path = pane < panes.length ? panes[pane].activeTab?.path : null;
    // A split opening or closing moves the compare tab to another pane,
    // which is no note opened over it.
    final covered =
        _shows && _lastPane?.pane == pane && _lastPane?.path != path;
    _lastPane = (pane: pane, path: path);
    return covered;
  }

  /// The compare tab's chip, at the end of [pane]'s row (#712): the note
  /// and the version's day, a click shows it again, the ✕ closes it.
  Widget chip(int pane) {
    final compare = _open!;
    final w = workspace.value;
    return PinnedTabChip(
      tabKey: const Key('compare-tab'),
      closeKey: const Key('compare-tab-close'),
      icon: Icons.history,
      label:
          '${p.basename(compare.path)} — '
          '${historyWhen(compare.version.savedAt, DateTime.now())}',
      maxLabelWidth: 240,
      selected: shownIn(pane),
      focused: !w.isSplit || w.focused == pane,
      onTap: () {
        // A study in this pane lets go of it, as it does for a note tab
        // (#976): the page would be drawn under the study otherwise.
        if (pane == reviewPane()) reviewTab.show(on: false);
        update(() => _shows = true);
      },
      onClose: close,
    );
  }

  /// The compare tab's page, in its pane, over the notes: a restore
  /// closes it, offers its undo in [context] and has the note re-read
  /// through [onRestored].
  Widget page(
    BuildContext context,
    LibrarySession controller, {
    required VoidCallback onRestored,
  }) {
    final compare = _open!;
    final ops = controller.ops;
    if (ops == null) return const SizedBox.shrink();
    return NoteVersionScreen(
      key: ValueKey(('compare', compare.path, compare.version.number)),
      ops: ops,
      path: compare.path,
      version: compare.version,
      onRestored: () {
        close();
        offerRestoreUndo(
          context,
          ops: ops,
          path: compare.path,
          restored: compare.version,
          onRestored: onRestored,
        );
      },
    );
  }
}
