/// The library scan, one directory at a time (#302).
///
/// The whole-tree reconciliation loaded every index row, every disk entry
/// and the parsed content of every changed note into memory before it
/// wrote anything — nine seconds and about a gigabyte at a million notes
/// (T-M6-01), an OOM on a phone, and it runs on the periodic rescan too.
/// This walks the tree with [DirWalker] and diffs one directory against
/// the rows of that directory, reads and writes its changed notes in
/// bounded batches, and moves on: peak memory is the largest directory or
/// read batch, not the library.
///
/// Renames are the hard half. A note moved from a folder the walk has
/// already passed to one it reaches later — or the other way around — must
/// still keep its id (and with it its FTS, tag and link rows). Two
/// scan-scoped temp tables carry that across directories: `scan_orphans`
/// holds the notes of every folder walked so far that are gone from disk,
/// and their rows stay in `notes` until the scan's end; `scan_gone` holds
/// the paths to prune when no pairing claimed them. Both are SQLite's, not
/// Dart's, so a mass delete costs disk, not heap. A second pass after the
/// walk pairs what per-directory pairing could not see (a new home the
/// walk reached before the old one) and repairs the fresh row it made.
/// Link edges go to the durable `pending_links` queue instead of being
/// resolved as they are parsed: a target may live in a directory the walk
/// has not reached, or move into one it has already passed, so the edges
/// resolve at the end, against the final tree.
library;

import 'package:drift/drift.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/index_tree.dart';
import 'package:niman/src/links/resolver.dart';

/// Reconciles the index with the library a directory at a time (#302).
///
/// Owned by the indexer facade, which serializes every entry point through
/// its mutex before calling in.
final class IndexReconciler {
  /// Creates the reconciler over the given [IndexDatabase], sharing the
  /// tree sync and content store of the indexer facade.
  new(this._db, this._dao, this._tree, this._store)
    : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final IndexTree _tree;

  final IndexContentStore _store;

  final AppLogger _log;

  /// How many new rows the second pairing pass inspects per query, so a
  /// mass move never becomes a list in memory.
  static const _pairPage = 200;

  /// How many gone paths the prune deletes per query, for the same reason.
  static const _prunePage = 200;

  /// How many deferred link edges resolve and write per query.
  static const _linkPage = 500;

  /// Highest row id before the walk: every row above it was inserted by
  /// this scan, which is how the second pairing pass finds the fresh rows
  /// a rename may have left behind.
  int _baseline = 0;

  /// Whether these scan's orphan tables exist — the index had rows when it
  /// started. A library with none cannot have a note that moved away from
  /// it, so the pairing is skipped and its tables never made.
  bool _pairing = false;

