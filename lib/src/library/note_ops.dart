import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/frontmatter/edit_in_file.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_relocation.dart';
import 'package:niman/src/library/note_sync_writes.dart';
import 'package:niman/src/library/note_trash.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/library/note_op_seams.dart' show SyncHintSink;
export 'package:niman/src/library/note_trash.dart' show TrashItem;

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
    this.carryOutside,
  }) : _dao = NoteDao(db),
       history = NoteHistory(root: root, config: config) {
    writer = NoteWriter(root: root, indexer: indexer, history: history);
    // A note the writer is about to read into the index is left to it by
    // the watcher's scans, which would otherwise read it now as well.
    indexer.awaitedByWriter = writer.awaits;
    config.onWritten = () => _hint(settingsFilePath, SyncOpKind.changed);
  }

  /// The library settings file, library-relative.
  static const String settingsFilePath = NoteSyncWrites.settingsFilePath;

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

  /// The library's `.trash/` and its manifest.
  late final NoteTrash _trash = NoteTrash(
    root: root,
    indexer: indexer,
    history: history,
    config: config,
    serialize: _synchronized,
    hint: _hint,
    find: _mustFind,
  );

  /// Moves notes and folders and carries what named them along.
  late final NoteRelocator _relocator = NoteRelocator(
    root: root,
    dao: _dao,
    indexer: indexer,
    history: history,
    config: config,
    writer: writer,
    hint: _hint,
    find: _mustFind,
    readNote: readNote,
    carryOutside: carryOutside,
  );

  /// What else, outside the library's own files, names a note by its path
  /// and has to follow a rename or a move (#506): the home-screen note
  /// widgets, kept in the app's database rather than the library's. Null
  /// (the default, and every test) carries nothing further.
  final Future<void> Function(String from, String to, {required bool isDir})?
  carryOutside;

  /// Where user operations report the paths they changed; null (the
  /// default, and every library without sync) reports nothing. The sync's
  /// own operations never report: what they write already agrees with the
  /// server.
  SyncHintSink? syncHints;

  /// How long a sync write keeps the file watcher's echo of it out of
  /// the queue.
  static const Duration syncEchoWindow = NoteSyncWrites.echoWindow;

  /// The writes the sync makes, and the echo window they keep.
  late final NoteSyncWrites _syncWrites = NoteSyncWrites(
    root: root,
    indexer: indexer,
    history: history,
    config: config,
    writer: writer,
    serialize: _synchronized,
    moveIntoTrash: _trash.moveIntoTrash,
  );

  void _hint(String path, SyncOpKind kind, {String? fromPath}) =>
      syncHints?.call(path, kind, fromPath: fromPath);

  /// Whether a sync operation wrote, trashed or moved [path] within
  /// [syncEchoWindow]: the file watcher's event for it is an echo.
  bool changedBySync(String path) => _syncWrites.changedBySync(path);

  /// The name of the trash manifest inside `.trash/`.
  static const String manifestFileName = NoteTrash.manifestFileName;

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

  @override
  Future<List<Note>> recentlyModified({
    int limit = 8,
    String excludeFolder = '',
  }) => _dao.recentlyModified(limit: limit, excludeFolder: excludeFolder);

  @override
  Future<Note?> randomNote({String excludeFolder = ''}) =>
      _dao.randomNote(excludeFolder: excludeFolder);

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

  /// The folder a captured web page or quote goes in as a new note
  /// (default `Clippings`).
  @override
  Future<String> get captureFolder async => (await config.config).captureFolder;

  /// Sets the capture folder (sanitized; an empty result falls back to
  /// the default).
  @override
  Future<void> setCaptureFolder({required String folder}) => config.update(
    (c) => c.copyWith(captureFolder: cleanCaptureFolder(folder)),
  );

  /// The colour a passage is highlighted in, the one last chosen (#626).
  @override
  Future<String> get highlightColour async =>
      (await config.config).highlightColour;

  /// Keeps [colour] as the one to highlight in.
  @override
  Future<void> setHighlightColour(String colour) =>
      config.update((c) => c.copyWith(highlightColour: colour));

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
  Future<({NavigationLayout? library, NavigationLayout? device})>
  get navigation async {
    final c = await config.config;
    return (library: c.navigation, device: c.deviceNavigation);
  }

  @override
  Future<void> setNavigation(
    NavigationLayout layout, {
    required bool onDevice,
  }) => config.update(
    (c) => onDevice
        ? c.copyWith(deviceNavigation: layout)
        : c.copyWith(navigation: layout, clearDeviceNavigation: true),
  );

  @override
  Future<({HomeLayout? library, HomeLayout? device})> get home async {
    final device = (await config.config).deviceHome;
    return (
      library: await HomeFile(root).read(),
      device: device == null ? null : HomeLayout.fromJson(device),
    );
  }

  @override
  Future<void> setHome(HomeLayout layout, {required bool onDevice}) async {
    if (onDevice) {
      await config.update((c) => c.copyWith(deviceHome: layout.toJson()));
      return;
    }
    await HomeFile(root).write(layout);
    _hint(HomeFile.filePath, SyncOpKind.changed);
    await clearDeviceHome();
  }

  @override
  Future<HomeLayout> editHome({
    required HomeLayout from,
    required HomeLayout to,
    required bool onDevice,
  }) async {
    if (onDevice) {
      var edited = to;
      await config.update((c) {
        final current = switch (c.deviceHome) {
          final json? => HomeLayout.fromJson(json),
          null => null,
        };
        edited = (current ?? from).withEdit(from: from, to: to);
        return c.copyWith(deviceHome: edited.toJson());
      });
      return edited;
    }
    final edited = await HomeFile(root)
        .update((current) => current.withEdit(from: from, to: to));
    _hint(HomeFile.filePath, SyncOpKind.changed);
    await clearDeviceHome();
    return edited;
  }

  @override
  Future<void> clearDeviceHome() =>
      config.update((c) => c.copyWith(clearDeviceHome: true));

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
      // A file keeps its extension: a note its `.md`, a picture or a book
      // its own — a PDF renamed is still a PDF, not `book.pdf.md`. Typed
      // again at the end of the new name, it is not doubled.
      final ext = row.isDir
          ? ''
          : path.toLowerCase().endsWith('.md')
          ? '.md'
          : p.extension(path);
      var base = newName;
      if (ext.isNotEmpty && base.toLowerCase().endsWith(ext.toLowerCase())) {
        base = base.substring(0, base.length - ext.length);
      }
      String target;
      if (row.isDir) {
        final clean = sanitizeName(base, fallback: defaultFolderName);
        target = await uniqueFolderName(parentDir, clean, exclude: _abs(path));
      } else {
        final clean = sanitizeName(base, fallback: defaultNoteName);
        target = await uniqueFileName(
          parentDir,
          clean,
          ext,
          exclude: _abs(path),
        );
      }
      final newRel = resolvePath(parent, target);
      if (newRel == path) return row;
      return await _relocator.relocate(row, path, newRel);
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
      return await _relocator.relocate(row, path, newRel);
    });
  }

  /// The text of the note at [path], decoded leniently (a note with a
  /// broken byte is still a note) and without its BOM.
  @override
  Future<String> readNote(String path) async {
    final bytes = await readNoteBytes(path);
    final text = decodeNoteText(bytes);
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  }

  /// The note's bytes as the file holds them.
  @override
  Future<Uint8List> readNoteBytes(String path) async {
    await _mustFind(path);
    return await File(_abs(path)).readAsBytes();
  }

  /// The headings of the note at [path], read and outlined where the note
  /// lies — off the UI isolate (#491).
  ///
  /// The wikilink panel's rows after `#` are the note's whole outline, and
  /// getting them means reading, decoding and walking the file: seconds on
  /// a novel-length note, per keystroke if the panel paid it on the UI
  /// isolate. The panel keeps the answer per revision, so this runs once
  /// per target and not once per key.
  Future<List<String>> noteHeadings(String path) async {
    await _mustFind(path);
    final abs = _abs(path);
    return await IsolateGauge.run(
      () => headingsOfNoteFile(abs),
      'headings "$path"',
    );
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
  Future<bool> tidyNote(String path, {Set<LintRule>? rules}) async {
    final changed = await writer.tidy(path, rules: rules);
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
  Future<void> delete(String path) => _trash.delete(path);

  // -- sync (docs/records/sync.md) -------------------------------------------

  /// Whether [path] keeps history: the text notes the editor saves.
  static bool keepsHistory(String path) => NoteSyncWrites.keepsHistory(path);

  /// Swaps the verified sync download at [tempAbs] in for the file at
  /// [path] (new or existing), as a `sync` version of a note.
  Future<void> syncReplace(String path, String tempAbs) =>
      _syncWrites.replace(path, tempAbs);

  /// Writes [text] at [path] because the sync merged both sides of it.
  Future<void> syncMerge(String path, String text) =>
      _syncWrites.merge(path, text);

  /// Moves [path] into `.trash/` because the remote deleted it, whatever
  /// the trash toggle.
  Future<void> syncTrash(String path) => _syncWrites.trash(path);

  /// Renames the file at [from] to [to] because the remote renamed it;
  /// the history follows.
  Future<void> syncMove(String from, String to) => _syncWrites.move(from, to);

  /// Pins the sync base of [path] to the version holding content [sha];
  /// null for files without history, or when the content is gone.
  Future<int?> pinSyncBase(String path, String sha) async {
    if (!keepsHistory(path)) return null;
    return await history.pinSyncBase(path, sha);
  }

  /// Lists the managed trash items (manifest-backed), in deletion order.
  @override
  Future<List<TrashItem>> trashItems() => _trash.items();

  /// Restores the trash item [trashName] to its original parent when that
  /// folder still exists, otherwise to the library root.
  @override
  Future<Note> restoreTrash(String trashName) => _trash.restore(trashName);

  /// Permanently deletes the trash item [trashName] (no restore possible).
  @override
  Future<void> deleteTrashPermanently(String trashName) =>
      _trash.deletePermanently(trashName);

  /// Deletes every entry in `.trash/`, not just the items Niman put
  /// there. Ends with an empty manifest.
  @override
  Future<void> emptyTrash() => _trash.empty();
}

/// The heading texts of the note file at absolute [path], read as it lies.
///
/// The whole file is read, decoded — leniently, without its BOM, as
/// [NoteOps.readNote] does — and walked for its headings, so this is work
/// for a background isolate ([IsolateGauge.run]), never the UI's (#491).
List<String> headingsOfNoteFile(String path) {
  final bytes = File(path).readAsBytesSync();
  var text = decodeNoteText(bytes);
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  return [for (final heading in outlineOfText(text)) heading.text];
}
