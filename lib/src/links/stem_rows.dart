/// The `note_stems` rows a `[[` target is looked up in (#475, #491).
///
/// One indexed prefix query, then a contains query only while the prefix rows
/// leave room — the read `NoteNames` ranks.
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/stem_trigrams.dart';
import 'package:niman/src/links/stem_row.dart';

/// The matching `note_stems` rows of a library.
final class StemRows {
  /// Reads the stems of [_db].
  const new(this._db);

  final IndexDatabase _db;

  /// How many matching rows are fetched before the list is ranked and cut to
  /// `NoteNames.limit`. The indexed prefix query takes this many, in stem
  /// order (the name typed in full first); the contains
  /// query — which cannot use the stem index (a leading `%`) — is read only
  /// while the prefix rows leave room, so a keystroke is not charged a `%q%`
  /// scan the prefix already answered (#475, #491).
  static const int _fetch = 200;

  /// What a stem that starts with `q` is below: `q` followed by the last
  /// code point (U+10FFFF) bounds the prefix range from above.
  static const String _afterPrefix = '\u{10FFFF}';

  /// A note, a PDF or an EPUB: the files a `[[…]]` link names, and the
  /// books the `#` half serves. Other attachments are left to embeds.
  static const String linkable =
      "(lower(substr(n.name, -3)) = '.md' "
      "OR lower(substr(n.name, -4)) = '.pdf' "
      "OR lower(substr(n.name, -5)) = '.epub')";

  /// Every file, whatever its kind: what Go to note finds (#1043).
  static const String anyFile = '1 = 1';

  /// Every file but a note: what an `![[` embed names first (#705).
  static const String attachment = "lower(substr(n.name, -3)) <> '.md'";

  /// A note: what an `![[` embed names after the attachments, a PDF or an
  /// EPUB being one of those.
  static const String note = "lower(substr(n.name, -3)) = '.md'";

  /// The matching `note_stems` rows of the [files] kind ([linkable],
  /// [attachment] or [note]) joined to their file, prefix matches first. An
  /// empty [q] lists every file, by path; a non-empty one reads the indexed
  /// prefix matches, then the contains matches only while the cap has room
  /// (#491). With [under], only the files in that folder (at any depth) — or,
  /// [outside], only the others.
  Future<List<StemRow>> rows(
    String q,
    String files, {
    String? under,
    bool outside = false,
  }) async {
    final scope = under == null
        ? ''
        : " AND n.path ${outside ? 'NOT ' : ''}LIKE ? ESCAPE '\\'";
    final scoped = <Variable<Object>>[
      if (under != null) Variable<String>('${_escapeLike(under)}/%'),
    ];
    String selectWith(String join) =>
        'SELECT s.stem AS stem, s.source AS source, n.id AS id, n.path AS path '
        'FROM note_stems AS s $join notes AS n ON n.id = s.note_id '
        'WHERE n.is_dir = 0 AND $files$scope';
    final select = selectWith('JOIN');
    final List<QueryRow> result;
    if (q.isEmpty) {
      result = await _db
          .customSelect(
            '$select ORDER BY n.path ASC LIMIT ?',
            variables: [...scoped, const Variable<int>(_fetch)],
          )
          .get();
    } else {
      // A prefix match (`q%`) is answered by the stem index, so it is read
      // first and cut by the cap. A contains match is answered by the
      // trigram index of the names, bounded by what the prefix left, and
      // only when the prefix rows do not fill the cap (#491, #1036): the
      // `%q%` it replaces had no index to use, and SQLite evaluated the
      // LIKE against every stem.
      //
      // The prefix is a range on the stem column, so the seek is the index's
      // whatever the LIKE optimizer would make of the pattern, and the rows
      // come out in stem order: the name typed in full, if there is one,
      // sorts first, and the cut keeps the closest names rather than the
      // first folders (#1035). `NoteNames` ranks what is fetched.
      var rows = await _db
          .customSelect(
            // CROSS JOIN fixes the order: the stems by their index, each
            // joined to its note. Left to itself the planner starts from
            // the notes (it has no statistics here) and walks every file.
            '${selectWith('CROSS JOIN')} AND s.stem >= ? AND s.stem < ? '
            'ORDER BY s.stem ASC LIMIT ?',
            variables: [
              ...scoped,
              Variable<String>(q),
              Variable<String>('$q$_afterPrefix'),
              const Variable<int>(_fetch),
            ],
          )
          .get();
      if (rows.length < _fetch) {
        rows = [
          ...rows,
          ...await _containing(
            q,
            files,
            scope,
            scoped,
            limit: _fetch - rows.length,
          ),
        ];
      }
      result = rows;
    }
    return [
      for (final row in result)
        StemRow(
          id: row.read<int>('id'),
          path: row.read<String>('path'),
          stem: row.read<String>('stem'),
          source: row.read<String>('source'),
        ),
    ];
  }

  /// The rows whose stem holds [q] but does not start with it, at most
  /// [limit] (#1043, #1036): the notes the trigram index names for [q], then
  /// the rows of theirs that really hold it, which trims what the
  /// tokenizer's folding lets through. Nothing for a [q] shorter than a
  /// trigram, nor on a file that has no trigram index yet.
  Future<List<QueryRow>> _containing(
    String q,
    String files,
    String scope,
    List<Variable<Object>> scoped, {
    required int limit,
  }) async {
    final match = stemTrigramQuery(q);
    if (match == null) return const [];
    try {
      return await _db
          .customSelect(
            'SELECT s.stem AS stem, s.source AS source, n.id AS id, '
            'n.path AS path FROM $stemTrigramsTable AS t '
            'CROSS JOIN note_stems AS s ON s.note_id = t.rowid '
            'CROSS JOIN notes AS n ON n.id = s.note_id '
            'WHERE t.stem MATCH ? AND n.is_dir = 0 AND $files$scope '
            r"AND s.stem LIKE ? ESCAPE '\' "
            'AND NOT (s.stem >= ? AND s.stem < ?) LIMIT ?',
            variables: [
              Variable<String>(match),
              ...scoped,
              Variable<String>('%${_escapeLike(q)}%'),
              Variable<String>(q),
              Variable<String>('$q$_afterPrefix'),
              Variable<int>(limit),
            ],
          )
          .get();
    } on Object catch (error) {
      // A file from before the index: it is built behind the tree once
      // the library is open, and the names it holds start with the query
      // until then.
      if ('$error'.contains('no such table')) return const [];
      rethrow;
    }
  }

  /// Escapes the LIKE wildcards in [s] so a query is matched literally.
  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
