/// The notes Go to note and the palette find by what is typed (#1043).
///
/// The same lookup the `[[` panel makes — the names and the aliases in
/// `note_stems`, by prefix and then by the trigram index — so a note is
/// found by an alias as well as by its file name, and the exact name is
/// the first row. After the names, the notes whose title (the frontmatter
/// `title:`, else the file name) holds a word that starts with the text:
/// the full-text index's title column, a prefix lookup bounded by its
/// limit. No query here reads more rows than it returns.
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/stem_rank.dart';
import 'package:niman/src/links/stem_rows.dart';
import 'package:niman/src/search/query.dart';

/// Finds notes by name, alias and title in the library's index.
final class NoteFinder {
  /// Reads the index [_db].
  const new(this._db);

  final IndexDatabase _db;

  /// How many characters a text needs before it finds anything: a single
  /// letter names half the library.
  static const int minChars = 2;

  /// The paths of the files [query] finds, best first, at most [limit]:
  /// the name or alias typed in full, the names that start with it, the
  /// ones that hold it, then the titles with a word that starts with it.
  Future<List<String>> paths(String query, {int limit = 50}) async {
    final q = query.trim().toLowerCase();
    if (q.runes.length < minChars) return const [];
    final rows = await StemRows(_db).rows(q, StemRows.anyFile);
    final out = <String>[
      for (final r in rankStems(rows, q).take(limit)) r.path,
    ];
    if (out.length < limit) {
      final seen = out.toSet();
      for (final path in await _titled(q, limit: limit)) {
        if (out.length >= limit) break;
        if (seen.add(path)) out.add(path);
      }
    }
    return out;
  }

  /// The files whose title holds a word starting with each word of [q],
  /// at most [limit], in the index's own order.
  Future<List<String>> _titled(String q, {required int limit}) async {
    final match = buildFtsQuery(q);
    if (match == null) return const [];
    final rows = await _db
        .customSelect(
          'SELECT n.path AS path FROM notes_fts '
          'CROSS JOIN notes AS n ON n.id = notes_fts.rowid '
          'WHERE notes_fts MATCH ? AND n.is_dir = 0 LIMIT ?',
          variables: [
            Variable<String>('title : ($match)'),
            Variable<int>(limit),
          ],
        )
        .get();
    return [for (final row in rows) row.read<String>('path')];
  }
}
