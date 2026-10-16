/// The right dock and the phone's panel sheets, split out of `shell.dart`
/// for #710: whether the window has room for the dock (#175), which pane
/// it shows, the button that opens it, the overlay a window without room
/// gets instead of the docked panel, and the sheet a phone gets instead
/// of it.
///
/// The shell keeps the width it takes on screen (`_dockWidth` and the
/// divider that drags it): that is the library's `dockWidth` setting,
/// which the tree's own divider shares.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/dock/dock_toggle.dart';
import 'package:niman/src/ui/dock/dock_toggles.dart';
import 'package:niman/src/ui/dock/history_dock_pane.dart';
import 'package:niman/src/ui/dock/links_dock_pane.dart';
import 'package:niman/src/ui/dock/outline_dock_pane.dart';
import 'package:niman/src/ui/dock/right_dock.dart';
import 'package:niman/src/ui/dock/spelling_dock_pane.dart';
import 'package:niman/src/ui/dock/tags_dock_pane.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/outline_panel.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The dock's room, state and widgets, as the shell drives them.
final class ShellDock {
  /// Creates the dock of the open library.
  ///
  /// [windowWidth] is the window's logical width now, [wide] whether the
  /// layout is the wide one, and [panelNote] the note the dock speaks
  /// for (the focused pane's on a wide window, the shown one on a phone).
  new({
    required this.workspace,
    required this.controller,
    required this.windowWidth,
    required this.wide,
    required this.panelNote,
    required this.journalBrowser,
    required this.onOpenHistory,
    required this.onOpenNoteFromLink,
    required this.onChanged,
    this.onOpenVersion,
  });

  /// The notes that are open, whose active one the dock follows.
  final ShellWorkspace workspace;

  /// The open library: the tag source, the ops its history pane reads.
  final LibrarySession controller;

  /// The window's width in logical pixels.
  final double Function() windowWidth;

  /// Whether the wide layout is up.
  final bool Function() wide;

  /// The note the dock speaks for, or null.
  final NoteViewHandle? Function() panelNote;

  /// The journal's calendar, the one pane that is the library's.
  final Widget Function(BuildContext context) journalBrowser;

  /// Opens the history of a path (the history pane's list).
  final void Function(String path) onOpenHistory;

  /// Opens a version of a note compared with it, as a pane's tab (#712).
  final void Function(String path, HistoryVersion version)? onOpenVersion;

  /// Opens the note at a path, from a link in the tags pane.
  final void Function(String path) onOpenNoteFromLink;

  /// Called when what the dock shows changed without the workspace
  /// saying so: the overlay opened or closed.
  final VoidCallback onChanged;

  /// Whether the panel was asked for over the note, on a window without
  /// room for it beside the note. Not remembered: it is never part of
  /// the saved workspace, so a narrow window at startup (or after a
  /// resize) does not open the panel by itself.
  bool _overlay = false;

  /// The buttons on screen, which the overlay keeps clear.
  final DockToggles toggles = DockToggles();

  /// Whether the window has room for the right dock beside a note (#175):
  /// a desktop, a tablet, a phone in landscape — on the same rule.
  bool get room => windowWidth() >= RightDock.minWindowWidth;

  /// Whether the dock shows beside the note: there is room, and it was
  /// not closed.
  bool get shown => room && workspace.value.dockOpen;

  /// Whether the panel shows over the note instead: a wide layout
  /// without room for the dock, and the panel asked for.
  bool get overlayShown => wide() && !room && _overlay;

  /// Whether the toggle reads as on: the dock open where it docks, the
  /// overlay where it does not.
  bool get on => room ? workspace.value.dockOpen : _overlay;

  /// Drops an overlay request once the window has room again, so that
  /// narrowing it later does not bring the panel back by itself: the
  /// remembered state is the docked one.
  void settle() {
    if (room) _overlay = false;
  }

  /// Closes the overlay, if it is open.
  void closeOverlay() {
    if (!_overlay) return;
    _overlay = false;
    onChanged();
  }

