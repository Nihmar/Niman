import 'dart:async';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/editor/toolbar.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/file_icon.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// One row of the flattened tree (note/folder + its depth).
final class _Row {
  const new({required this.note, required this.depth});

  final Note note;
  final int depth;
}

/// What the tree renders: the pinned notes, then the folder tree.
final class _Rows {
  const new({required this.pinned, required this.tree});

  final List<Note> pinned;
  final List<_Row> tree;

  bool get isEmpty => pinned.isEmpty && tree.isEmpty;
}

/// Lazy tree of the library's folders/notes.
///
/// Rows are flattened from per-level `NoteDao.children` queries and rendered
/// in a single [ListView.builder], so a 10k-note library only materializes
/// the visible rows (T-M1-04).
final class NoteTree extends StatefulWidget {
  /// Creates the note tree.
  const new({
    required this.controller,
    required this.selectedPath,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.nameDesc = false,
    super.key,
  });

  /// The session providing the index and the change-event stream.
  final LibrarySession controller;

  /// Whether the rows sort by name descending (T-UI-03).
  final bool nameDesc;

  /// Library-relative path of the selected note/folder, or null.
  final String? selectedPath;

  /// Paths of the expanded folders.
  final Set<String> expanded;

  /// Called when a folder's chevron is tapped (expand/collapse).
  final ValueChanged<String> onToggle;

  /// Called with the row's note when the row is selected.
  final void Function(Note note) onSelect;

  /// Called with the row's note on long-press (context menu, T-UI-05).
  final void Function(Note note)? onLongPress;

  /// Called with the row's note on right-click (context menu at the
  /// cursor, T-PP-20): the desktop twin of [onLongPress], which stays
  /// for touchscreens.
  final void Function(Note note, TapDownDetails details)? onSecondaryTapDown;

  @override
  State<NoteTree> createState() => _NoteTreeState();
}

final class _NoteTreeState extends State<NoteTree> {
  /// The rows currently being shown, and the inputs they were built from.
  ///
  /// The flatten runs one `children` query per expanded level, so it must
  /// not be restarted by every rebuild: selecting a note, toggling a
  /// button — any `setState` above this widget — used to re-query the
  /// whole visible tree, over a hundred queries a second on a real
  /// library. Reusing the same future also keeps [FutureBuilder] from
  /// flashing its spinner between rebuilds.
  Future<_Rows>? _rows;
  int? _rowsRevision;
  Set<String> _rowsExpanded = const <String>{};

  /// Whether the pinned section is rolled up, once the library has been
  /// asked. Null until then, and the section builds expanded — the common
  /// answer, and the one that does not make the tree jump when the real
  /// value lands.
  bool? _pinnedCollapsed;

  bool get _collapsed => _pinnedCollapsed ?? false;

  @override
  void initState() {
    super.initState();
    const AppLogger(name: 'tree.ui').debug('mount');
  }

  @override
  void dispose() {
    const AppLogger(name: 'tree.ui').debug('dispose');
    super.dispose();
  }

