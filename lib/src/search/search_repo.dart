/// FTS5 word search over the index's own copy of the text
/// (design.md: search/search_repo.dart).
///
/// The query text is built by `buildFtsQuery` — it is never passed to the
/// engine raw. Ranking is `bm25(notes_fts, 10.0, 1.0)` (title weighted ten
/// times the body, lower is better); every result carries a body `snippet()`
/// around the first match.
library;

import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart' show Variable;

/// One ranked search hit.
final class SearchHit {
  /// Creates a hit.
  const SearchHit({
    required this.noteId,
    required this.path,
    required this.title,
    required this.snippet,
  });

  /// The note row id (also the FTS rowid).
  final int noteId;

  /// Library-relative note path.
  final String path;

  /// The FTS title (frontmatter title or filename fallback).
  final String title;

  /// A body snippet around the first match, with `<mark>`/`</mark>` tags
  /// around the matched terms; empty when the match is title-only.
  final String snippet;
}

/// Runs the word search and drops the results of a superseded query.
///
/// The UI starts a new query per keystroke (debounced): it calls [begin],
/// awaits the repo, and discards the response when another `begin` has
/// been issued in the meantime — the invocation-id guard. Not stateful
/// beyond the counter, so one instance can back several screens.
final class SearchRepo {
  /// Creates the repo over [CopistDatabase].
  SearchRepo(this._db);

  final CopistDatabase _db;

  int _invocation = 0;

  /// Starts a new query; the previous one's results are superseded.
  int begin() => ++_invocation;

  /// Whether [id] is still the latest query (results are still wanted).
  bool isCurrent(int id) => id == _invocation;

  /// The ranked hits for an FTS [query] built by `buildFtsQuery`; an
  /// empty or malformed query returns no hits. [id] is an invocation id
  /// from `begin`; when superseded, the result is empty.
  Future<List<SearchHit>> search(
    String? query, {
    required int id,
    int limit = 200,
  }) async {
    if (query == null || query.trim().isEmpty) return const [];
    final rows = await _db
        .customSelect(
          'SELECT notes.id, notes.path, notes.name, notes_fts.title, '
          "snippet(notes_fts, 1, '<mark>', '</mark>', '…', 12) AS snippet "
          'FROM notes_fts JOIN notes ON notes.id = notes_fts.rowid '
          'WHERE notes_fts MATCH ?1 '
          'ORDER BY bm25(notes_fts, 10.0, 1.0) '
          'LIMIT ?2',
          variables: [Variable<String>(query), Variable<int>(limit)],
        )
        .get();
    if (!isCurrent(id)) return const [];
    return [
      for (final row in rows)
        SearchHit(
          noteId: row.read<int>('id'),
          path: row.read<String>('path'),
          title: row.read<String>('title'),
          snippet: row.read<String?>('snippet') ?? '',
        ),
    ];
  }
}
