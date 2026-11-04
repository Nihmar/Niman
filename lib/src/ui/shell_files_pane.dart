/// The Files pane (issue #100 moved it out of the shell): the note tree,
/// or the folder grid in its place (#727), and the folder the grid shows.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/expanded_folders.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';
import 'package:niman/src/ui/shell_marked_actions.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/shell_tree_editing.dart';
import 'package:niman/src/ui/shell_tree_menus.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';
import 'package:niman/src/ui/tree.dart';

/// The Files pane: the tree or the grid, and where the grid is.
final class ShellFilesPane {
  /// The pane of the library, drawn from the shell's [settings]
  /// (the order, the view) and [selected] path, with the tree's [expanded]
  /// folders and [focusNode]. A row's press goes to [onSelect] or
  /// [onOpenInNewTab], a folder's chevron to [onToggle]; the menus, the
  /// rows' actions and the rows edited in place are [menus]', [rows]',
  /// [marked]' and [editing]'s. A move of the grid selects its folder
  /// through [selectFolder], in the [update] — the shell's `setState` —
  /// that moves it.
  new({
    required this.ocrQueue,
    required this.settings,
    required this.selected,
    required this.treeFolder,
    required this.expanded,
    required this.focusNode,
    required this.treeActive,
    required this.desktop,
    required this.menus,
    required this.rows,
    required this.marked,
    required this.editing,
    required this.onToggle,
    required this.onSelect,
    required this.onOpenInNewTab,
    required this.selectFolder,
    required this.update,
  });

  /// The recognitions under way, which the rows mark (#594).
  final OcrQueue? ocrQueue;

  /// The library's editor settings: the tree's order and view.
  final ShellEditorSettings Function() settings;

  /// The path selected in the tree, a note or a folder.
  final String? Function() selected;

  /// The folder the tree is on: the selected folder, or the selected
  /// note's folder, or the root.
  final String Function() treeFolder;

  /// The tree's expanded folders.
  final ExpandedFolders expanded;

  /// The tree's keyboard focus (#712).
  final FocusNode focusNode;

  /// Whether the tree's keyboard walk (#727) holds: not while the search
  /// holds the sidebar's slot.
  final bool Function() treeActive;

  /// Whether this is a desktop, whose pointer marks several rows (#712).
  final bool Function() desktop;

  /// The rows' and the empty space's menus.
  final ShellTreeMenus menus;

  /// What a row's rename, delete or drop does.
  final ShellRowActions rows;

  /// What several marked rows do together (#712).
  final ShellMarkedActions marked;

  /// The rows renamed and made in place (#707, #712).
  final ShellTreeEditing editing;

  /// A folder's chevron: expands or collapses `path`.
  final void Function(String path) onToggle;

  /// A row or a tile activated (#727).
  final void Function(Note note) onSelect;

  /// A row or a tile opened in a tab of its own.
  final void Function(Note note) onOpenInNewTab;

  /// Selects the folder at `path` in the tree, and expands it: `''` the
  /// root, which has no row and clears the selection.
  final void Function(String path) selectFolder;

  /// The shell's `setState`: the pane is drawn from the grid's folder.
  final void Function(VoidCallback change) update;

  /// The folder the grid shows (#727): library-relative, `''` the root.
  ///
  /// In memory only, like the tree's expanded set: only the view itself
  /// (list or grid) is remembered. Written through to the tree whenever
  /// it moves — entered folders are selected and expanded there — and
  /// taken from the tree again on every switch to the grid, so the two
  /// never drift apart while the pane is switched.
  String? _gridFolder;

  /// Whether the grid has been shown once for this library (#727): only
  /// from then on is it kept mounted under the tree.
  bool _gridVisited = false;

  /// Whether the Files pane shows the grid rather than the tree.
  bool get gridOn => settings().treeView == TreeView.grid;

  /// The folder the grid shows: where the grid last went, or — before the
  /// pane has been built in the grid, which pins it — the tree's own
  /// folder.
  String get gridStart => _gridFolder ?? treeFolder();

  /// Whether the grid shows a folder inside the library, which Back steps
  /// out of (#727).
  bool get gridInFolder => gridOn && gridStart.isNotEmpty;

  /// Starts the grid in the tree's selection — the selected folder, or the
  /// selected note's folder — as a switch to it does. In the `setState` of
  /// the caller.
  void gridFromTree() => _gridFolder = treeFolder();

  /// The grid's own folder follows a rename or a move of it, or of a
  /// folder above it, from [from] to [to] (#727): F2 with no tile under
  /// the cursor renames the selection, which is the folder shown.
  void moved(String from, String to) {
    final grid = _gridFolder;
    if (grid != null && (grid == from || grid.startsWith('$from/'))) {
      update(() => _gridFolder = to + grid.substring(from.length));
    }
  }

