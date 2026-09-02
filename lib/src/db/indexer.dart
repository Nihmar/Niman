import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/files.dart';
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

/// Builds and maintains the notes index so it mirrors the library on disk.
///
/// Every mutation is serialized through an internal mutex, so
/// app-originated operations and disk-originated events converge identically
/// (T-M1-07).
final class Indexer {
  /// Creates the indexer over the given [CopistDatabase].
  Indexer(this._db) : _dao = NoteDao(_db);

  final CopistDatabase _db;

  final NoteDao _dao;

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

  /// Rebuilds the entire index from a full disk scan of `root`.
  ///
  /// Deletes every row and re-inserts, so the result is always an exact
  /// replica of the disk tree. Used on first open, on the periodic rescan
  /// fallback, and for explicit re-index. Skips the write (and does not
  /// fire [onChanged]) when the index already mirrors the disk tree.
  Future<void> fullScan(String root) {
    return _synchronized(() async {
      final old = <String, Note>{
        for (final row in await _dao.allRows()) row.path: row,
      };
      final entries = await _walk(root);
      final shas = <String, String>{};
      for (final e in entries) {
        if (e.isDir) continue;
        shas[e.rel] = await _hashOrReuse(root, e, 0, old);
      }
      if (!_treeChanged(old, entries, shas)) return;
      await _db.transaction(() async {
        await _db.customStatement('DELETE FROM notes');
        await _insertEntries(entries, shas);
      });
    });
  }

  /// Applies a batch of changed absolute paths incrementally.
  ///
  /// Each path is reconciled against disk: existing directories resync their
  /// whole subtree, existing files are upserted, and absent paths are pruned
  /// (with their subtree). Dot components (`.trash/`, `.history/`, dotfiles)
  /// are ignored.
  Future<void> applyEvents(String root, List<String> paths) {
    return _synchronized(() async {
      final seen = <String>{};
      for (final abs in paths) {
        if (!seen.add(abs)) continue;
        final rel = _safeRel(abs, root);
        if (rel == null) continue;
        final dir = Directory(abs);
        final file = File(abs);
        if (dir.existsSync()) {
          await _syncDirSubtree(root, abs);
        } else if (file.existsSync()) {
          await _upsertFile(root, abs, rel);
        } else {
          await _dao.deleteSubtree(rel);
        }
      }
    });
  }

  /// Reconciles [abs] with disk: if it exists as a directory the whole
  /// subtree is re-synced (covering renames/moves whose new path was not in
  /// the event batch), if it is a file it is upserted, and if it is gone its
  /// index rows are pruned. Dot components are ignored.
  Future<void> resync(String root, String abs) {
    return _synchronized(() async {
      final rel = _safeRel(abs, root);
      if (rel == null) return;
      final dir = Directory(abs);
      if (dir.existsSync()) {
        await _syncDirSubtree(root, abs);
      } else if (File(abs).existsSync()) {
        await _upsertFile(root, abs, rel);
      } else {
        await _dao.deleteSubtree(rel);
      }
    });
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

  /// Whether the desired tree (entries + shas) differs from [old].
  bool _treeChanged(
    Map<String, Note> old,
    List<DiskEntry> entries,
    Map<String, String> shas,
  ) {
    if (old.length != entries.length) return true;
    for (final e in entries) {
      final o = old[e.rel];
      if (o == null) return true;
      if (o.isDir != e.isDir || o.size != e.size || o.name != e.name) {
        return true;
      }
      if (o.modified != toStoredSecond(e.modified)) return true;
      if (!e.isDir && o.sha256 != shas[e.rel]) return true;
    }
    return false;
  }

  /// The sha256 for entry [e], reusing the previously indexed digest when
  /// the `(size, mtime)` shortcut proves the content unchanged.
  ///
  /// [depth] is the number of leading path segments stripped to form the
  /// lookup key (0 for full scans, N for a directory subtree sync); [old] is
  /// keyed accordingly.
  Future<String> _hashOrReuse(
    String root,
    DiskEntry e,
    int depth,
    Map<String, Note> old,
  ) async {
    final prev = old[stripSegments(e.rel, depth)];
    if (prev != null &&
        prev.size == e.size &&
        prev.modified == toStoredSecond(e.modified) &&
        prev.sha256 != null) {
      return prev.sha256!;
    }
    return hashFileSha256(File(p.join(root, e.rel)));
  }

  Future<List<DiskEntry>> _walk(String root) async {
    final out = <DiskEntry>[];
    await _walkDir(root, Directory(root), out);
    return out;
  }

  Future<void> _walkDir(String root, Directory dir, List<DiskEntry> out) async {
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
      if (name.startsWith('.')) continue;
      if (ent is Directory) {
        await _walkDir(root, ent, out);
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
      }
    }
  }

