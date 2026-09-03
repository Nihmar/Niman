import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

/// A note file or folder observed on disk during a scan.
final class DiskEntry {
  /// Creates a disk entry for the entry at `rel`.
  const DiskEntry({
    required this.rel,
    required this.name,
    required this.isDir,
    required this.size,
    required this.modified,
  });

  /// Library-relative slash-separated path.
  final String rel;

  /// Base name of the entry.
  final String name;

  /// Whether the entry is a directory.
  final bool isDir;

  /// Byte size (0 for directories).
  final int size;

  /// Last modification time.
  final DateTime modified;
}

/// One disk walk's result: the entries found, plus the log lines the walk
/// wanted to write.
///
/// The walk runs on a background isolate, where the app-wide log buffer
/// does not exist, so its lines travel back here and are replayed by the
/// caller instead.
final class ScanResult {
  /// Creates a walk result.
  const ScanResult({required this.entries, required this.logs});

  /// The entries found, directories and files, in traversal order.
  final List<DiskEntry> entries;

  /// Log lines produced during the walk, oldest first.
  final List<String> logs;
}

/// Walks [start] (the library root itself, or a directory inside [root])
/// depth-first, skipping hidden entries.
///
/// Top-level and fully synchronous so it can be handed to [Isolate.run]:
/// on Android every `listSync`/`statSync` is a FUSE round trip, and a
/// library of a few hundred entries costs the better part of a second —
/// long enough to be felt on the UI isolate, and to stack up into an ANR
/// together with the digests.
ScanResult scanTree(String root, String start) {
  final entries = <DiskEntry>[];
  final logs = <String>[];
  _walkDir(root, Directory(start), entries, logs);
  return ScanResult(entries: entries, logs: logs);
}

void _walkDir(
  String root,
  Directory dir,
  List<DiskEntry> out,
  List<String> logs,
) {
  final rel = relPath(dir.path, root);
  if (rel.isNotEmpty) {
    final st = dir.statSync();
    out.add(
      DiskEntry(
        rel: rel,
        name: p.basename(dir.path),
        isDir: true,
        size: 0,
        modified: st.modified,
      ),
    );
  }
  for (final ent in dir.listSync(followLinks: false)) {
    final name = p.basename(ent.path);
    if (name.startsWith('.')) {
      logs.add('walk: skip hidden entry "$name"');
      continue;
    }
    if (ent is Directory) {
      _walkDir(root, ent, out, logs);
    } else if (ent is File) {
      final st = ent.statSync();
      out.add(
        DiskEntry(
          rel: relPath(ent.path, root),
          name: name,
          isDir: false,
          size: st.size,
          modified: st.modified,
        ),
      );
    } else {
      logs.add('walk: skip non-file/dir entry "${ent.path}" ($ent)');
    }
  }
}

/// Digests the files at [rels] (library-relative) under [root].
///
/// Top-level for [Isolate.run]: hashing reads whole files, so it is the
/// most expensive thing a scan does. A file that cannot be read (deleted
/// or replaced mid-scan) is left out; the next scan picks it up.
Future<Map<String, String>> hashFiles(String root, List<String> rels) async {
  final out = <String, String>{};
  for (final rel in rels) {
    try {
      out[rel] = await hashFileSha256(File(p.join(root, rel)));
    } on FileSystemException catch (_) {
      continue;
    }
  }
  return out;
}

/// Builds and maintains the notes index so it mirrors the library on disk.
///
/// Every mutation is serialized through an internal mutex, so
/// app-originated operations and disk-originated events converge identically
/// (T-M1-07).
final class Indexer {
  /// Creates the indexer over the given [CopistDatabase].
  Indexer(this._db)
      :
        _dao = NoteDao(_db),
        _log = const AppLogger(name: 'indexer');

  final CopistDatabase _db;

  final NoteDao _dao;

  final AppLogger _log;

  /// How many entry paths are listed in a single debug log line before the
  /// rest is summarized, keeping huge libraries from flooding the buffer.
  static const _logEntryCap = 200;

  /// The DAO over the same database, exposed for read-side callers.
  NoteDao get dao => _dao;

