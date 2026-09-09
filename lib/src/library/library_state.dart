import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/legacy_library_settings.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/library/file_watcher.dart';
import 'package:copist/src/library/library_registry.dart';
import 'package:copist/src/library/note_ops.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:copist/src/search/replace.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/search/tag_repo.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Coarse lifecycle of a library session.
enum LibraryPhase {
  /// No library session is active (or the last open attempt failed).
  none,

  /// A library root is being opened and scanned.
  opening,

  /// The library is open and ready for use.
  ready,
}

/// Owns one library session: database, indexer, file watcher, and CRUD ops.
///
/// Open flow (T-M1-01): the user opens an existing root or creates a new
/// empty one. On open the root is scanned (the index is rebuildable), the
/// recursive watcher starts (T-M1-03), and a periodic full-rescan fallback
/// runs every [rescanInterval]. The last opened root is persisted in
/// `app_settings` so a restart can resume the library via [resume].
final class LibraryController implements LibrarySession {
  /// Creates the controller.
  ///
  /// [appDbFactory] opens the app's own settings database, once per
  /// session and lazily. [indexDbFactory] opens the index of one library,
  /// by its absolute path — a different file per library (T-ML-03), so
  /// it is called again on every open. [searchDbFactory] provides the
  /// same library's search connection (a background-isolate connection
  /// in the app — see [defaultSearchDatabase]; tests fall back to
  /// [indexDbFactory]).
  new(
    this.appDbFactory, {
    required this.indexDbFactory,
    this.indexFileOf,
    Future<IndexDatabase> Function(String libraryPath)? searchDbFactory,
    this.rescanInterval = defaultRescanInterval,
    this.resumeReconcileDelay = defaultResumeReconcileDelay,
    this.watcherDebounce = FileWatcher.defaultDebounce,
  }) : _searchDbFactory = searchDbFactory ?? indexDbFactory;

  /// Full-rescan fallback cadence (~60 s); doubles as the M5 poll cadence.
  static const defaultRescanInterval = Duration(seconds: 60);

  /// The root path of the currently open library, for crash reports (the
  /// crash file is written next to the debug logs the user already exports
  /// from there); null when no session is open. Set when a session opens,
  /// cleared on close.
  static String? currentRootPath;

  /// Default delay between a non-blocking resume becoming ready and its
  /// reconciliation scan. Five seconds: the app's first seconds (first
  /// frame, tree render, first interaction) are calmer without a scan and
  /// its index-bump frames; external changes still converge when it fires
  /// (the periodic rescan covers them too).
  static const defaultResumeReconcileDelay = Duration(seconds: 5);

  /// Builds the app settings database on demand (app-support location in
  /// the app).
  final Future<AppDatabase> Function() appDbFactory;

  /// Builds the index database of the library at the given absolute path.
  final Future<IndexDatabase> Function(String libraryPath) indexDbFactory;

  /// Locates a library's index file, so forgetting one can delete it.
  ///
  /// Null leaves the file behind, which costs disk space and nothing
  /// else — the index is derived data.
  final Future<File> Function(String libraryPath)? indexFileOf;

  /// The search connection; defaults to [indexDbFactory] (tests), the app
  /// injects the background-isolate connection.
  final Future<IndexDatabase> Function(String libraryPath) _searchDbFactory;

  /// How often the full-rescan fallback runs.
  final Duration rescanInterval;

  /// Delay between a non-blocking resume becoming ready and its
  /// reconciliation scan, leaving the UI time to paint the tree first.
  final Duration resumeReconcileDelay;

  /// Debounce window for the file watcher.
  final Duration watcherDebounce;

  final StreamController<int> _events = StreamController<int>.broadcast();
  final AppLogger _log = const AppLogger(name: 'session');
  int _revision = 0;
  LibraryPhase _phase = LibraryPhase.none;
  String? _root;
  String? _lastError;
  Future<void>? _resumeFuture;
  Future<AppDatabase>? _appDatabase;

  /// The open library's index; null while no library is open, and a
  /// different file for each library (T-ML-03).
  IndexDatabase? _indexDb;
  Indexer? _indexer;
  NoteOps? _ops;
  FileWatcher? _watcher;
  Timer? _rescanTimer;

  /// Reconciliation scan pending after a non-blocking resume; cancelled in
  /// [_teardown] so a stale scan can never hit a different library.
  Timer? _reconcileTimer;

