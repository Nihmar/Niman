import 'package:copist/src/core/logging.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/library/session.dart';
import 'package:flutter/material.dart';

/// One row of the flattened tree (note/folder + its depth).
final class _Row {
  const _Row({required this.note, required this.depth});

  final Note note;
  final int depth;
}

/// Lazy tree of the library's folders/notes.
///
/// Rows are flattened from per-level `NoteDao.children` queries and rendered
/// in a single [ListView.builder], so a 10k-note library only materializes
/// the visible rows (T-M1-04).
final class NoteTree extends StatefulWidget {
  /// Creates the note tree.
  const NoteTree({
    required this.controller,
    required this.selectedPath,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
    super.key,
  });

  /// The session providing the index and the change-event stream.
  final LibrarySession controller;

  /// Library-relative path of the selected note/folder, or null.
  final String? selectedPath;

  /// Paths of the expanded folders.
  final Set<String> expanded;

  /// Called when a folder's chevron is tapped (expand/collapse).
  final ValueChanged<String> onToggle;

  /// Called with the row's note when the row is selected.
  final void Function(Note note) onSelect;

  @override
  State<NoteTree> createState() => _NoteTreeState();
}

final class _NoteTreeState extends State<NoteTree> {
  static const AppLogger _log = AppLogger(name: 'tree');

  /// How many paths are listed in a single debug log line before the rest
  /// is summarized, keeping huge folders from flooding the buffer.
  static const _logPathCap = 12;

  /// The rows currently being shown, and the inputs they were built from.
  ///
  /// The flatten runs one `children` query per expanded level, so it must
  /// not be restarted by every rebuild: selecting a note, toggling a
  /// button — any `setState` above this widget — used to re-query the
  /// whole visible tree, over a hundred queries a second on a real
  /// library. Reusing the same future also keeps [FutureBuilder] from
  /// flashing its spinner between rebuilds.
  Future<List<_Row>>? _rows;
  int? _rowsRevision;
  Set<String> _rowsExpanded = const <String>{};

  @override
  void didUpdateWidget(NoteTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _rows = null;
    }
  }

  /// The flattened rows for [revision], recomputed only when the index
  /// revision or the set of expanded folders has changed.
  Future<List<_Row>> _rowsFor(int revision) {
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

  /// Flattens the visible tree from the index.
  Future<List<_Row>> _flatten() async {
    final out = <_Row>[];
    await _walk(0, 0, out);
    return out;
  }

  Future<void> _walk(int parentId, int depth, List<_Row> out) async {
    final children = await widget.controller.children(parentId);
    _log.debug(
      'tree: children(parent=$parentId) -> ${children.length}: '
      '${_pathList(children.map((n) => n.path))}',
    );
    for (final note in children) {
      out.add(_Row(note: note, depth: depth));
      if (note.isDir && widget.expanded.contains(note.path)) {
        await _walk(note.id, depth + 1, out);
      }
    }
  }

  static String _pathList(Iterable<String> paths) {
    final iterator = paths.iterator;
    if (!iterator.moveNext()) return '(none)';
    final shown = <String>[iterator.current];
    var extra = 0;
    while (iterator.moveNext() && shown.length < _logPathCap) {
      shown.add(iterator.current);
    }
    while (iterator.moveNext()) {
      extra++;
    }
    final list = shown.join(', ');
    return extra > 0 ? '$list, … (+$extra more)' : list;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.controller.events,
      initialData: widget.controller.revision,
      builder: (context, snapshot) {
        return FutureBuilder<List<_Row>>(
          future: _rowsFor(snapshot.data ?? widget.controller.revision),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data!;
            if (rows.isEmpty) {
              return const Center(child: Text('No notes yet'));
            }
            return ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return _RowTile(
                  note: row.note,
                  depth: row.depth,
                  isExpanded: widget.expanded.contains(row.note.path),
                  selected: row.note.path == widget.selectedPath,
                  onSelect: widget.onSelect,
                  onToggle: widget.onToggle,
                );
              },
            );
          },
        );
      },
    );
  }
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

/// One row tile: chevron (folders), icon, and name.
final class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.note,
    required this.depth,
    required this.isExpanded,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
  });

  final Note note;
  final int depth;
  final bool isExpanded;
  final bool selected;
  final void Function(Note note) onSelect;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onSelect(note),
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
              const SizedBox(width: 24),
            Icon(note.isDir ? Icons.folder : Icons.article, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
