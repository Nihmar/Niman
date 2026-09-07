import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/frontmatter/parser.dart';
import 'package:copist/src/links/parser.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:crypto/crypto.dart';
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

/// The on-disk state of one path, as probed by [probePaths].
final class DiskProbe {
  /// Creates a probe result.
  const DiskProbe({
    required this.exists,
    required this.isDir,
    required this.modified,
    this.size = 0,
  });

  /// Whether the path exists (file or directory).
  final bool exists;

  /// Whether it is a directory.
  final bool isDir;

  /// The byte size (0 unless a file).
  final int size;

  /// The last-modification time.
  final DateTime modified;
}

/// Probes [paths] (exists? directory? size? mtime?) — top-level so it can
/// run on a background isolate via [Isolate.run]: on Android every stat is
/// a FUSE round trip, and a cold FUSE takes seconds, so the watcher-event
/// path must not stat on the UI isolate (a save behind an open editor is
/// what froze the app, M2a on-device round 2).
List<DiskProbe> probePaths(List<String> paths) => [
  for (final path in paths) _probePath(path),
];

DiskProbe _probePath(String path) {
  final st = File(path).statSync();
  final type = st.type;
  // A symlink probes through to its target, as the old existsSync calls did.
  final isDir =
      type == FileSystemEntityType.directory ||
      (type == FileSystemEntityType.link && Directory(path).existsSync());
  return DiskProbe(
    exists: type != FileSystemEntityType.notFound,
    isDir: isDir,
    size: type == FileSystemEntityType.file ? st.size : 0,
    modified: st.modified,
  );
}

/// One note's content after a read on the index isolate: the digest, the
/// full text (the FTS body copy) and everything the index derives from it
/// (title, tags, aliases, links) — parsed off the UI isolate and off the
/// main flow, so a scan costs one read per changed note and no more.
final class NoteContent {
  /// Creates a parsed note content.
  const NoteContent({
    required this.rel,
    required this.sha256,
    required this.text,
    required this.title,
    required this.frontmatterTags,
    required this.inlineTags,
    required this.aliases,
    required this.links,
  });

  /// Library-relative note path.
  final String rel;

  /// Content sha256 (hex).
  final String sha256;

  /// The full note text (FTS `body` copy).
  final String text;

  /// The search title: frontmatter `title`, else the filename without
  /// `.md` (case preserved).
  final String title;

  /// Normalized tags from frontmatter `tags:`.
  final List<String> frontmatterTags;

  /// Normalized inline `#tags`.
  final List<String> inlineTags;

  /// Raw frontmatter `aliases:` values.
  final List<String> aliases;

  /// The note's links, in document order.
  final List<ParsedLink> links;
}

/// Reads and parses the notes at [rels] (library-relative, under [root]) —
/// one file read per note returning digest **and** text, with frontmatter,
/// inline tags and links extracted on this (index) isolate.
///
/// Top-level for [Isolate.run]; batched by the caller (a few hundred per
/// call). A note that cannot be read (deleted or replaced mid-scan) is left
/// out; the next scan picks it up.
Future<List<NoteContent>> readNoteContents(
  String root,
  List<String> rels,
) async {
  final out = <NoteContent>[];
  for (final rel in rels) {
    try {
      final bytes = await File(p.join(root, rel)).readAsBytes();
      var text = utf8.decode(bytes, allowMalformed: true);
      // A UTF-8 BOM is content for FTS but noise for matching the editor.
      if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
        text = text.substring(1);
      }
      final sha = sha256.convert(bytes).toString();
      out.add(_extractContent(rel, sha, text));
    } on FileSystemException {
      continue;
    }
  }
  return out;
}

/// Parses [text] into a [NoteContent] (pure: frontmatter, tags, links).
NoteContent _extractContent(String rel, String sha, String text) {
  final doc = HighlightDocument.fromText(text);
  final fm = parseFrontmatter(text);
  return NoteContent(
    rel: rel,
    sha256: sha,
    text: text,
    title: fm?.title ?? _titleFromName(rel),
    frontmatterTags: fm?.tags ?? const [],
    inlineTags: inlineTagsOf(doc),
    aliases: fm?.aliases ?? const [],
    links: linksInDocument(doc),
  );
}