  /// The right dock: the focused pane's note's outline, tags or history.
  /// As the [overlay] its close shuts the overlay and leaves the docked
  /// state as it was, and a note opened from a pane uncovers itself.
  Widget build(BuildContext context, {bool overlay = false}) {
    final w = workspace.value;
    final path = w.activePath;
    // A page opened from a pane lands under the scrim unless the overlay
    // is shut first (#978).
    void shut() {
      if (overlay) closeOverlay();
    }

    void open(String path) {
      shut();
      workspace.show(path);
    }

    return RightDock(
      pane: w.dockPane,
      onPane: (pane) =>
          workspace.controller.update((w) => w.withDock(pane: pane)),
      onClose: overlay
          ? closeOverlay
          : () => workspace.controller.update((w) => w.withDock(open: false)),
      paneBuilder: (pane) =>
          _paneBody(context, pane, open: open, shut: shut, path: path),
    );
  }

  /// What [pane] holds, in the dock or in the sheet that stands for it: one
  /// switch for both, so no pane reaches a surface that shows another.
  /// [open] opens a note from the pane, [shut] clears the pane's own cover
  /// (the overlay, the sheet) before a page opens from it.
  Widget _paneBody(
    BuildContext context,
    DockPane pane, {
    required void Function(String path) open,
    required VoidCallback shut,
    required String? path,
  }) => switch (pane) {
    DockPane.outline => OutlineDockPane(note: panelNote()),
    DockPane.tags => TagsDockPane(
      note: panelNote(),
      tags: controller.tagSource,
      onOpenNote: open,
    ),
    DockPane.links => LinksDockPane(
      note: panelNote(),
      links: controller.linkSource,
      libraryRoot: controller.root,
      onOpenNote: open,
    ),
    DockPane.spelling => SpellingDockPane(note: panelNote()),
    DockPane.history => HistoryDockPane(
      ops: controller.ops,
      path: path,
      onOpenHistory: () {
        if (path == null) return;
        shut();
        onOpenHistory(path);
      },
      onOpenVersion: switch ((onOpenVersion, path)) {
        (final openVersion?, final path?) => (version) {
          shut();
          openVersion(path, version);
        },
        _ => null,
      },
    ),
    DockPane.journal => journalBrowser(context),
  };

  /// Shows or hides the dock (the note row's button, Ctrl+Shift+B): the
  /// docked panel where there is room, the overlay where there is not.
  void toggleOpen() {
    if (room) {
      workspace.controller.update((w) => w.withDock(open: !w.dockOpen));
      return;
    }
    _overlay = !_overlay;
    onChanged();
  }

  /// The note row's dock button. It is always there on the wide layout,
  /// whatever the window's width: a control that shows in only some
  /// states would move the row under a thumb crossing the threshold.
  Widget toggle() =>
      DockToggle(toggles: toggles, on: on, onPressed: toggleOpen);

  /// Opens [pane] for the note: in the dock where it fits, else as a
  /// sheet (the phone's way to the same panes, #175). The outline, as a
  /// pointer's menu, grows from [anchor], the control that asked for it.
  Future<void> showPanel(
    BuildContext context,
    DockPane pane, {
    Rect? anchor,
  }) async {
    if (wide() && room) {
      workspace.controller.update((w) => w.withDock(open: true, pane: pane));
      return;
    }
    final note = panelNote();
    // The journal is the library's, not the note's: it needs no note.
    if (note == null && pane != DockPane.journal) return;
    if (pane == DockPane.outline && note != null) {
      final line = await showOutlineSheet(
        context,
        entries: note.outline.value,
        anchor: anchor,
      );
      if (line != null) note.jumpToHeading(line);
      return;
    }
    // Every other pane is the same body the dock draws, in a sheet of its
    // own: a pane never lands in a sheet made for another one (#1011).
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SizedBox(
        height: MediaQuery.sizeOf(sheet).height * 0.5,
        child: _paneBody(
          sheet,
          pane,
          open: (path) {
            Navigator.pop(sheet);
            onOpenNoteFromLink(path);
          },
          shut: () => Navigator.pop(sheet),
          path: note?.notePath,
        ),
      ),
    );
  }
}
