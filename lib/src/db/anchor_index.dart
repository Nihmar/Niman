/// The headings and block ids of the whole library, searched by what was
/// typed (#844, #845): what `[[##term` and `[[^^term` list.
///
/// A note's headings and ids are rows (`note_headings`, `note_blocks`), and
/// the words of both are in one row per note of `note_anchors_fts`. A search
/// is a prefix query on that word index, taken in note order and cut to
/// `candidateNotes` notes, and the rows of those notes are then read by their
/// key and told apart by what was typed, compared in the index's own fold
/// (`foldForIndex`): what the word index matched, the filter keeps. Nothing
/// walks the headings of the library: a million notes cost the same lookup
/// as a hundred, and the answer is bounded by `candidateNotes` and the
/// `limit` asked for.
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/search/index_fold.dart';

/// A heading found by a library-wide search.
typedef HeadingHit = ({String path, String heading, int line, int level});

/// A block id found by a library-wide search.
typedef BlockHit = ({String path, String blockId, int line, String excerpt});

/// The library-wide search over headings and block ids.
final class AnchorIndex {
  /// A search over [_db].
  new(this._db);

  final IndexDatabase _db;

  /// How many notes a search takes from the word index before the rows are
  /// read and told apart by the query: the bound on the work, whatever the
  /// size of the library or how common the typed word is.
  static const int candidateNotes = 200;

  /// The words of a folded query, the way the word index splits text: runs
  /// of letters, digits and the marks the fold keeps.
  static final RegExp _word = RegExp(r'[\p{L}\p{N}\p{M}]+', unicode: true);

  /// Headings across the library that match [query], best first: a heading
  /// that starts with the typed text before one that holds it, then by note
  /// path and line. An empty [query] lists the first headings of the first
  /// notes. At most [limit] rows.
  Future<List<HeadingHit>> headings(String query, {required int limit}) async {
    final q = foldForIndex(query.trim());
    final words = _words(q);
    if (q.isNotEmpty && words.isEmpty) return const <HeadingHit>[];
    final List<QueryRow> rows;
    if (q.isEmpty) {
      rows = await _db
          .customSelect(
            'SELECT n.path AS path, h.heading AS heading, h.line AS line, '
            'h.level AS level FROM note_headings AS h '
            'JOIN notes AS n ON n.id = h.note_id '
            'ORDER BY h.note_id, h.line LIMIT ?',
            variables: [Variable<int>(limit)],
          )
          .get();
    } else {
      final ids = await _candidates('headings', words);
      if (ids.isEmpty) return const <HeadingHit>[];
      rows = await _db
          .customSelect(
            'SELECT n.path AS path, h.heading AS heading, h.line AS line, '
            'h.level AS level FROM note_headings AS h '
            'JOIN notes AS n ON n.id = h.note_id '
            'WHERE h.note_id IN (${_marks(ids.length)})',
            variables: [for (final id in ids) Variable<int>(id)],
          )
          .get();
    }
    final hits = <HeadingHit>[
      for (final row in rows)
        (
          path: row.read<String>('path'),
          heading: row.read<String>('heading'),
          line: row.read<int>('line'),
          level: row.read<int>('level'),
        ),
    ];
    return _best(
      hits,
      limit,
      q,
      words,
      (hit) => hit.heading,
      (hit) => hit.path,
      (hit) => hit.line,
    );
  }

  /// Block ids across the library that match [query], best first: an id
  /// that starts with the typed text before one that holds it (or whose
  /// first words do), then by note path and line. An empty [query] lists the
  /// first ids of the first notes. At most [limit] rows.
  Future<List<BlockHit>> blocks(String query, {required int limit}) async {
    final q = foldForIndex(query.trim());
    final words = _words(q);
    if (q.isNotEmpty && words.isEmpty) return const <BlockHit>[];
    final List<QueryRow> rows;
    if (q.isEmpty) {
      rows = await _db
          .customSelect(
            'SELECT n.path AS path, b.block_id AS block_id, b.line AS line, '
            'b.excerpt AS excerpt FROM note_blocks AS b '
            'JOIN notes AS n ON n.id = b.note_id '
            'ORDER BY b.note_id, b.line LIMIT ?',
            variables: [Variable<int>(limit)],
          )
          .get();
    } else {
      final ids = await _candidates('blocks', words);
      if (ids.isEmpty) return const <BlockHit>[];
      rows = await _db
          .customSelect(
            'SELECT n.path AS path, b.block_id AS block_id, b.line AS line, '
            'b.excerpt AS excerpt FROM note_blocks AS b '
            'JOIN notes AS n ON n.id = b.note_id '
            'WHERE b.note_id IN (${_marks(ids.length)})',
            variables: [for (final id in ids) Variable<int>(id)],
          )
          .get();
    }
    final hits = <BlockHit>[
      for (final row in rows)
        (
          path: row.read<String>('path'),
          blockId: row.read<String>('block_id'),
          line: row.read<int>('line'),
          excerpt: row.read<String>('excerpt'),
        ),
    ];
    return _best(
      hits,
      limit,
      q,
      words,
      (hit) => '${hit.blockId} ${hit.excerpt}',
      (hit) => hit.path,
      (hit) => hit.line,
      lead: (hit) => hit.blockId,
    );
  }

  static List<String> _words(String q) => [
    for (final match in _word.allMatches(q)) match.group(0)!,
  ];

  static String _marks(int count) => List.filled(count, '?').join(', ');

  /// The ids of the first [candidateNotes] notes whose [column] holds every
  /// word of [words], the last as a prefix, in note order.
  Future<List<int>> _candidates(String column, List<String> words) async {
    final phrase = [for (final word in words) '"$word"'].join(' ');
    final rows = await _db
        .customSelect(
          'SELECT rowid FROM note_anchors_fts WHERE note_anchors_fts MATCH ? '
          'ORDER BY rowid LIMIT ?',
          variables: [
            Variable<String>('$column : ($phrase *)'),
            const Variable<int>(candidateNotes),
          ],
        )
        .get();
    return [for (final row in rows) row.read<int>('rowid')];
  }

  /// [hits] that hold every word of the folded query [q] in their [text],
  /// ranked and cut to [limit]: a [lead] (or [text]) that starts with [q]
  /// first, then by path and line.
  static List<T> _best<T>(
    List<T> hits,
    int limit,
    String q,
    List<String> words,
    String Function(T hit) text,
    String Function(T hit) path,
    int Function(T hit) line, {
    String Function(T hit)? lead,
  }) {
    if (q.isEmpty) return hits;
    final kept = <(T, bool)>[];
    for (final hit in hits) {
      final folded = foldForIndex(text(hit));
      if (!words.every(folded.contains)) continue;
      final head = foldForIndex((lead ?? text)(hit));
      kept.add((hit, head.startsWith(q)));
    }
    kept.sort((a, b) {
      if (a.$2 != b.$2) return a.$2 ? -1 : 1;
      final byPath = path(a.$1).compareTo(path(b.$1));
      return byPath != 0 ? byPath : line(a.$1).compareTo(line(b.$1));
    });
    return [for (final (hit, _) in kept.take(limit)) hit];
  }
}
