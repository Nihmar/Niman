import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/custom_theme_repo.dart';
import 'package:niman/src/core/settings/legacy_library_settings.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/file_watcher.dart';
import 'package:niman/src/library/library_registry.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/library/trash_cleaner.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/sync/network_monitor.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/templates/repo.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/update/update_scheduler.dart';
import 'package:niman/src/update/update_service.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_libraries.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:niman/src/workspace/workspace_store.dart';
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
    SyncSecretStore? syncSecrets,
    this.syncNetwork,
  }) : _searchDbFactory = searchDbFactory ?? indexDbFactory,
       syncSecrets = syncSecrets ?? SecureSyncSecretStore();

  /// Full-rescan fallback cadence: the watcher covers live changes, so the
  /// full walk is the safety net (a missed event, a network mount). One
  /// walk a minute cost 27-46 ms on a 901-entry library and scales with it
  /// (T-PP-22); five minutes keeps the net without the constant cost. It
  /// doubles as the M5 poll cadence.
  static const defaultRescanInterval = Duration(minutes: 5);

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

  /// Where each library's WebDAV password lives (M5); the OS secure
  /// storage unless a test injects another.
  final SyncSecretStore syncSecrets;

  /// Builds the network monitor the sync's automatic triggers read (the
  /// app passes `connectivity_plus`); null, as in tests, counts the
  /// network as always usable.
  final NetworkMonitor Function()? syncNetwork;

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

  /// The open library's `.niman/settings.json`; null while none is open,
  /// and then every setting reads and writes app-wide.
  LibraryConfigRepo? _configRepo;
  Indexer? _indexer;
  NoteOps? _ops;
  LibrarySyncService? _sync;
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

  /// The open library's WebDAV sync, or null while closed.
  @override
  SyncService? get sync => _sync;

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
    final history = _ops?.history;
    return ReplaceRunner(
      db,
      root,
      onNotesReindexed: (paths) => indexer.rescanFiles(root, paths),
      historyRequest: history == null
          ? null
          : () => history.requestFor('', forced: HistoryReason.replace),
    );
  }

  @override
  Future<TagSource?> get tagSource async {
    final db = _indexDb;
    if (db == null) return null;
    return TagRepo(db);
  }

  @override
  Future<FieldSource?> get fieldSource async {
    final db = _indexDb;
    if (db == null) return null;
    return FieldRepo(db);
  }

  @override
  Future<TemplateSource?> get templateSource async {
    final indexer = _indexer;
    final ops = this.ops;
    if (indexer == null || ops == null) return null;
    return TemplateRepo(indexer.dao, ops);
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
      _startUpdateChecks(appDb);
      // Before anything reads the settings: a library upgraded from the
      // `library_settings` table gets its `.niman/settings.json` here,
      // now that the folder is known to be reachable (T-ML-02).
      await LegacyLibrarySettings(appDb).seed(abs);
      // This library's own index file (T-ML-03). Opening a second library
      // no longer scans over the first one's rows, so coming back to it
      // costs a reconciliation rather than a full walk.
      final indexDb = await indexDbFactory(abs);
      _indexDb = indexDb;
      final indexer = Indexer(indexDb)..onChanged = _bump;
      // One reader of `.niman/settings.json` per session: the four
      // per-library settings and the overrides (T-ML-10) share its cache.
      final config = LibraryConfigRepo(abs);
      _configRepo = config;
      final ops = NoteOps(
        root: abs,
        db: indexDb,
        indexer: indexer,
        config: config,
      );
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
      // The library's WebDAV sync (M5): idle until configured; the state and
      // the password are per device, keyed by this root.
      final syncStore = SyncStore(appDb);
      final sync = LibrarySyncService(
        root: abs,
        engine: SyncEngine(
          root: abs,
          ops: ops,
          store: syncStore,
          secrets: syncSecrets,
        ),
        store: syncStore,
        secrets: syncSecrets,
        network: syncNetwork?.call(),
        phone: Platform.isAndroid || Platform.isIOS,
      );
      _sync = sync;
      ops.syncHints = sync.hint;
      // Loads the status, then the automatic triggers take over (the
      // "library opened" full sync among them) — idle without a
      // destination.
      unawaited(sync.start());
      // The library's own text sizes, on screen with it (T-M6-12) and
      // before the ready bump, so nothing paints at the wrong size first.
      final settings = await config.config;
      AppTextScales.apply(
        ui: settings.uiTextScale,
        note: settings.noteTextScale,
      );
      _phase = LibraryPhase.ready;
      currentRootPath = abs;
      // Warm the tree's first query while the caller still shows its
      // opening state: the first flatten otherwise paid drift's statement
      // preparation and SQLite's page cache right as the shell built
      // (78-118 ms in the log, T-PP-22).
      unawaited(_warmUpTree(indexer.dao));
      await AppSettingsRepo(appDb).setLastLibraryPath(abs);
      // The list the home screen shows (T-ML-04). Opening is what puts a
      // folder on it, so a library the app has never seen needs no
      // registration step of its own.
      await LibraryRegistry(appDb).touch(abs);
      // The native widget config activity cannot read the registry (no
      // Dart engine at placement), so it reads this mirror instead.
      unawaited(_saveWidgetLibraryMirror(appDb));
      // Opening is when the trash empties itself, if the library asked
      // it to (issue #79) — behind the ready bump, because a folder full
      // of old deletions must not hold the library shut.
      unawaited(_autoEmptyTrash(ops, settings.trashAutoEmptyDays));
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

  /// The home-screen widget instances reading [libraryPath] (issue 6).
  @override
  Future<List<WidgetConfig>> widgetConfigsFor(String libraryPath) async {
    return await WidgetConfigStore(await appDatabase).forLibrary(libraryPath);
  }

  /// Records a placed todo widget for [libraryPath] (issue 6).
  @override
  Future<void> adoptTodoWidget(int androidWidgetId, String libraryPath) async {
    final store = WidgetConfigStore(await appDatabase);
    if (await store.find(androidWidgetId) != null) return;
    await store.upsert(
      androidWidgetId: androidWidgetId,
      provider: WidgetProvider.todo,
      libraryPath: libraryPath,
    );
  }

  /// Records a placed note widget for [notePath] (issue 6).
  @override
  Future<void> adoptNoteWidget(
    int androidWidgetId,
    String libraryPath,
    String notePath,
  ) async {
    final store = WidgetConfigStore(await appDatabase);
    if (await store.find(androidWidgetId) != null) return;
    await store.upsert(
      androidWidgetId: androidWidgetId,
      provider: WidgetProvider.note,
      libraryPath: libraryPath,
      notePath: notePath,
    );
  }

  /// Drops [libraryPath]'s [provider] widget configurations whose
  /// instance is no longer placed (issue 6); the refresh calls this,
  /// since the native `onDeleted` cannot reach the database.
  @override
  Future<void> pruneWidgetConfigs({
    required String libraryPath,
    required WidgetProvider provider,
    required Set<int> placedIds,
  }) async {
    final store = WidgetConfigStore(await appDatabase);
    final stale = {
      for (final config in await store.forLibrary(libraryPath))
        if (config.provider == provider.name &&
            !placedIds.contains(config.androidWidgetId))
          config.androidWidgetId,
    };
    for (final id in stale) {
      await store.remove(id);
    }
  }

  /// Drops [libraryPath] from the known list; the folder is untouched.
  @override
  Future<void> forgetLibrary(String libraryPath) async {
    _log.info('forget library: $libraryPath');
    final db = await appDatabase;
    await LibraryRegistry(db).forget(libraryPath);
    // Widgets pointing at it would open a library the home screen no
    // longer lists; their rows go with the entry (issue 6).
    await WidgetConfigStore(db).removeForLibrary(libraryPath);
    // Its sync state describes a library the app no longer knows; opened
    // again, it starts unconfigured (docs/dev/sync.md, "Configuration").
    await SyncStore(db).removeLibrary(libraryPath);
    // What was left open in it goes too (#23): opened again, it starts
    // with nothing open, like a library the app has never seen.
    await WorkspaceStore(db).remove(libraryPath);
    try {
      await syncSecrets.delete(libraryPath);
    } on Exception catch (e) {
      // A missing keychain must not block forgetting; the entry is inert
      // without its destination row.
      _log.warning('forget library: sync password not deleted: $e');
    }
    // The mirror would otherwise keep offering a forgotten library.
    unawaited(_saveWidgetLibraryMirror(db));
    // The index is derived data and the entry that named it is gone, so
    // the file would sit there forever with nothing pointing at it.
    await _deleteIndexOf(libraryPath);
    _bump();
  }

  /// Mirrors the known libraries for the native widget config activity
  /// (round 2, R1): path, display name and index file per library.
  ///
  /// Best effort and Android-only: the activity treats the mirror as a
  /// cache, and a failure here must never break an open or a forget.
  Future<void> _saveWidgetLibraryMirror(AppDatabase appDb) async {
    if (!Platform.isAndroid) return;
    try {
      final libraries = await LibraryRegistry(appDb).all();
      final locate = indexFileOf ?? libraryIndexFile;
      final indexByPath = <String, String>{};
      for (final lib in libraries) {
        indexByPath[lib.path] = (await locate(lib.path)).path;
      }
      await HomeWidget.saveWidgetData<String>(
        widgetLibrariesKey,
        encodeLibraryMirror(libraries, indexByPath),
      );
    } on MissingPluginException {
      // No host handler (tests, desktops).
    } on PlatformException catch (error) {
      _log.warning('widget library mirror not saved ($error)');
    }
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

  /// Whether the app checks GitHub Releases for updates (issue #81).
  @override
  Future<bool> get autoUpdateEnabled async =>
      await AppSettingsRepo(await appDatabase).autoUpdateEnabled();

  @override
  Future<bool> get closeToTray async =>
      await AppSettingsRepo(await appDatabase).closeToTray();

  @override
  Future<void> setCloseToTray({required bool enabled}) async {
    _log.info('close to tray: $enabled');
    await AppSettingsRepo(await appDatabase).setCloseToTray(enabled: enabled);
  }

  /// Sets (and persists) the auto-update toggle.
  @override
  Future<void> setAutoUpdateEnabled({required bool enabled}) async {
    _log.info('auto-update set to $enabled');
    await AppSettingsRepo(await appDatabase)
        .setAutoUpdateEnabled(enabled: enabled);
  }

  UpdateScheduler? _updateScheduler;

  /// The latest available update the scheduler found, if any (issue #81).
  ///
  /// Read by the shell banner and the settings row; both rebuild on
  /// session events, which [UpdateScheduler.onUpdate] bumps.
  @override
  UpdateAvailable? get pendingUpdate => _pendingUpdate;
  UpdateAvailable? _pendingUpdate;

  /// Drops the pending update (the banner's dismiss action).
  @override
  void clearPendingUpdate() {
    _pendingUpdate = null;
    notify();
  }

  /// Starts the launch + six-hourly update checks, once per controller.
  ///
  /// The scheduler only reads the settings store and GitHub; drift writes
  /// stay on the main isolate, in its callbacks.
  void _startUpdateChecks(AppDatabase appDb) {
    // Testing builds check no release channel (issue #106): the stored
    // toggle is irrelevant, nothing polls and no banner can appear.
    if (isTestingBuild) return;
    if (_updateScheduler != null) return;
    final repo = AppSettingsRepo(appDb);
    _updateScheduler = UpdateScheduler(
      isEnabled: repo.autoUpdateEnabled,
      runCheck: () async {
        try {
          final current = await currentAppVersion();
          final update = await checkNow(current: current);
          _log.debug(
            'update check: current $current -> '
            '${update == null ? 'up to date' : 'available ${update.version}'}',
          );
          return update;
        } on Object catch (error) {
          _log.warning('update check failed: $error');
          return null;
        }
      },
      noteChecked: repo.setLastUpdateCheck,
      onUpdate: (update) {
        _pendingUpdate = update;
        notify();
      },
    )..start();
  }

  /// The open library's settings, or the shipped defaults while none is
  /// open (T-ML-10).
  ///
  /// The settings screen only exists inside an open library, so the
  /// defaults branch is what a startup read sees before the first open,
  /// not a state a user can edit from.
  Future<LibraryConfig> get _library async =>
      await _configRepo?.config ?? LibraryConfig.defaults;

  /// Applies [change] to the open library's settings; a no-op with none
  /// open, since there is nothing to write it to.
  Future<void> _editLibrary(
    LibraryConfig Function(LibraryConfig) change,
  ) async {
    await _configRepo?.update(change);
  }

  @override
  Future<Workspace> get savedWorkspace async {
    final root = this.root;
    if (root == null) return Workspace.empty;
    return await WorkspaceStore(await appDatabase).load(root);
  }

  @override
  Future<void> saveWorkspace(Workspace workspace) async {
    final root = this.root;
    if (root == null) return;
    await WorkspaceStore(await appDatabase).save(root, workspace);
  }

  /// Whether the note editor shows the row-number column.
  @override
  Future<bool> get lineNumbersEnabled async => (await _library).lineNumbers;

  /// Sets (and persists) the editor line-numbers toggle.
  @override
  Future<void> setLineNumbersEnabled({required bool enabled}) async {
    _log.info('editor line numbers set to $enabled');
    await _editLibrary((c) => c.copyWith(lineNumbers: enabled));
  }

  @override
  Future<bool> get readableLineLength async =>
      (await _library).readableLineLength;

  @override
  Future<void> setReadableLineLength({required bool enabled}) async {
    _log.info('readable line length set to $enabled');
    await _editLibrary((c) => c.copyWith(readableLineLength: enabled));
  }

  @override
  Future<bool> get typewriter async => (await _library).typewriter;

  @override
  Future<void> setTypewriter({required bool enabled}) async {
    _log.info('typewriter mode set to $enabled');
    await _editLibrary((c) => c.copyWith(typewriter: enabled));
  }

  @override
  Future<double> get noteColumnWidth async => (await _library).noteColumnWidth;

  @override
  Future<void> setNoteColumnWidth(double width) async {
    _log.info('note column width set to $width');
    await _editLibrary(
      (c) => c.copyWith(noteColumnWidth: normalizeNoteColumnWidth(width)),
    );
  }

  /// Whether the note editor focuses (shows the keyboard) on note open.
  @override
  Future<bool> get editorAutofocusEnabled async =>
      (await _library).editorAutofocus;

  /// Sets (and persists) the keyboard-on-open toggle.
  @override
  Future<void> setEditorAutofocusEnabled({required bool enabled}) async {
    _log.info('editor keyboard-on-open set to $enabled');
    await _editLibrary((c) => c.copyWith(editorAutofocus: enabled));
  }

  /// Whether reminder text keeps the +project/@context/#tag markers.
  @override
  Future<bool> get reminderShowTokens async =>
      (await _library).reminderShowTokens;

  /// Sets (and persists) the reminder-markers toggle.
  @override
  Future<void> setReminderShowTokens({required bool enabled}) async {
    _log.info('reminder markers set to $enabled');
    await _editLibrary((c) => c.copyWith(reminderShowTokens: enabled));
  }

  /// The spell-check dictionary names, in selection order.
  @override
  Future<List<String>> get spellDictionaries async =>
      (await _library).spellDictionaries;

  /// Sets (and persists) the spell-check dictionaries.
  @override
  Future<void> setSpellDictionaries(List<String> names) async {
    _log.info(
      'spell-check dictionaries set to '
      '${names.isEmpty ? 'system' : names.join(', ')}',
    );
    await _editLibrary((c) => c.copyWith(spellDictionaries: names));
  }

  /// Which editor the library writes in (default source).
  @override
  Future<EditorKind> get editorKind async => (await _library).editorKind;

  /// Sets (and persists) the editor kind.
  @override
  Future<void> setEditorKind(EditorKind kind) async {
    _log.info('editor kind set to ${kind.name}');
    await _editLibrary((c) => c.copyWith(editorKind: kind));
  }

  /// Which editors the library offers (default both).
  @override
  Future<Set<EditorKind>> get enabledEditors async =>
      (await _library).enabledEditors;

  /// Sets (and persists) the enabled editors; an empty set is ignored.
  @override
  Future<void> setEnabledEditors(Set<EditorKind> editors) async {
    if (editors.isEmpty) {
      _log.info('enabled editors: empty set ignored');
      return;
    }
    _log.info('enabled editors set to ${editors.map((e) => e.name).join(',')}');
    await _editLibrary((c) => c.copyWith(enabledEditors: {...editors}));
  }

  /// Whether the preview exists at all (default true).
  @override
  Future<bool> get previewEnabled async => (await _library).previewEnabled;

  /// Sets (and persists) the preview switch.
  @override
  Future<void> setPreviewEnabled({required bool enabled}) async {
    _log.info('preview enabled set to $enabled');
    await _editLibrary((c) => c.copyWith(previewEnabled: enabled));
  }

  /// The preview layout mode.
  ///
  /// App-wide, with the split ratio: both follow the screen rather than
  /// the library, so carrying them in the library folder would move a
  /// tablet's layout onto a phone.
  @override
  Future<PreviewLayoutMode> get previewMode async =>
      await AppSettingsRepo(await appDatabase).previewMode();

  /// Sets (and persists) the preview layout mode.
  @override
  Future<void> setPreviewMode(PreviewLayoutMode mode) async {
    _log.info('preview mode set to ${mode.name}');
    await AppSettingsRepo(await appDatabase).setPreviewMode(mode);
  }

  /// The editor|preview split ratio.
  @override
  Future<double> get splitRatio async =>
      await AppSettingsRepo(await appDatabase).splitRatio();

  /// Sets (and persists) the split ratio.
  @override
  Future<void> setSplitRatio(double ratio) async {
    await AppSettingsRepo(await appDatabase).setSplitRatio(ratio);
  }

  /// The library tree sort order.
  @override
  Future<TreeSort> get treeSort async => (await _library).treeSort;

  /// Sets (and persists) the library tree sort order.
  @override
  Future<void> setTreeSort(TreeSort sort) async {
    await _editLibrary((c) => c.copyWith(treeSort: sort));
  }

  /// The tree pane's width in logical pixels.
  @override
  Future<double> get treeWidth async => (await _library).treeWidth;

  /// Sets (and persists) the tree pane's width.
  @override
  Future<void> setTreeWidth(double width) async {
    await _editLibrary((c) => c.copyWith(treeWidth: width));
  }

  /// Whether the tree's pinned section is rolled up.
  @override
  Future<bool> get pinnedCollapsed async => (await _library).pinnedCollapsed;

  /// Sets (and persists) the pinned section's rolled-up state.
  @override
  Future<void> setPinnedCollapsed({required bool collapsed}) async {
    await _editLibrary((c) => c.copyWith(pinnedCollapsed: collapsed));
  }

  /// The link format the editor's link button inserts.
  @override
  Future<LinkType> get linkType async => (await _library).linkType;

  /// Sets (and persists) the link format.
  @override
  Future<void> setLinkType(LinkType type) async {
    _log.info('link type set to ${type.name}');
    await _editLibrary((c) => c.copyWith(linkType: type));
  }

  /// Where a note created from a dead link lands.
  @override
  Future<MissingNoteLocation> get missingNoteLocation async =>
      (await _library).missingNoteLocation;

  /// Sets (and persists) the dead-link note location.
  @override
  Future<void> setMissingNoteLocation(MissingNoteLocation location) async {
    _log.info('missing note location set to ${location.name}');
    await _editLibrary((c) => c.copyWith(missingNoteLocation: location));
  }

  /// The editor's indent/outdent width in spaces.
  @override
  Future<int> get indentWidth async => (await _library).indentWidth;

  /// Sets (and persists) the indent/outdent width, clamped to its range.
  @override
  Future<void> setIndentWidth(int width) async {
    _log.info('indent width set to $width');
    await _editLibrary(
      (c) => c.copyWith(indentWidth: normalizeIndentWidth(width)),
    );
  }

  @override
  Future<int> get trashAutoEmptyDays async =>
      (await _library).trashAutoEmptyDays;

  @override
  Future<void> setTrashAutoEmptyDays(int days) async {
    _log.info('trash auto-empty set to $days day(s)');
    await _editLibrary(
      (c) => c.copyWith(trashAutoEmptyDays: normalizeTrashAutoEmptyDays(days)),
    );
  }

  @override
  Future<int> get historyVersions async => (await _library).historyVersions;

  @override
  Future<void> setHistoryVersions(int versions) async {
    _log.info('history versions set to $versions');
    await _editLibrary(
      (c) => c.copyWith(historyVersions: normalizeHistoryVersions(versions)),
    );
  }

  @override
  Future<int> get historyIntervalMinutes async =>
      (await _library).historyIntervalMinutes;

  @override
  Future<void> setHistoryIntervalMinutes(int minutes) async {
    _log.info('history interval set to $minutes min');
    await _editLibrary(
      (c) => c.copyWith(
        historyIntervalMinutes: normalizeHistoryIntervalMinutes(minutes),
      ),
    );
  }

  /// The stored editor-toolbar layout (empty = the shipped toolbar).
  @override
  Future<String> get editorToolbar async => (await _library).editorToolbar;

  /// Sets (and persists) the editor-toolbar layout.
  @override
  Future<void> setEditorToolbar(String layout) async {
    _log.info('editor toolbar set to "$layout"');
    await _editLibrary((c) => c.copyWith(editorToolbar: layout));
  }

  /// The interface text size.
  @override
  Future<double> get uiTextScale async => (await _library).uiTextScale;

  /// Sets (and persists) the interface text size, and puts it on screen.
  @override
  Future<void> setUiTextScale(double scale) async {
    final clamped = normalizeTextScale(scale);
    _log.info('interface text scale set to $clamped');
    await _editLibrary((c) => c.copyWith(uiTextScale: clamped));
    AppTextScales.ui = clamped;
  }

  /// The note text size.
  @override
  Future<double> get noteTextScale async => (await _library).noteTextScale;

  /// Sets (and persists) the note text size, and puts it on screen.
  @override
  Future<void> setNoteTextScale(double scale) async {
    final clamped = normalizeTextScale(scale);
    _log.info('note text scale set to $clamped');
    await _editLibrary((c) => c.copyWith(noteTextScale: clamped));
    AppTextScales.note = clamped;
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

  /// The keyboard shortcuts changed on this device (#159).
  @override
  Future<String?> get keyMap async =>
      await AppSettingsRepo(await appDatabase).keyMap();

  @override
  Future<void> setKeyMap(String json) async {
    _log.info('key map set');
    await AppSettingsRepo(await appDatabase).setKeyMap(json);
  }

  @override
  Future<String?> get pinnedCommands async =>
      await AppSettingsRepo(await appDatabase).pinnedCommands();

  @override
  Future<void> setPinnedCommands(String json) async {
    await AppSettingsRepo(await appDatabase).setPinnedCommands(json);
  }

  /// How bright the app is (T-M6-05).
  @override
  Future<AppBrightness> get themeBrightness async =>
      await AppSettingsRepo(await appDatabase).themeBrightness();

  /// Sets (and persists) the brightness choice.
  @override
  Future<void> setThemeBrightness(AppBrightness brightness) async {
    _log.info('theme brightness set to ${brightness.id}');
    await AppSettingsRepo(await appDatabase).setThemeBrightness(brightness);
  }

  /// The theme the app wears.
  ///
  /// A setting that points at a custom theme this installation no longer
  /// holds is repaired here, to Niman's own colors: there is always
  /// something to wear (issue #269).
  @override
  Future<AppTheme> get theme async {
    final settings = AppSettingsRepo(await appDatabase);
    final id = await settings.themeId();
    final customId = AppTheme.customIdIn(id);
    if (customId == null) return themeFromId(id);
    final custom = await CustomThemeRepo(await appDatabase).byId(customId);
    if (custom != null) return themeFromId(id, custom: custom);
    _log.warning('theme $id is gone; wearing Niman instead');
    await settings.setThemeId(AppPalette.niman.id);
    return const BuiltinAppTheme(AppPalette.niman);
  }

  /// Sets (and persists) the theme, by its id.
  @override
  Future<void> setTheme(AppTheme theme) async {
    _log.info('theme set to ${theme.id}');
    await AppSettingsRepo(await appDatabase).setThemeId(theme.id);
  }

  /// The custom themes this installation holds, by name (issue #269).
  @override
  Future<List<CustomTheme>> customThemes() async =>
      await CustomThemeRepo(await appDatabase).list();

  /// The custom theme with [id], or null.
  @override
  Future<CustomTheme?> customTheme(String id) async =>
      await CustomThemeRepo(await appDatabase).byId(id);

  /// Stores [theme]: the row with its id, or a new one.
  @override
  Future<void> saveCustomTheme(CustomTheme theme) async {
    _log.info('custom theme ${theme.id} saved as "${theme.name}"');
    await CustomThemeRepo(await appDatabase).save(theme);
  }

  /// Renames the custom theme with [id].
  @override
  Future<void> renameCustomTheme(String id, String name) async {
    _log.info('custom theme $id renamed to "$name"');
    await CustomThemeRepo(await appDatabase).rename(id, name);
  }

  /// Deletes the custom theme with [id], and returns the theme in force
  /// afterwards: deleting the one being worn falls back to the app's own
  /// colors.
  @override
  Future<AppTheme> deleteCustomTheme(String id) async {
    _log.info('custom theme $id deleted');
    await CustomThemeRepo(await appDatabase).delete(id);
    // Reading it back repairs a setting that pointed at the deleted
    // theme, so what comes out is what the app wears from here on.
    return await theme;
  }

  /// Whether [name] is a custom theme's name already.
  @override
  Future<bool> customThemeNameTaken(String name) async =>
      await CustomThemeRepo(await appDatabase).nameTaken(name);

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
    _updateScheduler?.stop();
    _updateScheduler = null;
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
    _configRepo = null;
    final sync = _sync;
    _sync = null;
    // A sync going now writes through the index about to close: its
    // triggers stop, and it gets a moment to finish.
    await sync?.close();
    // The text sizes belonged to the library that just went away; the
    // home screen is nobody's library and reads at the shipped sizes.
    AppTextScales.reset();
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
      // What changed behind the ops' back (another app, a background
      // isolate, a hand edit) reaches the sync queue this way.
      _sync?.watched(batch.paths, batch.resyncDirs);
    } on Object catch (error) {
      // Transient watcher errors are covered by the periodic rescan.
      _log.warning('watch batch failed: $error');
    }
  }

  /// Prepares the tree's first query off the critical path.
  Future<void> _warmUpTree(NoteDao dao) async {
    try {
      await dao.tree(const <String>[]);
    } on Object catch (error) {
      _log.debug('tree warm-up failed ($error)');
    }
  }

  /// Runs the automatic trash empty for a library that asked for one,
  /// and swallows whatever it runs into: the library is open and usable
  /// either way, and a trash that could not be emptied is not a reason to
  /// fail the open behind the user's back.
  Future<void> _autoEmptyTrash(NoteOperations ops, int days) async {
    if (days <= 0) return;
    try {
      await autoEmptyTrash(ops, maxAgeDays: days);
    } on Object catch (error) {
      _log.error('auto-empty failed: $error');
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
  return File(p.join(dir.path, 'niman.db'));
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
/// on disk are the source of truth, and `.niman/` is for what the user
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
    syncNetwork: ConnectivityNetworkMonitor.new,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
