/// Disk-to-rows mirroring for the index: walks, probes and reads on one
/// side, diff/pair/upsert writes on the other. Owned by the indexer
/// facade, which orchestrates the public entry points around these calls.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:path/path.dart' as p;

/// Mirrors the library tree on disk into the index rows (#51).
final class IndexTree {
  /// Creates the tree sync over the given [IndexDatabase], sharing a
  /// content store for completeness checks, stem writes and content
  /// passes.
  new(this._db, this._dao, this._store)
    : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final IndexContentStore _store;

  final AppLogger _log;

  /// Called with each note a content pass reads, while it is set. Kept
  /// here (not on the facade) because the reads live here; the facade
  /// forwards its own setter to this field.
  void Function(IndexProgress)? onProgress;

  /// Whether the note at a library-relative path is one whose reindex its
  /// writer has scheduled (`NoteWriter.awaits`): a note the app itself
  /// just wrote, that the writer reads into the index once it is left
  /// alone.
  ///
  /// The scans that are not the writer's leave such a note be. The watcher
  /// reports every write — the app's own too — and a note's size changes
  /// with nearly every save, so the event path read it at once: 13.5 s of
  /// the 247 MB stress note after a pin, and again 30 s later when the
  /// writer's own reindex ran (log, 2026-09-24) — the wait that reindex
  /// keeps for a note being written, undone by the watcher at every save.
  /// Should the app go before the writer reads it, the next open's scan
  /// finds the row older than the file and reads it then.
  bool Function(String rel) awaited = _none;

  static bool _none(String rel) => false;

  /// How many changed notes are read per isolate call (T-M3-03: a few
  /// hundred).
  static const _contentBatch = 200;

  /// Library-relative path of [abs], or `null` when the path is outside the
  /// library, is the library root itself, or is hidden.
  ///
  /// Slash-separated, through the same [relPath] the scan walk uses. A
  /// bare `p.relative` gives the platform separator, which on Windows had
  /// this function answering `Docs\One.md` for a note the walk had
  /// indexed as `Docs/One.md`: the same note under two paths, one row per
  /// spelling, and every lookup by the path the rest of the app builds
  /// missing the row the incremental pass had just written.
  String? safeRel(String abs, String root) {
    final rootN = p.normalize(root);
    final absN = p.normalize(abs);
    if (absN.length <= rootN.length ||
        !absN.startsWith('$rootN${p.separator}')) {
      return null;
    }
    final rel = relPath(absN, rootN);
    if (rel.isEmpty || _isHidden(rel)) return null;
    return rel;
  }

  bool _isHidden(String rel) {
    for (final part in rel.split('/')) {
      if (part.startsWith('.')) return true;
    }
    return false;
  }

  /// Walks [start] on a background isolate and replays its log lines.
  Future<List<DiskEntry>> walk(String root, String start) async {
    final scan = await IsolateGauge.run(
      () => scanTree(root, start),
      'walk "$start"',
    );
    scan.logs.forEach(_log.debug);
    return scan.entries;
  }

  /// Probes a batch of absolute paths on a background isolate.
  ///
  /// Kept as its own method (no instance members referenced) so the
  /// [Isolate.run] closure captures only the sendable path list — the
  /// indexer itself holds an unsendable future chain.
  Future<List<DiskProbe>> probeAll(List<String> absPaths) {
    final paths = List<String>.of(absPaths);
    return IsolateGauge.run(
      () => probePaths(paths),
      'probe ${paths.length} path(s)',
    );
  }

  /// Reads [rels] in batches of [_contentBatch] on the index isolate.
  ///
  /// While [onProgress] is set, the read isolate reports each note as it
  /// reaches it. The port is opened only then: a scan nobody is watching
  /// should not pay for a message per note.
  ///
  /// [known] holds what the app knows of notes it wrote itself
  /// ([KnownContent]), taken when the file is still the one written.
  Future<Map<String, NoteContent>> readRelContents(
    String root,
    List<String> rels, {
    Map<String, KnownContent> known = const {},
    int total = 0,
    int doneBase = 0,
  }) async {
    if (rels.isEmpty) return const {};
    final contents = <String, NoteContent>{};
    _log.debug('contents: reading ${rels.length} note(s)');
    final report = onProgress;
    // The denominator of a progress report: a directory-at-a-time scan
    // knows the library's note count once and passes it down, so the bar
    // does not reset at every folder; a one-off read reports its own size.
    final of = total > 0 ? total : rels.length;
    ReceivePort? port;
    if (report != null) {
      var done = 0;
      port = ReceivePort()
        ..listen((message) {
          done++;
          report(
            IndexProgress(
              file: message! as String,
              done: doneBase + done,
              of: of,
            ),
          );
        });
    }
    final send = port?.sendPort;
    try {
      for (var i = 0; i < rels.length; i += _contentBatch) {
        final end = i + _contentBatch < rels.length
            ? i + _contentBatch
            : rels.length;
        final batch = rels.sublist(i, end);
        final read = await readBatchOnIsolate(root, batch, send, {
          for (final rel in batch) rel: ?known[rel],
        });
        for (final c in read) {
          contents[c.rel] = c;
        }
      }
    } finally {
      port?.close();
    }
    return contents;
  }