  /// Inserts [entries] (directories first, then files), assigning the parent
  /// ids collected from the directory pass.
  Future<void> _insertEntries(
    List<DiskEntry> entries,
    Map<String, String> shas,
  ) async {
    final dirIds = <String, int>{};
    for (final e in entries) {
      if (!e.isDir) continue;
      final id = await _db
          .into(_db.notes)
          .insert(
            NotesCompanion.insert(
              path: e.rel,
              parent: 0,
              name: e.name,
              isDir: true,
              size: 0,
              modified: e.modified,
            ),
          );
      dirIds[e.rel] = id;
    }
    for (final e in entries) {
      if (!e.isDir) continue;
      final parentId = _parentId(e.rel, dirIds);
      if (parentId != 0) {
        await (_db.update(_db.notes)
              ..where((t) => t.path.equals(e.rel)))
            .write(NotesCompanion(parent: Value(parentId)));
      }
    }
    for (final e in entries) {
      if (e.isDir) continue;
      final parentId = _parentId(e.rel, dirIds);
      await _db.into(_db.notes).insert(
        NotesCompanion.insert(
          path: e.rel,
          parent: parentId,
          name: e.name,
          isDir: false,
          size: e.size,
          modified: e.modified,
          sha256: Value(shas[e.rel]),
        ),
      );
    }
  }

  int _parentId(String rel, Map<String, int> dirIds) {
    final parentRel = parentOf(rel);
    return parentRel.isEmpty ? 0 : dirIds[parentRel] ?? 0;
  }

  bool _isHidden(String rel) {
    for (final part in rel.split('/')) {
      if (part.startsWith('.')) return true;
    }
    return false;
  }

  /// Resyncs the subtree rooted at [abs] (which exists as a directory on
  /// disk): walks the subtree, reuses unchanged digests, deletes the stale
  /// rows, and inserts the fresh ones.
  Future<void> _syncDirSubtree(String root, String abs) async {
    final rel = relPath(abs, root);
    final entries = <DiskEntry>[];
    await _walkDir(root, Directory(abs), entries);
    final oldRows = await _dao.subtreeRows(rel);
    final depth = rel.isEmpty ? 0 : rel.split('/').length;
    final oldBySuffix = <String, Note>{
      for (final row in oldRows)
        if (!row.isDir) stripSegments(row.path, depth): row,
    };
    final shas = <String, String>{};
    for (final e in entries) {
      if (e.isDir) continue;
      shas[e.rel] = await _hashOrReuse(root, e, depth, oldBySuffix);
    }
    await _db.transaction(() async {
      if (rel.isEmpty) {
        await _db.customStatement('DELETE FROM notes');
      } else {
        await _dao.deleteSubtree(rel);
      }
      await _insertEntries(entries, shas);
    });
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

  Future<void> _upsertFile(String root, String abs, String rel) async {
    final parentRel = parentOf(rel);
    final parentId = parentRel.isEmpty
        ? 0
        : await _ensureDirChain(root, parentRel);
    final st = File(abs).statSync();
    final sha = await hashFileSha256(File(abs));
    final existing = await _dao.find(rel);
    if (existing == null) {
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
    } else {
      await (_db.update(_db.notes)
            ..where((t) => t.path.equals(rel)))
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
    }
  }
}
