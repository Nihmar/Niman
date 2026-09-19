/// The shell's side of the workspace (issue #23): reads what was left
/// open when a library opens, opens notes into it the way the tree was
/// clicked, runs the tab bar's actions, decides which tabs keep their
/// editor alive behind the one showing, and follows the library when a
/// note or a folder under an open note is renamed, moved or deleted.
///
/// On a phone the notes opened stay open, one on screen at a time, and
/// the open-notes switcher reaches the others (#23, PR 4).
library;

import 'dart:async';

import 'package:niman/src/library/session.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:niman/src/workspace/workspace_controller.dart';

/// The open library's workspace, as the shell drives it.
final class ShellWorkspace {
  /// The workspace of [session]'s library, kept through the session.
  new(LibrarySession session)
    : _session = session,
      controller = WorkspaceController(save: session.saveWorkspace);

  final LibrarySession _session;

  /// The workspace itself.
  final WorkspaceController controller;

  /// How many tabs besides the showing one keep their editor mounted —
  /// and with it undo, find and folds (decision 4 of the plan on #23).
  static const int keptAlive = 4;

  /// Past this many characters a note keeps its editor only while it
  /// shows: novel-length notes are what the app is built to open, and
  /// five of them mounted at once is not.
  static const int largeNote = 200000;

  /// The note last followed, so an unchanged build changes nothing.
  String? _following;
  bool _followed = false;

  /// The next note opened goes into a new tab (Ctrl+click, the row menu,
  /// the tab bar's +) instead of the showing one.
  bool _nextInNewTab = false;

  /// Open notes, most recently shown first.
  final List<String> _recent = [];

  /// Loaded notes' lengths, for [largeNote].
  final Map<String, int> _lengths = {};

  /// What is open now.
  Workspace get value => controller.value;

  /// Reads back what was left open in the library on this device.
  Future<void> load() async {
    controller.adopt(await _session.savedWorkspace);
  }

  /// Opens [notePath] now: in a new tab when [newTab] (or when one was
  /// asked for with [openNextInNewTab]), in place of the showing one
  /// otherwise. Already open, it is shown where it is.
  void show(String notePath, {bool newTab = false}) {
    final fresh = newTab || _nextInNewTab;
    _nextInNewTab = false;
    _following = notePath;
    _followed = true;
    controller.update(
      (w) => fresh ? w.open(notePath) : w.replaceActive(notePath),
    );
  }

  /// The next note the shell opens, however it opens it, goes into a new
  /// tab: for the flows that pick their note later (a new note's name).
  void openNextInNewTab() => _nextInNewTab = true;

  /// The shell now shows [notePath] (library-relative), or no note.
  ///
  /// Called from the shell's build, for the ways in that set the shell's
  /// note without going through [show] (a link, a template, a quick
  /// note), so the change lands after the frame instead of notifying in
  /// the middle of one. With [keepOnNone] no note closes nothing: a
  /// folder selected, or the phone back on its tree, leaves the open
  /// notes open. With [alongside] — the phone, which has no tab to show
  /// a note in place of — a note joins the ones already open.
  void follow(
    String? notePath, {
    bool keepOnNone = false,
    bool alongside = false,
  }) {
    if (_followed && notePath == _following) return;
    final previous = _following;
    _following = notePath;
    _followed = true;
    scheduleMicrotask(() {
      if (notePath != null) {
        final fresh = alongside || _nextInNewTab;
        _nextInNewTab = false;
        controller.update(
          (w) => fresh ? w.open(notePath) : w.replaceActive(notePath),
        );
      } else if (previous != null && !keepOnNone) {
        controller.update((w) => w.closePath(previous));
      }
    });
  }

  /// Shows [pane]'s tab at [index], focusing the pane.
  void activate(int pane, int index) =>
      controller.update((w) => w.activate(pane, index));

  /// Closes [pane]'s tab at [index].
  void close(int pane, int index) =>
      controller.update((w) => w.close(pane, index));

  /// Gives [pane] the focus: where the next note opens.
  void focus(int pane) => controller.update((w) => w.focus(pane));

