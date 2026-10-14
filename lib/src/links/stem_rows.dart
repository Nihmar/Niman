/// The `note_stems` rows a `[[` target is looked up in (#475, #491).
///
/// One indexed prefix query, then a contains query only while the prefix rows
/// leave room — the read `NoteNames` ranks.
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/stem_row.dart';

/// The matching `note_stems` rows of a library.
final class StemRows {
  /// Reads the stems of [_db].
  const new(this._db);

  final IndexDatabase _db;

  /// How many matching rows are fetched before the list is ranked and cut to
  /// `NoteNames.limit`. The indexed prefix query takes this many; the contains
  /// query — which cannot use the stem index (a leading `%`) — is read only
  /// while the prefix rows leave room, so a keystroke is not charged a `%q%`
  /// scan the prefix already answered (#475, #491).
  static const int _fetch = 200;

  /// A note, a PDF or an EPUB: the files a `[[…]]` link names, and the
  /// books the `#` half serves. Other attachments are left to embeds.
  static const String linkable =
      "(lower(substr(n.name, -3)) = '.md' "
      "OR lower(substr(n.name, -4)) = '.pdf' "
      "OR lower(substr(n.name, -5)) = '.epub')";

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
    final select =
        'SELECT s.stem AS stem, s.source AS source, n.id AS id, n.path AS path '
        'FROM note_stems AS s JOIN notes AS n ON n.id = s.note_id '
        'WHERE n.is_dir = 0 AND $files$scope';
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
      // first and cut by the cap. A contains match (`%q%`) has no index to
      // use — SQLite would evaluate the LIKE against every stem and sort the
      // matches before the LIMIT — so it is read, bounded by what the prefix
      // left, only when the prefix rows do not fill the cap (#491).
      final escaped = _escapeLike(q);
      final prefix = '$escaped%';
      var rows = await _db
          .customSelect(
            "$select AND s.stem LIKE ? ESCAPE '\\' "
            'ORDER BY n.path ASC LIMIT ?',
            variables: [
              ...scoped,
              Variable<String>(prefix),
              const Variable<int>(_fetch),
            ],
          )
          .get();
      if (rows.length < _fetch) {
        rows = [
          ...rows,
          ...await _db
              .customSelect(
                "$select AND s.stem LIKE ? ESCAPE '\\' "
                r"AND s.stem NOT LIKE ? ESCAPE '\' "
                'ORDER BY n.path ASC LIMIT ?',
                variables: [
                  ...scoped,
                  Variable<String>('%$escaped%'),
                  Variable<String>(prefix),
                  Variable<int>(_fetch - rows.length),
                ],
              )
              .get(),
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

  /// Escapes the LIKE wildcards in [s] so a query is matched literally.
  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