  /// Rebuilds the index from a full disk scan of `root`.
  ///
  /// The index is diffed against the walk directory by directory, so every
  /// row whose path survives keeps its id (the stable id space is what the
  /// M3 `frontmatter_fields`, `note_tags` and FTS indexes key off): gone
  /// paths are deleted, new paths inserted, surviving rows updated where
  /// they actually changed. Used on first open, on the periodic rescan
  /// fallback, and for explicit re-index. Answers whether the index wrote;
  /// [onChanged] fires once at the end when it did, and [onRemoved] with
  /// the paths the scan pruned.
  Future<void> fullScan(
    String root, {
    void Function()? onChanged,
    void Function(Set<String> removed)? onRemoved,
  }) async {
    await _db.customStatement('PRAGMA incremental_vacuum');
    final contentOwed = !await _store.contentIndexComplete();
    final hadRows = await _dao.hasRows();
    final progressTotal = _tree.onProgress == null ? 0 : await _dao.noteCount();
    if (contentOwed) {
      _log.info(
        'fullScan: content index incomplete — rebuilding it as it scans',
      );
    }
    final clock = Stopwatch()..start();
    var wrote = false;
    var entries = 0;
    var files = 0;
    var reads = 0;
    final removed = <String>{};
    await _openScanTables(hadRows);
    try {
      final walk = await DirWalker.start(root);
      Object? failure;
      try {
        for (
          var listing = await walk.next();
          listing != null;
          listing = await walk.next()
        ) {
          listing.logs.forEach(_log.debug);
          // Gone between its parent's listing and its own: the next scan
          // repairs the row it left behind.
          if (listing.failed) continue;
          entries += listing.entries.length;
          files += listing.entries.where((e) => !e.isDir).length;
          final result = await _reconcileDir(
            root,
            listing,
            contentOwed: contentOwed,
            progressTotal: progressTotal,
            readsDone: reads,
          );
          reads += result.read;
          wrote |= result.wrote;
        }
      } catch (error) {
        failure = error;
        rethrow;
      } finally {
        await walk.close(error: failure);
      }
      if (hadRows) {
        final paired = await _pairOrphans(
          root,
          contentOwed: contentOwed,
          progressTotal: progressTotal,
          readsDone: reads,
        );
        reads += paired.read;
        wrote |= paired.wrote;
      }
      final pruned = await _pruneGone();
      wrote |= pruned.wrote;
      removed.addAll(pruned.removed);
      await _writePendingLinks();
      if (contentOwed && await _store.repairDerivedRows()) wrote = true;
    } finally {
      await _closeScanTables();
    }
    _log.info(
      'fullScan $root: $entries entr(ies) ($files file, '
      '${entries - files} dir) in ${clock.elapsedMilliseconds} ms',
    );
    if (!wrote) {
      _log.info('fullScan: index already mirrors disk, no write');
    } else {
      final cb = onChanged;
      if (cb != null) cb();
    }
    if (removed.isNotEmpty) {
      final cb = onRemoved;
      if (cb != null) cb(removed);
    }
  }

  /// The first index of a library, the tree alone: when the index is empty,
  /// the walk's rows — paths, sizes, times, the names links resolve by —
  /// written without reading a note. Answers whether it did, in which case
  /// the content (the search body, tags, links, frontmatter, digests) is
  /// owed, and a [fullScan] builds it: it finds every note without a
  /// content row and reads it. A directory at a time, like [fullScan], so
  /// the first walk of a million-note library costs a listing and its
  /// subtree's rows (#302).
  ///
  /// What makes a first open wait for the tree and not for the notes: a
  /// library holding the 247 MB stress note took some eleven seconds to
  /// read on a desktop before it opened at all (`docs/records/huge-notes.md`,
  /// item 8), for rows the tree does not need. On an index that has rows a
  /// scan writes digests it read, and a row written without one would lose
  /// the digest the rename pairing keys on — so this is the empty index's
  /// alone.
  Future<bool> treeFirst(String root, {void Function()? onChanged}) async {
    if (await _dao.hasRows()) return false;
    var wrote = false;
    var entries = 0;
    final walk = await DirWalker.start(root);
    Object? failure;
    try {
      for (
        var listing = await walk.next();
        listing != null;
        listing = await walk.next()
      ) {
        listing.logs.forEach(_log.debug);
        if (listing.failed) continue;
        entries += listing.entries.length;
        final dirRel = listing.rel;
        final dirRow = dirRel.isEmpty ? null : await _dao.find(dirRel);
        final old = <String, Note>{dirRel: ?dirRow};
        final listingEntries = <DiskEntry>[
          if (dirRow != null)
            DiskEntry(
              rel: dirRel,
              name: listing.name,
              isDir: true,
              size: 0,
              modified: listing.modified,
            ),
          ...listing.entries,
        ];
        await _db.transaction(() async {
          final result = await _tree.applyDiff(
            entries: listingEntries,
            old: old,
            shas: const <String, String>{},
            contents: const <String, NoteContent>{},
            scope: dirRel,
            scopeParentId: dirRow?.parent ?? 0,
          );
          wrote |= result.wrote;
        });
      }
    } catch (error) {
      failure = error;
      rethrow;
    } finally {
      await walk.close(error: failure);
    }
    if (entries == 0) return false;
    _log.info(
      'first index $root: the tree first, $entries entr(ies); '
      'the notes after it',
    );
    if (wrote) {
      final cb = onChanged;
      if (cb != null) cb();
    }
    return wrote;
  }

