import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';

/// Target ids per `WHERE to_note IN (…)` statement: SQLite binds 999
/// variables by default, so a set of targets is asked in chunks (#360).
const _idChunk = 500;

/// One note that links to another, as the index has it: its row id (the
/// cursor a page resumes after), its path, and its revision (mtime and size),
/// which says when what it says has to be read again.
typedef ReferrerRow = ({int id, String path, DateTime modified, int size});

/// A page of [ReferrerRow]s, by path, and the cursor of the next page —
/// null when this one is the last.
typedef ReferrerPage = ({List<ReferrerRow> items, int? next});

/// The reverse link lookups over `note_links`: who links to a note.
///
/// Both read the `links_to` index (`to_note, from_note, kind`), the
/// direction the table's primary key cannot answer: a note's own inbound
/// edges, never a walk of the library.
final class ReferrerDao {
  /// Creates the lookups over [_db].
  new(this._db);

  final IndexDatabase _db;

  /// The query behind [page], public so a test can hold its plan to an
  /// index walk: `?1` the target, `?2` the cursor, `?3` the page size.
  static const String pageQuery =
      'SELECT l.from_note AS id, n.path AS path, n.modified AS modified, '
      'n.size AS size '
      'FROM note_links l JOIN notes n ON n.id = l.from_note '
      'WHERE l.to_note = ?1 AND l.from_note > ?2 AND l.from_note <> ?1 '
      'GROUP BY l.from_note ORDER BY l.from_note LIMIT ?3';

  /// The paths of the notes holding a link to any note in [toIds], distinct:
  /// the backlinks of a moved note, in one lookup per [_idChunk] target ids
  /// (#507).
  Future<List<String>> pathsOf(Iterable<int> toIds) async {
    final wanted = toIds.toSet().toList(growable: false);
    if (wanted.isEmpty) return const <String>[];
    final paths = <String>{};
    for (var i = 0; i < wanted.length; i += _idChunk) {
      final end = i + _idChunk < wanted.length ? i + _idChunk : wanted.length;
      final placeholders = List.filled(end - i, '?').join(', ');
      final rows = await _db
          .customSelect(
            'SELECT DISTINCT n.path AS path FROM note_links l '
            'JOIN notes n ON n.id = l.from_note '
            'WHERE l.to_note IN ($placeholders)',
            variables: [
              for (final id in wanted.sublist(i, end)) Variable.withInt(id),
            ],
            readsFrom: {_db.noteLinks, _db.notes},
          )
          .get();
      paths.addAll([for (final row in rows) row.read<String>('path')]);
    }
    return paths.toList(growable: false);
  }

  /// The notes that link to the note [toId] (#842): at most [limit] of them,
  /// the ones after the cursor [after] (0 for the first page).
  ///
  /// The edges are read in the index's own order — by the referrer's id,
  /// one entry each, stopping at [limit] — so a note a million others link
  /// to costs a page, not a sort of every edge; the page is put in path
  /// order here. The note itself is left out (a link to its own heading is
  /// no one else's mention), and so is a link to a note that is not there:
  /// dead links are not edges. Embeds and images are edges too (#507); the
  /// reader of the referrer's text tells them apart.
  Future<ReferrerPage> page(
    int toId, {
    required int limit,
    int after = 0,
  }) async {
    final rows = await _db
        .customSelect(
          pageQuery,
          variables: [
            Variable.withInt(toId),
            Variable.withInt(after),
            Variable.withInt(limit + 1),
          ],
          readsFrom: {_db.noteLinks, _db.notes},
        )
        .get();
    final kept = rows.take(limit).toList(growable: false);
    final items = <ReferrerRow>[
      for (final row in kept)
        (
          id: row.read<int>('id'),
          path: row.read<String>('path'),
          modified: row.read<DateTime>('modified'),
          size: row.read<int>('size'),
        ),
    ];
    final next = rows.length > limit && kept.isNotEmpty
        ? kept.last.read<int>('id')
        : null;
    items.sort((a, b) => a.path.compareTo(b.path));
    return (items: items, next: next);
  }
}
