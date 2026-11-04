/// The second pairing pass of a scan, after its walk (#302).
library;

import 'package:drift/drift.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_tree.dart';
import 'package:niman/src/db/pending_link_queue.dart';
import 'package:niman/src/db/scan_orphans.dart';
import 'package:niman/src/db/scan_touches.dart';
import 'package:niman/src/links/link_path.dart';

/// Pairs what per-directory pairing could not see — a new home the walk
/// reached before the old one — and repairs the fresh row it made.
///
/// The walk pairs a new note with the orphans of the directories it has
/// already passed; a note whose new folder came first was inserted as a
/// fresh row, and its old row became an orphan only later. This pass finds
/// those fresh rows (every id above [ScanOrphans.baseline]) and turns each
/// back into the orphan it should have been.
final class LatePairing {
  /// Creates the pass over the shared index handles of a scan.
  new(
    this._db,
    this._dao,
    this._tree,
    this._store,
    this._touches,
    this._orphans,
    this._links,
  ) : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final IndexTree _tree;

  final IndexContentStore _store;

  final ScanTouches _touches;

  final ScanOrphans _orphans;

  final PendingLinkQueue _links;

  final AppLogger _log;

  /// How many new rows the second pairing pass inspects per query, so a
  /// mass move never becomes a list in memory.
  static const _pairPage = 200;

  /// Pairs the new notes the walk met before their old homes with the
  /// orphans of the directories it had already passed, and prunes nothing
  /// yet: [ScanOrphans.pruneGone] takes what is left. Runs only when the
  /// scan found orphans, and pages the new rows so a mass move stays
  /// bounded.
  Future<({bool wrote, int read})> pair(
    String root, {
    required bool contentOwed,
    required int progressTotal,
    required int readsDone,
  }) async {
    if (await _orphans.count() == 0) return (wrote: false, read: 0);
    _log.info('scan: pairing notes that moved into an earlier folder');
    var wrote = false;
    var after = _orphans.baseline;
    final reread = <String>[];
    while (true) {
      final page = await _db
          .customSelect(
            'SELECT id, path, name, size, modified, sha256 FROM notes '
            'WHERE id > ? AND is_dir = 0 AND sha256 IS NOT NULL '
            'ORDER BY id LIMIT $_pairPage',
            variables: [Variable<int>(after)],
          )
          .get();
      if (page.isEmpty) break;
      after = page.last.read<int>('id');
      for (final row in page) {
        final orphanPath = await _orphans.soleMatch(
          row.read<String>('sha256'),
          row.read<int>('size'),
          row.read<DateTime>('modified'),
        );
        if (orphanPath == null) continue;
        if (_touches.shields(orphanPath) ||
            _touches.shields(row.read<String>('path'))) {
          continue;
        }
        final orphan = await _dao.find(orphanPath);
        if (orphan == null) continue;
        final newPath = row.read<String>('path');
        await _repairPair(
          root,
          orphan: orphan,
          newPath: newPath,
          newName: row.read<String>('name'),
        );
        await _orphans.consume(orphanPath);
        if (contentOwed || orphan.title == null) reread.add(newPath);
        wrote = true;
      }
      if (page.length < _pairPage) break;
    }
    // The orphan's content rows are the ones it never lost, but an
    // incomplete index may have been missing them — its directory was
    // scanned before the pair existed, so nothing filled the gap. A note
    // without a frontmatter title is re-read regardless: its search title
    // is the old filename until the pass re-derives it (#352).
    if (reread.isNotEmpty) {
      final contents = await _tree.readRelContents(
        root,
        reread,
        total: progressTotal,
        doneBase: readsDone,
      );
      final pending = <QueuedLink>[];
      await _store.applyContent(
        contents,
        paired: const {},
        repair: false,
        pendingLink: pending.add,
      );
      await _links.defer(pending);
    }
    return (wrote: wrote, read: reread.length);
  }

  /// Turns the fresh row a late pairing left behind into the orphan it
  /// should have been: the surviving row is repointed at the new path, and
  /// the fresh row — with the content rows just written for it — goes.
  ///
  /// Nothing points at the fresh row's id: every link edge of a scan is
  /// deferred to [PendingLinkQueue.writePending], which runs after this, so
  /// an edge resolves against the surviving row the first time.
  Future<void> _repairPair(
    String root, {
    required Note orphan,
    required String newPath,
    required String newName,
  }) async {
    _log.debug(
      'pair: "${orphan.path}" -> "$newPath" (content unchanged, later home)',
    );
    await _carryLinks(orphan, newPath);
    await _dao.deleteSubtree(newPath);
    final parentRel = parentOf(newPath);
    final parentId = parentRel.isEmpty
        ? 0
        : await _tree.ensureDirChain(root, parentRel);
    await (_db.update(_db.notes)..where((t) => t.id.equals(orphan.id))).write(
      NotesCompanion(
        path: Value(newPath),
        parent: Value(parentId),
        name: Value(newName),
        nameKey: Value(nameSortKey(newName)),
        isDir: const Value(false),
      ),
    );
    await _store.replaceFileStems(orphan.id, newName);
  }

  /// Hands the links the fresh row at [newPath] queued to the [orphan] that
  /// moved there, when one of them reads from the note's folder (#491).
  ///
  /// The orphan keeps its rows, its edges among them, and those were
  /// resolved from its old folder. The fresh row's queued links are the
  /// note's own, parsed when its directory was walked, so the note is not
  /// read again: they replace the orphan's edges and resolve from the new
  /// path at the end of the walk.
  Future<void> _carryLinks(Note orphan, String newPath) async {
    final fresh = await _dao.find(newPath);
    if (fresh == null) return;
    final queued = await _db
        .customSelect(
          'SELECT target, kind FROM pending_links WHERE note_id = ?',
          variables: [Variable<int>(fresh.id)],
        )
        .get();
    final depends = queued.any(
      (row) => LinkPaths.dependsOnLocation(
        row.read<String>('target'),
        markdown: row.read<String>('kind') == 'md',
      ),
    );
    if (!depends) return;
    await _db.customStatement('DELETE FROM note_links WHERE from_note = ?', [
      orphan.id,
    ]);
    await _db.customStatement('DELETE FROM pending_links WHERE note_id = ?', [
      orphan.id,
    ]);
    await _store.dangling.forget(orphan.id);
    await _db.customStatement(
      'UPDATE OR IGNORE pending_links SET note_id = ? WHERE note_id = ?',
      [orphan.id, fresh.id],
    );
  }
}