  /// Splits [axis] with [pane]'s tab at [index] (#23): it moves into the
  /// new pane, or the new pane opens empty beside a pane's only tab.
  void splitWith(int pane, int index, SplitAxis axis) =>
      controller.update((w) => w.splitWith(pane, index, axis));

  /// Moves [pane]'s tab at [index] to the other pane.
  void moveToOtherPane(int pane, int index) =>
      controller.update((w) => w.moveTab(pane, index, 1 - pane));

  /// Moves [from]'s tab at [index] into [to], at [at] of its row — a tab
  /// dragged from the other pane (#204); null lands it last.
  void moveTabHere(int from, int index, int to, int? at) =>
      controller.update((w) => w.moveTab(from, index, to, at: at));

  /// Moves [pane]'s tab at [index] to [to] in its own row (#204).
  void reorder(int pane, int index, int to) =>
      controller.update((w) => w.reorder(pane, index, to));

  /// Opens [path] in the other pane, splitting [axis] first if need be.
  void openBeside(String path, SplitAxis axis) {
    _following = path;
    _followed = true;
    controller.update((w) => w.openBeside(path, axis));
  }

  /// Sets the split's first pane to [fraction] of the space.
  void setFraction(double fraction) =>
      controller.update((w) => w.withFraction(fraction));

  /// Closes the tab showing, if any.
  void closeActive() => controller.update((w) {
    final pane = w.focusedPane;
    return pane.active < 0 ? w : w.close(w.focused, pane.active);
  });

  /// Splits [axis] with the focused pane's showing tab (`Ctrl+\`).
  void splitActive(SplitAxis axis) => controller.update((w) {
    final pane = w.focusedPane;
    return w.splitWith(w.focused, pane.active, axis);
  });

  /// Shows the tab [step] away from the showing one, wrapping around.
  void cycle(int step) => controller.update((w) {
    final pane = w.focusedPane;
    if (pane.tabs.length < 2) return w;
    final next = (pane.active + step) % pane.tabs.length;
    return w.activate(w.focused, next);
  });

  /// Remembers where [path] was left. Deferred: it arrives while an
  /// editor is being taken down, when nothing may be rebuilt.
  void remember(String path, NoteMemento memento) {
    scheduleMicrotask(
      () => controller.update((w) => w.withMemento(path, memento)),
    );
  }

  /// Open notes, the most recently shown first: what the palette offers
  /// before anything is typed (#155).
  List<String> get recentNotes => [
    ..._recent,
    for (final tab in value.tabs)
      if (!_recent.contains(tab.path)) tab.path,
  ];

  /// Records a loaded note's [length], for [largeNote].
  void noteLoaded(String path, int length) => _lengths[path] = length;

  /// The tabs whose editor stays mounted: each pane's showing one, then
  /// the most recently shown others up to [keptAlive], passing over
  /// large notes.
  Set<String> mounted() {
    final w = value;
    final active = w.activePath;
    final showing = {
      for (final pane in w.panes)
        if (pane.activeTab case final tab?) tab.path,
    };
    final open = {for (final tab in w.tabs) tab.path};
    _recent.removeWhere((path) => !open.contains(path));
    if (active != null) {
      _recent
        ..remove(active)
        ..insert(0, active);
    }
    final alive = <String>{...showing};
    var extra = 0;
    for (final path in _recent) {
      if (extra >= keptAlive) break;
      if (alive.contains(path) || (_lengths[path] ?? 0) > largeNote) continue;
      alive.add(path);
      extra++;
    }
    return alive;
  }

  /// [from] is now at [to]: a note, or a folder with notes under it.
  void moved(String from, String to) {
    String remap(String path) => path == from || path.startsWith('$from/')
        ? to + path.substring(from.length)
        : path;
    if (_following case final open?) _following = remap(open);
    for (var i = 0; i < _recent.length; i++) {
      _recent[i] = remap(_recent[i]);
    }
    for (final path in [..._lengths.keys]) {
      final moved = remap(path);
      if (moved != path) _lengths[moved] = _lengths.remove(path)!;
    }
    controller.update((w) => w.renamed(from, to));
  }

  /// [path] is gone: a note, or a folder with notes under it.
  void deleted(String path) => controller.update((w) => w.deleted(path));

  /// Writes what is pending and lets go.
  void dispose() => controller.dispose();
}