  /// Callback invoked after each successful index mutation.
  void Function()? onChanged;

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
      final entries = await _walk(root, root);
      final files = entries.where((e) => !e.isDir).length;
      _log.info(
        'fullScan $root: found ${entries.length} entr(ies) '
        '($files file, ${entries.length - files} dir)',
      );
      _log.debug('fullScan entries: ${_entryList(entries)}');
      // Checked before the digests: a rescan that changes nothing — the
      // common case, once a minute — then costs the walk and no reads.
      if (!_treeChanged(old, entries)) {
        _log.info('fullScan: index already mirrors disk, no write');
        return;
      }
      _log.info('fullScan: tree changed, applying diff');
      final shas = await _digests(root, entries, old);
      var wrote = false;
      await _db.transaction(() async {
        wrote = await _applyDiff(entries: entries, old: old, shas: shas);
      });
      if (wrote) {
        final cb = onChanged;
        if (cb != null) cb();
      }
    });
  }

  /// Applies a batch of changed absolute paths incrementally.
  ///
  /// Each path is reconciled against disk: existing directories resync their
  /// whole subtree, existing files are upserted, and absent paths are pruned
  /// (with their subtree). Dot components (`.trash/`, `.history/`, dotfiles)
  /// are ignored. [onChanged] fires once per call, after the writes, and
  /// only when the batch actually changed the index.
  Future<void> applyEvents(String root, List<String> paths) {
    return _synchronized(() async {
      var wrote = false;
      final seen = <String>{};
      for (final abs in paths) {
        if (!seen.add(abs)) continue;
        final rel = _safeRel(abs, root);
        if (rel == null) {
          _log.debug(
            'applyEvents: skip "$abs" (outside root, root itself, or hidden)',
          );
          continue;
        }
        wrote |= await _reconcile(root, abs, rel, 'applyEvents');
      }
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
      final rel = _safeRel(abs, root);
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
    if (Directory(abs).existsSync()) {
      _log.debug('$tag: "$abs" -> resync dir "$rel"');
      return _syncDirSubtree(root, abs);
    }
    if (File(abs).existsSync()) {
      _log.debug('$tag: "$abs" -> upsert file "$rel"');
      return _upsertFile(root, abs, rel);
    }
    _log.debug('$tag: "$abs" -> prune "$rel"');
    final deleted = await _dao.deleteSubtree(rel);
    if (deleted > 0) {
      _log.debug('$tag: pruned "$rel" ($deleted row(s))');
    }
    return deleted > 0;
  }

  /// Library-relative path of [abs], or `null` when the path is outside the
  /// library, is the library root itself, or is hidden.
  String? _safeRel(String abs, String root) {
    final rootN = p.normalize(root);
    final absN = p.normalize(abs);
    if (absN.length <= rootN.length ||
        !absN.startsWith('$rootN${p.separator}')) {
      return null;
    }
    final rel = p.relative(absN, from: rootN);
    if (rel.isEmpty || _isHidden(rel)) return null;
    return rel;
  }

  /// Whether the desired tree differs from [old].
  ///
  /// Includes the parent links: an index written by an older build can hold
  /// the right paths with wrong parents, and the diff repairs those, so the
  /// no-write check has to see them. Digests take no part in this:
  /// [_digests] only ever reuses a stored one when `(size, mtime)` already
  /// proves the content unchanged, so a digest can never be the deciding
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

  /// The digests for the note files in [entries].
  ///
  /// A stored digest is reused whenever the `(size, mtime)` shortcut
  /// proves the content unchanged; the rest are hashed in one batch on a
  /// background isolate. Only notes are digested — an attachment folder
  /// full of images and e-books would otherwise be read end to end on
  /// every first scan, which is what made the app freeze for seconds.
  ///
  /// [old] holds the current index rows keyed root-relative, which serves
  /// both a full scan and a subtree walk.
  Future<Map<String, String>> _digests(
    String root,
    List<DiskEntry> entries,
    Map<String, Note> old,
  ) async {
    final shas = <String, String>{};
    final todo = <String>[];
    for (final e in entries) {
      if (e.isDir || !_isNote(e.name)) continue;
      final prev = old[e.rel];
      if (prev != null &&
          prev.size == e.size &&
          prev.modified == toStoredSecond(e.modified) &&
          prev.sha256 != null) {
        shas[e.rel] = prev.sha256!;
      } else {
        todo.add(e.rel);
      }
    }
    if (todo.isEmpty) return shas;
    _log.debug('digests: hashing ${todo.length} note(s)');
    shas.addAll(await Isolate.run(() => hashFiles(root, todo)));
    return shas;
  }

  /// Whether [name] is a note file, the only kind the index digests.
  static bool _isNote(String name) =>
      p.extension(name).toLowerCase() == '.md';

  /// Walks [start] on a background isolate and replays its log lines.
  Future<List<DiskEntry>> _walk(String root, String start) async {
    final scan = await Isolate.run(() => scanTree(root, start));
    scan.logs.forEach(_log.debug);
    return scan.entries;
  }

  /// The [entries] rel paths as a single debug log line, capped at
  /// [_logEntryCap] paths.
  String _entryList(List<DiskEntry> entries) {
    if (entries.isEmpty) return '(none)';
    final shown = entries.take(_logEntryCap).map((e) => e.rel).join(', ');
    final extra = entries.length - _logEntryCap;
    return extra > 0 ? '$shown, … (+$extra more)' : shown;
  }

  /// Applies the difference between the desired tree [entries] (a walk of
  /// [scope], keyed root-relative) and the current index rows [old] (scoped
  /// to [scope]), returning whether anything was written.
  ///
  /// New paths are inserted, rows whose name, size, mtime, parent link or
  /// digest changed are updated, and gone paths are deleted through their
  /// highest gone ancestor so a removed directory takes its descendants with
  /// it. Every surviving path keeps its id, so parent links pointing into
  /// the index stay valid and only genuinely re-parented rows are updated.
  Future<bool> _applyDiff({
    required List<DiskEntry> entries,
    required Map<String, Note> old,
    required Map<String, String> shas,
    String scope = '',
    int scopeParentId = 0,
  }) async {
    final scopeParentRel = parentOf(scope);
    final newIds = <String, int>{};
    var wrote = false;
    for (final e in entries) {
      final parentId = _resolveParent(
        parentOf(e.rel),
        scopeParentRel,
        scopeParentId,
        old,
        newIds,
        e.rel,
      );
      final prev = old[e.rel];
      if (prev == null) {
        final id = await _db.into(_db.notes).insert(
          NotesCompanion.insert(
            path: e.rel,
            parent: parentId,
            name: e.name,
            isDir: e.isDir,
            size: e.size,
            modified: e.modified,
            sha256: Value(shas[e.rel]),
          ),
        );
        newIds[e.rel] = id;
        wrote = true;
        continue;
      }
      final changed =
          prev.parent != parentId ||
          prev.name != e.name ||
          prev.isDir != e.isDir ||
          prev.size != e.size ||
          prev.modified != toStoredSecond(e.modified) ||
          prev.sha256 != shas[e.rel];
      if (!changed) continue;
      await (_db
            .update(_db.notes)
            ..where((t) => t.path.equals(e.rel)))
          .write(
            NotesCompanion(
              parent: Value(parentId),
              name: Value(e.name),
              isDir: Value(e.isDir),
              size: Value(e.size),
              modified: Value(e.modified),
              sha256: Value(shas[e.rel]),
            ),
          );
      wrote = true;
    }
    final entryRels = <String>{for (final e in entries) e.rel};
    final gone = <String>{
      for (final rel in old.keys)
        if (!entryRels.contains(rel)) rel,
    };
    for (final rel in gone) {
      if (gone.contains(parentOf(rel))) continue;
      await _dao.deleteSubtree(rel);
      wrote = true;
    }
    return wrote;
  }

  /// The parent id for the entry at [rel]: 0 for the walk root's parent,
  /// [scopeParentId] for the scope's parent, and the stored — or freshly
  /// inserted — id of the parent row otherwise.
  ///
  /// A parent that is neither stored nor in this batch is an index
  /// invariant violation, surfaced instead of silently re-parenting the row
  /// to the library root.
  int _resolveParent(
    String parentRel,
    String scopeParentRel,
    int scopeParentId,
    Map<String, Note> old,
    Map<String, int> newIds,
    String rel,
  ) {
    if (parentRel == scopeParentRel) return scopeParentId;
    final id = old[parentRel]?.id ?? newIds[parentRel];
    if (id == null) {
      throw StateError(
        'Index is missing the parent row "$parentRel" of "$rel"',
      );
    }
    return id;
  }

  bool _isHidden(String rel) {
    for (final part in rel.split('/')) {
      if (part.startsWith('.')) return true;
    }
    return false;
  }

  /// Resyncs the subtree rooted at [abs] (which exists as a directory on
  /// disk) against the index: walks the subtree, reuses unchanged digests,
  /// and applies the diff — inserts, updates and deletes — so every row
  /// whose path survives keeps its id.
  Future<bool> _syncDirSubtree(String root, String abs) async {
    final rel = relPath(abs, root);
    final entries = await _walk(root, abs);
    _log.debug('syncDirSubtree "$rel": ${entries.length} entr(ies)');
    final old = <String, Note>{
      for (final row in rel.isEmpty
          ? await _dao.allRows()
          : await _dao.subtreeRows(rel))
        row.path: row,
    };
    final shas = await _digests(root, entries, old);
    var wrote = false;
    await _db.transaction(() async {
      // The scope root's parent lives outside the walk, so it is resolved
      // from the index — the directory chain is ensured when the rows are
      // still missing — instead of from the batch.
      final scopeParentId = rel.isEmpty
          ? 0
          : await _ensureDirChain(root, parentOf(rel));
      wrote = await _applyDiff(
        entries: entries,
        old: old,
        shas: shas,
        scope: rel,
        scopeParentId: scopeParentId,
      );
    });
    return wrote;
  }

  /// Ensures directory rows exist for every ancestor of [dirRel] (and
  /// [dirRel] itself), returning the id of the [dirRel] row.
  Future<int> _ensureDirChain(String root, String dirRel) async {
    final segs = dirRel.isEmpty ? <String>[] : dirRel.split('/');
    var prefix = '';
    var currentId = 0;
    for (final seg in segs) {
      prefix = prefix.isEmpty ? seg : '$prefix/$seg';
      final row = await _dao.find(prefix);
      if (row == null) {
        final st = Directory(p.join(root, prefix)).statSync();
        currentId = await _db.into(_db.notes).insert(
          NotesCompanion.insert(
            path: prefix,
            parent: currentId,
            name: seg,
            isDir: true,
            size: 0,
            modified: st.modified,
          ),
        );
      } else {
        currentId = row.id;
      }
    }
    return currentId;
  }

  /// Inserts or updates the row for the file at [abs] (root-relative path
  /// [rel]) and returns whether the index changed. The directory chain is
  /// ensured first, so a file appearing outside the app comes in with its
  /// parents.
  Future<bool> _upsertFile(String root, String abs, String rel) async {
    final parentRel = parentOf(rel);
    final parentId = parentRel.isEmpty
        ? 0
        : await _ensureDirChain(root, parentRel);
    final st = File(abs).statSync();
    // Notes only, as in [_digests]; one note is small enough to hash here.
    final sha =
        _isNote(p.basename(abs)) ? await hashFileSha256(File(abs)) : null;
    final existing = await _dao.find(rel);
    if (existing == null) {
      _log.debug('upsert "$rel": insert (parent "$parentRel")');
      await _db.into(_db.notes).insert(
        NotesCompanion.insert(
          path: rel,
          parent: parentId,
          name: p.basename(abs),
          isDir: false,
          size: st.size,
          modified: st.modified,
          sha256: Value(sha),
        ),
      );
      return true;
    }
    final changed = existing.parent != parentId ||
        existing.name != p.basename(abs) ||
        existing.isDir || // a stale directory row at a file path
        existing.size != st.size ||
        existing.modified != toStoredSecond(st.modified) ||
        existing.sha256 != sha;
    if (!changed) {
      _log.debug('upsert "$rel": unchanged');
      return false;
    }
    _log.debug('upsert "$rel": update (parent "$parentRel")');
    await (_db.update(_db.notes)..where((t) => t.path.equals(rel)))
        .write(
          NotesCompanion(
            parent: Value(parentId),
            name: Value(p.basename(abs)),
            isDir: const Value(false),
            size: Value(st.size),
            modified: Value(st.modified),
            sha256: Value(sha),
          ),
        );
    return true;
  }
}
