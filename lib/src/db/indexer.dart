/// The notes index: mirroring the library on disk (T-M1-07).
library;

import 'dart:async';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/index_tree.dart';
import 'package:path/path.dart' as p;

/// Builds and maintains the notes index so it mirrors the library on disk.
///
/// Every mutation is serialized through an internal mutex, so
/// app-originated operations and disk-originated events converge identically
/// (T-M1-07).
///
/// The work itself lives in collaborators (#51): [IndexTree] mirrors the
/// disk tree into the notes rows, [IndexContentStore] writes the
/// content-derived rows (FTS, tags, links, fields, stems), and this class
/// orchestrates the public entry points around them.
final class Indexer {
  /// Creates the indexer over the given [IndexDatabase].
  new(this._db) : _dao = NoteDao(_db), _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final AppLogger _log;

  /// The content store and the tree sync, sharing this indexer's database
  /// handle and DAO. Late so one DAO instance serves all three.
  late final IndexContentStore _store = IndexContentStore(_db, _dao);
  late final IndexTree _tree = IndexTree(_db, _dao, _store);

  /// The DAO over the same database, exposed for read-side callers.
  NoteDao get dao => _dao;

  /// Callback invoked after each successful index mutation.
  void Function()? onChanged;

  /// Called with each note a content pass reads, while it is set.
  ///
  /// Every content read reports, not only a full scan. The session sets
  /// it around a first index and clears it after, because it costs a
  /// message per note and is worth paying only when someone is looking.
  /// Forwarded to the tree sync, which owns the reads.
  set onProgress(void Function(IndexProgress)? cb) => _tree.onProgress = cb;

  /// The forwarded progress callback.
  void Function(IndexProgress)? get onProgress => _tree.onProgress;

  Future<void> _chain = Future<void>.value();

