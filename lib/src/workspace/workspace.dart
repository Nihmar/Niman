/// The notes open in a window (issue #23): one or two panes, each with
/// its tabs, and the pane that has the focus.
///
/// A value, and every change returns a new one. The rules the shell must
/// not get wrong — where a new tab goes, which tab shows after a close,
/// what a rename or a delete does to the tabs under it — live here, where
/// they are tested without a widget in sight.
///
/// The plan on #23 fixes two of them:
///
/// * a note is open in **one place**: opening it again shows the tab it is
///   already in (decision 2);
/// * the workspace is **the device's**, not the library's: it is stored
///   in the app database, keyed by library, so a phone never inherits a
///   desktop's tabs (decision 1).
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/workspace_pane.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

/// What the right dock shows (#175).
enum DockPane {
  /// The note's headings.
  outline,

  /// The note's tags, and the notes that share them.
  tags,

  /// The note's kept versions.
  history,

  /// The journal's calendar (#7): not the note's, the library's.
  journal,
}

/// Which way the second pane opens.
enum SplitAxis {
  /// Side by side: the second pane on the right.
  right,

  /// One over the other: the second pane below.
  down,
}

/// The open notes of one library, on this device.
@immutable
final class Workspace {
  /// A workspace of [panes] (one or two), [focused] among them.
  const new({
    this.panes = const [WorkspacePane.empty],
    this.focused = 0,
    this.axis = SplitAxis.right,
    this.fraction = 0.5,
    this.dockOpen = true,
    this.dockPane = DockPane.outline,
  }) : assert(focused >= 0, 'focused is a pane');

  /// Reads a stored form.
  ///
  /// Forgiving, because the store outlives the build that wrote it: a
  /// malformed tab is dropped, a note open twice keeps its first tab
  /// (decision 2 holds on the way in too), an empty second pane closes,
  /// and anything unreadable — or written by a newer build — reads as
  /// nothing open.
  factory fromJson(Object? json) {
    if (json is! Map || json['version'] != formatVersion) {
      return Workspace.empty;
    }
    final rawPanes = json['panes'];
    if (rawPanes is! List || rawPanes.isEmpty) return Workspace.empty;
    final seen = <String>{};
    final panes = <WorkspacePane>[];
    for (final rawPane in rawPanes.take(2)) {
      if (rawPane is! Map) continue;
      final rawTabs = rawPane['tabs'];
      final tabs = <WorkspaceTab>[];
      if (rawTabs is List) {
        for (final rawTab in rawTabs) {
          if (rawTab is! Map) continue;
          final path = rawTab['path'];
          if (path is! String || path.isEmpty || !seen.add(path)) continue;
          tabs.add(
            WorkspaceTab(
              path,
              memento: NoteMemento.fromJson(rawTab['memento']),
            ),
          );
        }
      }
      final active = rawPane['active'];
      panes.add(WorkspacePane.clamped(tabs, active is int ? active : 0));
    }
    if (panes.isEmpty) return Workspace.empty;
    if (panes.length == 2 && panes[1].isEmpty) panes.removeLast();
    if (panes.length == 2 && panes[0].isEmpty) panes.removeAt(0);
    final focused = json['focused'];
    final axis = json['axis'];
    final fraction = json['fraction'];
    final dock = json['dock'];
    final dockOpen = dock is Map ? dock['open'] : null;
    final dockPane = dock is Map ? dock['pane'] : null;
    return Workspace(
      dockOpen: dockOpen is! bool || dockOpen,
      dockPane: DockPane.values.firstWhere(
        (p) => p.name == dockPane,
        orElse: () => DockPane.outline,
      ),
      panes: List.unmodifiable(panes),
      focused: focused is int && focused >= 0 && focused < panes.length
          ? focused
          : 0,
      axis: SplitAxis.values.firstWhere(
        (a) => a.name == axis,
        orElse: () => SplitAxis.right,
      ),
      fraction: fraction is num && fraction.isFinite
          ? fraction.toDouble().clamp(0.2, 0.8)
          : 0.5,
    );
  }

  /// Nothing open.
  static const Workspace empty = Workspace();