  /// Moves the grid to [path], writing the move through to the tree: the
  /// folder is selected and expanded there, so switching back to the list
  /// finds it open (#727).
  ///
  /// The root has no row to select: going there clears the selection
  /// rather than selecting the path `''`, which every command reading the
  /// selection — F2's rename first — would take for a row of its own.
  void gridGoTo(String path) {
    update(() {
      _gridFolder = path;
      selectFolder(path);
    });
  }

  /// Activates a tile: a folder is entered, a note opens as a tree row
  /// does — and takes the caret (#727).
  void _gridOpen(Note note) {
    if (note.isDir) update(() => _gridFolder = note.path);
    onSelect(note);
  }

  /// The grid's Up, and the phone's Back inside a folder: up one level,
  /// or nothing at the root.
  void gridUp() {
    final at = gridStart;
    if (at.isEmpty) return;
    gridGoTo(parentOf(at));
  }

  /// The tree pane: the action bar and the note tree — the whole body on
  /// phones, the left column on wide screens. Switched to the grid (#727),
  /// it is the same pane: the breadcrumb and the folder's tiles, of
  /// [controller]'s library. [context] is the shell's, where the menus
  /// open.
  ///
  /// Both stay mounted across a switch, like the search beside them
  /// (#712): the tree keeps its expanded rows and its scroll, the grid its
  /// folder and its scroll. The grid is built on its first visit — a
  /// library no one switched to the grid pays no queries for one.
  Widget build(BuildContext context, LibrarySession controller) {
    final gridOn = this.gridOn;
    final showGrid = gridOn || _gridVisited;
    if (gridOn) {
      _gridVisited = true;
      // A library opened in the grid starts it in the tree's selection, as
      // a switch does — once: from then on a note opened from the search,
      // a tab or the palette does not move it.
      _gridFolder ??= treeFolder();
    }
    final sort = settings().treeSort;
    return TourTarget(
      id: TourTargets.tree,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Offstage(
            offstage: gridOn,
            child: NoteTree(
              ocrQueue: ocrQueue,
              controller: controller,
              sort: sort,
              selectedPath: selected(),
              expanded: expanded.folders,
              // The keyboard's walk (#727) lets go while the grid holds the
              // pane, and while the search holds the sidebar's slot.
              active: !gridOn && treeActive(),
              onToggle: onToggle,
              onSelect: onSelect,
              onOpenInNewTab: onOpenInNewTab,
              onLongPress: (note, anchor) =>
                  menus.rowMenu(context, note, anchor),
              onSecondaryTapDown: (note, details) =>
                  menus.rowMenuAt(context, note, details.globalPosition),
              onBackgroundSecondaryTapUp: (details) => unawaited(
                menus.treeBackgroundAt(context, details.globalPosition),
              ),
              onMove: (paths, folder) =>
                  unawaited(marked.moveTo(context, paths, folder)),
              onRename: (path) => unawaited(rows.rename(context, path)),
              onDelete: (path) => unawaited(rows.delete(context, path)),
              // Several rows at once (#712): a pointer's, with keys.
              onMarkedMenu: desktop()
                  ? (paths, anchor) =>
                        unawaited(marked.menu(context, paths, anchor))
                  : null,
              onDeleteMarked: (paths) =>
                  unawaited(marked.delete(context, paths)),
              focusNode: focusNode,
              renaming: editing.renaming,
              creating: editing.creating,
            ),
          ),
          if (showGrid)
            Offstage(
              offstage: !gridOn,
              child: FolderGrid(
                ocrQueue: ocrQueue,
                controller: controller,
                folder: gridStart,
                active: gridOn,
                sort: sort,
                selectedPath: selected(),
                onOpen: _gridOpen,
                onGoTo: gridGoTo,
                onUp: gridUp,
                onFolderResolved: (path) => update(() => _gridFolder = path),
                onLongPress: (note, anchor) =>
                    menus.rowMenu(context, note, anchor),
                onSecondaryTapDown: (note, details) =>
                    menus.rowMenuAt(context, note, details.globalPosition),
                onOpenInNewTab: onOpenInNewTab,
                onBackgroundSecondaryTapUp: (folder, details) => menus
                    .gridBackgroundAt(context, folder, details.globalPosition),
                onMove: (paths, folder) =>
                    unawaited(marked.moveTo(context, paths, folder)),
                onRename: (path) => unawaited(rows.rename(context, path)),
                onDelete: (path) => unawaited(rows.delete(context, path)),
                renaming: editing.renaming,
              ),
            ),
        ],
      ),
    );
  }
}
