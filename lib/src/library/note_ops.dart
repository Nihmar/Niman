import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/edit_in_file.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

/// Hears what a user operation did to a library-relative path, for the
/// sync queue (docs/records/sync.md, "Queue and triggers"). A hint, not a
/// command: the reconcile decides what to do.
typedef SyncHintSink = void Function(
  String path,
  SyncOpKind kind, {
  String? fromPath,
});

/// One item in `.trash/`, mapped back to its library-relative origin.
final class TrashItem {
  /// Creates a trash listing entry.
  const new({
    required this.name,
    required this.originalPath,
    required this.deletedAt,
  });

  /// Name inside `.trash/` (timestamped when a collision was resolved).
  final String name;

  /// Library-relative path before the delete.
  final String originalPath;

  /// When the item was deleted.
  final DateTime deletedAt;
}

/// Creates / renames / moves / deletes notes and folders on disk, and keeps
/// the index in step through the shared [indexer] (T-M1-05, T-M1-07).
///
/// Deletes move into `.trash/` while the trash toggle is on; with it off
/// they hard-delete. Trash contents are tracked in a manifest file so items
/// can be restored to their original location.
final class NoteOps implements NoteOperations {
  /// Creates the ops for the library at [root].
  ///
  /// [config] is the session's own reader of `.niman/settings.json`, not
  /// a second one: the session resolves the overridable settings through
  /// the same cache these four go through (T-ML-10).
  new({
    required this.root,
    required IndexDatabase db,
    required this.indexer,
    required this.config,
  }) : _dao = NoteDao(db),
       history = NoteHistory(root: root, config: config) {
    writer = NoteWriter(root: root, indexer: indexer, history: history);
    // A note the writer is about to read into the index is left to it by
    // the watcher's scans, which would otherwise read it now as well.
    indexer.awaitedByWriter = writer.awaits;
    config.onWritten = () => _hint(settingsFilePath, SyncOpKind.changed);
  }

  /// The library settings file, library-relative.
  static const settingsFilePath = '.niman/settings.json';

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer; every op funnels its disk change through it.
  final Indexer indexer;

  /// The library's `.niman/settings.json`, shared with the session so
  /// both read one cached copy.
  final LibraryConfigRepo config;

  /// The note-text write path, outside the op chain: saves never wait on
  /// a rename or an empty-trash, only on earlier saves of the same note.
  late final NoteWriter writer;

  /// The library's `.history/`: the ops carry it along when a note is
  /// renamed, moved or deleted for good.
  final NoteHistory history;

  final NoteDao _dao;

  /// Where user operations report the paths they changed; null (the
  /// default, and every library without sync) reports nothing. The sync's
  /// own operations never report: what they write already agrees with the
  /// server.
  SyncHintSink? syncHints;

  /// When each path was last written by a sync operation.
  final Map<String, DateTime> _syncWrites = {};

  /// How long a sync write keeps the file watcher's echo of it out of
  /// the queue.
  static const syncEchoWindow = Duration(seconds: 10);

  void _hint(String path, SyncOpKind kind, {String? fromPath}) =>
      syncHints?.call(path, kind, fromPath: fromPath);

  void _markSyncWrite(String path) {
    final now = DateTime.now();
    _syncWrites
      ..removeWhere((_, at) => now.difference(at) > syncEchoWindow)
      ..[path] = now;
  }

  /// Whether a sync operation wrote, trashed or moved [path] within
  /// [syncEchoWindow]: the file watcher's event for it is an echo.
  bool changedBySync(String path) {
    final at = _syncWrites[path];
    return at != null && DateTime.now().difference(at) <= syncEchoWindow;
  }

  /// The name of the trash manifest inside `.trash/`.
  static const manifestFileName = '.niman-trash.json';

  Future<void> _chain = Future<void>.value();