  /// How far the first index has got, or null when no scan is running.
  @override
  IndexProgress? get indexProgress => _indexProgress;

  IndexProgress? _indexProgress;
  DateTime? _progressShown;

  /// Records a scan's progress, and lets the UI see it at a readable rate.
  ///
  /// The reports arrive one per note, which on a large library is far
  /// faster than a frame; rebuilding on each would spend the scan drawing
  /// instead of reading. Twenty a second already reads as a blur, which
  /// is the point of showing them.
  void _onIndexProgress(IndexProgress progress) {
    _indexProgress = progress;
    final now = DateTime.now();
    final last = _progressShown;
    if (last != null && now.difference(last) < _progressInterval) return;
    _progressShown = now;
    _bump();
  }

  /// How often a running scan redraws the name it is showing.
  static const _progressInterval = Duration(milliseconds: 50);

  /// Current phase.
  @override
  LibraryPhase get phase => _phase;

  /// Absolute root path while [phase] is opening or ready.
  @override
  String? get root => _root;

  /// Last failure message, or null.
  @override
  String? get lastError => _lastError;

  /// Bumped after every index change.
  @override
  int get revision => _revision;

  /// Fires with the new [revision] after every index change.
  @override
  Stream<int> get events => _events.stream;

  /// The app's settings database, opened once per session.
  ///
  /// Unlike the index it does not belong to a library: it holds the
  /// resume pointer, the language and the rest, and it is read before any
  /// library is open.
  Future<AppDatabase> get appDatabase => _appDatabase ??= appDbFactory();

  /// The cached search source; the background-isolate worker connection is
  /// created once per open library and reused (see [searchSource]).
  SearchSource? _searchSource;

  /// The search connection when it is a distinct database from the index
  /// one; closed with the library, since it is that library's file.
  IndexDatabase? _searchDb;

  /// CRUD ops for the open library, or null while closed.
  @override
  NoteOps? get ops => _ops;

  /// Children of the row with id [parentId] (0 = library root),
  /// directories first, then by name.
  ///
  /// Empty while no library is open: there is no index to read, and the
  /// tree UI asks for the root's children before the first open.
  @override
  Future<List<Note>> children(int parentId, {bool nameDesc = false}) async {
    final db = _indexDb;
    if (db == null) return const [];
    return await NoteDao(db).children(parentId, nameDesc: nameDesc);
  }

  @override
  Future<List<Note>> tree(
    Iterable<String> expandedPaths, {
    bool nameDesc = false,
  }) async {
    final db = _indexDb;
    if (db == null) return const [];
    return await NoteDao(db).tree(expandedPaths, nameDesc: nameDesc);
  }

  /// Every indexed folder, path-ordered (for move-target pickers).
  @override
  Future<List<Note>> folders() async {
    final db = _indexDb;
    if (db == null) return const [];
    return await NoteDao(db).folders();
  }

  @override
  Future<SearchSource?> get searchSource async {
    // The search connection is background-isolate backed: the MATCH +
    // snippet() work for large result sets (and novel-length bodies) never
    // runs on the UI isolate. One connection per open library, created
    // once: a fresh connection per call leaked one worker isolate per
    // SearchScreen mount (drift keeps the worker alive until closed) and
    // left nothing to recover when its startup failed. It is dropped with
    // the library, since it is a connection to that library's own file.
    final root = _root;
    final indexDb = _indexDb;
    if (root == null || indexDb == null) return null;
    var source = _searchSource;
    if (source == null) {
      final db = await _searchDbFactory(root);
      _searchDb = identical(db, indexDb) ? null : db;
      source = SearchRepo(db);
      _searchSource = source;
    }
    return source;
  }

  @override
  Future<ReplaceSource?> get replaceSource async {
    // Bound to the current root + indexer: rewritten notes are re-indexed
    // through applyEvents as each write batch lands, so search reflects a
    // replace without waiting on the (Android-unreliable) watcher or the
    // periodic rescan.
    final root = _root;
    final indexer = _indexer;
    final db = _indexDb;
    if (root == null || indexer == null || db == null) return null;
    return ReplaceRunner(
      db,
      root,
      onNotesReindexed: (paths) => indexer.rescanFiles(root, paths),
    );
  }

  @override
  Future<TagSource?> get tagSource async {
    final db = _indexDb;
    if (db == null) return null;
    return TagRepo(db);
  }