  /// The panes, first (left or top) to last.
  final List<WorkspacePane> panes;

  /// The index of the pane with the focus: where the next note opens.
  final int focused;

  /// Which way the panes are split; meaningless with one pane.
  final SplitAxis axis;

  /// The first pane's share of the space, when there are two.
  final double fraction;

  /// Whether the right dock is open (#175) — where the window has room
  /// for it; closing it is how a narrow laptop gets the space back.
  final bool dockOpen;

  /// Which of its panes the dock shows.
  final DockPane dockPane;

  /// The pane with the focus.
  WorkspacePane get focusedPane => panes[focused];

  /// The note showing in the focused pane: the one "the note" means.
  String? get activePath => focusedPane.activeTab?.path;

  /// Whether the window is split.
  bool get isSplit => panes.length == 2;

  /// Every open note, pane by pane.
  Iterable<WorkspaceTab> get tabs => panes.expand((pane) => pane.tabs);

  /// Where [path] is open, or null.
  ({int pane, int index})? locate(String path) {
    for (var pane = 0; pane < panes.length; pane++) {
      final index = panes[pane].indexOf(path);
      if (index >= 0) return (pane: pane, index: index);
    }
    return null;
  }

  /// Opens [path]: shows its tab where it already is, or adds one after
  /// the focused pane's active tab.
  Workspace open(String path) {
    final at = locate(path);
    if (at != null) return activate(at.pane, at.index);
    final pane = focusedPane;
    final insert = pane.active + 1;
    final tabs = [...pane.tabs]..insert(insert, WorkspaceTab(path));
    return _withPane(focused, WorkspacePane.clamped(tabs, insert));
  }

  /// Shows [path] in place of the focused pane's active tab — the
  /// one-note-at-a-time behaviour, until the tab bar exists to open
  /// alongside. A note already open is shown where it is.
  Workspace replaceActive(String path) {
    final at = locate(path);
    if (at != null) return activate(at.pane, at.index);
    final pane = focusedPane;
    if (pane.isEmpty) return open(path);
    final tabs = [...pane.tabs]..[pane.active] = WorkspaceTab(path);
    return _withPane(focused, WorkspacePane.clamped(tabs, pane.active));
  }

  /// Shows the tab at [index] of [pane], and focuses that pane.
  Workspace activate(int pane, int index) {
    final target = panes[pane];
    if (index < 0 || index >= target.tabs.length) return this;
    return _copy(
      panes: _replaced(pane, WorkspacePane.clamped(target.tabs, index)),
      focused: pane,
    );
  }

  /// Gives [pane] the focus — an empty one too: the next note opens
  /// there.
  Workspace focus(int pane) =>
      pane < 0 || pane >= panes.length || pane == focused
      ? this
      : _copy(focused: pane);

  /// Splits [axis] with the tab at [index] of [pane]: it moves into the
  /// new pane, which takes the focus. A pane with that tab alone keeps
  /// it, and the new pane opens empty — a note is open in one place, so
  /// there is nothing else to put there.
  Workspace splitWith(int pane, int index, SplitAxis axis) {
    if (isSplit) return this;
    final split = this.split(axis);
    final source = panes[pane];
    if (source.tabs.length < 2 || index < 0 || index >= source.tabs.length) {
      return split;
    }
    return split.moveTab(pane, index, 1);
  }

  /// Opens [path] in the other pane, splitting [axis] first when the
  /// window is not split: "open to the side".
  Workspace openBeside(String path, SplitAxis axis) {
    final at = locate(path);
    if (at != null) return activate(at.pane, at.index);
    final split = isSplit ? this : this.split(axis);
    final other = isSplit ? 1 - focused : 1;
    return split.focus(other).open(path);
  }

  /// Closes the tab at [index] of [pane].
  ///
  /// Closing the tab that is showing shows its right-hand neighbour, or
  /// the left one at the end of the row — the tab that slides under the
  /// pointer. A second pane left empty goes away.
  Workspace close(int pane, int index) {
    final target = panes[pane];
    if (index < 0 || index >= target.tabs.length) return this;
    return _filtered((p, i, _) => !(p == pane && i == index));
  }

