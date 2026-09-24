/// FTS5 word search over the index's word index, and the contains scan
/// over the notes themselves (design.md: search/search_repo.dart).
///
/// The query text is built by `buildFtsQuery` — it is never passed to the
/// engine raw. Ranking is `bm25(notes_fts, 10.0, 1.0)` (title weighted ten
/// times the body, lower is better).
///
/// The index keeps no copy of the text (`IndexDatabase`), so what is read
/// out of a note — a word result's excerpt, a contains match — is read from
/// the note on disk, off the UI isolate and no further than its first match
/// (`search_excerpt.dart`).
library;

import 'dart:isolate';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/search/search_excerpt.dart';
import 'package:path/path.dart' as p;

/// One ranked search hit.
final class SearchHit {
  /// Creates a hit.
  const new({
    required this.noteId,
    required this.path,
    required this.title,
    required this.snippet,
  });

  /// The note row id (also the FTS rowid).
  final int noteId;

  /// Library-relative note path.
  final String path;

  /// The frontmatter title, or the filename without `.md`.
  final String title;

  /// The text around the first match, with `<mark>`/`</mark>` around it;
  /// empty when there is none to show, or none yet — a word result's is
  /// read on demand ([SearchSource.excerpt]).
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

  /// The contains-mode hits: notes whose text contains [pattern]
  /// (case- and accent-insensitive, a literal string), in path order, each
  /// with an excerpt cut around the first match. [id] from [begin];
  /// superseded queries return no hits.
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  });

  /// The excerpt of word result [hit] for the words typed as [userText]:
  /// read from the note when a row asks for it, so a search answers with
  /// its list and reads only the notes whose rows are shown. Empty when the
  /// words are only in the title.
  Future<String> excerpt(SearchHit hit, String userText);
}

/// Runs the word search and drops the results of a superseded query.
///
/// The UI starts a new query per keystroke (debounced): it calls [begin],
/// awaits the repo, and discards the response when another `begin` has
/// been issued in the meantime — the invocation-id guard. Not stateful
/// beyond the counter, so one instance can back several screens.
final class SearchRepo implements SearchSource {
  /// Creates the repo over [IndexDatabase], for the library at [root] — the
  /// notes the excerpts and the contains scan are read from.
  new(this._db, {required this.root});

  final IndexDatabase _db;

  /// Absolute path of the library root.
  final String root;

  /// How many notes one step of the contains scan reads before it asks
  /// whether its query is still the current one.
  static const int _scanBatch = 200;

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
            'SELECT notes.id, notes.path, notes.name, notes.title '
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
    if (!isCurrent(id)) {
      log.debug(
        'word "$query" (id $id): superseded by id $_invocation — dropped',
      );
      return const [];
    }
    log.debug(
      'word "$query" -> ${rows.length} hit(s) '
      'in ${clock.elapsedMilliseconds} ms',
    );
    return [for (final row in rows) _hitOf(row, snippet: '')];
  }

  @override
  Future<String> excerpt(SearchHit hit, String userText) async {
    final terms = wordTermsOf(userText);
    if (terms.isEmpty) return '';
    try {
      return await _wordExcerpt(p.join(root, hit.path), terms) ?? '';
    } on Object catch (e) {
      const AppLogger(name: 'search').warning('excerpt of ${hit.path}: $e');
      return '';
    }
  }

  @override
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  }) async {
    // A scan of the notes themselves, in path order: the index keeps no
    // copy of their text to scan instead. The notes are listed a batch at
    // a time and each batch read on an isolate — every note only up to its
    // first match — with the query asked after each batch whether it is
    // still the one wanted, so a keystroke stops the scan it replaces.
    if (foldForSearch(pattern).isEmpty) return const [];
    const log = AppLogger(name: 'search');
    final clock = Stopwatch()..start();
    final hits = <SearchHit>[];
    var after = '';
    var read = 0;
    try {
      while (hits.length < limit) {
        final rows = await _db
            .customSelect(
              'SELECT id, path, name, title FROM notes '
              "WHERE is_dir = 0 AND lower(substr(name, -3)) = '.md' "
              'AND path > ?1 ORDER BY path LIMIT ?2',
              variables: [
                Variable<String>(after),
                const Variable<int>(_scanBatch),
              ],
            )
            .get();
        if (rows.isEmpty) break;
        after = rows.last.read<String>('path');
        final paths = [
          for (final row in rows) p.join(root, row.read<String>('path')),
        ];
        final excerpts = await _containsExcerpts(paths, pattern);
        read += rows.length;
        if (!isCurrent(id)) {
          log.debug(
            'contains "$pattern" (id $id): superseded by id $_invocation '
            'after $read note(s) — dropped',
          );
          return const [];
        }
        for (var i = 0; i < rows.length && hits.length < limit; i++) {
          final excerpt = excerpts[i];
          if (excerpt != null) hits.add(_hitOf(rows[i], snippet: excerpt));
        }
      }
    } on Object catch (e) {
      log.warning('contains search failed for "$pattern": $e');
      return const [];
    }
    log.debug(
      'contains "$pattern" -> ${hits.length} hit(s) from $read note(s) '
      'in ${clock.elapsedMilliseconds} ms',
    );
    return hits;
  }

  static SearchHit _hitOf(QueryRow row, {required String snippet}) {
    final name = row.read<String>('name');
    return SearchHit(
      noteId: row.read<int>('id'),
      path: row.read<String>('path'),
      title:
          row.read<String?>('title') ??
          (name.toLowerCase().endsWith('.md')
              ? name.substring(0, name.length - 3)
              : name),
      snippet: snippet,
    );
  }
}

// The isolate runs are top-level so each closure captures only the plain
// values it is handed: inside a method it would capture the method's
// context, which holds the async body's future and cannot be sent.

/// The word excerpt of the note at [abs], on an isolate.
Future<String?> _wordExcerpt(String abs, List<String> terms) =>
    Isolate.run(() => excerptInFile(abs, wordFinder(terms)));

/// The contains excerpt of each note at [paths], null where it has none,
/// on an isolate.
Future<List<String?>> _containsExcerpts(List<String> paths, String pattern) =>
    Isolate.run(() async {
      final find = containsFinder(pattern);
      return [for (final path in paths) await excerptInFile(path, find)];
    });
