import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/frontmatter/fields.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/note_ops.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:copist/src/search/replace.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/search/tag_repo.dart';
import 'package:copist/src/templates/repo.dart';

/// Operations the UI layer performs on an open library.
///
/// Implemented by [NoteOps] (real disk + index, production) and by an
/// in-memory fake in widget tests: `testWidgets` runs on a fake async
/// zone where real filesystem/sqlite I/O never completes, so the UI is
/// exercised against the fake while the real implementation is covered
/// by unit tests.
abstract interface class NoteOperations {
  /// Creates a `<name>.md` note in [parentPath]; [content] is the
  /// initial file content (default empty).
  Future<Note> createNote({
    required String parentPath,
    required String name,
    String content = '',
  });

  /// Creates a folder in [parentPath].
  Future<Note> createFolder({required String parentPath, required String name});

  /// The folder at library-relative [path], created — with every folder
  /// above it — if it is not there (T-TPL-02).
  ///
  /// Unlike [createFolder] this one does *not* uniquify: a template that
  /// files its notes in `Journal/2026` means that folder, and a second
  /// note must not land in `Journal/2026 2`. An existing folder is
  /// returned untouched.
  Future<Note> ensureFolder(String path);

  /// Adds [content] to the end of the note at library-relative [path],
  /// creating it when it is not there (T-TPL-02).
  ///
  /// A blank line is inserted between what was there and what is added,
  /// unless the file already ends in one, so appended entries do not run
  /// into the last paragraph of the previous one.
  Future<Note> appendToNote(String path, String content);

  /// Renames the note or folder at [path] to [newName].
  Future<Note> rename(String path, String newName);

  /// Moves the note or folder at [path] into [targetParent].
  Future<Note> move(String path, String targetParent);

  /// The indexed note/folder at library-relative [path], or null.
  Future<Note?> find(String path);

  /// The text of the note at [path].
  ///
  /// The editor reads notes through its own seam; this is for the flows
  /// that need a note's content without opening it — creating one from a
  /// template, so far. Throws when the note is not there.
  Future<String> readNote(String path);

  /// Deletes [path] (into `.trash/` while the trash toggle is on).
  Future<void> delete(String path);

  /// Pins or unpins the note at [path] (T-M4-04).
  ///
  /// Pinning is a frontmatter edit — `pinned: true` goes into the note's
  /// own block, and unpinning takes the key back out — so the pin travels
  /// with the file and is visible to whoever opens it elsewhere. Returns
  /// the re-indexed row.
  Future<Note> setPinned(String path, {required bool pinned});

  /// Whether deletes move notes into `.trash/` (default true).
  Future<bool> get trashEnabled;

  /// The user-chosen quick note (library-relative path), or null while
  /// none has been chosen.
  Future<String?> get quickNotePath;

  /// The folder (library-relative) that holds the list notes
  /// (default `Lists`).
  Future<String> get listNoteFolder;

  /// Sets the list-note folder.
  Future<void> setListNoteFolder({required String folder});

  /// The folder (library-relative) that holds the note templates
  /// (default `Templates`, T-M4-05).
  Future<String> get templateFolder;

  /// Sets the template folder.
  Future<void> setTemplateFolder({required String folder});

  /// Sets (or clears, with null) the user-chosen quick note.
  Future<void> setQuickNotePath({required String? path});

  /// Sets the trash toggle: `true` = deletes move into `.trash/`.
  Future<void> setTrashEnabled({required bool enabled});

  /// Lists the managed trash items, in deletion order.
  Future<List<TrashItem>> trashItems();

  /// Restores the trash item [trashName] to its original location.
  Future<Note> restoreTrash(String trashName);

  /// Permanently deletes the trash item [trashName].
  Future<void> deleteTrashPermanently(String trashName);

  /// Permanently deletes every managed trash item.
  Future<void> emptyTrash();
}

/// What the UI layer needs from a library session (open/resume/lifecycle,
/// change events, tree reads, and the operation surface).
///
/// Implemented by [LibraryController] (production) and by an in-memory
/// fake in widget tests.
abstract interface class LibrarySession {
  /// Coarse lifecycle of the session.
  LibraryPhase get phase;

  /// Absolute root path while [phase] is opening or ready.
  String? get root;

  /// Last failure message, or null.
  String? get lastError;

  /// Bumped after every index change.
  int get revision;

  /// The note the first index is reading, or null when no scan is
  /// running. Reported only for the blocking scan of an opening library.
  IndexProgress? get indexProgress;

  /// Fires with the new [revision] after every index change.
  Stream<int> get events;

  /// CRUD ops for the open library, or null while closed.
  NoteOperations? get ops;

  /// Resumes the last opened library (if it still exists).
  ///
  /// Non-blocking: the library becomes ready immediately from the last
  /// index, and a background reconciliation scan converges it with the
  /// disk, so a relaunch does not wait on a full disk walk.
  Future<void> resume();

  /// Opens the library at [path]; with [create] true it is created first
  /// when missing.
  ///
  /// With [blockingScan] true (the default) the full index scan completes
  /// before the library becomes ready. With [blockingScan] false (used by
  /// [resume]) the scan is deferred to a background reconciliation.
  Future<void> open(
    String path, {
    required bool create,
    bool blockingScan = true,
  });

  /// Closes the current library (stops watching; keeps the index).
  Future<void> close();

  /// Closes the open library and opens the one at [libraryPath]
  /// (T-ML-06).
  ///
  /// One library is open at a time, so a switch is a close and an open —
  /// but it is one operation for the caller, and it takes the fast path:
  /// the target keeps its own index (T-ML-03), so it comes up from that
  /// and reconciles in the background rather than waiting on a scan.
  /// Switching to the library already open does nothing.
  Future<void> switchTo(String libraryPath);

