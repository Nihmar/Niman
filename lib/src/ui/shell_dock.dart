/// The right dock and the phone's panel sheets, split out of `shell.dart`
/// for #710: whether the window has room for the dock (#175), which pane
/// it shows, the button that opens it, and the sheet a phone gets
/// instead of it.
///
/// The shell keeps the width it takes on screen (`_dockWidth` and the
/// divider that drags it): that is the library's `dockWidth` setting,
/// which the tree's own divider shares.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/dock/history_dock_pane.dart';
import 'package:niman/src/ui/dock/links_dock_pane.dart';
import 'package:niman/src/ui/dock/outline_dock_pane.dart';
import 'package:niman/src/ui/dock/right_dock.dart';
import 'package:niman/src/ui/dock/spelling_dock_pane.dart';
import 'package:niman/src/ui/dock/tags_dock_pane.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/outline_panel.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/strings.dart';
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

  /// Whether the window has room for the right dock beside a note (#175):
  /// a desktop, a tablet, a phone in landscape — on the same rule.
  bool get room => windowWidth() >= RightDock.minWindowWidth;

  /// Whether the dock shows: there is room, and it was not closed.
  bool get shown => room && workspace.value.dockOpen;

  /// The right dock: the focused pane's note's outline, tags or history.
  Widget build(BuildContext context) {
    final w = workspace.value;
    final path = w.activePath;
    return RightDock(
      pane: w.dockPane,
      onPane: (pane) =>
          workspace.controller.update((w) => w.withDock(pane: pane)),
      onClose: () =>
          workspace.controller.update((w) => w.withDock(open: false)),
      paneBuilder: (pane) => switch (pane) {
        DockPane.outline => OutlineDockPane(note: panelNote()),
        DockPane.tags => TagsDockPane(
          note: panelNote(),
          tags: controller.tagSource,
          onOpenNote: workspace.show,
        ),
        DockPane.links => LinksDockPane(
          note: panelNote(),
          links: controller.linkSource,
          libraryRoot: controller.root,
          onOpenNote: workspace.show,
        ),
        DockPane.spelling => SpellingDockPane(note: panelNote()),
        DockPane.history => HistoryDockPane(
          ops: controller.ops,
          path: path,
          onOpenHistory: () {
            if (path != null) onOpenHistory(path);
          },
          onOpenVersion: switch ((onOpenVersion, path)) {
            (final open?, final path?) => (version) => open(path, version),
            _ => null,
          },
        ),
        DockPane.journal => journalBrowser(context),
      },
    );
  }

  /// Shows or hides the dock (the note row's button, Ctrl+Shift+B).
  void toggleOpen() =>
      workspace.controller.update((w) => w.withDock(open: !w.dockOpen));

  /// The note row's dock button, where the window has room for a dock.
  Widget toggle() => IconButton(
    key: const Key('dock-toggle'),
    tooltip: AppStrings.sidePanelTooltip,
    isSelected: workspace.value.dockOpen,
    icon: const Icon(Icons.view_sidebar_outlined),
    selectedIcon: const Icon(Icons.view_sidebar),
    onPressed: toggleOpen,
  );

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
    // The spelling sheet is the note's own: it opens it where there is no
    // dock.
    if (note == null || pane == DockPane.spelling) return;
    if (pane == DockPane.outline) {
      final line = await showOutlineSheet(
        context,
        entries: note.outline.value,
        anchor: anchor,
      );
      if (line != null) note.jumpToHeading(line);
      return;
    }
    if (pane == DockPane.links) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SizedBox(
          height: MediaQuery.sizeOf(sheet).height * 0.5,
          child: LinksDockPane(
            note: note,
            links: controller.linkSource,
            libraryRoot: controller.root,
            onOpenNote: (path) {
              Navigator.pop(sheet);
              onOpenNoteFromLink(path);
            },
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SizedBox(
        height: MediaQuery.sizeOf(sheet).height * 0.5,
        child: TagsDockPane(
          note: note,
          tags: controller.tagSource,
          onOpenNote: (path) {
            Navigator.pop(sheet);
            onOpenNoteFromLink(path);
          },
        ),
      ),
    );
  }
}