/// The filename without the `.md` extension, case preserved.
String _titleFromName(String rel) {
  final name = p.basename(rel);
  return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
}

/// Builds and maintains the notes index so it mirrors the library on disk.
///
/// Every mutation is serialized through an internal mutex, so
/// app-originated operations and disk-originated events converge identically
/// (T-M1-07).
final class Indexer {
  /// Creates the indexer over the given [CopistDatabase].
  Indexer(this._db)
    : _dao = NoteDao(_db),
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
      // The content index can still be incomplete (a v7-era database
      // predates the M3 tables): in that case the no-write exit is skipped
      // and the content pass rebuilds FTS/tags/links for every note.
      if (!_treeChanged(old, entries)) {
        if (await _contentIndexComplete()) {
          _log.info('fullScan: index already mirrors disk, no write');
          return;
        }
        _log.info('fullScan: content index incomplete — building content rows');
      }
      _log.info('fullScan: tree changed, applying diff');
      final read = await _readContents(root, entries, old);
      var wrote = false;
      var pairedRels = const <String>{};
      await _db.transaction(() async {
        final result = await _applyDiff(
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
      await _applyContent(read.contents, paired: pairedRels);
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
        final rel = _safeRel(abs, root);
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
      final probes = await _probeAll(absList);
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
      final contents = await _readBatchContents(root, live);

      // Pair renames with unchanged content: the old row keeps its id (and
      // with it its FTS/tags/links rows) and is repointed at the new path.
      final paired = await _pairRenames(root, live, gone, contents);
      final pairedOld = <String>{for (final o in paired.values) o};
      for (final pair in paired.entries) {
        final oldRow = await _dao.find(pair.value);
        if (oldRow == null) continue;
        final probe = live[pair.key]!;
        final newParentRel = parentOf(pair.key);
        final parentId = newParentRel.isEmpty
            ? 0
            : await _ensureDirChain(root, newParentRel);
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
        await _replaceStems(oldRow.id, p.basename(pair.key));
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
          wrote |= await _syncDirSubtree(root, p.join(root, entry.key));
        } else {
          _log.debug('applyEvents: "${entry.key}" -> upsert file');
          final result = await _upsertFile(
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
        await _applyContent({c.rel: c}, paired: paired.keys.toSet());
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
    // One background-isolate probe (a FUSE stat on Android is a round trip
    // that can take seconds cold, so it must not run on the UI isolate).
    final probe = await Isolate.run(() => probePaths(<String>[abs]).single);
    if (probe.isDir) {
      _log.debug('$tag: "$abs" -> resync dir "$rel"');
      return _syncDirSubtree(root, abs);
    }
    if (probe.exists) {
      _log.debug('$tag: "$abs" -> upsert file "$rel"');
      final result = await _upsertFile(root, abs, rel, probe);
      if (result.content != null) {
        await _applyContent({rel: result.content!}, paired: const {});
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
  /// [_readContents] only ever reuses a stored one when `(size, mtime)`
  /// already proves the content unchanged, so a digest can never be the
  /// deciding difference — and comparing it would force a rewrite of every
  /// index written by an older build.
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
  _readContents(
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
    // Notes without a content row (the v7-era index or a half-rebuilt db)
    // are read once here, so the content pass can build their rows — even
    // when their (size, mtime) did not change.
    if (!await _contentIndexComplete()) {
      _log.info('contents: content index incomplete, rebuilding missing rows');
      for (final rel in await _missingFtsPaths()) {
        if (!todo.contains(rel)) todo.add(rel);
      }
    }
    final contents = await _readRelContents(root, todo);
    for (final c in contents.values) {
      shas[c.rel] = c.sha256;
    }
    return (contents: contents, shas: shas);
  }

  /// Whether every md note has a content row (`notes_fts.rowid`
  /// = `notes.id`, same for tags/links — they are written together).
  ///
  /// Count-based; the join runs only when the counts differ. The mismatch
  /// is the migration case: a v7-era index has the tree but no content
  /// rows, and an unchanged rescan must still build them once.
  Future<bool> _contentIndexComplete() async {
    final rows = await _db
        .customSelect(
          'SELECT (SELECT count(*) FROM notes WHERE is_dir = 0 '
          "AND lower(substr(name, -3)) = '.md') AS notes, "
          '(SELECT count(*) FROM notes_fts) AS fts, '
          '(SELECT count(*) FROM notes WHERE is_dir = 0) AS files, '
          "(SELECT count(*) FROM note_stems WHERE source = 'file') AS stems",
        )
        .getSingle();
    return rows.read<int>('notes') == rows.read<int>('fts') &&
        rows.read<int>('files') == rows.read<int>('stems');
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
          await _replaceStems(
            rows[j].read<int>('id'),
            rows[j].read<String>('name'),
          );
        }
      });
      if (end < rows.length) await Future<void>.delayed(Duration.zero);
    }
  }

  /// The paths of md notes that have no `notes_fts` row.
  Future<List<String>> _missingFtsPaths() async {
    final rows = await _db
        .customSelect(
          'SELECT notes.path FROM notes LEFT JOIN notes_fts '
          'ON notes.id = notes_fts.rowid WHERE notes_fts.rowid IS NULL '
          "AND notes.is_dir = 0 AND lower(substr(notes.name, -3)) = '.md'",
        )
        .get();
    return [for (final r in rows) r.read<String>('path')];
  }

  /// Probes a batch of absolute paths on a background isolate.
  ///
  /// Kept as its own method (no instance members referenced) so the
  /// [Isolate.run] closure captures only the sendable path list — the
  /// indexer itself holds an unsendable future chain.
  Future<List<DiskProbe>> _probeAll(List<String> absPaths) {
    final paths = List<String>.of(absPaths);
    return Isolate.run(() => probePaths(paths));
  }

  /// Reads [rels] in batches of [_contentBatch] on the index isolate.
  Future<Map<String, NoteContent>> _readRelContents(
    String root,
    List<String> rels,
  ) async {
    if (rels.isEmpty) return const {};
    final contents = <String, NoteContent>{};
    _log.debug('contents: reading ${rels.length} note(s)');
    for (var i = 0; i < rels.length; i += _contentBatch) {
      final end = i + _contentBatch < rels.length
          ? i + _contentBatch
          : rels.length;
      final read = await Isolate.run(
        () => readNoteContents(root, rels.sublist(i, end)),
      );
      for (final c in read) {
        contents[c.rel] = c;
      }
    }
    return contents;
  }

  /// Reads the notes of an event batch that need content: new note files
  /// and existing notes whose `(size, mtime)` no longer proves the content
  /// unchanged — one read per note, parsed off the UI isolate.
  Future<Map<String, NoteContent>> _readBatchContents(
    String root,
    Map<String, DiskProbe> live,
  ) async {
    final todo = <String>[];
    for (final entry in live.entries) {
      if (entry.value.isDir || !_isNote(p.basename(entry.key))) continue;
      final row = await _dao.find(entry.key);
      if (row == null ||
          row.size != entry.value.size ||
          row.modified != toStoredSecond(entry.value.modified)) {
        todo.add(entry.key);
      }
    }
    return _readRelContents(root, todo);
  }

  /// Pairs newly-appeared note files with vanished ones from the same
  /// batch when the content is provably unchanged: same size, same mtime
  /// (a rename keeps both) and — verified by the read — the same digest.
  ///
  /// Returns `newRel → oldRel`; pairs are one-to-one and unique, so a
  /// scan that moved two files onto each other's paths pairs nothing.
  Future<Map<String, String>> _pairRenames(
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
        _log.debug(
          'pair: "$candidate" -> "${entry.key}" (content unchanged)',
        );
      }
    }
    return paired;
  }

  /// How many changed notes are read per isolate call (T-M3-03: a few
  /// hundred).
  static const _contentBatch = 200;

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
  Future<void> _replaceStems(
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

  /// Whether [name] is a note file, the only kind the index digests.
  static bool _isNote(String name) => p.extension(name).toLowerCase() == '.md';

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
  Future<({bool wrote, Set<String> pairedRels})> _applyDiff({
    required List<DiskEntry> entries,
    required Map<String, Note> old,
    required Map<String, String> shas,
    required Map<String, NoteContent> contents,
    String scope = '',
    int scopeParentId = 0,
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
      final pairOld = _pairCandidate(
        e,
        shas[e.rel],
        old,
        gone,
        pairedOld,
      );
      if (pairOld != null) {
        // Rename with unchanged content: the old row keeps its id.
        final oldRow = old[pairOld]!;
        await (_db.update(
          _db.notes,
        )..where((t) => t.id.equals(oldRow.id))).write(
          NotesCompanion(
            path: Value(e.rel),
            parent: Value(parentId),
            name: Value(e.name),
            isDir: const Value(false),
            size: Value(e.size),
            modified: Value(e.modified),
            sha256: Value(shas[e.rel]),
          ),
        );
        newIds[e.rel] = oldRow.id;
        pairedRels.add(e.rel);
        pairedOld.add(pairOld);
        await _replaceStems(oldRow.id, e.name);
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
      await _replaceStems(id, e.name, isDir: e.isDir);
      wrote = true;
    }
    for (final rel in gone) {
      if (gone.contains(parentOf(rel))) continue;
      if (pairedOld.contains(rel)) continue;
      await _dao.deleteSubtree(rel);
      wrote = true;
    }
    return (wrote: wrote, pairedRels: pairedRels);
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
      for (final row
          in rel.isEmpty ? await _dao.allRows() : await _dao.subtreeRows(rel))
        row.path: row,
    };
    final read = await _readContents(root, entries, old);
    var wrote = false;
    var pairedRels = const <String>{};
    await _db.transaction(() async {
      // The scope root's parent lives outside the walk, so it is resolved
      // from the index — the directory chain is ensured when the rows are
      // still missing — instead of from the batch.
      final scopeParentId = rel.isEmpty
          ? 0
          : await _ensureDirChain(root, parentOf(rel));
      final result = await _applyDiff(
        entries: entries,
        old: old,
        shas: read.shas,
        contents: read.contents,
        scope: rel,
        scopeParentId: scopeParentId,
      );
      wrote = result.wrote;
      pairedRels = result.pairedRels;
    });
    await _applyContent(read.contents, paired: pairedRels);
    return wrote;
  }

  /// Ensures directory rows exist for every ancestor of [dirRel] (and
  /// [dirRel] itself), returning the id of the [dirRel] row.
  Future<int> _ensureDirChain(String root, String dirRel) async {
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
        : await Isolate.run(
            () => probePaths(
              [for (final m in missing) p.join(root, m)],
            ),
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
  Future<({bool wrote, NoteContent? content})> _upsertFile(
    String root,
    String abs,
    String rel,
    DiskProbe probe, {
    NoteContent? expected,
  }) async {
    final parentRel = parentOf(rel);
    final parentId = parentRel.isEmpty
        ? 0
        : await _ensureDirChain(root, parentRel);
    final existing = await _dao.find(rel);
    String? sha;
    NoteContent? content;
    if (_isNote(p.basename(abs))) {
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
        final read = await _readRelContents(root, <String>[rel]);
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
      await _replaceStems(id, p.basename(abs));
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

  /// Writes the content-derived rows — `notes_fts` (title + body copy),
  /// `note_tags` (+ the `tags` table) and the resolved `note_links` edges
  /// — for changed notes. Runs after the notes rows of the batch are
  /// written, so links pointing at notes indexed later in the same walk
  /// resolve; [paired] rels keep their existing rows (their content did
  /// not change — the rename only moved the path).
  Future<void> _applyContent(
    Map<String, NoteContent> contents, {
    required Set<String> paired,
  }) async {
    final items = <(Note, NoteContent)>[
      for (final c in contents.values)
        if (!paired.contains(c.rel))
          if (await _dao.find(c.rel) case final Note row) (row, c),
    ];
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
    await _repairMissingFileStems();
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
    await _replaceStems(row.id, row.name);
    await _writeAliasStems(row.id, c);
    await _writeTags(row.id, c);
    await _writeLinks(row.id, c, resolved);
  }

  /// Rewrites the `note_stems` alias rows (source `alias`) of note
  /// [noteId] to match [c]'s frontmatter aliases — the same index the
  /// resolver reads, so `[[alias]]` resolves by alias from M3 on.
  Future<void> _writeAliasStems(int noteId, NoteContent c) async {
    await (_db.delete(_db.noteStems)..where(
          (s) => s.noteId.equals(noteId) & s.source.equals('alias'),
        ))
        .go();
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
  /// are skipped.
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