  /// The libraries the app knows about, most recently opened first
  /// (T-ML-04); what the home screen lists.
  Future<List<KnownLibrary>> knownLibraries();

  /// Drops [libraryPath] from that list.
  ///
  /// Forgetting is a list operation: the folder, its notes and its
  /// `.copist/settings.json` are untouched, so opening it again lists it
  /// again with its settings.
  Future<void> forgetLibrary(String libraryPath);

  /// Triggers a full rescan immediately (explicit re-index).
  Future<void> rescanNow();

  /// Whether the in-app debug log buffer records events.
  ///
  /// Also applies the persisted value to the live logger.
  Future<bool> get debugLogsEnabled;

  /// Sets (and persists) the debug log recording toggle.
  Future<void> setDebugLogsEnabled({required bool enabled});

  /// Whether the note editor shows the row-number column (default true).
  Future<bool> get lineNumbersEnabled;

  /// Sets (and persists) the editor line-numbers toggle.
  Future<void> setLineNumbersEnabled({required bool enabled});

  /// Whether the note editor focuses (shows the keyboard) when a note
  /// opens (default false).
  Future<bool> get editorAutofocusEnabled;

  /// Sets (and persists) the keyboard-on-open toggle.
  Future<void> setEditorAutofocusEnabled({required bool enabled});

  /// Whether a reminder's notification text keeps the `+project`,
  /// `@context` and `#tag` markers (default false).
  Future<bool> get reminderShowTokens;

  /// Sets (and persists) the reminder-markers toggle.
  Future<void> setReminderShowTokens({required bool enabled});

  /// The preview layout mode (default `auto`: split on wide screens,
  /// full-screen switch on phones).
  Future<PreviewLayoutMode> get previewMode;

  /// Sets (and persists) the preview layout mode.
  Future<void> setPreviewMode(PreviewLayoutMode mode);

  /// The editor|preview split ratio (0..1, default 0.55).
  Future<double> get splitRatio;

  /// Sets (and persists) the split ratio.
  Future<void> setSplitRatio(double ratio);

  /// The library tree sort order (default [TreeSort.nameAsc]).
  Future<TreeSort> get treeSort;

  /// Sets (and persists) the library tree sort order.
  Future<void> setTreeSort(TreeSort sort);

  /// Whether the tree's pinned section is rolled up (default false).
  ///
  /// Per library, like the sort order: which notes are worth pinning — and
  /// how many — is a property of the library, not of the app.
  Future<bool> get pinnedCollapsed;

  /// Sets (and persists) the pinned section's rolled-up state.
  Future<void> setPinnedCollapsed({required bool collapsed});

  /// The link format the editor's link button inserts
  /// (default [LinkType.wikilink]).
  Future<LinkType> get linkType;

  /// Sets (and persists) the link format.
  Future<void> setLinkType(LinkType type);

  /// The editor's indent/outdent width in spaces (default 2).
  Future<int> get indentWidth;

  /// Sets (and persists) the indent/outdent width.
  Future<void> setIndentWidth(int width);

  /// The stored editor-toolbar layout (empty = the shipped toolbar);
  /// `ToolbarLayout.parse` turns it into the toolbar.
  Future<String> get editorToolbar;

  /// Sets (and persists) the editor-toolbar layout.
  Future<void> setEditorToolbar(String layout);

  /// The interface text size, as a multiplier of the shipped one
  /// (default 1.0). Applied by the app root, which also multiplies the
  /// platform's own scale.
  Future<double> get uiTextScale;

  /// Sets (and persists) the interface text size.
  Future<void> setUiTextScale(double scale);

  /// The note text size, as a multiplier of the shipped one (default
  /// 1.0). It reaches the source editor as a font size and the preview as
  /// a text scale, and the two have to agree.
  Future<double> get noteTextScale;

  /// Sets (and persists) the note text size.
  Future<void> setNoteTextScale(double scale);

  /// The UI language ([AppLanguage.system] by default).
  Future<AppLanguage> get language;

  /// Sets (and persists) the UI language.
  Future<void> setLanguage(AppLanguage language);

  /// Notifies listeners that state changed without an index mutation.
  void notify();

  /// Closes the session and releases resources; call exactly once.
  Future<void> dispose();

  /// Children of the row with id [parentId] (0 = library root),
  /// directories first, then by name (ascending, or descending with
  /// [nameDesc]).
  Future<List<Note>> children(int parentId, {bool nameDesc = false});

  /// Every note that belongs to the root or to one of the [expandedPaths].
  Future<List<Note>> tree(
    Iterable<String> expandedPaths, {
    bool nameDesc = false,
  });

  /// Every indexed folder, path-ordered (for move-target pickers).
  Future<List<Note>> folders();

  /// The search data source (FTS words + contains scan over the open
  /// library's index); null while no library is ready.
  Future<SearchSource?> get searchSource;

  /// The replace data source (exact whole-word replace across the open
  /// library's notes, T-M3-10); null while no library is ready.
  Future<ReplaceSource?> get replaceSource;

  /// The tag data source (tag list with counts, tag→notes).
  Future<TagSource?> get tagSource;

  /// The frontmatter-field data source (pinned notes, `key = value`
  /// filtering, the keys in use); null while no library is ready.
  Future<FieldSource?> get fieldSource;

  /// The template data source (the configured folder and what is in it);
  /// null while no library is ready.
  Future<TemplateSource?> get templateSource;

  /// The link-resolution source (wiki targets + markdown hrefs against
  /// the open index).
  Future<LinkSource?> get linkSource;
}