  /// Reconciles one directory listing against the index rows of that
  /// directory. Answers whether it wrote and how many notes it read.
  Future<({bool wrote, int read})> _reconcileDir(
    String root,
    DirListing listing, {
    required bool contentOwed,
    required int progressTotal,
    required int readsDone,
  }) async {
    final dirRel = listing.rel;
    final dirRow = dirRel.isEmpty ? null : await _dao.find(dirRel);
    if (dirRel.isNotEmpty && dirRow == null) {
      // Its parent's listing should have written the row before the walk
      // descended; without one the parent chain cannot resolve. Nothing
      // else can prune it mid-scan — the scan holds the indexer's mutex —
      // so this is a race with the disk, and the next scan finds it again.
      _log.debug('scan: no row for "$dirRel" — skipping its listing');
      return (wrote: false, read: 0);
    }
    final parentId = dirRow?.id ?? 0;
    final old = <String, Note>{
      dirRel: ?dirRow,
      for (final row in await _dao.children(parentId)) row.path: row,
    };
    final entries = <DiskEntry>[
      if (dirRow != null)
        DiskEntry(
          rel: dirRel,
          name: listing.name,
          isDir: true,
          size: 0,
          modified: listing.modified,
        ),
      ...listing.entries,
    ];
    final read = await _tree.readContents(
      root,
      entries,
      old,
      contentOwed: contentOwed,
      progressTotal: progressTotal,
      doneBase: readsDone,
    );
    var wrote = read.contents.isNotEmpty;
    var paired = const <String>{};
    final pending = <QueuedLink>[];
    await _db.transaction(() async {
      final result = await _tree.applyDiff(
        entries: entries,
        old: old,
        shas: read.shas,
        contents: read.contents,
        scope: dirRel,
        scopeParentId: dirRow?.parent ?? 0,
        deferDeletes: true,
        orphanLookup: _lookupOrphan,
      );
      wrote |= result.wrote;
      paired = result.pairedRels;
      await _registerGone(old, result.goneLeft);
    });
    // Content rows (FTS, tags, stems) for the notes whose content was
    // read; a paired rename keeps the rows it already had. Link edges are
    // collected instead of written: their targets resolve at the end of
    // the walk, against the whole final tree (_writePendingLinks).
    if (read.contents.isNotEmpty) {
      await _store.applyContent(
        read.contents,
        paired: paired,
        repair: false,
        pendingLink: pending.add,
      );
    }
    await _deferLinks(pending);
    return (wrote: wrote, read: read.contents.length);
  }

