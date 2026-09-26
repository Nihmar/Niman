/// The notes index: mirroring the library on disk (T-M1-07).
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_reconcile.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/index_tree.dart';
import 'package:niman/src/frontmatter/parser.dart';
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

  /// The directory-at-a-time full scan (#302).
  late final IndexReconciler _scan = IndexReconciler(_db, _dao, _tree, _store);

  /// The DAO over the same database, exposed for read-side callers.
  NoteDao get dao => _dao;

  /// Callback invoked after each successful index mutation.
  void Function()? onChanged;

  /// Callback invoked with the library-relative paths a scan or a batch
  /// pruned from the tree — a note or a folder gone from disk. Renames are
  /// paired, not pruned, so they never arrive here. Lets a caller close
  /// what it holds open on a path that no longer exists.
  void Function(Set<String> removed)? onRemoved;

  /// Called with each note a content pass reads, while it is set.
  ///
  /// Every content read reports, not only a full scan. The session sets
  /// it around a first index and clears it after, because it costs a
  /// message per note and is worth paying only when someone is looking.
  /// Forwarded to the tree sync, which owns the reads.
  set onProgress(void Function(IndexProgress)? cb) => _tree.onProgress = cb;

  /// The forwarded progress callback.
  void Function(IndexProgress)? get onProgress => _tree.onProgress;

  /// Which notes their writer reads in a moment, by library-relative path
  /// (`NoteWriter.awaits`): every entry point but [rescanFiles] — the
  /// writer's own — leaves those notes' rows as they are
  /// (`IndexTree.awaited`).
  bool Function(String rel) get awaitedByWriter => _tree.awaited;

  set awaitedByWriter(bool Function(String rel) awaited) =>
      _tree.awaited = awaited;

  Future<void> _chain = Future<void>.value();

  /// Runs [fn] serially with every other index mutation.
  Future<T> _synchronized<T>(Future<T> Function() fn) {
    final next = _chain.then((_) => fn());
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// Rebuilds the index from a full disk scan of `root`.
  ///
  /// The index is diffed against the walk a directory at a time (#302), so
  /// every row whose path survives keeps its id (the stable id space is
  /// what the M3 `frontmatter_fields`, `note_tags` and FTS indexes key
  /// off): gone paths are deleted, new paths inserted, surviving rows
  /// updated where they actually changed. Used on first open, on the
  /// periodic rescan fallback, and for explicit re-index. Skips the write
  /// (and does not fire [onChanged]) when the index already mirrors the
  /// disk tree.
  Future<void> fullScan(String root) {
    return _synchronized(
      () => _scan.fullScan(root, onChanged: onChanged, onRemoved: onRemoved),
    );
  }

  /// The first index of a library, the tree alone: when the index is empty,
  /// the walk's rows — paths, sizes, times, the names links resolve by —
  /// written without reading a note. Answers whether it did, in which case
  /// the content (the search body, tags, links, frontmatter, digests) is
  /// owed, and a [fullScan] builds it: it finds every note without a
  /// content row and reads it.
  ///
  /// What makes a first open wait for the tree and not for the notes: a
  /// library holding the 247 MB stress note took some eleven seconds to
  /// read on a desktop before it opened at all (`docs/records/huge-notes.md`,
  /// item 8), for rows the tree does not need. On an index that has rows a
  /// scan writes digests it read, and a row written without one would lose
  /// the digest the rename pairing keys on — so this is the empty index's
  /// alone.
  Future<bool> indexTreeFirst(String root) {
    return _synchronized(() => _scan.treeFirst(root, onChanged: onChanged));
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
          if (!probes[i].isDir && _tree.awaited(rels[i])) {
            _log.debug('applyEvents: "${rels[i]}" -> its writer reads it');
            continue;
          }
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
      final removed = <String>{};
      for (final entry in live.entries) {
        if (paired.containsKey(entry.key)) continue;
        if (entry.value.isDir) {
          _log.debug('applyEvents: "$root/${entry.key}" -> resync dir');
          final synced = await _tree.syncDirSubtree(
            root,
            p.join(root, entry.key),
          );
          wrote |= synced.wrote;
          removed.addAll(synced.removed);
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
        if (gone.contains(parentOf(rel))) continue;
        if (pairedOld.contains(rel)) continue;
        final deleted = await _dao.deleteSubtree(rel);
        if (deleted > 0) {
          _log.debug('applyEvents: pruned "$rel" ($deleted row(s))');
          removed.add(rel);
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
      if (removed.isNotEmpty) {
        final cb = onRemoved;
        if (cb != null) cb(removed);
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
  ///
  /// [known] is what the writer knows of notes it wrote, by
  /// library-relative path ([KnownContent]): taken where the file is still
  /// the one it wrote.
  Future<void> rescanFiles(
    String root,
    List<String> paths, {
    Map<String, KnownContent> known = const {},
  }) {
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
      ], known: known);
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

  /// Records the frontmatter [head] of the note at [rel] (library-relative)
  /// — the fields, and the title, date and pin the tree shows — without
  /// reading the note.
  ///
  /// For an edit that changed only the note's frontmatter and knows what
  /// the block now says: a pin. The rest of what the index holds of the
  /// note — its digest, its full-text row, its tags and links, its size
  /// and time — is left as it was, so the note still reads as changed to
  /// every scan, and the next reindex of it brings those up to date. On the
  /// 247 MB stress note that reindex is 15 to 34 s on a phone; the pin is
  /// on screen at once.
  Future<void> applyFrontmatter(String rel, Frontmatter? head) {
    return _synchronized(() async {
      final row = await _dao.find(rel);
      if (row == null || row.isDir || !isNoteFile(row.name)) return;
      await _db.transaction(
        () => _store.writeFields(
          row.id,
          fields: head?.fields ?? const {},
          date: head?.date,
          pinned: head?.pinned ?? false,
        ),
      );
      final cb = onChanged;
      if (cb != null) cb();
    });
  }

  /// Reconciles [abs] with disk: if it exists as a directory the whole
  /// subtree is re-synced (covering renames/moves whose new path was not in
  /// the event batch), if it is a file it is upserted, and if it is gone its
  /// index rows are pruned. Dot components are ignored. [onChanged] fires
  /// after the writes, and only when the index actually changed; [onRemoved]
  /// fires with the paths the reconcile pruned.
  Future<void> resync(String root, String abs) {
    return _synchronized(() async {
      final rel = _tree.safeRel(abs, root);
      if (rel == null) {
        _log.debug(
          'resync: skip "$abs" (outside root, root itself, or hidden)',
        );
        return;
      }
      final result = await _reconcile(root, abs, rel, 'resync');
      if (result.wrote) {
        final cb = onChanged;
        if (cb != null) cb();
      }
      if (result.removed.isNotEmpty) {
        final cb = onRemoved;
        if (cb != null) cb(result.removed);
      }
    });
  }

  /// Reconciles one absolute path against disk and the index, returning
  /// whether the index changed and the top-level paths it pruned. [tag] is
  /// the public entry point, kept in the log lines.
  Future<({bool wrote, Set<String> removed})> _reconcile(
    String root,
    String abs,
    String rel,
    String tag,
  ) async {
    // One background-isolate probe (a FUSE stat on Android is a round trip
    // that can take seconds cold, so it must not run on the UI isolate).
    final probe = await IsolateGauge.run(
      () => probePaths(<String>[abs]).single,
      '$tag probe "$rel"',
    );
    if (probe.isDir) {
      _log.debug('$tag: "$abs" -> resync dir "$rel"');
      return await _tree.syncDirSubtree(root, abs);
    }
    if (probe.exists && _tree.awaited(rel)) {
      _log.debug('$tag: "$rel" -> its writer reads it');
      return (wrote: false, removed: const <String>{});
    }
    if (probe.exists) {
      _log.debug('$tag: "$abs" -> upsert file "$rel"');
      final result = await _tree.upsertFile(root, abs, rel, probe);
      if (result.content != null) {
        await _store.applyContent({rel: result.content!}, paired: const {});
      }
      return (wrote: result.wrote, removed: const <String>{});
    }
    _log.debug('$tag: "$abs" -> prune "$rel"');
    final deleted = await _dao.deleteSubtree(rel);
    if (deleted > 0) {
      _log.debug('$tag: pruned "$rel" ($deleted row(s))');
      return (wrote: true, removed: <String>{rel});
    }
    return (wrote: false, removed: const <String>{});
  }
}