  /// Runs [fn] serially with every other op.
  Future<T> _synchronized<T>(Future<T> Function() fn) {
    final next = _chain.then((_) => fn());
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// The indexed note/folder at library-relative [path], or null.
  @override
  Future<Note?> find(String path) => _dao.find(path);

  @override
  Future<List<Note>> notesNamed(String query, {int limit = 50}) =>
      _dao.named(query, limit: limit);

  Future<Note> _mustFind(String path) async {
    final row = await _dao.find(path);
    if (row == null) throw StateError('No indexed note at "$path"');
    return row;
  }

  /// The current trash toggle for this library.
  @override
  Future<bool> get trashEnabled async => (await config.config).trashEnabled;

  /// Sets the trash toggle: `true` = deletes move into `.trash/`.
  @override
  Future<void> setTrashEnabled({required bool enabled}) =>
      config.update((c) => c.copyWith(trashEnabled: enabled));

  /// The list-note folder (library-relative).
  @override
  Future<String> get listNoteFolder async =>
      (await config.config).listNoteFolder;

  /// Sets the list-note folder (sanitized; an empty result falls back to
  /// the default).
  @override
  Future<void> setListNoteFolder({required String folder}) =>
      config.update((c) => c.copyWith(listNoteFolder: cleanListFolder(folder)));

  /// The folder holding the note templates (default `Templates`).
  @override
  Future<String> get templateFolder async =>
      (await config.config).templateFolder;

  /// Sets the template folder (sanitized; an empty result falls back to
  /// the default).
  @override
  Future<void> setTemplateFolder({required String folder}) => config.update(
    (c) => c.copyWith(templateFolder: cleanTemplateFolder(folder)),
  );

  /// The folder holding the attachments (default `assets`).
  @override
  Future<String> get attachmentsFolder async =>
      (await config.config).attachmentsFolder;

  /// Sets the attachments folder (sanitized; an empty result falls back
  /// to the default).
  @override
  Future<void> setAttachmentsFolder({required String folder}) => config.update(
    (c) => c.copyWith(attachmentsFolder: cleanAttachmentsFolder(folder)),
  );

  /// The folder where a note annotating a PDF or a book is made (default
  /// `Annotations`, #284).
  @override
  Future<String> get annotationsFolder async =>
      (await config.config).annotationsFolder;

  /// Sets the annotations folder (sanitized; an empty result falls back
  /// to the default).
  @override
  Future<void> setAnnotationsFolder({required String folder}) => config.update(
    (c) => c.copyWith(annotationsFolder: cleanAnnotationsFolder(folder)),
  );

  /// The user-chosen quick note, or null for the default.
  @override
  Future<String?> get quickNotePath async =>
      (await config.config).quickNotePath;

  /// Sets (or clears) the user-chosen quick note.
  @override
  Future<void> setQuickNotePath({required String? path}) => config.update(
    (c) => c.copyWith(quickNotePath: path, clearQuickNotePath: path == null),
  );

  @override
  Future<JournalSettings> get journal async => (await config.config).journal;

  @override
  Future<void> setJournal(JournalSettings settings) =>
      config.update((c) => c.copyWith(journal: settings));

  @override
  Future<List<String>> notePathsUnder(String folder) =>
      _dao.filePathsUnder(folder);

  /// Creates a `<name>.md` note in [parentPath] with [content] as its
  /// initial content, uniquifying the name. Returns the indexed row.
  @override
  Future<Note> createNote({
    required String parentPath,
    required String name,
    String content = '',
  }) {
    return _synchronized(() async {
      final clean = sanitizeName(name, fallback: defaultNoteName);
      final dir = Directory(_abs(parentPath));
      final unique = await uniqueFileName(dir, clean, '.md');
      final file = File(_abs(resolvePath(parentPath, unique)));
      await writeFileAtomically(file, utf8.encode(content));
      _hint(resolvePath(parentPath, unique), SyncOpKind.changed);
      await indexer.applyEvents(root, [file.path]);
      return await _mustFind(resolvePath(parentPath, unique));
    });
  }

  /// The folder at [path], created with its parents if missing.
  ///
  /// No uniquifying: the caller named a folder, not a wish for one.
  @override
  Future<Note> ensureFolder(String path) {
    return _synchronized(() async {
      final clean = cleanFolderPath(path, '');
      if (clean.isEmpty) {
        // The root is not a row, and "make sure the root exists" is not
        // a thing a caller can mean.
        throw ArgumentError('ensureFolder was given no folder: "$path"');
      }
      final dir = Directory(_abs(clean));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
        // Every folder on the way is new too, so the index hears about
        // the whole chain rather than only its last link.
        final segments = clean.split('/');
        final made = <String>[
          for (var i = 1; i <= segments.length; i++)
            _abs(segments.take(i).join('/')),
        ];
        await indexer.applyEvents(root, made);
      }
      return await _mustFind(clean);
    });
  }