  @override
  Future<LinkSource?> get linkSource async {
    final db = _indexDb;
    if (db == null) return null;
    return LinkResolver(db);
  }

  /// Resumes the last opened library (if it still exists). Best effort:
  /// safe to call repeatedly, no-op when no library has been opened yet.
  @override
  Future<void> resume() {
    _resumeFuture ??= _doResume();
    return _resumeFuture!;
  }

  Future<void> _doResume() async {
    try {
      final last = await AppSettingsRepo(await appDatabase).lastLibraryPath();
      _log.info('resume: lastLibraryPath=$last');
      if (last == null) return;
      final dir = Directory(last);
      if (!dir.existsSync()) {
        _log.warning('resume: root no longer exists: $last');
        return;
      }
      await open(last, create: false, blockingScan: false);
    } on Object catch (error) {
      // Resume is best effort; the open screen is reached with lastError.
      _log.error('resume failed: $error');
    }
  }

  /// Opens the library at [path]; with [create] true it is created first
  /// when missing.
  ///
  /// With [blockingScan] true (the default) the full index scan completes
  /// before the library becomes ready. With [blockingScan] false (used by
  /// [resume] for a fast relaunch) the library becomes ready immediately
  /// from the last index, and a reconciliation scan runs
  /// [resumeReconcileDelay] later so external changes converge within
  /// seconds (the scan is still a blocking disk walk, so it must not gate
  /// the first frame).
  @override
  Future<void> open(
    String path, {
    required bool create,
    bool blockingScan = true,
  }) async {
    if (_phase != LibraryPhase.none) {
      throw StateError('A library is already open (phase: ${_phase.name})');
    }
    _phase = LibraryPhase.opening;
    _lastError = null;
    _bump();
    try {
      _log.info('open start: $path create=$create blockingScan=$blockingScan');
      final abs = p.normalize(path.trim());
      final rootDir = Directory(abs);
      if (create) {
        if (!rootDir.existsSync()) {
          await rootDir.create(recursive: true);
        }
      } else if (!rootDir.existsSync()) {
        throw ArgumentError('Directory does not exist: $abs');
      }
      final appDb = await appDatabase;
      AppLog.enabled = await AppSettingsRepo(appDb).debugLogsEnabled();
      // Before anything reads the settings: a library upgraded from the
      // `library_settings` table gets its `.copist/settings.json` here,
      // now that the folder is known to be reachable (T-ML-02).
      await LegacyLibrarySettings(appDb).seed(abs);
      // This library's own index file (T-ML-03). Opening a second library
      // no longer scans over the first one's rows, so coming back to it
      // costs a reconciliation rather than a full walk.
      final indexDb = await indexDbFactory(abs);
      _indexDb = indexDb;
      final indexer = Indexer(indexDb)..onChanged = _bump;
      final ops = NoteOps(root: abs, db: indexDb, indexer: indexer);
      if (blockingScan) {
        // Only here: the first index is the scan long enough to be worth
        // watching, and reporting costs a message per note.
        indexer.onProgress = _onIndexProgress;
        try {
          await indexer.fullScan(abs);
        } finally {
          indexer.onProgress = null;
          _indexProgress = null;
        }
      }
      final watcher = FileWatcher(abs, debounce: watcherDebounce);
      watcher.events.listen(_onWatchBatch);
      await watcher.start();
      // Held so [_teardown] can stop it: an unheld watcher keeps its
      // recursive watch (and its event handling) alive for the whole
      // process, and every reopen adds another one.
      _watcher = watcher;
      _log.info('open: watcher started for $abs');
      _rescanTimer = Timer.periodic(rescanInterval, (_) => _safeRescan(abs));
      _indexer = indexer;
      _ops = ops;
      _root = abs;
      _phase = LibraryPhase.ready;
      currentRootPath = abs;
      await AppSettingsRepo(appDb).setLastLibraryPath(abs);
      // The list the home screen shows (T-ML-04). Opening is what puts a
      // folder on it, so a library the app has never seen needs no
      // registration step of its own.
      await LibraryRegistry(appDb).touch(abs);
      _bump();
      if (!blockingScan) {
        _reconcileTimer = Timer(resumeReconcileDelay, () => _safeRescan(abs));
      }
      _log.info('open complete: ready root=$abs');
    } on Object catch (error) {
      _log.error('open failed: $error');
      _lastError = '$error';
      _phase = LibraryPhase.none;
      _root = null;
      await _teardown();
      _bump();
    }
  }