  /// Closes [path]'s tab, wherever it is.
  Workspace closePath(String path) {
    final at = locate(path);
    return at == null ? this : close(at.pane, at.index);
  }

  /// Closes everything, and the split with it.
  Workspace closeAll() => Workspace(dockOpen: dockOpen, dockPane: dockPane);

  /// Opens a second pane, empty and focused, [axis] of the first. A split
  /// window stays as it is.
  Workspace split(SplitAxis axis) => isSplit
      ? this
      : _copy(panes: [...panes, WorkspacePane.empty], focused: 1, axis: axis);

  /// Moves the tab at [index] of [from] to the end of [to], showing it
  /// there.
  Workspace moveTab(int from, int index, int to, {int? at}) {
    if (from == to || to < 0 || to >= panes.length) return this;
    final source = panes[from];
    if (index < 0 || index >= source.tabs.length) return this;
    final tab = source.tabs[index];
    final landingAt = (at ?? panes[to].tabs.length).clamp(
      0,
      panes[to].tabs.length,
    );
    final landing = WorkspacePane.clamped(
      [...panes[to].tabs]..insert(landingAt, tab),
      landingAt,
    );
    final moved = _copy(panes: _replaced(to, landing), focused: to);
    // Remove it from where it came from with the close rules, then put the
    // focus back on the pane it went to (the collapse may renumber it).
    final closed = moved._filtered((p, i, _) => !(p == from && i == index));
    final landed = closed.locate(tab.path)!;
    return closed.activate(landed.pane, landed.index);
  }

  /// Moves the tab at [index] of [pane] to [to] in the same row (#204):
  /// dragging a tab along its own pane.
  ///
  /// [to] is a position in the row as it is now, so dropping a tab where
  /// it already is changes nothing, and dropping it past the end puts it
  /// last. The moved tab keeps the focus and shows.
  Workspace reorder(int pane, int index, int to) {
    final target = panes[pane];
    if (index < 0 || index >= target.tabs.length) return this;
    final landing = to.clamp(0, target.tabs.length - 1);
    if (landing == index) return activate(pane, index);
    final tabs = [...target.tabs];
    final tab = tabs.removeAt(index);
    tabs.insert(landing, tab);
    return _copy(
      panes: _replaced(pane, WorkspacePane.clamped(tabs, landing)),
      focused: pane,
    );
  }

  /// Follows a rename or a move of [from] to [to]: the note itself, or —
  /// for a folder — every note under it.
  Workspace renamed(String from, String to) {
    if (from == to) return this;
    final prefix = '$from/';
    return _mapTabs((tab) {
      if (tab.path == from) return tab.copyWith(path: to);
      if (!tab.path.startsWith(prefix)) return tab;
      return tab.copyWith(path: '$to/${tab.path.substring(prefix.length)}');
    });
  }

  /// Closes [path]'s tab and, for a folder, every tab under it.
  Workspace deleted(String path) {
    final prefix = '$path/';
    return _filtered(
      (_, _, tab) => tab.path != path && !tab.path.startsWith(prefix),
    );
  }

  /// Remembers where [path] was left.
  Workspace withMemento(String path, NoteMemento memento) =>
      _mapTab(path, (tab) => tab.copyWith(memento: memento));

  /// Marks exactly the tabs in [paths] as gone from disk.
  Workspace withMissing(Set<String> paths) => _mapTabs(
    (tab) => tab.missing == paths.contains(tab.path)
        ? tab
        : tab.copyWith(missing: !tab.missing),
  );

  /// The dock opened or closed.
  Workspace withDock({bool? open, DockPane? pane}) =>
      _copy(dockOpen: open ?? dockOpen, dockPane: pane ?? dockPane);

  /// The split's first pane at [fraction] of the space, kept to where
  /// both panes stay usable.
  Workspace withFraction(double fraction) =>
      _copy(fraction: fraction.clamp(0.2, 0.8));

  // --- persistence ---------------------------------------------------------

  /// The stored form's version: a reader meeting a newer one starts empty
  /// rather than guessing.
  static const int formatVersion = 1;