  /// Adds [content] to the end of the note at [path], creating it when it
  /// is not there.
  @override
  Future<Note> appendToNote(String path, String content) {
    return _synchronized(() async {
      final file = File(_abs(path));
      final existing = file.existsSync() ? await file.readAsString() : '';
      final joined = existing.isEmpty
          ? content
          : '${_endingInABlankLine(existing)}$content';
      await writeFileAtomically(file, utf8.encode(joined));
      _hint(path, SyncOpKind.changed);
      await indexer.applyEvents(root, [file.path]);
      return await _mustFind(path);
    });
  }

  /// [text] with exactly one blank line at its end, so what follows
  /// starts a paragraph of its own.
  static String _endingInABlankLine(String text) {
    final eol = text.contains('\r\n') ? '\r\n' : '\n';
    final trimmed = text.replaceFirst(RegExp(r'\s+$'), '');
    return '$trimmed$eol$eol';
  }

  /// Creates a folder in [parentPath], uniquifying the name.
  @override
  Future<Note> createFolder({
    required String parentPath,
    required String name,
  }) {
    return _synchronized(() async {
      final clean = sanitizeName(name, fallback: defaultFolderName);
      final dir = Directory(_abs(parentPath));
      final unique = await uniqueFolderName(dir, clean);
      final newDir = Directory(_abs(resolvePath(parentPath, unique)));
      await newDir.create(recursive: true);
      await indexer.applyEvents(root, [newDir.path]);
      return await _mustFind(resolvePath(parentPath, unique));
    });
  }