  /// Queues [links] for [_writePendingLinks], which resolves them once the
  /// whole tree is mirrored. Durable, so a scan that never reaches its end
  /// leaves them for the next one instead of losing them.
  Future<void> _deferLinks(Iterable<QueuedLink> links) async {
    final batch = links.toList(growable: false);
    if (batch.isEmpty) return;
    await _db.batch((b) {
      for (final link in batch) {
        b.insert(
          _db.pendingLinks,
          PendingLinksCompanion.insert(
            noteId: link.fromNote,
            target: link.target,
            kind: link.kind,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// A content-preserving rename candidate among the notes an earlier
  /// directory of this scan found gone. Asked only when the listing itself
  /// has no candidate; the answer is consumed, so one row pairs once.
  ///
  /// None or several matches pair nothing, exactly as [IndexTree.applyDiff]
  /// treats its local candidates: two identical orphans and one new note
  /// make the move ambiguous, and guessing would repoint the wrong id.
  Future<Note?> _lookupOrphan(DiskEntry e, String sha) async {
    if (!_pairing) return null;
    final rows = await _db
        .customSelect(
          'SELECT path FROM scan_orphans '
          'WHERE sha256 = ? AND size = ? AND modified = ?',
          variables: [
            Variable<String>(sha),
            Variable<int>(e.size),
            Variable<int>(_seconds(e.modified)),
          ],
        )
        .get();
    if (rows.length != 1) return null;
    final path = rows.single.read<String>('path');
    final row = await _dao.find(path);
    if (row == null) return null;
    await _db.customStatement('DELETE FROM scan_orphans WHERE path = ?', [
      path,
    ]);
    _log.debug('pair: "$path" -> "${e.rel}" (content unchanged)');
    return row;
  }

  /// Keeps the vanished entries of one listing for the rest of the scan.
  ///
  /// A gone note with a digest becomes a rename candidate; the notes under
  /// a gone folder become candidates too — moving a folder is a rename of
  /// each note in it — while the folder's own path goes to `scan_gone`, so
  /// whatever no pairing claimed is pruned at the end. The rows themselves
  /// stay in `notes` until then: pairing repoints them, it cannot resurrect
  /// a row whose FTS, tags and links were already wiped.
  Future<void> _registerGone(
    Map<String, Note> old,
    Set<String> goneLeft,
  ) async {
    for (final rel in goneLeft) {
      final row = old[rel];
      if (row == null) continue;
      if (row.isDir) {
        final range = subtreePathRange(rel);
        await _db.customStatement(
          'INSERT OR IGNORE INTO scan_orphans '
          '(id, path, sha256, size, modified) '
          'SELECT id, path, sha256, size, modified FROM notes '
          'WHERE is_dir = 0 AND sha256 IS NOT NULL '
          'AND path >= ? AND path < ?',
          [range.from, range.to],
        );
      } else if (row.sha256 case final String sha) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO scan_orphans '
          '(id, path, sha256, size, modified) VALUES (?, ?, ?, ?, ?)',
          [row.id, row.path, sha, row.size, _seconds(row.modified)],
        );
      }
      await _db.customStatement(
        'INSERT OR IGNORE INTO scan_gone (path) VALUES (?)',
        [rel],
      );
    }
  }

  /// Pairs the new notes the walk met before their old homes with the
  /// orphans of the directories it had already passed, and prunes nothing
  /// yet: [_pruneGone] takes what is left. Runs only when the scan found
  /// orphans, and pages the new rows so a mass move stays bounded.
  Future<({bool wrote, int read})> _pairOrphans(
    String root, {
    required bool contentOwed,
    required int progressTotal,
    required int readsDone,
  }) async {
    final count = await _db
        .customSelect('SELECT count(*) AS c FROM scan_orphans')
        .getSingle();
    if (count.read<int>('c') == 0) return (wrote: false, read: 0);
    _log.info('scan: pairing notes that moved into an earlier folder');
    var wrote = false;
    var after = _baseline;
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
        final matches = await _db
            .customSelect(
              'SELECT path FROM scan_orphans '
              'WHERE sha256 = ? AND size = ? AND modified = ?',
              variables: [
                Variable<String>(row.read<String>('sha256')),
                Variable<int>(row.read<int>('size')),
                Variable<int>(_seconds(row.read<DateTime>('modified'))),
              ],
            )
            .get();
        if (matches.length != 1) continue;
        final orphanPath = matches.single.read<String>('path');
        final orphan = await _dao.find(orphanPath);
        if (orphan == null) continue;
        final newPath = row.read<String>('path');
        await _repairPair(
          root,
          orphan: orphan,
          newPath: newPath,
          newName: row.read<String>('name'),
        );
        await _db.customStatement('DELETE FROM scan_orphans WHERE path = ?', [
          orphanPath,
        ]);
        if (contentOwed) reread.add(newPath);
        wrote = true;
      }
      if (page.length < _pairPage) break;
    }
    // The orphan's content rows are the ones it never lost, but an
    // incomplete index may have been missing them — its directory was
    // scanned before the pair existed, so nothing filled the gap.
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
      await _deferLinks(pending);
    }
    return (wrote: wrote, read: reread.length);
  }

  /// Turns the fresh row a late pairing left behind into the orphan it
  /// should have been: the surviving row is repointed at the new path, and
  /// the fresh row — with the content rows just written for it — goes.
  ///
  /// Nothing points at the fresh row's id: every link edge of a scan is
  /// deferred to [_writePendingLinks], which runs after this, so an edge
  /// resolves against the surviving row the first time.
  Future<void> _repairPair(
    String root, {
    required Note orphan,
    required String newPath,
    required String newName,
  }) async {
    _log.debug(
      'pair: "${orphan.path}" -> "$newPath" (content unchanged, later home)',
    );
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
        isDir: const Value(false),
      ),
    );
    await _store.replaceFileStems(orphan.id, newName);
  }

  /// Resolves and writes every link edge the walk queued, against the tree
  /// as it stands after the pairing and the prune: a link to a note a later
  /// directory introduced, or to one that moved, finds its row. Edges a
  /// killed scan left queued are resolved here too.
  ///
  /// One page of pending links at a time — the distinct targets of a page
  /// resolve in one batch, and the page is deleted with the edges it wrote
  /// — so a first index of a million notes never holds the library's edges
  /// in memory.
  Future<void> _writePendingLinks() async {
    while (true) {
      final rows = await _db
          .customSelect(
            'SELECT rowid, note_id, target, kind FROM pending_links '
            'ORDER BY rowid LIMIT $_linkPage',
          )
          .get();
      if (rows.isEmpty) break;
      final targets = <String>{
        for (final row in rows) row.read<String>('target'),
      };
      final resolved = await LinkResolver(_db).resolveBatch(targets);
      final last = rows.last.read<int>('rowid');
      await _db.transaction(() async {
        for (final row in rows) {
          final fromNote = row.read<int>('note_id');
          final outcome = resolved[row.read<String>('target')];
          if (outcome is! ResolvedNote || outcome.note.id == fromNote) {
            continue;
          }
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
        await _db.customStatement(
          'DELETE FROM pending_links WHERE rowid <= ?',
          [last],
        );
      });
    }
  }

  /// Deletes every path the walk found gone and no pairing claimed, one
  /// page at a time, reporting the top-level ones. `scan_gone` holds only
  /// the entries of a present directory's listing, so no path here is
  /// inside another.
  Future<({bool wrote, Set<String> removed})> _pruneGone() async {
    var wrote = false;
    final removed = <String>{};
    if (!_pairing) return (wrote: wrote, removed: removed);
    while (true) {
      final rows = await _db
          .customSelect(
            'SELECT path FROM scan_gone ORDER BY path LIMIT $_prunePage',
          )
          .get();
      if (rows.isEmpty) break;
      for (final row in rows) {
        final path = row.read<String>('path');
        final deleted = await _dao.deleteSubtree(path);
        await _db.customStatement('DELETE FROM scan_gone WHERE path = ?', [
          path,
        ]);
        if (deleted > 0) {
          wrote = true;
          removed.add(path);
        }
      }
    }
    return (wrote: wrote, removed: removed);
  }

  /// Creates the scan's temp tables, and captures the row id the walk
  /// starts from. A library with no rows has no orphans to pair: the tables
  /// stay away, and a fresh index of a million notes pays nothing for a
  /// pairing it cannot need.
  Future<void> _openScanTables(bool hadRows) async {
    await _closeScanTables();
    _pairing = hadRows;
    if (!hadRows) return;
    _baseline = await _dao.maxId();
    await _db.customStatement(
      'CREATE TEMP TABLE scan_orphans '
      '(id INTEGER PRIMARY KEY, path TEXT UNIQUE NOT NULL, '
      'sha256 TEXT NOT NULL, size INTEGER NOT NULL, modified INTEGER NOT NULL)',
    );
    await _db.customStatement(
      'CREATE INDEX scan_orphans_key ON scan_orphans (sha256, size, modified)',
    );
    await _db.customStatement(
      'CREATE TEMP TABLE scan_gone (path TEXT PRIMARY KEY)',
    );
  }

  Future<void> _closeScanTables() async {
    _pairing = false;
    await _db.customStatement('DROP TABLE IF EXISTS scan_orphans');
    await _db.customStatement('DROP TABLE IF EXISTS scan_gone');
  }

  static int _seconds(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;
}
