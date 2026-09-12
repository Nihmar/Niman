/// Content-derived index rows: FTS, tags, links, fields and stems.
/// Everything the index derives from a note's parsed text, written and
/// repaired behind the indexer's orchestration.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

/// Writes and repairs the content-derived rows of the notes index (#51).
///
/// Owned by the indexer facade, which calls [applyContent] after the
/// notes rows of a batch are written.
final class IndexContentStore {
  /// Creates the store over the given [IndexDatabase].
  new(this._db, this._dao) : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final AppLogger _log;

  /// How many notes' content rows are written per chunk transaction
  /// (T-M3-09: a big backfill must not hold frames for its whole run).
  static const _contentChunk = 64;

  /// One row's stem text, or null for directories. Every file gets a stem
  /// (not just `.md`): `![[…]]` embeds reference attachments by bare name,
  /// and the resolver answers those through the same index.
  static String? _stemFor(String name, [bool isDir = false]) =>
      isDir ? null : noteStem(name);

  /// Makes the `note_stems` rows for note [noteId] match its current
  /// [name]: deletes whatever is there (a rename moves the stem rows) and
  /// inserts the row for the new name when the row is a file.
  Future<void> replaceFileStems(
    int noteId,
    String name, {
    bool isDir = false,
  }) async {
    await (_db.delete(
      _db.noteStems,
    )..where((s) => s.noteId.equals(noteId))).go();
    final stem = _stemFor(name, isDir);
    if (stem == null) return;
    await _db
        .into(_db.noteStems)
        .insert(
          NoteStemsCompanion.insert(stem: stem, noteId: noteId, source: 'file'),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Whether every md note has a content row (`notes_fts.rowid`
  /// = `notes.id`, same for tags/links — they are written together).
  ///
  /// Count-based; the join runs only when the counts differ. The mismatch
  /// is the migration case: a v7-era index has the tree but no content
  /// rows, and an unchanged rescan must still build them once.
  Future<bool> contentIndexComplete() async {
    final rows = await _db
        .customSelect(
          'SELECT (SELECT count(*) FROM notes WHERE is_dir = 0 '
          "AND lower(substr(name, -3)) = '.md') AS notes, "
          '(SELECT count(*) FROM notes_fts) AS fts, '
          '(SELECT count(*) FROM notes WHERE is_dir = 0) AS files, '
          "(SELECT count(*) FROM note_stems WHERE source = 'file') AS stems, "
          '(SELECT count(*) FROM notes WHERE is_dir = 0 '
          "AND lower(substr(name, -3)) <> '.md' "
          'AND (title IS NOT NULL OR date IS NOT NULL '
          'OR pinned <> 0)) AS stray',
        )
        .getSingle();
    // `stray` counts frontmatter recorded against a file that is not a
    // note — impossible now, but an index written before that was fixed
    // can hold some. Counting it here is what gets the repair pass run on
    // a library where nothing else changed: the no-write exit is skipped
    // until the rows are clean.
    return rows.read<int>('notes') == rows.read<int>('fts') &&
        rows.read<int>('files') == rows.read<int>('stems') &&
        rows.read<int>('stray') == 0;
  }

  /// The paths of md notes that have no `notes_fts` row.
  Future<List<String>> missingFtsPaths() async {
    final rows = await _db
        .customSelect(
          'SELECT notes.path FROM notes LEFT JOIN notes_fts '
          'ON notes.id = notes_fts.rowid WHERE notes_fts.rowid IS NULL '
          "AND notes.is_dir = 0 AND lower(substr(notes.name, -3)) = '.md'",
        )
        .get();
    return [for (final r in rows) r.read<String>('path')];
  }

  /// Writes the missing file stems (every file without one) — the one-time
  /// repair when non-`.md` files gained stems (embeds) after an older
  /// index was built.
  Future<void> _repairMissingFileStems() async {
    final rows = await _db
        .customSelect(
          'SELECT notes.id, notes.name FROM notes LEFT JOIN note_stems '
          "ON note_stems.note_id = notes.id AND note_stems.source = 'file' "
          'WHERE note_stems.note_id IS NULL AND notes.is_dir = 0',
        )
        .get();
    if (rows.isEmpty) return;
    _log.info('contents: writing ${rows.length} missing file stem(s)');
    for (var i = 0; i < rows.length; i += _contentChunk) {
      final end = i + _contentChunk < rows.length
          ? i + _contentChunk
          : rows.length;
      await _db.transaction(() async {
        for (var j = i; j < end; j++) {
          await replaceFileStems(
            rows[j].read<int>('id'),
            rows[j].read<String>('name'),
          );
        }
      });
      if (end < rows.length) await Future<void>.delayed(Duration.zero);
    }
  }

  /// Clears frontmatter the index should never have recorded: the known
  /// fields on a row that is not a Markdown note, and its field rows.
  ///
  /// A one-time repair, like the missing file stems above. `rescanFiles`
  /// used to read whatever it was handed, so pinning a `todo.txt` — which
  /// wrote a YAML block into it — came back as `pinned` on that row and
  /// put the file in the tree's pinned block. The write path is fixed;
  /// this takes back what it already recorded.
  Future<void> _clearNonNoteFrontmatter() async {
    const nonNote = "is_dir = 0 AND lower(substr(name, -3)) <> '.md'";
    final fixed = await _db.customUpdate(
      'UPDATE notes SET title = NULL, date = NULL, pinned = 0 '
      'WHERE $nonNote AND (title IS NOT NULL OR date IS NOT NULL '
      'OR pinned <> 0)',
      updates: {_db.notes},
    );
    if (fixed == 0) return;
    _log.info('contents: cleared frontmatter on $fixed non-note row(s)');
    await _db.customStatement(
      'DELETE FROM frontmatter_fields WHERE note_id IN '
      '(SELECT id FROM notes WHERE $nonNote)',
    );
  }

  /// Writes the content-derived rows — `notes_fts` (title + body copy),
  /// `note_tags` (+ the `tags` table) and the resolved `note_links` edges
  /// — for changed notes. Runs after the notes rows of the batch are
  /// written, so links pointing at notes indexed later in the same walk
  /// resolve; [paired] rels keep their existing rows (their content did
  /// not change — the rename only moved the path).
  Future<void> applyContent(
    Map<String, NoteContent> contents, {
    required Set<String> paired,
  }) async {
    // Notes only. FTS, tags, links and frontmatter fields are all derived
    // from Markdown, and the completeness check counts `.md` rows, so a
    // non-note that reached here would be indexed and then permanently
    // look like a missing row to the repair pass.
    final items = <(Note, NoteContent)>[
      for (final c in contents.values)
        if (!paired.contains(c.rel) && isNoteFile(p.basename(c.rel)))
          if (await _dao.find(c.rel) case final Note row) (row, c),
    ];

    // One-time repair, before the early return: an index built before
    // files gained stems (embeds — `![[foo.png]]` by bare name) has every
    // FTS row but no attachment stems, so an unchanged rescan must still
    // write the missing ones. Sitting after the `items.isEmpty` return it
    // never ran — content rows were complete, nothing else was rewritten
    // (T-M3-09 device report: `![[…]]` images stayed placeholders).
    await _repairMissingFileStems();
    await _clearNonNoteFrontmatter();
    if (items.isEmpty) return;

    // Link targets resolve once per pass — one stems lookup per distinct
    // stem and one notes lookup, via [LinkResolver.resolveBatch] — instead
    // of two queries per link (the per-link queries dominated the content
    // pass: hundreds of notes × a dozen links each).
    final batchTargets = <String>{};
    for (final (_, c) in items) {
      for (final link in c.links) {
        final target = switch (link) {
          final WikiLink w when w.ref.target.isNotEmpty => w.ref.target,
          final MarkdownLink m
              when !LinkResolver.hasScheme(m.href) &&
                  !m.href.trim().startsWith('#') &&
                  m.href.contains('.md') =>
            m.href,
          _ => null,
        };
        if (target != null) batchTargets.add(target);
      }
    }
    final resolved = await LinkResolver(_db).resolveBatch(batchTargets);

    // Chunked writes: each chunk its own transaction with a yield between
    // chunks, so a large backfill leaves frames free (typing stays
    // responsive) — and a partial pass is repaired by the completeness
    // check on the next scan.
    for (var i = 0; i < items.length; i += _contentChunk) {
      final end = i + _contentChunk < items.length
          ? i + _contentChunk
          : items.length;
      await _db.transaction(() async {
        for (final (row, c) in items.sublist(i, end)) {
          await _writeContentRow(row, c, resolved);
        }
      });
      if (end < items.length) await Future<void>.delayed(Duration.zero);
    }
  }

  /// The content-derived rows of one note within a chunk transaction:
  /// FTS (title + body copy), file + alias stems, tags, and the resolved
  /// link edges from the batched resolution map.
  Future<void> _writeContentRow(
    Note row,
    NoteContent c,
    Map<String, ResolveResult> resolved,
  ) async {
    await _db.customStatement(
      'DELETE FROM notes_fts WHERE rowid = ?',
      <Object?>[row.id],
    );
    await _db.customStatement(
      'INSERT INTO notes_fts (rowid, title, body) VALUES (?, ?, ?)',
      <Object?>[row.id, c.title, c.text],
    );
    // The file stem (and the alias stems) are content-derived too: a
    // v7-era restore has no stems at all, so the content pass rebuilds
    // them instead of relying on the insert path alone.
    await replaceFileStems(row.id, row.name);
    await _writeAliasStems(row.id, c);
    await _writeTags(row.id, c);
    await _writeFields(row.id, c);
    await _writeLinks(row.id, c, resolved);
  }

  /// Writes the known frontmatter fields onto the note row itself and the
  /// whole block into `frontmatter_fields` (T-M4-02).
  ///
  /// The three known ones are on the row because the tree renders them per
  /// visible row; the table holds every key, including those three, and is
  /// what a `key = value` filter reads. A note whose block was removed —
  /// or never parsed — writes them back as null/false, so a title that is
  /// gone stops overriding the filename.
  Future<void> _writeFields(int noteId, NoteContent c) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
      NotesCompanion(
        title: Value(c.fields['title']?.first),
        date: Value(c.date),
        pinned: Value(c.pinned),
      ),
    );
    await (_db.delete(
      _db.frontmatterFields,
    )..where((f) => f.noteId.equals(noteId))).go();
    if (c.fields.isEmpty) return;
    await _db.batch((batch) {
      for (final entry in c.fields.entries) {
        for (final value in entry.value) {
          batch.insert(
            _db.frontmatterFields,
            FrontmatterFieldsCompanion.insert(
              noteId: noteId,
              key: entry.key,
              value: value,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  /// Rewrites the `note_stems` alias rows (source `alias`) of note
  /// [noteId] to match [c]'s frontmatter aliases — the same index the
  /// resolver reads, so `[[alias]]` resolves by alias from M3 on.
  Future<void> _writeAliasStems(int noteId, NoteContent c) async {
    await (_db.delete(
      _db.noteStems,
    )..where((s) => s.noteId.equals(noteId) & s.source.equals('alias'))).go();
    for (final alias in c.aliases) {
      await _db
          .into(_db.noteStems)
          .insert(
            NoteStemsCompanion.insert(
              stem: alias.toLowerCase(),
              noteId: noteId,
              source: 'alias',
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  /// Rewrites the `note_tags` rows (and the `tags` table) of note
  /// [noteId] to match [c]'s frontmatter and inline tags.
  Future<void> _writeTags(int noteId, NoteContent c) async {
    await (_db.delete(
      _db.noteTags,
    )..where((t) => t.noteId.equals(noteId))).go();
    for (final tag in c.frontmatterTags) {
      await _db
          .into(_db.tags)
          .insert(
            TagsCompanion.insert(name: tag),
            mode: InsertMode.insertOrIgnore,
          );
      await _db
          .into(_db.noteTags)
          .insert(
            NoteTagsCompanion.insert(
              tag: tag,
              noteId: noteId,
              isFrontmatter: true,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final tag in c.inlineTags) {
      await _db
          .into(_db.tags)
          .insert(
            TagsCompanion.insert(name: tag),
            mode: InsertMode.insertOrIgnore,
          );
      await _db
          .into(_db.noteTags)
          .insert(
            NoteTagsCompanion.insert(
              tag: tag,
              noteId: noteId,
              isFrontmatter: false,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  /// Rewrites the resolved `note_links` edges of note [noteId] to match
  /// [c]'s links: wiki and `.md` targets that resolve to another indexed
  /// note become edges; dead links, external URLs, anchors and self-links
  /// are skipped. [resolved] carries the batched resolution results
  /// (target text → outcome, same rules as the single-target path).
  Future<void> _writeLinks(
    int noteId,
    NoteContent c,
    Map<String, ResolveResult> resolved,
  ) async {
    await (_db.delete(
      _db.noteLinks,
    )..where((l) => l.fromNote.equals(noteId))).go();
    await _db.batch((batch) {
      for (final link in c.links) {
        final target = switch (link) {
          final WikiLink w when w.ref.target.isNotEmpty => w.ref.target,
          final MarkdownLink m
              when !LinkResolver.hasScheme(m.href) &&
                  !m.href.trim().startsWith('#') &&
                  m.href.contains('.md') =>
            m.href,
          _ => null,
        };
        if (target == null) continue;
        final outcome = resolved[target];
        if (outcome is! ResolvedNote || outcome.note.id == noteId) continue;
        batch.insert(
          _db.noteLinks,
          NoteLinksCompanion.insert(
            fromNote: noteId,
            toNote: outcome.note.id,
            kind: link is WikiLink ? 'wiki' : 'md',
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
