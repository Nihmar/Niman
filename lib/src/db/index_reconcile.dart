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

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_change.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/index_tree.dart';
import 'package:niman/src/db/pending_link_queue.dart';
import 'package:niman/src/db/scan_late_pairing.dart';
import 'package:niman/src/db/scan_orphans.dart';
import 'package:niman/src/db/scan_touches.dart';

/// Reconciles the index with the library a directory at a time (#302).
///
/// Owned by the indexer facade, which serializes every entry point through
/// its mutex before calling in; [fullScan] takes it a step at a time.
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

  /// The link edges the walk defers to its end.
  late final PendingLinkQueue _links = PendingLinkQueue(_db, _store);

  /// What writes outside the scan touched while it ran (#697).
  final ScanTouches touches = ScanTouches();

  /// The notes the walk found gone, kept for the rename pairing.
  late final ScanOrphans _orphans = ScanOrphans(_db, _dao, touches);

  /// The second pairing pass, after the walk.
  late final LatePairing _late = LatePairing(
    _db,
    _dao,
    _tree,
    _store,
    touches,
    _orphans,
    _links,
  );

  /// A directory that takes this long is logged with its numbers (#698).
  static const _slowDirMs = 500;

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
    required Future<T> Function<T>(Future<T> Function() fn) step,
    void Function(IndexChange change)? onChanged,
    void Function(Set<String> removed)? onRemoved,
  }) async {
    // Each [step] holds the indexer's lock: the setup, one directory, the
    // close. Between them a write outside the scan goes through — a note
    // made during a long walk opens at once (#697) — and [touches] keeps
    // what it touched out of the scan's hands.
    final (:contentOwed, :hadRows, :progressTotal) = await step(() async {
      await _db.customStatement('PRAGMA incremental_vacuum');
      final contentOwed = !await _store.contentIndexComplete();
      final hadRows = await _dao.hasRows();
      final progressTotal = _tree.onProgress == null
          ? 0
          : await _dao.noteCount();
      await _orphans.open(hadRows: hadRows);
      touches.begin();
      return (
        contentOwed: contentOwed,
        hadRows: hadRows,
        progressTotal: progressTotal,
      );
    });
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
          final dirClock = Stopwatch()..start();
          // The notes are read before the step, off the lock: a big one
          // takes seconds on a phone, and the lock is only the writes'.
          final read = await _readDir(
            root,
            listing,
            contentOwed: contentOwed,
            progressTotal: progressTotal,
            readsDone: reads,
          );
          final readMs = dirClock.elapsedMilliseconds;
          final current = listing;
          final result = await step(() => _reconcileDir(root, current, read));
          // Where a slow scan spends its time (#698).
          if (dirClock.elapsedMilliseconds >= _slowDirMs) {
            final biggest = _biggestRead(listing, read.contents.keys);
            _log.debug(
              'scan: "${listing.rel}" ${listing.entries.length} entr(ies), '
              '${result.read} read in $readMs ms'
              '${biggest == null ? '' : ' (largest "${biggest.rel}", '
                        '${biggest.size} b)'}, '
              'written in ${dirClock.elapsedMilliseconds - readMs} ms',
            );
          }
          reads += result.read;
          wrote |= result.wrote;
        }
      } catch (error) {
        failure = error;
        rethrow;
      } finally {
        await walk.close(error: failure);
      }
      await step(() async {
        if (hadRows) {
          final paired = await _late.pair(
            root,
            contentOwed: contentOwed,
            progressTotal: progressTotal,
            readsDone: reads,
          );
          reads += paired.read;
          wrote |= paired.wrote;
        }
        final pruned = await _orphans.pruneGone();
        wrote |= pruned.wrote;
        removed.addAll(pruned.removed);
        await _links.writePending();
        // The notes this walk made answer links that were waiting.
        await _store.dangling.flush();
        if (contentOwed && await _store.repairDerivedRows()) wrote = true;
      });
    } finally {
      await step(() async {
        touches.end();
        await _orphans.close();
      });
    }
    _log.info(
      'fullScan $root: $entries entr(ies) ($files file, '
      '${entries - files} dir) in ${clock.elapsedMilliseconds} ms',
    );
    if (!wrote) {
      _log.info('fullScan: index already mirrors disk, no write');
    } else {
      final cb = onChanged;
      if (cb != null) cb(IndexChange.tree);
    }
    if (removed.isNotEmpty) {
      final cb = onRemoved;
      if (cb != null) cb(removed);
    }
  }

  /// The largest of [listing]'s entries among [read], for the slow
  /// directory's log line (#698).
  static DiskEntry? _biggestRead(DirListing listing, Iterable<String> read) {
    final rels = read.toSet();
    DiskEntry? biggest;
    for (final e in listing.entries) {
      if (rels.contains(e.rel) && (biggest == null || e.size > biggest.size)) {
        biggest = e;
      }
    }
    return biggest;
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
  Future<bool> treeFirst(
    String root, {
    void Function(IndexChange change)? onChanged,
  }) async {
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
              created: listing.created,
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
      if (cb != null) cb(IndexChange.tree);
    }
    return wrote;
  }

  /// Reconciles one directory listing against the index rows of that
  /// directory. Answers whether it wrote and how many notes it read.
  Future<_DirRead> _readDir(
    String root,
    DirListing listing, {
    required bool contentOwed,
    required int progressTotal,
    required int readsDone,
  }) async {
    final version = touches.version;
    final state = await _dirState(listing);
    if (listing.rel.isNotEmpty && state.dirRow == null) {
      return (
        contents: const <String, NoteContent>{},
        shas: const <String, String>{},
        state: state,
        version: version,
      );
    }
    final read = await _tree.readContents(
      root,
      state.entries,
      state.old,
      contentOwed: contentOwed,
      progressTotal: progressTotal,
      doneBase: readsDone,
    );
    return (
      contents: read.contents,
      shas: read.shas,
      state: state,
      version: version,
    );
  }

  /// [listing]'s directory row, the rows under it and the entries to
  /// mirror, leaving out what a write touched since the scan began.
  Future<_DirState> _dirState(DirListing listing) async {
    final dirRel = listing.rel;
    final dirRow = dirRel.isEmpty ? null : await _dao.find(dirRel);
    final parentId = dirRow?.id ?? 0;
    // A path a write touched since the listing was taken is the write's:
    // neither its entry nor its row is the scan's to change (#697). A
    // folder holding one stays: it is on disk and in the listing, and out
    // of `old` it would read as new and be written twice; the prune and
    // the pairing shield it instead.
    final old = <String, Note>{
      dirRel: ?dirRow,
      if (dirRel.isEmpty || dirRow != null)
        for (final row in await _dao.children(parentId)) row.path: row,
    }..removeWhere((rel, _) => rel != dirRel && touches.owns(rel));
    final entries = <DiskEntry>[
      if (dirRow != null)
        DiskEntry(
          rel: dirRel,
          name: listing.name,
          isDir: true,
          size: 0,
          modified: listing.modified,
          created: listing.created,
        ),
      for (final e in listing.entries)
        if (!touches.owns(e.rel)) e,
    ];
    return (dirRow: dirRow, old: old, entries: entries);
  }

  Future<({bool wrote, int read})> _reconcileDir(
    String root,
    DirListing listing,
    _DirRead before,
  ) async {
    final dirRel = listing.rel;
    // The rows as they are now, under the lock — read again only when a
    // write came in between, or an idle library's every directory would be
    // queried twice — and what was read before it, less what a write
    // touched in between (#697).
    final (:dirRow, :old, :entries) = before.version == touches.version
        ? before.state
        : await _dirState(listing);
    if (dirRel.isNotEmpty && dirRow == null) {
      // Its parent's listing should have written the row before the walk
      // descended; without one the parent chain cannot resolve. A write
      // between two of the scan's steps may have deleted or moved it
      // (#697): a race with the disk either way, which the write itself
      // or the next scan settles.
      _log.debug('scan: no row for "$dirRel" — skipping its listing');
      return (wrote: false, read: 0);
    }
    final read = (
      contents: {
        for (final MapEntry(:key, :value) in before.contents.entries)
          if (!touches.owns(key)) key: value,
      },
      shas: {
        for (final MapEntry(:key, :value) in before.shas.entries)
          if (!touches.owns(key)) key: value,
      },
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
        orphanLookup: _orphans.lookup,
      );
      wrote |= result.wrote;
      paired = result.pairedRels;
      await _orphans.registerGone(old, result.goneLeft);
    });
    // Content rows (FTS, tags, stems) for the notes whose content was
    // read; a paired rename keeps the rows it already had. Link edges are
    // collected instead of written: their targets resolve at the end of
    // the walk, against the whole final tree (PendingLinkQueue.writePending).
    if (read.contents.isNotEmpty) {
      await _store.applyContent(
        read.contents,
        paired: paired,
        repair: false,
        pendingLink: pending.add,
      );
    }
    await _links.defer(pending);
    return (wrote: wrote, read: read.contents.length);
  }
}

/// A directory's notes as read before its step: their parsed content, and
/// the digest of every note the step mirrors.
typedef _DirRead = ({
  Map<String, NoteContent> contents,
  Map<String, String> shas,
  _DirState state,
  int version,
});

/// A directory's row, the rows under it and the entries to mirror.
typedef _DirState = ({
  Note? dirRow,
  Map<String, Note> old,
  List<DiskEntry> entries,
});