  @override
  void didUpdateWidget(NoteTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _rows = null;
    }
  }

  /// The flattened rows for [revision], recomputed only when the index
  /// revision or the set of expanded folders has changed.
  Future<_Rows> _rowsFor(int revision) {
    final cached = _rows;
    if (cached != null &&
        _rowsRevision == revision &&
        _setEquals(_rowsExpanded, widget.expanded)) {
      return cached;
    }
    _rowsRevision = revision;
    _rowsExpanded = Set<String>.of(widget.expanded);
    return _rows = _flatten();
  }

  /// Flattens the visible tree from the index, and reads the pinned notes
  /// alongside it — one revision, one build, so the two never disagree.
  Future<_Rows> _flatten() async {
    final started = DateTime.now();
    final allNodes = await widget.controller.tree(
      widget.expanded,
      nameDesc: widget.nameDesc,
    );
    final fields = await widget.controller.fieldSource;
    final pinned = await fields?.pinnedNotes() ?? const <Note>[];
    // Asked once per session, not per flatten: after the first answer the
    // state lives here, so a toggle repaints instead of round-tripping
    // through the settings file.
    _pinnedCollapsed ??= await widget.controller.pinnedCollapsed;

    final nodesByParent = <int, List<Note>>{};
    for (final node in allNodes) {
      nodesByParent.putIfAbsent(node.parent, () => []).add(node);
    }

    final out = <_Row>[];
    _walkSync(0, 0, nodesByParent, out);

    const AppLogger(name: 'tree.ui').debug(
      'flatten: ${DateTime.now().difference(started).inMilliseconds}ms '
      '(${out.length} rows, ${pinned.length} pinned)',
    );
    return _Rows(pinned: pinned, tree: out);
  }

  void _walkSync(
    int parentId,
    int depth,
    Map<int, List<Note>> nodesByParent,
    List<_Row> out,
  ) {
    final children = nodesByParent[parentId] ?? const [];
    for (final note in children) {
      out.add(_Row(note: note, depth: depth));
      if (note.isDir && widget.expanded.contains(note.path)) {
        _walkSync(note.id, depth + 1, nodesByParent, out);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.controller.events,
      initialData: widget.controller.revision,
      builder: (context, snapshot) {
        return FutureBuilder<_Rows>(
          future: _rowsFor(snapshot.data ?? widget.controller.revision),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data!;
            if (rows.isEmpty) {
              return Center(child: Text(AppStrings.treeEmpty));
            }
            // The pinned notes sit above the tree with a heading of their
            // own; below the divider the tree is unchanged, so a pinned
            // note appears twice — once where it is kept, once where it
            // is wanted. Rolled up, the heading and the divider stay: the
            // count is still worth seeing, and the tree keeps the room.
            final header = rows.pinned.isEmpty
                ? 0
                : (_collapsed ? 2 : rows.pinned.length + 2);
            return ListView.builder(
              key: const Key('note-tree-list'),
              itemCount: header + rows.tree.length,
              itemBuilder: (context, index) {
                if (index < header) return _pinnedItem(rows.pinned, index);
                final row = rows.tree[index - header];
                return _RowTile(
                  note: row.note,
                  depth: row.depth,
                  isExpanded: widget.expanded.contains(row.note.path),
                  selected: row.note.path == widget.selectedPath,
                  onSelect: widget.onSelect,
                  onToggle: widget.onToggle,
                  onLongPress: widget.onLongPress,
                  onSecondaryTapDown: widget.onSecondaryTapDown,
                );
              },
            );
          },
        );
      },
    );
  }

  /// One item of the pinned block: the heading, a pinned note, or the
  /// divider that closes it off from the tree.
  Widget _pinnedItem(List<Note> pinned, int index) {
    if (index == 0) return _pinnedHeading(pinned.length);
    if (index == (_collapsed ? 1 : pinned.length + 1)) {
      // The hairline sits directly under the heading — aligned with the
      // editor toolbar's divider across the pane boundary — with the
      // breathing room kept below it, so the block keeps its metrics.
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [Divider(height: 1), SizedBox(height: 8)],
      );
    }
    final note = pinned[index - 1];
    return _RowTile(
      key: Key('pinned-${note.path}'),
      note: note,
      // No indentation and no chevron: a pinned note is shown regardless
      // of where it lives, so its folder depth would mean nothing here.
      depth: 0,
      isExpanded: false,
      selected: note.path == widget.selectedPath,
      onSelect: widget.onSelect,
      onToggle: widget.onToggle,
      onLongPress: widget.onLongPress,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      icon: Icons.push_pin_outlined,
    );
  }

  /// The pinned section's heading: a chevron, the word, and how many are
  /// in there. Tapping it rolls the section up or down.
  ///
  /// The count is what makes rolling it up bearable — closed, the heading
  /// still says how much is behind it, so the section is a thing you put
  /// away rather than a thing you lose.
  ///
  /// The row is exactly [editorToolbarHeight] tall, matching the editor
  /// toolbar across the pane boundary so the rows below start together
  /// (user, 2026-09-09).
  Widget _pinnedHeading(int count) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: editorToolbarHeight,
      child: InkWell(
        key: const Key('pinned-heading'),
        onTap: () => _togglePinned(collapsed: !_collapsed),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 16),
          child: Row(
            children: [
              Icon(
                _collapsed ? Icons.chevron_right : Icons.expand_more,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(AppStrings.pinnedSectionCount(count), style: style),
            ],
          ),
        ),
      ),
    );
  }

  /// Rolls the pinned section up or down, and remembers it for the
  /// library. The repaint does not wait on the write.
  void _togglePinned({required bool collapsed}) {
    setState(() => _pinnedCollapsed = collapsed);
    unawaited(widget.controller.setPinnedCollapsed(collapsed: collapsed));
  }
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

/// One row tile: chevron (folders) or doc icon (files), then the name —
/// the name column is shared, per the mockup.
final class _RowTile extends StatelessWidget {
  const new({
    required this.note,
    required this.depth,
    required this.isExpanded,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.icon,
    super.key,
  });

  final Note note;
  final int depth;
  final bool isExpanded;
  final bool selected;
  final void Function(Note note) onSelect;
  final ValueChanged<String> onToggle;
  final void Function(Note note)? onLongPress;
  final void Function(Note note, TapDownDetails details)? onSecondaryTapDown;

  /// Replaces the file-type icon; the pinned block uses it to say why the
  /// row is there.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onSelect(note),
      onLongPress: onLongPress == null ? null : () => onLongPress!(note),
      onSecondaryTapDown: onSecondaryTapDown == null
          ? null
          : (details) => onSecondaryTapDown!(note, details),
      child: Container(
        height: 40,
        color: selected ? theme.highlightColor.withValues(alpha: 0.4) : null,
        padding: EdgeInsets.only(left: depth * 16.0 + 8),
        child: Row(
          children: [
            if (note.isDir)
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                ),
                onPressed: () => onToggle(note.path),
              )
            else
              SizedBox(
                width: 48,
                child: Icon(icon ?? fileIconFor(note.name), size: 16),
              ),
            Expanded(
              child: Text(
                displayNameOf(note),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (note.date case final DateTime date)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Text(
                  isoDate(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What a note is called on screen: its frontmatter `title:` when it has
/// one, else its filename (T-M4-02).
///
/// The title is the note's own name for itself, so it wins wherever the
/// note is listed. The filename still decides the file on disk and still
/// resolves `[[links]]` — this changes what is shown, not what anything
/// points at.
String displayNameOf(Note note) {
  final title = note.title;
  return (title == null || title.isEmpty) ? note.name : title;
}

/// A frontmatter date as `YYYY-MM-DD` — the form it is written in.
String isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