  /// Closes the current library (stops watching; keeps the index) and clears
  /// the persisted last-library path.
  @override
  Future<void> close() async {
    _log.info('close: root=$_root');
    await _teardown();
    _root = null;
    _phase = LibraryPhase.none;
    currentRootPath = null;
    try {
      await AppSettingsRepo(await appDatabase).setLastLibraryPath(null);
    } on Object catch (_) {
      // Settings unavailable; nothing else to clear.
    }
    _bump();
  }

  /// Closes the open library and opens the one at [libraryPath].
  ///
  /// Non-blocking, unlike a plain open from the picker: the target has
  /// its own index from the last time it was open (T-ML-03), so its tree
  /// is there at once and a reconciliation scan follows. A failure to
  /// open leaves no library open, with [lastError] set — which lands the
  /// app on the home screen, where the failure can be read and another
  /// library picked.
  @override
  Future<void> switchTo(String libraryPath) async {
    final target = p.normalize(libraryPath.trim());
    if (target == _root) return;
    _log.info('switch library: $_root -> $target');
    if (_phase != LibraryPhase.none) await close();
    await open(target, create: false, blockingScan: false);
  }

  /// The libraries the app knows about, most recently opened first.
  @override
  Future<List<KnownLibrary>> knownLibraries() async {
    return await LibraryRegistry(await appDatabase).all();
  }

  /// Drops [libraryPath] from the known list; the folder is untouched.
  @override
  Future<void> forgetLibrary(String libraryPath) async {
    _log.info('forget library: $libraryPath');
    await LibraryRegistry(await appDatabase).forget(libraryPath);
    // The index is derived data and the entry that named it is gone, so
    // the file would sit there forever with nothing pointing at it.
    await _deleteIndexOf(libraryPath);
    _bump();
  }