  /// Renames the note or folder at [path] to [newName].
  ///
  /// Notes are always stored as `<name>.md`; a trailing `.md` in [newName]
  /// is treated as redundant. Names are uniquified against the new parent
  /// (self excluded). Returns the updated row.
  @override
  Future<Note> rename(String path, String newName) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      final parent = parentOf(path);
      final parentDir = Directory(_abs(parent));
      var base = newName;
      if (base.endsWith('.md')) base = base.substring(0, base.length - 3);
      String target;
      if (row.isDir) {
        final clean = sanitizeName(base, fallback: defaultFolderName);
        target = await uniqueFolderName(parentDir, clean, exclude: _abs(path));
      } else {
        final clean = sanitizeName(base, fallback: defaultNoteName);
        target = await uniqueFileName(
          parentDir,
          clean,
          '.md',
          exclude: _abs(path),
        );
      }
      final newRel = resolvePath(parent, target);
      if (newRel == path) return row;
      final oldAbs = _abs(path);
      if (row.isDir) {
        await Directory(oldAbs).rename(_abs(newRel));
      } else {
        await File(oldAbs).rename(_abs(newRel));
      }
      _hint(newRel, SyncOpKind.moved, fromPath: path);
      await history.moved(path, newRel, isDir: row.isDir);
      await _carryReading(path, newRel, isDir: row.isDir);
      await indexer.applyEvents(root, [oldAbs, _abs(newRel)]);
      return await _mustFind(newRel);
    });
  }

  /// Moves the note or folder at [path] into [targetParent], keeping its
  /// name (uniquified in the target). Returns the updated row.
  ///
  /// Throws [ArgumentError] when [targetParent] is [path] itself or inside
  /// it — a folder cannot be renamed onto its own subtree.
  @override
  Future<Note> move(String path, String targetParent) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      if (resolvePath(targetParent, p.basename(path)) == path) return row;
      if (targetParent == path || isUnder(path, targetParent)) {
        throw ArgumentError(
          'Cannot move "$path" into itself or its own subtree',
        );
      }
      final name = p.basename(path);
      final targetDir = Directory(_abs(targetParent));
      String target;
      if (row.isDir) {
        target = await uniqueFolderName(targetDir, name);
      } else {
        final parts = splitFileName(name);
        target = await uniqueFileName(targetDir, parts.base, parts.ext);
      }
      final newRel = resolvePath(targetParent, target);
      final oldAbs = _abs(path);
      if (row.isDir) {
        await Directory(oldAbs).rename(_abs(newRel));
      } else {
        await File(oldAbs).rename(_abs(newRel));
      }
      _hint(newRel, SyncOpKind.moved, fromPath: path);
      await history.moved(path, newRel, isDir: row.isDir);
      await _carryReading(path, newRel, isDir: row.isDir);
      await indexer.applyEvents(root, [oldAbs, _abs(newRel)]);
      return await _mustFind(newRel);
    });
  }

  /// Carries the reading positions of what moved from [from] to [to]
  /// (#281): a book or a PDF, or a folder that may hold some. A note
  /// keeps none, and costs no read of the file.
  Future<void> _carryReading(String from, String to, {required bool isDir}) {
    if (!isDir && isMarkdownNote(from)) return Future<void>.value();
    return ReadingPositions(root).moved(from, to);
  }

  /// The text of the note at [path], decoded leniently (a note with a
  /// broken byte is still a note) and without its BOM.
  @override
  Future<String> readNote(String path) async {
    await _mustFind(path);
    final bytes = await File(_abs(path)).readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  }

  /// Pins or unpins the note at [path] by editing its frontmatter.
  ///
  /// Unpinning removes the key rather than writing `pinned: false`: the
  /// file goes back to what it looked like before, instead of collecting
  /// a line that says nothing.
  ///
  /// The index records the new frontmatter at once, from the head the edit
  /// wrote ([Indexer.applyFrontmatter]); the note itself is read back later,
  /// as a save's is ([NoteWriter.reindexWhenQuiet]). Read back before the
  /// pin was answered, the 247 MB stress note kept the pin on screen for
  /// the 15 to 34 s a phone takes to read it — or for good, when the app
  /// was closed first (device log, 2026-09-24).
  @override
  Future<Note> setPinned(String path, {required bool pinned}) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      // The pin lives in the note's frontmatter, so only a note can carry
      // one. Pinning a `todo.txt` wrote a YAML block into a file that has
      // no such thing, and every todo.txt reader — this app's included —
      // then read the three lines as tasks. Unpinning stays allowed
      // whatever the file is, so a block already written can be taken
      // back out.
      if (row.isDir || (pinned && !isMarkdownNote(row.name))) {
        throw ArgumentError('Only Markdown notes can be pinned, not "$path"');
      }
      final file = File(_abs(path));
      // The head of the note, not the note: off the UI isolate, the rest
      // of the file copied behind the edited frontmatter as it is.
      final head = await editFrontmatterKeyOnIsolate(
        file.path,
        'pinned',
        pinned ? 'true' : null,
      );
      if (head == null) return row;
      _hint(path, SyncOpKind.changed);
      // Scheduled first: from here the watcher's report of this very write
      // leaves the note to the writer, and the pin below may wait behind a
      // scan already running.
      writer.reindexWhenQuiet(path, bytes: row.size);
      await indexer.applyFrontmatter(path, parseFrontmatter(head));
      return await _mustFind(path);
    });
  }

  @override
  Future<void> saveNote(String path, String content, {int? editSession}) async {
    await writer.save(path, content, editSession: editSession);
    // After the write: a sync that read the hint before the text landed
    // could otherwise upload the old text and drop the hint.
    _hint(path, SyncOpKind.changed);
  }

  @override
  Future<bool> tidyNote(String path) async {
    final changed = await writer.tidy(path);
    if (changed) _hint(path, SyncOpKind.changed);
    return changed;
  }

  @override
  Future<void> saveNoteStream(
    String path,
    NoteContentProducer content, {
    int? editSession,
    NoteReferences? references,
  }) async {
    await writer.save(
      path,
      content,
      editSession: editSession,
      references: references,
    );
    _hint(path, SyncOpKind.changed);
  }

  @override
  Future<HistoryManifest> noteHistory(String path) => history.manifestOf(path);

  @override
  Future<String> readNoteVersion(String path, int number) =>
      history.readVersion(path, number);

  /// Keeps the current text as a [HistoryReason.restore] version, then
  /// writes version [number] back through the writer — so the restore is
  /// itself undoable, and the index and sync see an ordinary save.
  @override
  Future<void> restoreNoteVersion(String path, int number) async {
    final text = await history.readVersion(path, number);
    await restoreNoteText(path, text);
  }

  /// Keeps the current text as a [HistoryReason.restore] version, then
  /// writes [text] through the writer — the part of a restore that does
  /// not care where the text came from.
  @override
  Future<void> restoreNoteText(String path, String text) async {
    await writer.save(path, text, forced: HistoryReason.restore);
    _hint(path, SyncOpKind.changed);
  }

  /// Deletes [path]: into `.trash/` when the trash toggle is on, hard
  /// delete otherwise.
  @override
  Future<void> delete(String path) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      final oldAbs = _abs(path);
      final trash = await trashEnabled;
      String? trashAbs;
      if (trash) {
        trashAbs = await _moveIntoTrash(path, isDir: row.isDir);
      } else {
        if (row.isDir) {
          await Directory(oldAbs).delete(recursive: true);
        } else {
          await File(oldAbs).delete();
        }
        // No trash to come back from: the history goes with the note.
        await history.deleted(path, isDir: row.isDir);
      }
      _hint(path, SyncOpKind.deleted);
      final events = <String>[oldAbs];
      if (trashAbs != null) events.add(trashAbs);
      await indexer.applyEvents(root, events);
    });
  }

  /// Moves [path] into `.trash/` under a collision-safe name and records
  /// it in the manifest; returns the absolute trash path. The history
  /// stays at [path] (a restore brings it back).
  Future<String> _moveIntoTrash(String path, {required bool isDir}) async {
    final trashDir = Directory(_abs('.trash'));
    if (!trashDir.existsSync()) {
      await trashDir.create(recursive: true);
    }
    final name = p.basename(path);
    String target;
    if (isDir) {
      target = await trashDirName(trashDir, name);
    } else {
      final parts = splitFileName(name);
      target = await trashFileName(trashDir, parts.base, parts.ext);
    }
    final trashAbs = _abs('.trash/$target');
    if (isDir) {
      await Directory(_abs(path)).rename(trashAbs);
    } else {
      await File(_abs(path)).rename(trashAbs);
    }
    await _manifestAdd(trashDir, target, path);
    return trashAbs;
  }

  // -- sync (docs/records/sync.md) -------------------------------------------

  /// Whether [path] keeps history: the text notes the editor saves.
  static bool keepsHistory(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.md') || lower.endsWith('.txt');
  }

  /// Swaps the verified sync download at [tempAbs] in for the file at
  /// [path] (new or existing): a note's replaced text becomes a `sync`
  /// version first, and it runs in the note's save order so an editor
  /// save never interleaves. Replacing `.niman/settings.json` drops the
  /// cached settings.
  Future<void> syncReplace(String path, String tempAbs) async {
    _markSyncWrite(path);
    await writer.replaceFromFile(
      path,
      tempAbs,
      forced: keepsHistory(path) ? HistoryReason.sync : null,
    );
    if (path == settingsFilePath) await config.reload();
  }

  /// Writes [text] at [path] because the sync merged both sides of it:
  /// the text being replaced becomes a `sync` history version, and the
  /// write goes through the note's save order like any other.
  Future<void> syncMerge(String path, String text) async {
    _markSyncWrite(path);
    await writer.save(path, text, forced: HistoryReason.sync);
  }

  /// Moves [path] into `.trash/` because the remote deleted it — always
  /// the trash, whatever the trash toggle: a deletion that arrives from
  /// another device must stay recoverable here.
  Future<void> syncTrash(String path) {
    return _synchronized(() async {
      final abs = _abs(path);
      final isDir = Directory(abs).existsSync();
      if (!isDir && !File(abs).existsSync()) return;
      _markSyncWrite(path);
      final trashAbs = await _moveIntoTrash(path, isDir: isDir);
      await indexer.applyEvents(root, [abs, trashAbs]);
    });
  }

  /// Renames the file at [from] to [to] (any folder, created on demand)
  /// because the remote renamed it; the history follows. Throws
  /// [StateError] when [from] is gone or [to] is taken.
  Future<void> syncMove(String from, String to) {
    return _synchronized(() async {
      final fromAbs = _abs(from);
      final toAbs = _abs(to);
      if (!File(fromAbs).existsSync()) {
        throw FileSystemException('Nothing to move', fromAbs);
      }
      if (File(toAbs).existsSync() || Directory(toAbs).existsSync()) {
        throw FileSystemException('Already taken', toAbs);
      }
      await Directory(p.dirname(toAbs)).create(recursive: true);
      _markSyncWrite(from);
      _markSyncWrite(to);
      await File(fromAbs).rename(toAbs);
      await history.moved(from, to, isDir: false);
      await indexer.applyEvents(root, [fromAbs, toAbs]);
    });
  }

  /// Pins the sync base of [path] to the version holding content [sha];
  /// null for files without history, or when the content is gone.
  Future<int?> pinSyncBase(String path, String sha) async {
    if (!keepsHistory(path)) return null;
    return await history.pinSyncBase(path, sha);
  }

  /// Lists the managed trash items (manifest-backed), in deletion order.
  @override
  Future<List<TrashItem>> trashItems() {
    return _synchronized(() async {
      final manifest = await _readManifest();
      return [
        for (final entry in manifest.entries)
          if (_existsInTrash(entry.key))
            TrashItem(
              name: entry.key,
              originalPath: entry.value.originalPath,
              deletedAt: entry.value.deletedAt,
            ),
      ];
    });
  }

  /// Restores the trash item [trashName] to its original parent when that
  /// folder still exists, otherwise to the library root.
  ///
  /// The item comes back under its original name (uniquified only on a
  /// real collision), which is taken from the manifest's `originalPath` —
  /// never from the name inside `.trash/`, which carries a collision
  /// timestamp and would survive the restore.
  @override
  Future<Note> restoreTrash(String trashName) {
    return _synchronized(() async {
      final manifest = await _readManifest();
      final entry = manifest[trashName];
      if (entry == null) {
        throw StateError('Not a managed trash item: "$trashName"');
      }
      final trashAbs = _abs('.trash/$trashName');
      final isDir = Directory(trashAbs).existsSync();
      final originalName = p.basename(entry.originalPath);
      final originalParent = parentOf(entry.originalPath);
      final originalDir = Directory(_abs(originalParent));
      final restoreParent = originalDir.existsSync() ? originalParent : '';
      final parentDirObj = Directory(_abs(restoreParent));
      String target;
      if (isDir) {
        target = await uniqueFolderName(parentDirObj, originalName);
      } else {
        final parts = splitFileName(originalName);
        target = await uniqueFileName(parentDirObj, parts.base, parts.ext);
      }
      final newRel = resolvePath(restoreParent, target);
      if (isDir) {
        await Directory(trashAbs).rename(_abs(newRel));
      } else {
        await File(trashAbs).rename(_abs(newRel));
      }
      manifest.remove(trashName);
      await _writeManifest(manifest);
      _hint(newRel, SyncOpKind.changed);
      // The history stayed at the original path while the item was in the
      // trash; it follows only when the item came back somewhere else.
      await history.moved(entry.originalPath, newRel, isDir: isDir);
      await indexer.applyEvents(root, [trashAbs, _abs(newRel)]);
      return await _mustFind(newRel);
    });
  }

  /// Permanently deletes the trash item [trashName] (no restore possible).
  @override
  Future<void> deleteTrashPermanently(String trashName) {
    return _synchronized(() async {
      final manifest = await _readManifest();
      final entry = manifest.remove(trashName);
      if (entry == null) {
        throw StateError('Not a managed trash item: "$trashName"');
      }
      final trashAbs = _abs('.trash/$trashName');
      final isDir = Directory(trashAbs).existsSync();
      if (isDir) {
        await Directory(trashAbs).delete(recursive: true);
      } else if (File(trashAbs).existsSync()) {
        await File(trashAbs).delete();
      }
      await _writeManifest(manifest);
      await _dropTrashedHistory(entry.originalPath, isDir: isDir);
    });
  }

  /// Permanently deletes every managed trash item.
  @override
  /// Deletes every entry in `.trash/`, not just the items Niman put
  /// there: the trash screen promises to empty the folder, and that
  /// includes anything a user moved into it by hand. Ends with an empty
  /// manifest.
  Future<void> emptyTrash() {
    return _synchronized(() async {
      final trashDir = Directory(_abs('.trash'));
      // Read before the items go: the manifest is what knows where each
      // one came from, and so whose history is now orphaned.
      final origins = [
        for (final entry in (await _readManifest()).entries)
          (
            entry.value.originalPath,
            Directory(_abs('.trash/${entry.key}')).existsSync(),
          ),
      ];
      if (trashDir.existsSync()) {
        for (final entry in trashDir.listSync()) {
          if (entry is Directory) {
            await entry.delete(recursive: true);
          } else {
            await entry.delete();
          }
        }
      }
      await _writeManifest(<String, _ManifestEntry>{});
      for (final (originalPath, isDir) in origins) {
        await _dropTrashedHistory(originalPath, isDir: isDir);
      }
    });
  }

  /// Removes the history a permanently deleted trash item left at
  /// [originalPath] — unless a note lives there again, whose history it
  /// now is.
  Future<void> _dropTrashedHistory(
    String originalPath, {
    required bool isDir,
  }) async {
    final abs = _abs(originalPath);
    if (File(abs).existsSync() || Directory(abs).existsSync()) return;
    await history.deleted(originalPath, isDir: isDir);
  }

  bool _existsInTrash(String name) {
    final abs = _abs('.trash/$name');
    return Directory(abs).existsSync() || File(abs).existsSync();
  }

  // -- manifest --------------------------------------------------------

  /// Reads the trash manifest, surviving a torn or partially corrupt file:
  /// a whole file that is not a JSON object yields an empty manifest, and
  /// individual entries that do not decode are skipped, so one bad entry
  /// can never take the trash screen down.
  Future<Map<String, _ManifestEntry>> _readManifest() async {
    final file = File(_abs('.trash/$manifestFileName'));
    if (!file.existsSync()) return <String, _ManifestEntry>{};
    final raw = file.readAsStringSync();
    if (raw.trim().isEmpty) return <String, _ManifestEntry>{};
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return <String, _ManifestEntry>{};
    }
    if (decoded is! Map) return <String, _ManifestEntry>{};
    final manifest = <String, _ManifestEntry>{};
    for (final entry in decoded.entries) {
      final name = entry.key;
      if (name is! String) continue;
      final parsed = _parseManifestEntry(entry.value);
      if (parsed != null) manifest[name] = parsed;
    }
    return manifest;
  }

  static _ManifestEntry? _parseManifestEntry(Object? json) {
    if (json is! Map) return null;
    final originalPath = json['originalPath'];
    final deletedAt = json['deletedAt'];
    if (originalPath is! String || deletedAt is! int) return null;
    return _ManifestEntry(
      originalPath: originalPath,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(deletedAt),
    );
  }

  /// Writes the manifest, dropping entries whose item is no longer on disk
  /// so the file converges with `.trash/` even when something removed an
  /// item without going through the ops.
  Future<void> _writeManifest(Map<String, _ManifestEntry> manifest) async {
    final trashDir = Directory(_abs('.trash'));
    if (!trashDir.existsSync()) await trashDir.create(recursive: true);
    final kept = {
      for (final entry in manifest.entries)
        if (_existsInTrash(entry.key)) entry.key: entry.value,
    };
    final payload = jsonEncode({
      for (final entry in kept.entries) entry.key: entry.value.toJson(),
    });
    await writeFileAtomically(
      File(_abs('.trash/$manifestFileName')),
      utf8.encode(payload),
    );
  }

  Future<void> _manifestAdd(
    Directory trashDir,
    String name,
    String originalPath,
  ) async {
    final manifest = await _readManifest();
    manifest[name] = _ManifestEntry(
      originalPath: originalPath,
      deletedAt: DateTime.now(),
    );
    await _writeManifest(manifest);
  }
}

/// One manifest entry: where a trash item came from.
final class _ManifestEntry {
  /// Creates a manifest entry.
  const new({required this.originalPath, required this.deletedAt});

  /// Library-relative path before the delete.
  final String originalPath;

  /// When the item was deleted.
  final DateTime deletedAt;

  /// Serializes the entry for the manifest file.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'originalPath': originalPath,
    'deletedAt': deletedAt.millisecondsSinceEpoch,
  };
}
