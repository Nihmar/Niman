import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/shell_compare_tab.dart';
import 'package:niman/src/ui/shell_note_kind.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/workspace/workspace.dart';

/// What the shell does when the workspace moves (#23, #1256): a tab shown,
/// closed, renamed. On a wide window the selection follows the showing
/// tab; a note shown where a page covered the pane takes it back; and the
/// shell rebuilds only for what it draws.
final class ShellWorkspaceFollow {
  /// Follows [workspace] into [selection].
  new({
    required this.workspace,
    required this.selection,
    required this.compare,
    required this.reviewTab,
    required this.reviewPane,
    required this.kind,
    required this.wide,
    required this.update,
    required this.mounted,
  });

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// What is selected and what shows.
  final ShellSelection selection;

  /// The version beside the note (#906).
  final ShellCompareTab compare;

  /// The study beside the deck (#533).
  final ReviewTab reviewTab;

  /// Which pane draws the study.
  final int Function() reviewPane;

  /// The open notes' kinds: a newly shown note is asked its kind afresh.
  final ShellNoteKind kind;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// The shell's `setState`.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// [shapeOf] when [changed] last rebuilt.
  String? _lastShape;

  /// The showing tab when [changed] last looked.
  String? _lastShown;

  /// The pane that draws the study beside the deck and the note it shows,
  /// when [changed] last looked (#533).
  ({int pane, String? path})? _lastReviewPane;

  /// Starts following the workspace.
  void attach() => workspace.controller.addListener(changed);

  /// Stops following it.
  void detach() => workspace.controller.removeListener(changed);

  /// What of [w] the shell draws from, as one comparable value.
  static String shapeOf(Workspace w) => [
    w.dockOpen,
    w.dockPane.name,
    w.focused,
    w.axis.name,
    w.isSplit,
    w.fraction,
    for (final pane in w.panes) ...[
      pane.active,
      for (final tab in pane.tabs)
        [
          tab.path,
          tab.memento.editorKind,
          tab.memento.preview,
          tab.missing,
        ].join('|'),
    ],
  ].join('\n');

  /// The workspace moved. On a wide window the tree follows the showing
  /// tab, and a newly shown note is asked its kind afresh.
  void changed() {
    if (!mounted()) return;
    final shown = workspace.value.activePath;
    final moved = shown != _lastShown;
    _lastShown = shown;
    // A note shown in the pane the compare tab covers takes the pane back
    // (#906); the same for the study beside the deck (#533).
    final compareCovered = compare.coveredByWorkspace();
    final panes = workspace.value.panes;
    final review = reviewPane();
    final reviewNow = (
      pane: review,
      path: review < panes.length ? panes[review].activeTab?.path : null,
    );
    if (reviewTab.shows &&
        _lastReviewPane?.pane == review &&
        _lastReviewPane?.path != reviewNow.path) {
      reviewTab.show(on: false);
    }
    _lastReviewPane = reviewNow;
    // A caret or a scroll handed in changes nothing drawn here: only the
    // tabs, which listen for themselves. The shell rebuilds for what it
    // draws — tabs, panes, and how each tab shows its note.
    final shape = shapeOf(workspace.value);
    if (!moved && !compareCovered && shape == _lastShape) return;
    _lastShape = shape;
    update(() {
      if (compareCovered) compare.hide();
      if (!wide()) return;
      if (moved) kind.reset();
      selection.follow(shown);
    });
  }
}