  /// Deletes the index file of a forgotten library, if it can be found.
  ///
  /// Best effort: a failure here costs disk space, not correctness, and
  /// must not turn "forget this library" into an error.
  Future<void> _deleteIndexOf(String libraryPath) async {
    try {
      final locate = indexFileOf;
      if (locate == null) return;
      final file = await locate(libraryPath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (error) {
      _log.warning('forget: index file not removed ($error)');
    }
  }

  /// Triggers a full rescan immediately (explicit re-index).
  @override
  Future<void> rescanNow() {
    final indexer = _indexer;
    final root = _root;
    if (indexer == null || root == null) {
      throw StateError('No library is open');
    }
    _log.info('manual rescan requested');
    return indexer.fullScan(root);
  }

  /// Whether the in-app debug log buffer records events.
  @override
  Future<bool> get debugLogsEnabled async {
    final enabled = await AppSettingsRepo(await appDatabase).debugLogsEnabled();
    AppLog.enabled = enabled;
    return enabled;
  }

  /// Sets (and persists) the debug log recording toggle.
  @override
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    _log.info('debug logging set to $enabled');
    await AppSettingsRepo(await appDatabase)
        .setDebugLogsEnabled(enabled: enabled);
    AppLog.enabled = enabled;
  }

  /// Whether the note editor shows the row-number column.
  @override
  Future<bool> get lineNumbersEnabled async {
    return await AppSettingsRepo(await appDatabase).lineNumbersEnabled();
  }

  /// Sets (and persists) the editor line-numbers toggle.
  @override
  Future<void> setLineNumbersEnabled({required bool enabled}) async {
    _log.info('editor line numbers set to $enabled');
    await AppSettingsRepo(await appDatabase)
        .setLineNumbersEnabled(enabled: enabled);
  }

  /// Whether the note editor focuses (shows the keyboard) on note open.
  @override
  Future<bool> get editorAutofocusEnabled async {
    return await AppSettingsRepo(await appDatabase).editorAutofocusEnabled();
  }

  /// Sets (and persists) the keyboard-on-open toggle.
  @override
  Future<void> setEditorAutofocusEnabled({required bool enabled}) async {
    _log.info('editor keyboard-on-open set to $enabled');
    await AppSettingsRepo(await appDatabase)
        .setEditorAutofocusEnabled(enabled: enabled);
  }

  /// Whether reminder text keeps the +project/@context/#tag markers.
  @override
  Future<bool> get reminderShowTokens async {
    return await AppSettingsRepo(await appDatabase).reminderShowTokens();
  }

  /// Sets (and persists) the reminder-markers toggle.
  @override
  Future<void> setReminderShowTokens({required bool enabled}) async {
    _log.info('reminder markers set to $enabled');
    await AppSettingsRepo(await appDatabase)
        .setReminderShowTokens(enabled: enabled);
  }

  /// The preview layout mode.
  @override
  Future<PreviewLayoutMode> get previewMode async {
    return await AppSettingsRepo(await appDatabase).previewMode();
  }

  /// Sets (and persists) the preview layout mode.
  @override
  Future<void> setPreviewMode(PreviewLayoutMode mode) async {
    _log.info('preview mode set to ${mode.name}');
    await AppSettingsRepo(await appDatabase).setPreviewMode(mode);
  }

  /// The editor|preview split ratio.
  @override
  Future<double> get splitRatio async {
    return await AppSettingsRepo(await appDatabase).splitRatio();
  }

  /// Sets (and persists) the split ratio.
  @override
  Future<void> setSplitRatio(double ratio) async {
    await AppSettingsRepo(await appDatabase).setSplitRatio(ratio);
  }

  /// The library tree sort order.
  @override
  Future<TreeSort> get treeSort async {
    return await AppSettingsRepo(await appDatabase).treeSort();
  }

  /// Sets (and persists) the library tree sort order.
  @override
  Future<void> setTreeSort(TreeSort sort) async {
    await AppSettingsRepo(await appDatabase).setTreeSort(sort);
  }

  /// The link format the editor's link button inserts.
  @override
  Future<LinkType> get linkType async {
    return await AppSettingsRepo(await appDatabase).linkType();
  }

  /// Sets (and persists) the link format.
  @override
  Future<void> setLinkType(LinkType type) async {
    _log.info('link type set to ${type.name}');
    await AppSettingsRepo(await appDatabase).setLinkType(type);
  }

  /// The editor's indent/outdent width in spaces.
  @override
  Future<int> get indentWidth async {
    return await AppSettingsRepo(await appDatabase).indentWidth();
  }

  /// Sets (and persists) the indent/outdent width.
  @override
  Future<void> setIndentWidth(int width) async {
    _log.info('indent width set to $width');
    await AppSettingsRepo(await appDatabase).setIndentWidth(width);
  }

  /// The stored editor-toolbar layout (empty = the shipped toolbar).
  @override
  Future<String> get editorToolbar async {
    return await AppSettingsRepo(await appDatabase).editorToolbar();
  }

  /// Sets (and persists) the editor-toolbar layout.
  @override
  Future<void> setEditorToolbar(String layout) async {
    _log.info('editor toolbar set to "$layout"');
    await AppSettingsRepo(await appDatabase).setEditorToolbar(layout);
  }

  /// The UI language.
  @override
  Future<AppLanguage> get language async {
    return await AppSettingsRepo(await appDatabase).language();
  }

  /// Sets (and persists) the UI language.
  @override
  Future<void> setLanguage(AppLanguage language) async {
    _log.info('language set to ${language.id}');
    await AppSettingsRepo(await appDatabase).setLanguage(language);
  }

  /// Notifies listeners that state changed without an index mutation
  /// (e.g. a settings change the tree UI should react to).
  @override
  void notify() => _bump();

  /// Closes the session and releases resources; call exactly once.
  ///
  /// The library's own connections went with [close]; what is left is the
  /// app settings database, which outlives every library.
  @override
  Future<void> dispose() async {
    await close();
    if (!_events.isClosed) {
      await _events.close();
    }
    final appDb = _appDatabase;
    _appDatabase = null;
    if (appDb != null) {
      await (await appDb).close();
    }
  }

  void _bump() {
    _revision++;
    if (!_events.isClosed) {
      _events.add(_revision);
    }
  }

  /// Drops everything that belongs to the open library, the index file
  /// included: it is that library's own file (T-ML-03), so leaving it
  /// open would keep a connection — and, for the search connection, a
  /// worker isolate — per library ever opened this session.
  Future<void> _teardown() async {
    _rescanTimer?.cancel();
    _rescanTimer = null;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    final watcher = _watcher;
    _watcher = null;
    await watcher?.stop();
    _indexer = null;
    _ops = null;
    // Nulled before the awaits: a caller that races us must not find a
    // half-closed database.
    final searchDb = _searchDb;
    final indexDb = _indexDb;
    _searchSource = null;
    _searchDb = null;
    _indexDb = null;
    await searchDb?.close();
    await indexDb?.close();
  }

  Future<void> _onWatchBatch(WatchBatch batch) async {
    _log.debug(
      'watch batch: ${batch.paths.length} path(s), '
      '${batch.resyncDirs.length} resync dir(s)',
    );
    final indexer = _indexer;
    final root = _root;
    if (indexer == null || root == null || phase != LibraryPhase.ready) {
      return;
    }
    try {
      for (final dir in batch.resyncDirs) {
        await indexer.resync(root, dir);
      }
      if (batch.paths.isNotEmpty) {
        await indexer.applyEvents(root, batch.paths);
      }
    } on Object catch (error) {
      // Transient watcher errors are covered by the periodic rescan.
      _log.warning('watch batch failed: $error');
    }
  }

  Future<void> _safeRescan(String abs) async {
    final indexer = _indexer;
    if (indexer == null || phase != LibraryPhase.ready) return;
    try {
      _log.info('periodic rescan start: $abs');
      await indexer.fullScan(abs);
      _log.info('periodic rescan complete');
    } on Object catch (error) {
      _log.error('rescan failed: $error');
      if (!Directory(abs).existsSync()) {
        await close();
        _lastError = 'The library folder is no longer available.';
      }
    }
  }
}

/// The app settings database FILE in the platform application-support
/// directory.
///
/// It has held that name since M1, when it was the index too; T-ML-03
/// moved the index into [libraryIndexFile] and left the settings here.
Future<File> defaultAppDbFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'copist.db'));
}