  /// Runs [fn] serially with every other index mutation.
  Future<T> _synchronized<T>(Future<T> Function() fn) {
    final next = _chain.then((_) => fn());
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// Rebuilds the index from a full disk scan of `root`.
  ///
  /// The index is diffed against the walk, so every row whose path survives
  /// keeps its id (the stable id space is what the M3 `frontmatter_fields`,
  /// `note_tags` and FTS indexes key off): gone paths are deleted, new
  /// paths inserted, surviving rows updated where they actually changed.
  /// Used on first open, on the periodic rescan fallback, and for explicit
  /// re-index. Skips the write (and does not fire [onChanged]) when the
  /// index already mirrors the disk tree.
  Future<void> fullScan(String root) {
    return _synchronized(() async {
      final old = <String, Note>{
        for (final row in await _dao.allRows()) row.path: row,
      };
      final entries = await _tree.walk(root, root);
      final files = entries.where((e) => !e.isDir).length;
      _log
        ..info(
          'fullScan $root: found ${entries.length} entr(ies) '
          '($files file, ${entries.length - files} dir)',
        )
        // The paths themselves are not logged: on a large library the line
        // was ~8 KB of the 512 KB ring on every fallback scan, and it
        // evicted the useful history (T-PP-22).
        ..debug('fullScan entries: ${entries.length} path(s)');
      // Checked before the digests: a rescan that changes nothing — the
      // common case — then costs the walk and no reads.
      // The content index can still be incomplete (a v7-era database
      // predates the M3 tables): in that case the no-write exit is skipped
      // and the content pass rebuilds FTS/tags/links for every note.
      if (!_treeChanged(old, entries)) {
        if (await _store.contentIndexComplete()) {
          _log.info('fullScan: index already mirrors disk, no write');
          return;
        }
        _log.info('fullScan: content index incomplete — building content rows');
      }
      _log.info('fullScan: tree changed, applying diff');
      final read = await _tree.readContents(root, entries, old);
      var wrote = false;
      var pairedRels = const <String>{};
      await _db.transaction(() async {
        final result = await _tree.applyDiff(
          entries: entries,
          old: old,
          shas: read.shas,
          contents: read.contents,
        );
        wrote = result.wrote;
        pairedRels = result.pairedRels;
      });
      // Content rows (FTS, tags, links) for the notes whose content
      // actually changed; a paired rename keeps its rows untouched. Runs
      // in its own chunked transactions (after the notes rows) so the
      // frames stay free during a big backfill — and the completeness
      // check repairs a partial pass on the next scan.
      await _store.applyContent(read.contents, paired: pairedRels);
      if (wrote) {
        final cb = onChanged;
        if (cb != null) cb();
      }
    });
  }

  /// Applies a batch of changed absolute paths incrementally.
  ///
  /// The batch is reconciled in one pass: probes batched on a background
  /// isolate, changed-and-new notes read once (digest + text) in batches of
  /// a few hundred, renames-with-unchanged-content paired so the note id
  /// and its FTS/tags/links rows survive, and only then deletes applied —
  /// so a link inside the batch can resolve against notes written earlier
  /// in it. Dot components (`.trash/`, `.history/`, dotfiles) are ignored.
  /// [onChanged] fires once per call, after the writes, and only when the
  /// batch actually changed the index.
  Future<void> applyEvents(String root, List<String> paths) {
    return _synchronized(() async {
      var wrote = false;
      final seen = <String>{};
      final absList = <String>[];
      final rels = <String>[];
      for (final abs in paths) {
        if (!seen.add(abs)) continue;
        final rel = _tree.safeRel(abs, root);
        if (rel == null) {
          _log.debug(
            'applyEvents: skip "$abs" (outside root, root itself, or hidden)',
          );
          continue;
        }
        absList.add(abs);
        rels.add(rel);
      }
      if (absList.isEmpty) return;

      // One probe batch for the whole event set (each stat is a FUSE round
      // trip on Android, so they must be off the UI isolate and together).
      final probes = await _tree.probeAll(absList);
      final live = <String, DiskProbe>{};
      final gone = <String>{};
      for (var i = 0; i < rels.length; i++) {
        if (probes[i].exists) {
          live[rels[i]] = probes[i];
        } else {
          gone.add(rels[i]);
        }
      }

      // New and changed notes read once: digest + text, batched. New notes
      // are candidates for a rename pair; changed existing notes recompute
      // their content rows.
      final contents = await _tree.readBatchContents(root, live);

      // Pair renames with unchanged content: the old row keeps its id (and
      // with it its FTS/tags/links rows) and is repointed at the new path.
      final paired = await _tree.pairRenames(root, live, gone, contents);
      final pairedOld = <String>{for (final o in paired.values) o};
      for (final pair in paired.entries) {
        final oldRow = await _dao.find(pair.value);
        if (oldRow == null) continue;
        final probe = live[pair.key]!;
        final newParentRel = parentOf(pair.key);
        final parentId = newParentRel.isEmpty
            ? 0
            : await _tree.ensureDirChain(root, newParentRel);
        await (_db.update(
          _db.notes,
        )..where((t) => t.id.equals(oldRow.id))).write(
          NotesCompanion(
            path: Value(pair.key),
            parent: Value(parentId),
            name: Value(p.basename(pair.key)),
            isDir: const Value(false),
            size: Value(probe.size),
            modified: Value(probe.modified),
          ),
        );
        await _store.replaceFileStems(oldRow.id, p.basename(pair.key));
        wrote = true;
      }

      // Dirs resync their subtrees; files are upserted with the precomputed
      // content; vanished paths are pruned (pairs applied above count as
      // pruned and are left alone).
      final changed = <NoteContent>[];
      for (final entry in live.entries) {
        if (paired.containsKey(entry.key)) continue;
        if (entry.value.isDir) {
          _log.debug('applyEvents: "$root/${entry.key}" -> resync dir');
          wrote |= await _tree.syncDirSubtree(root, p.join(root, entry.key));
        } else {
          _log.debug('applyEvents: "${entry.key}" -> upsert file');
          final result = await _tree.upsertFile(
            root,
            p.join(root, entry.key),
            entry.key,
            entry.value,
            expected: contents[entry.key],
          );
          wrote |= result.wrote;
          if (result.content != null) changed.add(result.content!);
        }
      }
      for (final rel in gone) {
        if (pairedOld.contains(rel)) continue;
        final deleted = await _dao.deleteSubtree(rel);
        if (deleted > 0) {
          _log.debug('applyEvents: pruned "$rel" ($deleted row(s))');
        }
        wrote |= deleted > 0;
      }
      // Content rows for everything whose digest actually changed — after
      // the row writes, so links resolve against the whole batch.
      for (final c in changed) {
        await _store.applyContent({c.rel: c}, paired: paired.keys.toSet());
      }
      if (wrote) {
        final cb = onChanged;
        if (cb != null) cb();
      }
    });
  }

  /// Re-indexes [paths] (absolute, files) even when their `(size, mtime)`
  /// look unchanged against the stored row: an atomic rewrite of equal
  /// size within the same second is invisible to the (size, mtime, sha)
  /// shortcut the event and full-scan paths trust. The replace runner
  /// calls this for every note it rewrote — it knows the content changed
  /// because it wrote it. [onChanged] fires after the writes, when any row
  /// changed.
  Future<void> rescanFiles(String root, List<String> paths) {
    return _synchronized(() async {
      final seen = <String>{};
      final absList = <String>[];
      final rels = <String>[];
      for (final abs in paths) {
        if (!seen.add(abs)) continue;
        final rel = _tree.safeRel(abs, root);
        if (rel == null) continue;
        absList.add(abs);
        rels.add(rel);
      }
      if (absList.isEmpty) return;

      final probes = await _tree.probeAll(absList);
      final live = <String, DiskProbe>{};
      for (var i = 0; i < rels.length; i++) {
        if (probes[i].exists) live[rels[i]] = probes[i];
      }
      if (live.isEmpty) return;

      // Forced content read: the (size, mtime) shortcut must not apply.
      // Notes only, as on every other content path — this one took the
      // caller's word for it, and a `todo.txt` handed to it by the pin
      // flow was read and indexed as if it were a note.
      final contents = await _tree.readRelContents(root, <String>[
        for (final rel in live.keys)
          if (isNoteFile(p.basename(rel))) rel,
      ]);
      var wrote = false;
      final changed = <NoteContent>[];
      for (final entry in live.entries) {
        final content = contents[entry.key];
        if (content == null) continue;
        final probe = entry.value;
        final updated =
            await (_db.update(
              _db.notes,
            )..where((t) => t.path.equals(entry.key))).write(
              NotesCompanion(
                size: Value(probe.size),
                modified: Value(probe.modified),
                sha256: Value(content.sha256),
              ),
            );
        wrote |= updated > 0;
        changed.add(content);
      }
      if (changed.isEmpty) return;
      // Content rows (FTS, tags, stems, links) follow the forced read.
      await _store.applyContent({
        for (final c in changed) c.rel: c,
      }, paired: const {});
      if (wrote) {
        final cb = onChanged;
        if (cb != null) cb();
      }
    });
  }

  /// Reconciles [abs] with disk: if it exists as a directory the whole
  /// subtree is re-synced (covering renames/moves whose new path was not in
  /// the event batch), if it is a file it is upserted, and if it is gone its
  /// index rows are pruned. Dot components are ignored. [onChanged] fires
  /// after the writes, and only when the index actually changed.
  Future<void> resync(String root, String abs) {
    return _synchronized(() async {
      final rel = _tree.safeRel(abs, root);
      if (rel == null) {
        _log.debug(
          'resync: skip "$abs" (outside root, root itself, or hidden)',
        );
        return;
      }
      final wrote = await _reconcile(root, abs, rel, 'resync');
      if (wrote) {
        final cb = onChanged;
        if (cb != null) cb();
      }
    });
  }

  /// Reconciles one absolute path against disk and the index, returning
  /// whether the index changed. [tag] is the public entry point, kept in
  /// the log lines.
  Future<bool> _reconcile(
    String root,
    String abs,
    String rel,
    String tag,
  ) async {
    // One background-isolate probe (a FUSE stat on Android is a round trip
    // that can take seconds cold, so it must not run on the UI isolate).
    final probe = await Isolate.run(() => probePaths(<String>[abs]).single);
    if (probe.isDir) {
      _log.debug('$tag: "$abs" -> resync dir "$rel"');
      return await _tree.syncDirSubtree(root, abs);
    }
    if (probe.exists) {
      _log.debug('$tag: "$abs" -> upsert file "$rel"');
      final result = await _tree.upsertFile(root, abs, rel, probe);
      if (result.content != null) {
        await _store.applyContent({rel: result.content!}, paired: const {});
      }
      return result.wrote;
    }
    _log.debug('$tag: "$abs" -> prune "$rel"');
    final deleted = await _dao.deleteSubtree(rel);
    if (deleted > 0) {
      _log.debug('$tag: pruned "$rel" ($deleted row(s))');
    }
    return deleted > 0;
  }

  /// Whether the desired tree differs from [old].
  ///
  /// Includes the parent links: an index written by an older build can hold
  /// the right paths with wrong parents, and the diff repairs those, so the
  /// no-write check has to see them. Digests take no part in this: the
  /// reads only ever reuse a stored one when `(size, mtime)` already proves
  /// the content unchanged, so a digest can never be the deciding
  /// difference — and comparing it would force a rewrite of every index
  /// written by an older build.
  bool _treeChanged(Map<String, Note> old, List<DiskEntry> entries) {
    if (old.length != entries.length) return true;
    for (final e in entries) {
      final o = old[e.rel];
      if (o == null) return true;
      if (o.isDir != e.isDir || o.size != e.size || o.name != e.name) {
        return true;
      }
      if (o.modified != toStoredSecond(e.modified)) return true;
      final parentRel = parentOf(e.rel);
      if (o.parent != (parentRel.isEmpty ? 0 : old[parentRel]?.id)) {
        return true;
      }
    }
    return false;
  }
}