  /// Reads the notes of an event batch that need content: new note files
  /// and existing notes whose `(size, mtime)` no longer proves the content
  /// unchanged — one read per note, parsed off the UI isolate.
  Future<Map<String, NoteContent>> readBatchContents(
    String root,
    Map<String, DiskProbe> live,
  ) async {
    final todo = <String>[];
    for (final entry in live.entries) {
      if (entry.value.isDir || !isNoteFile(p.basename(entry.key))) continue;
      final row = await _dao.find(entry.key);
      if (row == null ||
          row.size != entry.value.size ||
          row.modified != toStoredSecond(entry.value.modified)) {
        todo.add(entry.key);
      }
    }
    return await readRelContents(root, todo);
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
  /// Reads the content of the notes in [entries] whose digest cannot be
  /// reused: new notes and notes whose `(size, mtime)` differs from the
  /// stored row. One read per changed note (digest + text, parsed on the
  /// index isolate), batched a few hundred per isolate call; unchanged
  /// notes reuse their stored digest and are never read (the incremental
  /// AC). Only notes are read — an attachment folder full of images and
  /// e-books would otherwise be read end to end on every first scan,
  /// which is what made the app freeze for seconds.
  ///
  /// Returns the parsed contents and the digest map for every entry
  /// [old] is keyed root-relative, which serves both a full scan and a
  /// subtree walk.
  Future<({Map<String, NoteContent> contents, Map<String, String> shas})>
  readContents(
    String root,
    List<DiskEntry> entries,
    Map<String, Note> old, {
    bool? contentOwed,
    int progressTotal = 0,
    int doneBase = 0,
  }) async {
    final shas = <String, String>{};
    final todo = <String>[];
    final pending = <String>{};
    final noteRels = <String>[];
    for (final e in entries) {
      if (e.isDir || !isNoteFile(e.name)) continue;
      noteRels.add(e.rel);
      final prev = old[e.rel];
      if (prev != null && awaited(e.rel)) {
        // Its writer reads it in a moment: its row stays as it is.
        final sha = prev.sha256;
        if (sha != null) shas[e.rel] = sha;
        continue;
      }
      if (prev != null &&
          prev.size == e.size &&
          prev.modified == toStoredSecond(e.modified) &&
          prev.sha256 != null) {
        shas[e.rel] = prev.sha256!;
      } else {
        todo.add(e.rel);
        pending.add(e.rel);
      }
    }
    // Notes without a content row (the v7-era index or a half-rebuilt db)
    // are read once here, so the content pass can build their rows — even
    // when their (size, mtime) did not change. Scoped to the notes of this
    // listing: a directory-at-a-time scan checks folder by folder, so a
    // million missing rows never become a list in memory (#302).
    if (contentOwed ?? !await _store.contentIndexComplete()) {
      for (final rel in await _store.missingFtsAmong(noteRels)) {
        if (pending.add(rel) && !awaited(rel)) todo.add(rel);
      }
    }
    final contents = await readRelContents(
      root,
      todo,
      total: progressTotal,
      doneBase: doneBase,
    );
    for (final c in contents.values) {
      shas[c.rel] = c.sha256;
    }
    return (contents: contents, shas: shas);
  }

  /// Pairs newly-appeared note files with vanished ones from the same
  /// batch when the content is provably unchanged: same size, same mtime
  /// (a rename keeps both) and — verified by the read — the same digest.
  ///
  /// Returns `newRel → oldRel`; pairs are one-to-one and unique, so a
  /// scan that moved two files onto each other's paths pairs nothing.
  Future<Map<String, String>> pairRenames(
    String root,
    Map<String, DiskProbe> live,
    Set<String> gone,
    Map<String, NoteContent> contents,
  ) async {
    final paired = <String, String>{};
    for (final entry in live.entries) {
      final content = contents[entry.key];
      if (content == null) continue;
      String? candidate;
      for (final goneRel in gone) {
        final row = await _dao.find(goneRel);
        if (row == null || row.isDir || row.sha256 != content.sha256) {
          continue;
        }
        if (row.size != entry.value.size ||
            row.modified != toStoredSecond(entry.value.modified)) {
          continue;
        }
        if (candidate != null) {
          candidate = null; // ambiguous — pair nothing
          break;
        }
        candidate = goneRel;
      }
      if (candidate != null) {
        paired[entry.key] = candidate;
        _log.debug('pair: "$candidate" -> "${entry.key}" (content unchanged)');
      }
    }
    return paired;
  }

  /// Applies the difference between the desired tree [entries] (a walk of
  /// [scope], keyed root-relative) and the current index rows [old] (scoped
  /// to [scope]), returning whether anything was written and which rels
  /// came in as content-preserving rename pairs.
  ///
  /// New paths are inserted, rows whose name, size, mtime, parent link or
  /// digest changed are updated, and gone paths are deleted through their
  /// highest gone ancestor so a removed directory takes its descendants with
  /// it. Every surviving path keeps its id, so parent links pointing into
  /// the index stay valid and only genuinely re-parented rows are updated.
  ///
  /// A vanished note whose content reappears unchanged under a new path
  /// (rename: same size, same mtime, same digest — [shas] holds the fresh
  /// digest because the path is new) is paired: the old row is repointed
  /// at the new path in place, keeping its id — and with the id its FTS,
  /// tags and links rows, which key on it.
  ///
  /// `removed` is the top-level paths actually pruned: a gone note, or a
  /// gone folder (its rows pruned whole). Renames are paired, not removed.
  ///
  /// [deferDeletes] leaves the gone rows alone and reports them through
  /// `goneLeft` instead — what a directory-at-a-time scan wants, so a note
  /// that vanished from this folder is still around to pair when a later
  /// folder turns out to be its new home (#302). [orphanLookup] is the
  /// other half: a candidate from a directory the scan has already passed,
  /// asked only when this listing has none, and expected to consume the
  /// candidate it answers with.
  Future<
    ({
      bool wrote,
      Set<String> pairedRels,
      Set<String> removed,
      Set<String> goneLeft,
    })
  >
  applyDiff({
    required List<DiskEntry> entries,
    required Map<String, Note> old,
    required Map<String, String> shas,
    required Map<String, NoteContent> contents,
    String scope = '',
    int scopeParentId = 0,
    bool deferDeletes = false,
    Future<Note?> Function(DiskEntry entry, String sha)? orphanLookup,
  }) async {
    final scopeParentRel = parentOf(scope);
    final entryRels = <String>{for (final e in entries) e.rel};
    final gone = <String>{
      for (final rel in old.keys)
        if (!entryRels.contains(rel)) rel,
    };
    final newIds = <String, int>{};
    final pairedRels = <String>{};
    final pairedOld = <String>{};
    var wrote = false;
    for (final e in entries) {
      final prev = old[e.rel];
      // A note its writer reads in a moment keeps the row it has: updated
      // here, its size and time would say the row is current while its
      // content is the text before.
      if (prev != null && !e.isDir && awaited(e.rel)) continue;
      if (prev != null) {
        final parentId = _resolveParent(
          parentOf(e.rel),
          scopeParentRel,
          scopeParentId,
          old,
          newIds,
          e.rel,
        );
        final changed =
            prev.parent != parentId ||
            prev.name != e.name ||
            prev.isDir != e.isDir ||
            prev.size != e.size ||
            prev.modified != toStoredSecond(e.modified) ||
            prev.sha256 != shas[e.rel];
        if (!changed) continue;
        await (_db.update(_db.notes)..where((t) => t.path.equals(e.rel))).write(
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
        continue;
      }
      final parentId = _resolveParent(
        parentOf(e.rel),
        scopeParentRel,
        scopeParentId,
        old,
        newIds,
        e.rel,
      );
      final pairOld = _pairCandidate(e, shas[e.rel], old, gone, pairedOld);
      final sha = shas[e.rel];
      var pairRow = pairOld == null ? null : old[pairOld];
      // A rename whose old home a previous directory of the same scan
      // found gone (#302): the candidate lives in the scan's orphan table,
      // not in this listing's rows. It is consumed by the lookup, so two
      // entries can never pair with one row.
      if (pairRow == null && !e.isDir && sha != null && orphanLookup != null) {
        pairRow = await orphanLookup(e, sha);
      }
      if (pairRow != null) {
        // Rename with unchanged content: the old row keeps its id. A
        // non-null local, because the query builder's closure below cannot
        // see the promotion of a variable the lookup may have written.
        final pairing = pairRow;
        await (_db.update(
          _db.notes,
        )..where((t) => t.id.equals(pairing.id))).write(
          NotesCompanion(
            path: Value(e.rel),
            parent: Value(parentId),
            name: Value(e.name),
            isDir: const Value(false),
            size: Value(e.size),
            modified: Value(e.modified),
            sha256: Value(sha),
          ),
        );
        newIds[e.rel] = pairing.id;
        pairedRels.add(e.rel);
        pairedOld.add(pairing.path);
        await _store.replaceFileStems(pairing.id, e.name);
        wrote = true;
        continue;
      }

      final id = await _db
          .into(_db.notes)
          .insert(
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
      await _store.replaceFileStems(id, e.name, isDir: e.isDir);
      wrote = true;
    }
    final removed = <String>{};
    final goneLeft = <String>{};
    for (final rel in gone) {
      if (gone.contains(parentOf(rel))) continue;
      if (pairedOld.contains(rel)) continue;
      // The caller prunes later: a directory-at-a-time scan keeps every
      // vanished note of this listing in its orphan table until the walk
      // has seen the whole tree, so a move into a directory it has already
      // passed can still pair (#302).
      goneLeft.add(rel);
      if (deferDeletes) continue;
      await _dao.deleteSubtree(rel);
      removed.add(rel);
      wrote = true;
    }
    return (
      wrote: wrote,
      pairedRels: pairedRels,
      removed: removed,
      goneLeft: goneLeft,
    );
  }

  /// The gone-path candidate for a content-preserving rename of [e]: a
  /// vanished note — not yet paired — with the same size, the same mtime
  /// and the same fresh digest as the new entry. Unique match only.
  String? _pairCandidate(
    DiskEntry e,
    String? sha,
    Map<String, Note> old,
    Set<String> gone,
    Set<String> alreadyPaired,
  ) {
    if (sha == null || e.isDir) return null;
    String? found;
    for (final goneRel in gone) {
      if (alreadyPaired.contains(goneRel)) continue;
      final row = old[goneRel];
      if (row == null || row.isDir || row.sha256 != sha) continue;
      if (row.size != e.size || row.modified != toStoredSecond(e.modified)) {
        continue;
      }
      if (found != null) return null; // ambiguous
      found = goneRel;
    }
    return found;
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

  /// Resyncs the subtree rooted at [abs] (which exists as a directory on
  /// disk) against the index: walks the subtree, reuses unchanged digests,
  /// and applies the diff — inserts, updates and deletes — so every row
  /// whose path survives keeps its id. `removed` is the top-level paths
  /// the resync pruned.
  Future<({bool wrote, Set<String> removed})> syncDirSubtree(
    String root,
    String abs,
  ) async {
    final rel = relPath(abs, root);
    final entries = await walk(root, abs);
    _log.debug('syncDirSubtree "$rel": ${entries.length} entr(ies)');
    final old = <String, Note>{
      for (final row
          in rel.isEmpty ? await _dao.allRows() : await _dao.subtreeRows(rel))
        row.path: row,
    };
    final read = await readContents(root, entries, old);
    var wrote = false;
    var pairedRels = const <String>{};
    var removed = const <String>{};
    await _db.transaction(() async {
      // The scope root's parent lives outside the walk, so it is resolved
      // from the index — the directory chain is ensured when the rows are
      // still missing — instead of from the batch.
      final scopeParentId = rel.isEmpty
          ? 0
          : await ensureDirChain(root, parentOf(rel));
      final result = await applyDiff(
        entries: entries,
        old: old,
        shas: read.shas,
        contents: read.contents,
        scope: rel,
        scopeParentId: scopeParentId,
      );
      wrote = result.wrote;
      pairedRels = result.pairedRels;
      removed = result.removed;
    });
    await _store.applyContent(read.contents, paired: pairedRels);
    return (wrote: wrote, removed: removed);
  }

  /// Ensures directory rows exist for every ancestor of [dirRel] (and
  /// [dirRel] itself), returning the id of the [dirRel] row.
  Future<int> ensureDirChain(String root, String dirRel) async {
    final segs = dirRel.isEmpty ? <String>[] : dirRel.split('/');
    // The missing rows first (index only, no disk), so the on-disk probe
    // (one FUSE round trip per path) batches into a single background
    // isolate call instead of one per ancestor on the UI isolate.
    final missing = <String>[];
    var prefix = '';
    for (final seg in segs) {
      prefix = prefix.isEmpty ? seg : '$prefix/$seg';
      if (await _dao.find(prefix) == null) missing.add(prefix);
    }
    final probes = missing.isEmpty
        ? const <DiskProbe>[]
        : await IsolateGauge.run(
            () => probePaths([for (final m in missing) p.join(root, m)]),
            'probe ${missing.length} missing parent(s)',
          );
    var probeIndex = 0;
    var currentId = 0;
    prefix = '';
    for (final seg in segs) {
      prefix = prefix.isEmpty ? seg : '$prefix/$seg';
      final row = await _dao.find(prefix);
      if (row == null) {
        final probe = probes[probeIndex++];
        currentId = await _db
            .into(_db.notes)
            .insert(
              NotesCompanion.insert(
                path: prefix,
                parent: currentId,
                name: seg,
                isDir: true,
                size: 0,
                modified: probe.modified,
              ),
            );
      } else {
        currentId = row.id;
      }
    }
    return currentId;
  }

  /// Inserts or updates the row for the file at [abs] (root-relative path
  /// [rel], on-disk state [probe]) and returns whether the index changed,
  /// plus the parsed content when the note's content changed (insert or
  /// digest change — the caller writes FTS/tags/links from it). The
  /// directory chain is ensured first, so a file appearing outside the
  /// app comes in with its parents.
  ///
  /// [expected] is the content already read for this rel (an event batch
  /// reads before it writes); without it a changed note is read once here
  /// (digest + text on the index isolate). Notes only, as everywhere in
  /// the content pipeline; the stored digest is reused when `(size,
  /// mtime)` prove the content unchanged, so our own save of a large note
  /// is not re-read end to end on every watcher event.
  Future<({bool wrote, NoteContent? content})> upsertFile(
    String root,
    String abs,
    String rel,
    DiskProbe probe, {
    NoteContent? expected,
  }) async {
    final parentRel = parentOf(rel);
    final parentId = parentRel.isEmpty
        ? 0
        : await ensureDirChain(root, parentRel);
    final existing = await _dao.find(rel);
    String? sha;
    NoteContent? content;
    if (isNoteFile(p.basename(abs))) {
      final expectedContent = expected;
      if (existing != null &&
          existing.sha256 != null &&
          existing.size == probe.size &&
          existing.modified == toStoredSecond(probe.modified)) {
        sha = existing.sha256;
      } else if (expectedContent != null) {
        sha = expectedContent.sha256;
        content = expectedContent;
      } else {
        final read = await readRelContents(root, <String>[rel]);
        content = read[rel];
        sha = content?.sha256;
      }
    }
    if (existing == null) {
      _log.debug('upsert "$rel": insert (parent "$parentRel")');
      final id = await _db
          .into(_db.notes)
          .insert(
            NotesCompanion.insert(
              path: rel,
              parent: parentId,
              name: p.basename(abs),
              isDir: false,
              size: probe.size,
              modified: probe.modified,
              sha256: Value(sha),
            ),
          );
      await _store.replaceFileStems(id, p.basename(abs));
      return (wrote: true, content: content);
    }
    final changed =
        existing.parent != parentId ||
        existing.name != p.basename(abs) ||
        existing.isDir || // a stale directory row at a file path
        existing.size != probe.size ||
        existing.modified != toStoredSecond(probe.modified) ||
        existing.sha256 != sha;
    if (!changed) {
      _log.debug('upsert "$rel": unchanged');
      return (wrote: false, content: null);
    }
    _log.debug('upsert "$rel": update (parent "$parentRel")');
    await (_db.update(_db.notes)..where((t) => t.path.equals(rel))).write(
      NotesCompanion(
        parent: Value(parentId),
        name: Value(p.basename(abs)),
        isDir: const Value(false),
        size: Value(probe.size),
        modified: Value(probe.modified),
        sha256: Value(sha),
      ),
    );
    return (wrote: true, content: content);
  }
}
