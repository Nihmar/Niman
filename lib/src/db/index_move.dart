/// A folder's move in the index: a rewrite of paths, not a re-index (#1063).
library;

import 'package:drift/drift.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_tree.dart';
import 'package:niman/src/links/link_path.dart';
import 'package:path/path.dart' as p;

/// Carries the index rows of a folder to its new path.
///
/// A folder renamed or moved on disk changes the path of every row under it
/// and nothing else: the notes are the same files with the same bytes. The
/// rows are rewritten in place — one statement over the path range — so every
/// note keeps its id, and with it its full-text row, tags, stems, headings
/// and link edges, which key on the id. Re-indexing instead (the folder
/// pruned, the new path read as new) read and hashed every note in it and
/// wrote all of that again, minutes on a phone for a folder of thirty
/// thousand.
///
/// What does not follow from the id alone is a link that reads from the
/// note's folder (a Markdown path, a `../` wiki target): a moved note may
/// now name something else, or nothing. Those notes are found from the
/// index — the ones with an edge to a note outside the moved folder, and the
/// ones with a dead link of that kind — and only they are read again.
final class IndexMove {
  /// Creates the move over the shared index handles.
  new(this._db, this._dao, this._store, this._tree)
    : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;
  final NoteDao _dao;
  final IndexContentStore _store;
  final IndexTree _tree;
  final AppLogger _log;

  /// Rewrites the folder [fromRel] and everything indexed under it to
  /// [toRel], for a move the caller has just made on disk.
  ///
  /// Answers whether it did. It does nothing — and the caller indexes the
  /// destination the ordinary way — when the index does not hold the folder,
  /// already holds something at the destination, or the disk does not show
  /// the move (the destination is not a folder, or the source is still
  /// there).
  Future<bool> moveFolder(String root, String fromRel, String toRel) async {
    if (fromRel == toRel || toRel.startsWith('$fromRel/')) return false;
    final folder = await _dao.find(fromRel);
    if (folder == null || !folder.isDir) return false;
    if (await _dao.find(toRel) != null || await _anyUnder(toRel)) return false;
    final probes = await _tree.probeAll([
      p.join(root, fromRel),
      p.join(root, toRel),
    ]);
    // A case-only rename on a case-insensitive disk still finds the source.
    final caseOnly = fromRel.toLowerCase() == toRel.toLowerCase();
    if (!probes[1].isDir || (probes[0].exists && !caseOnly)) return false;

    final parentRel = parentOf(toRel);
    final parentId = parentRel.isEmpty
        ? 0
        : await _tree.ensureDirChain(root, parentRel);
    final from = subtreePathRange(fromRel);
    final to = subtreePathRange(toRel);
    await _db.transaction(() async {
      // Every descendant: the new prefix over the old one. Length in
      // characters, as `substr` counts them.
      await _db.customUpdate(
        'UPDATE notes SET path = ? || substr(path, length(?) + 1) '
        'WHERE path >= ? AND path < ?',
        variables: [
          Variable<String>(toRel),
          Variable<String>(fromRel),
          Variable<String>(from.from),
          Variable<String>(from.to),
        ],
        updates: {_db.notes},
      );
      // The folder's own row: the only one whose parent and name change.
      await (_db.update(_db.notes)..where((t) => t.id.equals(folder.id))).write(
        NotesCompanion(
          path: Value(toRel),
          parent: Value(parentId),
          name: Value(p.basename(toRel)),
          modified: Value(probes[1].modified),
        ),
      );
    });
    _log.debug('moveFolder: "$fromRel" -> "$toRel" (rows rewritten in place)');

    final relink = await _notesToRelink(to);
    if (relink.isNotEmpty) {
      _log.debug('moveFolder: ${relink.length} note(s) read for their links');
      final contents = await _tree.readRelContents(root, relink);
      await _store.applyContent(contents, paired: contents.keys.toSet());
    }
    return true;
  }

  /// Whether the index holds a row under [folder].
  Future<bool> _anyUnder(String folder) async {
    final range = subtreePathRange(folder);
    final rows = await _db
        .customSelect(
          'SELECT 1 FROM notes WHERE path >= ? AND path < ? LIMIT 1',
          variables: [Variable<String>(range.from), Variable<String>(range.to)],
          readsFrom: {_db.notes},
        )
        .get();
    return rows.isNotEmpty;
  }

  /// The moved notes (by their new path, under [range]) whose links may read
  /// differently from where they are now: those with an edge to a note
  /// outside the moved folder, and those with a dead link that reads from
  /// the note's own folder.
  Future<List<String>> _notesToRelink(({String from, String to}) range) async {
    final args = [
      Variable<String>(range.from),
      Variable<String>(range.to),
      Variable<String>(range.from),
      Variable<String>(range.to),
    ];
    final edges = await _db
        .customSelect(
          'SELECT DISTINCT f.path AS path FROM notes f '
          'JOIN note_links l ON l.from_note = f.id '
          'JOIN notes t ON t.id = l.to_note '
          'WHERE f.path >= ? AND f.path < ? '
          'AND NOT (t.path >= ? AND t.path < ?)',
          variables: args,
          readsFrom: {_db.notes, _db.noteLinks},
        )
        .get();
    final dead = await _db
        .customSelect(
          'SELECT n.path AS path, d.target AS target, d.kind AS kind '
          'FROM dangling_links d JOIN notes n ON n.id = d.note_id '
          'WHERE n.path >= ? AND n.path < ?',
          variables: args.take(2).toList(),
          readsFrom: {_db.notes, _db.danglingLinks},
        )
        .get();
    return {
      for (final row in edges) row.read<String>('path'),
      for (final row in dead)
        if (LinkPaths.dependsOnLocation(
          row.read<String>('target'),
          markdown: row.read<String>('kind') == 'md',
        ))
          row.read<String>('path'),
    }.toList();
  }
}
