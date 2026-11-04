import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// The library's quick note (issue #73, #1256): its tile, its tab, its
/// chooser, and the text shared into Niman (#40) waiting for it.
final class ShellQuickNote {
  /// The quick note of [controller]'s library, opened through [selection].
  new({
    required this.controller,
    required this.unsaved,
    required this.selection,
    required this.nav,
    required this.tabs,
    required this.guard,
    required this.wide,
    required this.update,
    required this.mounted,
  });

  /// The open library.
  final LibrarySession controller;

  /// The editors holding edits: saved before shared text is appended.
  final UnsavedTracker unsaved;

  /// What is selected and what shows.
  final ShellSelection selection;

  /// Where the shell is.
  final ShellNavigationState nav;

  /// The moves between the destinations.
  final ShellTabSwitch tabs;

  /// Runs an action once at a time, saying so when it fails.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// The shell's `setState`.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// Whether the Quick note tab body is the choose/create screen.
  ///
  /// It is only ever wanted when no quick note is set. With one set, the
  /// tab is a way of opening that note, and the tab shell stays painted
  /// under the opening note for the length of the fade — long enough for
  /// the chooser to flash behind a note the user had already chosen.
  bool get choosing => _choosing;
  bool _choosing = false;

  /// Text shared into Niman (#40) with no quick note to put it in yet: it
  /// is appended to whatever note the chooser opens next.
  String? _pendingText;

  /// Opens the quick note at [path]; back returns to the tab it was
  /// opened from: the tile sits in every tab, not in Files (issue #73,
  /// item 1). The chooser flow arrives here from the quick note tab
  /// itself, and the home tab is its home. A stale setting (the note was
  /// moved, renamed, or deleted) is cleared so the tab returns to its
  /// empty state.
  Future<void> open(String path) async {
    // Closes the keyboard before the transition (issue #4): opening the
    // overlay over a live IME rips focus mid-fade while adjustResize
    // reshapes the window, which flashes on device. Tab switches already
    // do this in [ShellTabSwitch.select].
    FocusManager.instance.primaryFocus?.unfocus();
    await guard(() async {
      final ops = controller.ops;
      if (ops == null) return;
      final note = await ops.find(path);
      if (note == null || note.isDir) {
        // The note it pointed at is gone: forget it and ask again, rather
        // than leaving the tap with nothing to show for itself.
        await ops.setQuickNotePath(path: null);
        controller.notify();
        if (mounted()) openChooser();
        return;
      }
      // Text shared into Niman (#40) waits here for the note it goes in:
      // appended before the note is opened, so the first read of the file
      // already carries it. What is on screen is saved first — the append
      // reads the file, and a buffer written after it would take the
      // shared text back out.
      final pending = _pendingText;
      _pendingText = null;
      var reload = false;
      if (pending != null) {
        await unsaved.saveAll();
        await ops.appendToNote(note.path, pending);
        reload = selection.selects(note.path);
      }
      if (!mounted()) return;
      // Read the origin before the switch below: the chooser flow arrives
      // here from the quick note tab itself, and the home tab is its home;
      // a hidden tab is a page, not a place to come back to (#536).
      final tab = nav.tab;
      final from = tab == ShellTab.quickNote || !nav.shown(tab)
          ? tabs.startTab
          : tab;
      _choosing = false;
      // Already open: its buffer predates the appended text, so it
      // re-reads the file instead of keeping what it had.
      selection.openQuickNote(note.path, from: from, reload: reload);
      logNextFrame('shell', 'quick note open first frame');
    });
  }

  /// The bottom-nav tile: once a quick note is set it opens directly;
  /// otherwise switch to the tab (the choose/create screen).
  Future<void> openFromTile() async {
    final ops = controller.ops;
    if (ops == null) return;
    final path = await ops.quickNotePath;
    if (!mounted()) return;
    if (path == null || path.isEmpty) return openChooser();
    // Already on screen: just land on the tab. Reopening would unfocus
    // the editor, reset the kind view and restart the hide timer for
    // identical content — on wide, where both tabs share the detail pane,
    // that reads as a close/reopen flash.
    //
    // On screen, not merely selected (2026-09-10 device report): closing
    // the note leaves it selected, and on a phone the tab it lands on has
    // an empty body by design — so the shortcut showed nothing at all.
    // The tree being up is what says the note is closed.
    final onScreen = wide() || !selection.treeVisible;
    if (onScreen && selection.selects(path) && !_choosing) {
      if (nav.tab != ShellTab.quickNote) {
        update(() => nav.visit(ShellTab.quickNote));
      }
      return;
    }
    await open(path);
  }

  /// Shows the choose/create screen, wherever this layout keeps it.
  ///
  /// Every layout shows it inline in the Quick note tab body (the rail on
  /// wide, the bottom bar on narrow), so the tab chrome always persists —
  /// opening it over the shell used to hide the rail on wide.
  void openChooser() {
    update(() => _choosing = true);
    tabs.select(ShellTab.quickNote);
  }

  /// Inserts [text] at the end of the quick note and opens it.
  ///
  /// With no quick note set the choose/create screen opens instead, and
  /// the text waits: [open] inserts it into whatever note the choice lands
  /// on — the text is the point of the share, so it cannot be dropped just
  /// because the target is not configured yet.
  Future<void> share(String text) async {
    final ops = controller.ops;
    if (ops == null || !mounted()) return;
    _pendingText = text;
    final path = await ops.quickNotePath;
    if (!mounted()) return;
    if (path == null || path.isEmpty) return openChooser();
    await open(path);
  }
}