  /// The stored form. Missing flags are not written: they are found again.
  Map<String, Object> toJson() => {
    'version': formatVersion,
    'focused': focused,
    'axis': axis.name,
    'fraction': fraction,
    'dock': {'open': dockOpen, 'pane': dockPane.name},
    'panes': [
      for (final pane in panes)
        {
          'active': pane.active,
          'tabs': [
            for (final tab in pane.tabs)
              {
                'path': tab.path,
                if (!tab.memento.isEmpty) 'memento': tab.memento.toJson(),
              },
          ],
        },
    ],
  };

  // --- internals -----------------------------------------------------------

  Workspace _copy({
    List<WorkspacePane>? panes,
    int? focused,
    SplitAxis? axis,
    double? fraction,
    bool? dockOpen,
    DockPane? dockPane,
  }) => Workspace(
    panes: List.unmodifiable(panes ?? this.panes),
    focused: focused ?? this.focused,
    axis: axis ?? this.axis,
    fraction: fraction ?? this.fraction,
    dockOpen: dockOpen ?? this.dockOpen,
    dockPane: dockPane ?? this.dockPane,
  );

  List<WorkspacePane> _replaced(int index, WorkspacePane pane) =>
      [...panes]..[index] = pane;

  Workspace _withPane(int index, WorkspacePane pane) =>
      _copy(panes: _replaced(index, pane));

  /// Every tab through [change]; this workspace itself when none changed.
  Workspace _mapTabs(WorkspaceTab Function(WorkspaceTab) change) {
    var changed = false;
    final next = <WorkspacePane>[];
    for (final pane in panes) {
      final tabs = <WorkspaceTab>[];
      for (final tab in pane.tabs) {
        final mapped = change(tab);
        if (!identical(mapped, tab)) changed = true;
        tabs.add(mapped);
      }
      next.add(WorkspacePane.clamped(tabs, pane.active));
    }
    return changed ? _copy(panes: next) : this;
  }

  Workspace _mapTab(String path, WorkspaceTab Function(WorkspaceTab) change) {
    final at = locate(path);
    if (at == null) return this;
    final pane = panes[at.pane];
    final tabs = [...pane.tabs]..[at.index] = change(pane.tabs[at.index]);
    return _withPane(at.pane, WorkspacePane.clamped(tabs, pane.active));
  }

  /// Keeps the tabs [keep] says to, with the close rules: each pane's
  /// showing tab stays showing if it survives, otherwise the survivor
  /// that slid into its place does; a second pane left empty goes away.
  Workspace _filtered(
    bool Function(int pane, int index, WorkspaceTab tab) keep,
  ) {
    final next = <WorkspacePane>[];
    for (var p = 0; p < panes.length; p++) {
      final pane = panes[p];
      final kept = <WorkspaceTab>[];
      var active = -1;
      for (var i = 0; i < pane.tabs.length; i++) {
        final survives = keep(p, i, pane.tabs[i]);
        if (survives) kept.add(pane.tabs[i]);
        if (i == pane.active) {
          // The showing tab, or the first survivor at or after its place
          // (the one that slides under the pointer).
          active = survives ? kept.length - 1 : kept.length;
        }
      }
      next.add(WorkspacePane.clamped(kept, active));
    }
    final unchanged = [
      for (var p = 0; p < panes.length; p++)
        next[p].tabs.length == panes[p].tabs.length,
    ].every((same) => same);
    if (unchanged) return this;
    var focused = this.focused;
    if (next.length == 2 && next.any((pane) => pane.isEmpty)) {
      final gone = next[1].isEmpty ? 1 : 0;
      next.removeAt(gone);
      focused = 0;
    }
    return _copy(panes: next, focused: focused);
  }

  @override
  bool operator ==(Object other) =>
      other is Workspace &&
      other.focused == focused &&
      other.axis == axis &&
      other.fraction == fraction &&
      other.dockOpen == dockOpen &&
      other.dockPane == dockPane &&
      listEquals(other.panes, panes);

  @override
  int get hashCode => Object.hash(
    focused,
    axis,
    fraction,
    dockOpen,
    dockPane,
    Object.hashAll(panes),
  );

  @override
  String toString() => 'Workspace(focused $focused of $panes)';
}
