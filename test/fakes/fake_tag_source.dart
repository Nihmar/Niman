import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/search/tag_repo.dart';

/// In-memory [TagSource] for widget tests: a tag → note-path map.
///
/// Counts derive from the map (distinct notes per tag); [notesWithTag]
/// resolves paths against [notes] (default: a path row for every path in
/// the map). Entries are mutable, so tests can reshape the data.
final class FakeTagSource implements TagSource {
  /// Creates a fake source over [tags] (tag → note paths).
  new({Map<String, List<String>>? tags})
    : tags = tags ?? <String, List<String>>{};

  /// tag → note paths (mutable).
  Map<String, List<String>> tags;

  /// Rows for [notesWithTag] when [tags] alone is not enough; defaults to
  /// the paths in [tags] plus [notes].
  List<Note> notes = [];

  List<Note> _rowsFor(List<String> paths) {
    final rows = <Note>[];
    for (final path in paths) {
      rows.add(
        notes.firstWhere(
          (n) => n.path == path,
          orElse: () => Note(
            id: path.hashCode & 0x7fffffff,
            path: path,
            parent: 0,
            name: path.split('/').last,
            isDir: false,
            size: 0,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
            pinned: false,
          ),
        ),
      );
    }
    return rows;
  }

  @override
  Future<List<TagCount>> tagCounts() async {
    final counts = <String, int>{};
    for (final entry in tags.entries) {
      final distinct = entry.value.toSet();
      counts[entry.key] = distinct.length;
    }
    final out =
        [
          for (final entry in counts.entries)
            TagCount(name: entry.key, count: entry.value),
        ]..sort((a, b) {
          final byCount = b.count.compareTo(a.count);
          return byCount != 0 ? byCount : a.name.compareTo(b.name);
        });
    return out;
  }

  @override
  Future<List<Note>> notesWithTag(
    String tag, {
    int limit = tagNotesLimit,
  }) async {
    final paths = List<String>.of(tags[tag] ?? const [])..sort();
    final rows = _rowsFor(paths);
    return rows.length <= limit ? rows : rows.sublist(0, limit);
  }
}
