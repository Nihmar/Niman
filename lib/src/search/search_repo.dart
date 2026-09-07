/// FTS5 word search over the index's own copy of the text
/// (design.md: search/search_repo.dart).
///
/// The query text is built by `buildFtsQuery` — it is never passed to the
/// engine raw. Ranking is `bm25(notes_fts, 10.0, 1.0)` (title weighted ten
/// times the body, lower is better); every result carries a body `snippet()`
/// around the first match.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart' show QueryRow, Variable;

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

/// The search data source the UI talks to: FTS word search and the
/// contains scan, both with the invocation-id guard.
///
/// [SearchRepo] is the production implementation over drift; widget tests
/// inject a fake.
abstract interface class SearchSource {
  /// Starts a new query; the previous one's results are superseded.
  int begin();

  /// Whether [id] is still the latest query (results are still wanted).
  bool isCurrent(int id);

  /// The ranked word-search hits for an FTS [query] built by
  /// `buildFtsQuery`; empty for a null/blank query. [id] from [begin];
  /// superseded queries return no hits.
  Future<List<SearchHit>> search(
    String? query, {
    required int id,
    int limit = 200,
  });

  /// The contains-mode hits: notes whose FTS body copy contains [pattern]
  /// (case-insensitive, `LIKE` semantics), in path order, each with an
  /// excerpt cut around the first match. [id] from [begin]; superseded
  /// queries return no hits.
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  });
}

/// Runs the word search and drops the results of a superseded query.
///
/// The UI starts a new query per keystroke (debounced): it calls [begin],
/// awaits the repo, and discards the response when another `begin` has
/// been issued in the meantime — the invocation-id guard. Not stateful
/// beyond the counter, so one instance can back several screens.
final class SearchRepo implements SearchSource {
  /// Creates the repo over [CopistDatabase].
  SearchRepo(this._db);

  final CopistDatabase _db;

  int _invocation = 0;

  @override
  int begin() => ++_invocation;

  @override
  bool isCurrent(int id) => id == _invocation;

  @override
  Future<List<SearchHit>> search(
    String? query, {
    required int id,
    int limit = 200,
  }) async {
    if (query == null || query.trim().isEmpty) return const [];
    const log = AppLogger(name: 'search');
    final clock = Stopwatch()..start();
    List<QueryRow> rows;
    try {
      rows = await _db
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
    } on Object catch (e) {
      log.warning('word search failed for "$query": $e');
      return const [];
    }
    if (!isCurrent(id)) return const [];
    log.debug(
      'word "$query" -> ${rows.length} hit(s) '
      'in ${clock.elapsedMilliseconds} ms',
    );
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

  @override
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  }) async {
    // The scan runs against the index's own copy of the text (the FTS
    // table's body column), never against the note files on disk. The
    // pattern is LIKE-escaped and lowercased, and SQL's lower() does the
    // comparison, so wildcards in the input are literal and the match is
    // case-insensitive.
    final lower = pattern.toLowerCase();
    if (lower.isEmpty) return const [];
    const log = AppLogger(name: 'search');
    final clock = Stopwatch()..start();
    List<QueryRow> rows;
    try {
      rows = await _db
          .customSelect(
            'SELECT notes.id, notes.path, notes.name, notes_fts.title, '
            'notes_fts.body AS body '
            'FROM notes_fts JOIN notes ON notes.id = notes_fts.rowid '
            r"WHERE lower(notes_fts.body) LIKE ?1 ESCAPE '\'"
            ' ORDER BY notes.path '
            'LIMIT ?2',
            variables: [
              Variable<String>('%${sqlLikeEscape(lower)}%'),
              Variable<int>(limit),
            ],
          )
          .get();
    } on Object catch (e) {
      log.warning('contains search failed for "$pattern": $e');
      return const [];
    }
    if (!isCurrent(id)) return const [];
    log.debug(
      'contains "$pattern" -> ${rows.length} hit(s) '
      'in ${clock.elapsedMilliseconds} ms',
    );
    return [
      for (final row in rows)
        SearchHit(
          noteId: row.read<int>('id'),
          path: row.read<String>('path'),
          title: row.read<String>('title'),
          snippet: _excerpt(row.read<String>('body'), lower),
        ),
    ];
  }

  /// Cuts [body] around its first (case-insensitive) occurrence of
  /// [lower] and marks it; `…` ellipses at the cut ends.
  static String _excerpt(String body, String lower) {
    final index = body.toLowerCase().indexOf(lower);
    if (index < 0) return '';
    const radius = 40;
    var start = index - radius;
    var end = index + lower.length + radius;
    if (start < 0) start = 0;
    if (end > body.length) end = body.length;
    final before = start > 0 ? '…' : '';
    final after = end < body.length ? '…' : '';
    final match = body.substring(index, index + lower.length);
    return '$before${body.substring(start, index)}'
        '<mark>$match</mark>'
        '${body.substring(index + lower.length, end)}$after';
  }
}