/// The index FILE for the library at [libraryPath].
///
/// One per library, named by a digest of the absolute path: two libraries
/// never share a file, and a library that moves simply rebuilds under its
/// new name. The digest is truncated — it names a file in the app's own
/// folder, so a collision would need two libraries whose paths collide in
/// 64 bits, and the registry keeps the mapping readable (T-ML-04).
///
/// It lives OUTSIDE the library folder: the index is a cache, the files
/// on disk are the source of truth, and `.copist/` is for what the user
/// would want to keep.
Future<File> libraryIndexFile(String libraryPath) async {
  final dir = Directory(
    p.join((await getApplicationSupportDirectory()).path, 'indexes'),
  );
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final digest = sha256.convert(utf8.encode(p.normalize(libraryPath)));
  return File(p.join(dir.path, '${digest.toString().substring(0, 16)}.db'));
}

/// The one connection-level setup every connection applies: a busy
/// timeout (the search reader contends with indexer writes) and WAL
/// (readers do not block the writer).
void _databaseSetup(sqlite3.Database db) {
  db
    ..execute('PRAGMA busy_timeout = 5000')
    ..execute('PRAGMA journal_mode = WAL');
}

/// Creates the app settings database in the application-support directory.
Future<AppDatabase> defaultAppDatabase() async {
  return AppDatabase(
    NativeDatabase(await defaultAppDbFile(), setup: _databaseSetup),
  );
}

/// Opens the index of the library at [libraryPath].
Future<IndexDatabase> defaultIndexDatabase(String libraryPath) async {
  return IndexDatabase(
    NativeDatabase(await libraryIndexFile(libraryPath), setup: _databaseSetup),
  );
}

/// The search connection over the same library's index file, with drift's
/// background-isolate executor: `MATCH` + `snippet()` over large result
/// sets run off the UI isolate (T-M3-09 fix: many results with
/// novel-length bodies stalled every frame).
Future<IndexDatabase> defaultSearchDatabase(String libraryPath) async {
  return IndexDatabase(
    NativeDatabase.createInBackground(
      await libraryIndexFile(libraryPath),
      setup: _databaseSetup,
    ),
  );
}

/// The single library session for the app session.
///
/// Typed as the [LibrarySession] interface so the UI (and widget tests,
/// which substitute an in-memory fake) never depends on the concrete
/// [LibraryController].
final librarySessionProvider = Provider<LibrarySession>((ref) {
  final controller = LibraryController(
    defaultAppDatabase,
    indexDbFactory: defaultIndexDatabase,
    indexFileOf: libraryIndexFile,
    searchDbFactory: defaultSearchDatabase,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
