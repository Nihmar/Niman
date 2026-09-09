/// Tag-list and tag→note queries (design.md: search/tag_repo.dart).
///
/// Tags are answered from `tags`/`note_tags` — never from FTS — for the
/// tag list (counts) and for `#tag` searches. Path order for tag results,
/// so the same note folder grouping applies everywhere.
library;

import 'package:copist/src/db/index_database.dart';
import 'package:drift/drift.dart' show OrderingTerm;

/// A tag with its note count.
final class TagCount {
  /// Creates a tag count.
  const new({required this.name, required this.count});

  /// The normalized tag name.
  final String name;

  /// How many notes carry it (frontmatter or inline; one source per
  /// note-tag row, so a tag in both sources still counts once — the count
  /// is over DISTINCT note ids).
  final int count;
}

/// The tag data source the UI talks to (T-M3-06): tag list with counts
/// and tag→notes. [TagRepo] is the production implementation over drift;
/// widget tests inject a fake.
abstract interface class TagSource {
  /// Every tag with counts, most used first (ties alphabetical).
  Future<List<TagCount>> tagCounts();

  /// The notes carrying [tag] (normalized — no `#`), in path order.
  Future<List<Note>> notesWithTag(String tag);
}

/// The tag side of the search data (T-M3-04/T-M3-06).
final class TagRepo implements TagSource {
  /// Creates the repo over [IndexDatabase].
  new(this._db);

  final IndexDatabase _db;

  @override
  Future<List<TagCount>> tagCounts() async {
    final rows = await _db
        .customSelect(
          'SELECT tag, count(DISTINCT note_id) AS c FROM note_tags '
          'GROUP BY tag ORDER BY c DESC, tag ASC',
        )
        .get();
    return [
      for (final row in rows)
        TagCount(name: row.read<String>('tag'), count: row.read<int>('c')),
    ];
  }

  @override
  Future<List<Note>> notesWithTag(String tag) {
    return (_db.select(_db.notes)
          ..where(
            (n) => n.id.isInQuery(
              _db.selectOnly(_db.noteTags)
                ..addColumns([_db.noteTags.noteId])
                ..where(_db.noteTags.tag.equals(tag)),
            ),
          )
          ..orderBy([(n) => OrderingTerm.asc(n.path)]))
        .get();
  }
}
