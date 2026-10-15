/// The links that wait for a note not made yet (#974).
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/resolver.dart';

/// A link target a note holds that no note answered: the note it is written
/// in, the target text as written, the link form, and where the note sits
/// (a `..` walks from its folder).
typedef WaitingLink = ({int noteId, LinkQuery query, String kind});

/// Keeps the targets no note answers when a note is indexed, and turns them
/// into `note_links` edges when a note that answers them appears (#974).
///
/// An edge is written only for a link that resolves, and only when its own
/// note is indexed, so a link to a note made later had none: "Links to this
/// note" missed it, and a rename of the target left it to die again. The
/// store closes that gap without reading a note: the unresolved targets sit
/// in `dangling_links` keyed by the stem a note must carry to answer them,
/// and a stem that gains a note is an index lookup into it.
///
/// The stems that gained a note are collected as the content store writes
/// them ([appeared]) and settled in one go ([flush]) by whoever finished a
/// write — a bound on how many are kept makes a bulk write fall back to
/// [resolveAll], so a first index of a million notes holds no set of them.
final class DanglingLinkStore {
  /// Creates the store over [_db].
  new(this._db);

  final IndexDatabase _db;

  /// How many stems are collected before [flush] settles everything instead.
  static const _stemBound = 256;

  /// Waiting links read per page.
  static const _page = 500;

  final Set<String> _appeared = <String>{};

  /// Whether more stems appeared than [_stemBound] holds.
  bool _overflowed = false;

  /// Notes that appeared under [stem] (a note's file stem or one of its
  /// aliases, as `note_stems` has it) since the last [flush].
  void appeared(String stem) {
    if (_overflowed) return;
    _appeared.add(stem);
    if (_appeared.length > _stemBound) {
      _appeared.clear();
      _overflowed = true;
    }
  }

  /// Resolves the links waiting for the stems that appeared since the last
  /// call: by the stems themselves, or — when too many appeared to keep —
  /// all of them.
  Future<void> flush() async {
    if (!_overflowed && _appeared.isEmpty) return;
    if (_overflowed) {
      _overflowed = false;
      await resolveAll();
      return;
    }
    final stems = _appeared.toList(growable: false);
    _appeared.clear();
    await resolveStems(stems);
  }

  /// Forgets the waiting links of note [noteId]: it is indexed again, which
  /// writes the ones it holds now.
  Future<void> forget(int noteId) async {
    await (_db.delete(
      _db.danglingLinks,
    )..where((l) => l.noteId.equals(noteId))).go();
  }

  /// Keeps [links] as waiting, each under the stems a note must carry to
  /// answer it. A link no note can answer is not kept.
  Future<void> keep(Iterable<WaitingLink> links) async {
    final rows = <DanglingLinksCompanion>[
      for (final link in links)
        for (final stem in LinkResolver.stemsOf(link.query))
          DanglingLinksCompanion.insert(
            noteId: link.noteId,
            stem: stem,
            target: link.query.target,
            kind: link.kind,
          ),
    ];
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.danglingLinks, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  /// Writes the edges of the links waiting for [stems] that a note now
  /// answers. A page at a time per stem, so a stem a hundred thousand notes
  /// wait for costs pages, not a read of all of them.
  Future<void> resolveStems(Iterable<String> stems) async {
    for (final stem in stems.toSet()) {
      var after = 0;
      while (true) {
        final rows = await _db
            .customSelect(
              _waitingOn,
              variables: [Variable<String>(stem), Variable<int>(after)],
              readsFrom: {_db.danglingLinks, _db.notes},
            )
            .get();
        if (rows.isEmpty) break;
        after = rows.last.read<int>('rid');
        await _resolve(rows);
        if (rows.length < _page) break;
      }
    }
  }

  /// Writes the edges of every waiting link a note answers now: the settling
  /// after a bulk write, whose stems were too many to keep. One pass over
  /// the waiting links, a page at a time, each checked against `note_stems`
  /// by its key — the cost of the dead links, not of the notes.
  Future<void> resolveAll() async {
    var after = 0;
    while (true) {
      final rows = await _db
          .customSelect(
            'SELECT d.rowid AS rid, d.note_id AS note_id, '
            'd.target AS target, d.kind AS kind, n.path AS path '
            'FROM dangling_links d JOIN notes n ON n.id = d.note_id '
            'WHERE d.rowid > ?1 AND EXISTS '
            '(SELECT 1 FROM note_stems s WHERE s.stem = d.stem) '
            'ORDER BY d.rowid LIMIT $_page',
            variables: [Variable<int>(after)],
            readsFrom: {_db.danglingLinks, _db.notes, _db.noteStems},
          )
          .get();
      if (rows.isEmpty) break;
      after = rows.last.read<int>('rid');
      await _resolve(rows);
      if (rows.length < _page) break;
    }
  }

  /// The links waiting on one stem past a cursor: `?1` the stem, `?2` the
  /// row to continue after. The index on `stem` walks them in row order.
  static const _waitingOn =
      'SELECT d.rowid AS rid, d.note_id AS note_id, d.target AS target, '
      'd.kind AS kind, n.path AS path '
      'FROM dangling_links d JOIN notes n ON n.id = d.note_id '
      'WHERE d.stem = ?1 AND d.rowid > ?2 ORDER BY d.rowid LIMIT $_page';

  /// Resolves [rows] and writes the edge of each that a note answers now.
  Future<void> _resolve(List<QueryRow> rows) async {
    LinkQuery queryOf(QueryRow row) => (
      target: row.read<String>('target'),
      from: row.read<String>('path'),
      markdown: row.read<String>('kind') == 'md',
    );
    final resolved = await LinkResolver(_db)
        .resolveQueries({for (final row in rows) queryOf(row)});
    await _db.transaction(() async {
      for (final row in rows) {
        final fromNote = row.read<int>('note_id');
        final outcome = resolved[queryOf(row)];
        if (outcome is! ResolvedNote || outcome.note.id == fromNote) continue;
        await _db.customInsert(
          'INSERT OR IGNORE INTO note_links (from_note, to_note, kind) '
          'VALUES (?, ?, ?)',
          variables: [
            Variable<int>(fromNote),
            Variable<int>(outcome.note.id),
            Variable<String>(row.read<String>('kind')),
          ],
        );
      }
    });
  }
}
