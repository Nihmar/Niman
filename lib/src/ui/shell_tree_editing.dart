/// A name typed in a row of the Files pane (issue #100): the row being
/// renamed in place (#707) and the row being made (#712), each waiting for
/// its field.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/ui/expanded_folders.dart';
import 'package:niman/src/ui/tree_create_row.dart';
import 'package:niman/src/ui/tree_row_tile.dart';

/// The Files pane's rows in edit: one renamed, one being made.
final class ShellTreeEditing {
  /// Edits in place while [paneOnScreen] says the pane's own rows are on
  /// screen; [gridFolder] is the folder the grid shows, null while the
  /// pane is the tree. A row revealed opens its folders in [expanded], a
  /// name typed renames through [renameTo], and every change goes through
  /// [update], the shell's `setState`, while [mounted] holds.
  new({
    required this.expanded,
    required this.paneOnScreen,
    required this.gridFolder,
    required this.renameTo,
    required this.update,
    required this.mounted,
  });

  /// The tree's expanded folders: a row edited in place is revealed.
  final ExpandedFolders expanded;

  /// Whether the pane's own rows are on screen to edit: on Linux and
  /// Windows, a wide window, the sidebar showing the pane — not the search
  /// view it may hold instead (#712).
  final bool Function() paneOnScreen;

  /// The folder the grid shows (#727), or null while the pane is the tree.
  final String? Function() gridFolder;

  /// Renames the row at `path` to `name`: null when it was, else the
  /// problem to show under the field.
  final Future<String?> Function(String path, String name) renameTo;

  /// The shell's `setState`: the pane is drawn from these rows.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// The row being made in the tree, and the name it waits for (#712).
  ({String folder, bool isDir, String initial, Completer<String?> name})?
  _creating;

  /// The row being renamed in place in the tree (#707), or null.
  String? _renaming;

  /// Asks for a new item's name in a row of the tree, under [folder], as
  /// a rename in place does: on Linux and Windows, with the tree on screen
  /// (#712). Null leaves it to the dialog.
  Future<String?>? nameInPlace({
    required String folder,
    required bool isDir,
    required String initial,
  }) {
    if (!paneOnScreen() || gridFolder() != null) return null;
    _creating?.name.complete(null);
    final name = Completer<String?>();
    update(() {
      expanded.addWithAncestors(folder);
      _creating = (folder: folder, isDir: isDir, initial: initial, name: name);
    });
    return name.future;
  }

  /// What the made row's field does: the name typed, or none.
  TreeCreate? get creating => switch (_creating) {
    final creating? => (
      folder: creating.folder,
      isDir: creating.isDir,
      initial: creating.initial,
      submit: (typed) async {
        _endCreating(typed);
        return null;
      },
      cancel: () => _endCreating(null),
    ),
    null => null,
  };

  void _endCreating(String? name) {
    final creating = _creating;
    if (creating == null) return;
    if (mounted()) update(() => _creating = null);
    if (!creating.name.isCompleted) creating.name.complete(name);
  }

  /// Starts renaming [path] in its tree or grid row (#707): on Linux and
  /// Windows, with the pane on screen. The row is revealed — every folder
  /// above it opened — and its name becomes a field. False leaves the
  /// rename to a dialog: a phone, a desktop with the pane hidden, or a
  /// grid tile outside the folder the grid shows.
  bool startRename(String path) {
    // Renaming happens in the pane's own row: the sidebar has to be
    // showing it, not the search view it may hold instead (#712).
    if (!paneOnScreen()) return false;
    if (gridFolder() case final grid?) {
      // The tile has to be in the folder shown; the folder itself has no
      // tile, so renaming it stays a dialog (#727).
      if (parentOf(path) != grid) return false;
      update(() => _renaming = path);
      return true;
    }
    update(() {
      expanded.addWithAncestors(parentOf(path));
      _renaming = path;
    });
    return true;
  }

  /// What the renamed row's field does.
  TreeRename? get renaming => switch (_renaming) {
    final path? => (
      path: path,
      submit: (name) async {
        final problem = await renameTo(path, name);
        if (problem == null && mounted()) update(() => _renaming = null);
        return problem;
      },
      cancel: () {
        if (mounted()) update(() => _renaming = null);
      },
    ),
    null => null,
  };
}
