import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_workspace.dart';

/// A row of the tree, or a tile of the Files pane, opened (#23, #727,
/// #1256): a click in place of the tab's note, a double click or a
/// Ctrl+click in a tab of its own, a folder selected.
final class ShellTreeOpen {
  /// Opens the tree's rows through [selection] and [workspace].
  new({
    required this.selection,
    required this.workspace,
    required this.nav,
    required this.clock,
    required this.wide,
    required this.desktop,
    required this.panesShowNotes,
    required this.notePreview,
    required this.update,
  });

  /// What is selected and what shows.
  final ShellSelection selection;

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// Where the shell is.
  final ShellNavigationState nav;

  /// Now, for telling a double click (#437): a test scripting two clicks
  /// decides the gap between them rather than racing the machine.
  final DateTime Function() clock;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// Whether this is a desktop, where a click on a note puts the caret in
  /// it (#727).
  final bool Function() desktop;

  /// Whether a note opened now would land in a pane the user can see.
  final bool Function() panesShowNotes;

  /// Whether the note on screen shows its preview.
  final bool Function() notePreview;

  /// The shell's `setState`.
  final void Function(VoidCallback change) update;

  /// The tree's last plain click on a note, for telling a double click:
  /// the note, when, and what the tab showed before it.
  ({String path, DateTime at, String? replaced})? _lastClick;

  /// [note] picked in the tree; on a wide window in a tab of its own when
  /// [newTab].
  void pick(Note note, {bool newTab = false}) {
    // A note opening in preview-only has no editable for the IME.
    if (!note.isDir && notePreview()) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    if (wide()) {
      // A folder leaves the tabs alone: the note stays on screen.
      if (note.isDir) return selection.selectFolder(note.path);
      show(note.path, newTab: newTab);
    }
    selection.pick(note.path, isDir: note.isDir);
  }

  /// A row or a tile activated in the Files pane (#727): the note opens as
  /// it does from anywhere else, and on a desktop it also takes the caret.
  /// A click on a note is an invitation to write in it, and the pane is
  /// not where the keyboard should end up: the row's own click leaves the
  /// keys where they are for a note, and this is what puts them in it.
  void fromPane(Note note) {
    if (!note.isDir && desktop()) selection.requestCaret(note.path);
    pick(note);
  }

  /// Shows the note at [path] from the tree, on the wide layout (#23 and
  /// the 0.0.8 test round).
  ///
  /// - A click shows it in place of the tab's note.
  /// - Ctrl+click, a middle click ([newTab]) or a double click opens it
  ///   in a tab of its own. A double click starts as a click, so its
  ///   second half puts back what the first replaced, then opens the note
  ///   beside it. Waiting to tell the two apart instead would make every
  ///   single click late.
  void show(String path, {required bool newTab}) {
    // A note shows in the panes on a wide window: a content tab painting
    // over them (#712) or another destination would leave it out of
    // sight, as a note opened from the search is brought forward.
    if (wide() && !panesShowNotes()) {
      update(() => nav.visit(ShellTab.files));
    }
    final keys = HardwareKeyboard.instance;
    final now = clock();
    final last = _lastClick;
    _lastClick = null;
    if (newTab || keys.isControlPressed || keys.isMetaPressed) {
      workspace.show(path, newTab: true);
      return;
    }
    if (last != null &&
        last.path == path &&
        now.difference(last.at) <= kDoubleTapTimeout) {
      // The first click already showed the note, in a tab of its own; the
      // tab it replaced comes back beside it, and nothing else is shown or
      // recreated (#1076).
      if (last.replaced case final replaced?) {
        workspace.reopenBeforeShowing(replaced);
      }
      workspace.show(path, newTab: true);
      return;
    }
    final before = workspace.value.activePath;
    workspace.show(path);
    _lastClick = (
      path: path,
      at: now,
      replaced: before == path ? null : before,
    );
  }
}
