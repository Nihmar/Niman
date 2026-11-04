import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:niman/src/core/file_holds.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/library_journal.dart';
import 'package:niman/src/library/library_layouts.dart';
import 'package:niman/src/library/note_creation.dart';
import 'package:niman/src/library/note_link_questions.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_ops_blocking.dart';
import 'package:niman/src/library/note_pins.dart';
import 'package:niman/src/library/note_reads.dart';
import 'package:niman/src/library/note_relocation.dart';
import 'package:niman/src/library/note_renamer.dart';
import 'package:niman/src/library/note_save_result.dart';
import 'package:niman/src/library/note_sync_writes.dart';
import 'package:niman/src/library/note_trash.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/link_spot_slices.dart';
import 'package:niman/src/links/note_finder.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/todo/task_link_rewrites.dart';
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
    FileHolds? holds,
  }) : holds = holds ?? FileHolds.instance,
       _dao = NoteDao(db),
       _finder = NoteFinder(db),
       _resolver = LinkResolver(db),
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

  /// Finds notes by name, alias and title, for Go to note (#1043).
  final NoteFinder _finder;

  /// Resolves links against the index, for the links a move has to follow.
  final LinkResolver _resolver;

  /// The views holding files open (#833): a rename, a move, a delete or a
  /// sync's swap waits for every view of the file, or of a file under the
  /// folder, to let go of it, and hands it back after.
  final FileHolds holds;

  /// Runs [operation] on [path] (library-relative) once no view holds
  /// it, or anything under it, open ([FileHolds.around]).
  Future<T> _released<T>(String path, Future<T> Function() operation) =>
      holds.around([_abs(path)], operation);

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
    resolver: _resolver,
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
    // A remote move carries the device-only state a local one does
    // (#713): the device Home and the home-screen widgets.
    carryOutside: carryOutside,
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
  Future<List<DiskNoteStamp>> markdownOnDisk(String folder) {
    final library = root;
    return Isolate.run(() => markdownFilesIn(library, folder));
  }

  @override
  Future<List<String>> notesNamed(String query, {int limit = 50}) =>
      _finder.paths(query, limit: limit);

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

  /// The remembered answer of the delete question (#717).
  @override
  Future<bool> get deleteCarriesNotes async =>
      (await config.config).deleteCarriesNotes;

  /// Remembers the answer of the delete question (#717).
  @override
  Future<void> setDeleteCarriesNotes({required bool enabled}) =>
      config.update((c) => c.copyWith(deleteCarriesNotes: enabled));

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

  /// The journal settings, their folder spelled as the library spells it.
  late final LibraryJournal _journal = LibraryJournal(
    config: config,
    dao: _dao,
  );

  @override
  Future<JournalSettings> get journal => _journal.journal;

  @override
  Future<void> setJournal(JournalSettings settings) =>
      _journal.setJournal(settings);

  /// The navigation and the Home, the library's and this device's.
  late final LibraryLayouts _layouts = LibraryLayouts(
    root: root,
    config: config,
    hint: _hint,
  );

  @override
  Future<({NavigationLayout? library, NavigationLayout? device})>
  get navigation => _layouts.navigation;

  @override
  Future<void> setNavigation(
    NavigationLayout layout, {
    required bool onDevice,
  }) => _layouts.setNavigation(layout, onDevice: onDevice);

  @override
  Future<({HomeLayout? library, HomeLayout? device})> get home => _layouts.home;

  @override
  Future<void> setHome(HomeLayout layout, {required bool onDevice}) =>
      _layouts.setHome(layout, onDevice: onDevice);

  @override
  Future<HomeLayout> editHome({
    required HomeLayout from,
    required HomeLayout to,
    required bool onDevice,
  }) => _layouts.editHome(from: from, to: to, onDevice: onDevice);

  @override
  Future<void> clearDeviceHome() => _layouts.clearDeviceHome();

  @override
  Future<List<String>> notePathsUnder(String folder) =>
      _dao.filePathsUnder(folder);

  /// Makes notes and folders, copies of files and additions to notes.
  late final NoteCreation _creation = NoteCreation(
    root: root,
    dao: _dao,
    indexer: indexer,
    serialize: _synchronized,
    hint: _hint,
    find: _mustFind,
  );

  /// Creates a `<name>.md` note in [parentPath] with [content] as its
  /// initial content, uniquifying the name. Returns the indexed row.
  @override
  Future<Note> createNote({
    required String parentPath,
    required String name,
    String content = '',
  }) => _creation.createNote(
    parentPath: parentPath,
    name: name,
    content: content,
  );

  /// Copies the file at [path] beside itself, under a unique name
  /// (`note.md` → `note_1.md`), and returns the indexed row (#1100).
  @override
  Future<Note> duplicate(String path) => _creation.duplicate(path);

  /// The folder at [path], created with its parents if missing
  /// ([NoteCreation.ensureFolder]).
  @override
  @useResult
  Future<Note> ensureFolder(String path) => _creation.ensureFolder(path);

  /// Adds [content] to the end of the note at [path], creating it when it
  /// is not there.
  @override
  Future<Note> appendToNote(String path, String content) =>
      _creation.appendToNote(path, content);

  /// Creates a folder in [parentPath], uniquifying the name.
  @override
  Future<Note> createFolder({
    required String parentPath,
    required String name,
  }) => _creation.createFolder(parentPath: parentPath, name: name);

  /// Picks the path a renamed or moved note takes and has it moved there.
  late final NoteRenamer _renamer = NoteRenamer(
    root: root,
    relocator: _relocator,
    serialize: _synchronized,
    find: _mustFind,
  );

  /// The link rewrites a rename or a move left, asked about after it.
  late final NoteLinkQuestions _links = NoteLinkQuestions(
    serialize: _synchronized,
  );

  /// Renames the note or folder at [path] to [newName].
  ///
  /// Notes are always stored as `<name>.md`; a trailing `.md` in [newName]
  /// is treated as redundant. Names are uniquified against the new parent
  /// (self excluded). Returns the updated row.
  @override
  Future<Note> rename(
    String path,
    String newName, {
    LinkUpdateConfirm? confirmLinks,
    void Function()? onLinksRewritten,
    LinkRewriteProgress? onLinksProgress,
    FlushOpenNotes? flushOpen,
    TaskLinkRewrites? taskLinks,
  }) async {
    final done = await _released(
      path,
      () => _renamer.rename(path, newName, flushOpen, taskLinks),
    );
    _links.ask(done, confirmLinks, onLinksRewritten, onLinksProgress);
    return done.row;
  }

  /// Moves the note or folder at [path] into [targetParent], keeping its
  /// name (uniquified in the target). Returns the updated row.
  ///
  /// Throws [ArgumentError] when [targetParent] is [path] itself or inside
  /// it — a folder cannot be renamed onto its own subtree.
  @override
  Future<Note> move(
    String path,
    String targetParent, {
    LinkUpdateConfirm? confirmLinks,
    void Function()? onLinksRewritten,
    LinkRewriteProgress? onLinksProgress,
    FlushOpenNotes? flushOpen,
    TaskLinkRewrites? taskLinks,
  }) async {
    final done = await _released(
      path,
      () => _renamer.move(path, targetParent, flushOpen, taskLinks),
    );
    _links.ask(done, confirmLinks, onLinksRewritten, onLinksProgress);
    return done.row;
  }

  /// The question about the links [rename] and [move] left, still open or
  /// answered and carried out (#859); completes without error whatever
  /// became of it. What a test awaits to see the links rewritten.
  Future<void> get linkQuestion => _links.settled;

  /// Reads the notes, whole or the parts a panel or a card shows.
  late final NoteReads _reads = NoteReads(root: root, find: _mustFind);

  /// The text of the note at [path], decoded leniently (a note with a
  /// broken byte is still a note) and without its BOM.
  @override
  Future<String> readNote(String path) => _reads.readNote(path);

  /// The note's bytes as the file holds them.
  @override
  Future<Uint8List> readNoteBytes(String path) => _reads.readNoteBytes(path);

  /// The headings of the note at [path], read and outlined where the note
  /// lies — off the UI isolate (#491).
  Future<List<String>> noteHeadings(String path) => _reads.noteHeadings(path);

  /// The block anchors of the note at [path] — its blocks that end with a
  /// ` ^id` (#844) — read off the UI isolate.
  Future<List<BlockAnchor>> noteBlocks(String path) => _reads.noteBlocks(path);

  /// The beginning of the note at [path] for a preview card (#846), read
  /// off the UI isolate.
  Future<NotePreviewText> notePreview(String path) => _reads.notePreview(path);

  /// The links and embeds of the slice of the note at [path] that starts at
  /// [from] (#842, #1040), read off the UI isolate.
  Future<SpotSlice> noteLinkSpotSlice(String path, SpotCursor from) =>
      _reads.noteLinkSpotSlice(path, from);

  /// Pins and unpins notes through their frontmatter.
  late final NotePins _pins = NotePins(
    root: root,
    indexer: indexer,
    writer: writer,
    serialize: _synchronized,
    hint: _hint,
    find: _mustFind,
  );

  /// Pins or unpins the note at [path] by editing its frontmatter
  /// ([NotePins.setPinned]).
  @override
  Future<Note> setPinned(String path, {required bool pinned}) =>
      _pins.setPinned(path, pinned: pinned);

  @override
  Future<NoteSaveResult?> saveNote(
    String path,
    String content, {
    int? editSession,
    DiskStamp? expected,
  }) async {
    final saved = await writer.save(
      path,
      content,
      editSession: editSession,
      expected: expected,
    );
    // After the write: a sync that read the hint before the text landed
    // could otherwise upload the old text and drop the hint.
    _hint(path, SyncOpKind.changed);
    return saved;
  }

  @override
  Future<bool> tidyNote(String path, {Set<LintRule>? rules}) async {
    final changed = await writer.tidy(path, rules: rules);
    if (changed) _hint(path, SyncOpKind.changed);
    return changed;
  }

  @override
  Future<NoteSaveResult?> saveNoteStream(
    String path,
    NoteContentProducer content, {
    int? editSession,
    NoteReferences? references,
    DiskStamp? expected,
  }) async {
    final saved = await writer.save(
      path,
      content,
      editSession: editSession,
      references: references,
      expected: expected,
    );
    _hint(path, SyncOpKind.changed);
    return saved;
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
  Future<void> delete(String path) =>
      _released(path, () => _trash.delete(path));

  // -- sync (docs/records/sync.md) -------------------------------------------

  /// Whether [path] keeps history: the text notes the editor saves.
  static bool keepsHistory(String path) => NoteSyncWrites.keepsHistory(path);

  /// Swaps the verified sync download at [tempAbs] in for the file at
  /// [path] (new or existing), as a `sync` version of a note.
  Future<void> syncReplace(String path, String tempAbs) =>
      _released(path, () => _syncWrites.replace(path, tempAbs));

  /// Runs [write], which creates the new file at [path] under its final name
  /// as a sync download, and has the file indexed as a new one: the way a
  /// file that does not exist yet comes in, with no temp to swap.
  Future<T> syncCreate<T>(String path, Future<T> Function() write) =>
      _released(path, () => _syncWrites.create(path, write));

  /// Writes [text] at [path] because the sync merged both sides of it.
  Future<void> syncMerge(String path, String text) =>
      _syncWrites.merge(path, text);

  /// Moves [path] into `.trash/` because the remote deleted it, whatever
  /// the trash toggle.
  Future<void> syncTrash(String path) =>
      _released(path, () => _syncWrites.trash(path));

  /// Renames the file at [from] to [to] because the remote renamed it;
  /// the history follows. Throws [FileSystemException] when [from] is gone
  /// or [to] is taken (#714). [folder] is the folder the server's rename
  /// took with it, which this device's own Home follows (#774).
  Future<void> syncMove(
    String from,
    String to, {
    ({String from, String to})? folder,
  }) => _released(from, () => _syncWrites.move(from, to, folder: folder));

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
