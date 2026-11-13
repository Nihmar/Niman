import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/core/week_start.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/app_preferences.dart';
import 'package:niman/src/library/container_path.dart';
import 'package:niman/src/library/file_watcher.dart';
import 'package:niman/src/library/index_library_tree.dart';
import 'package:niman/src/library/index_progress_throttle.dart';
import 'package:niman/src/library/indexing_status.dart';
import 'package:niman/src/library/library_databases.dart';
import 'package:niman/src/library/library_index_files.dart';
import 'package:niman/src/library/library_open_chores.dart';
import 'package:niman/src/library/library_preferences.dart';
import 'package:niman/src/library/library_records.dart';
import 'package:niman/src/library/library_registry.dart';
import 'package:niman/src/library/library_sources.dart';
import 'package:niman/src/library/library_tree.dart';
import 'package:niman/src/library/library_widgets.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/open_library_preferences.dart';
import 'package:niman/src/library/open_library_settings.dart';
import 'package:niman/src/library/rescan_scheduler.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/library/session_events.dart';
import 'package:niman/src/library/session_themes.dart';
import 'package:niman/src/library/session_update_checks.dart';
import 'package:niman/src/library/stored_app_preferences.dart';
import 'package:niman/src/library/watch_batch_applier.dart';
import 'package:niman/src/library/watch_batch_queue.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/sync/network_monitor.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_probe.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/templates/repo.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/workspace/workspace_slot.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/library/library_databases.dart';

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
    this.watchSource,
    SyncSecretStore? syncSecrets,
    this.syncNetwork,
    this.syncProbe,
  }) : _searchDbFactory = searchDbFactory ?? indexDbFactory,
       syncSecrets = syncSecrets ?? SecureSyncSecretStore();

  /// Full-rescan fallback cadence: the watcher covers live changes, so the
  /// full walk is the safety net (a missed event, a network mount). One
  /// walk a minute cost 27-46 ms on a 901-entry library and scales with it
  /// (T-PP-22); five minutes keeps the net without the constant cost. It
  /// doubles as the M5 poll cadence.
  static const defaultRescanInterval = Duration(minutes: 5);

  /// The root path of the currently open library; null when no session is
  /// open. Set when a session opens, cleared on close.
  ///
  /// Nothing writes diagnostics here: a crash report carries the whole log
  /// buffer, the note and library paths and the sync host, so it goes to the
  /// app's private support folder instead — never into a library the sync
  /// walks and uploads (#383).
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

  /// Opens, repairs and deletes the libraries' index files.
  late final LibraryIndexFiles _indexFiles = LibraryIndexFiles(
    openDb: indexDbFactory,
    locate: indexFileOf,
  );

  /// The libraries this device knows and its records of each.
  late final LibraryRecords _known = LibraryRecords(
    appDatabase: () => appDatabase,
    syncSecrets: syncSecrets,
  );

  /// The home-screen widgets' records and the native library mirror.
  late final LibraryWidgets _widgets = LibraryWidgets(
    appDatabase: () => appDatabase,
    locateIndex: indexFileOf ?? libraryIndexFile,
  );

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

  /// Where the file watcher gets its raw changes; null is the OS watch.
  /// Tests inject a stream they drive, to end it at a moment they choose.
  final WatchSource? watchSource;

  /// Where each library's WebDAV password lives (M5); the OS secure
  /// storage unless a test injects another.
  final SyncSecretStore syncSecrets;

  /// Builds the network monitor the sync's automatic triggers read (the
  /// app passes `connectivity_plus`); null, as in tests, counts the
  /// network as always usable.
  final NetworkMonitor Function()? syncNetwork;

  /// Answers which watched paths still exist, for the sync's queue; null is
  /// the background-isolate probe. Tests inject one to hold an answer back.
  final ExistenceProbe? syncProbe;

  /// The revisions and the streams that announce them.
  final SessionEvents _changes = SessionEvents();
  final AppLogger _log = const AppLogger(name: 'session');

  /// The upkeep an open library gets behind its ready bump.
  static const _chores = LibraryOpenChores();

  /// The app's theme, the custom themes and the books' look on screen.
  late final SessionThemes _themes = SessionThemes(
    appDatabase: () => appDatabase,
    onCustomThemesChanged: _republishEpubLook,
  );
  LibraryPhase _phase = LibraryPhase.none;
  String? _root;
  String? _lastError;
  Future<void>? _resumeFuture;
  Future<AppDatabase>? _appDatabase;

  /// The open library's index; null while no library is open, and a
  /// different file for each library (T-ML-03).
  IndexDatabase? _indexDb;

  /// The open library's `.niman/settings.json` and the features it switches
  /// on; the shipped defaults while none is open.
  final OpenLibrarySettings _settings = OpenLibrarySettings();
  Indexer? _indexer;
  NoteOps? _ops;
  LibrarySyncService? _sync;
  FileWatcher? _watcher;

  /// The watcher's batches of the open library, run one at a time.
  WatchBatchQueue? _batches;

  /// What each of those batches does to the index, the editors and the sync.
  late final WatchBatchApplier _watchBatches = WatchBatchApplier(
    indexer: () => _indexer,
    root: () => _root,
    ready: () => phase == LibraryPhase.ready,
    walkWhole: _safeRescan,
    events: _changes,
    sync: () => _sync,
  );

  /// The full walks of the open library: one at a time, paced by how long
  /// the last took (#1067). Null while no library is open.
  RescanScheduler? _rescans;

  /// Whether the app is on screen; a hidden app runs no periodic walk.
  bool _foreground = true;

  /// Reconciliation scan pending after a non-blocking resume; cancelled in
  /// [_teardown] so a stale scan can never hit a different library.
  Timer? _reconcileTimer;

  /// How far the first index has got, or null when no scan is running.
  @override
  IndexProgress? get indexProgress => _progress.progress;

  /// The first index's progress, shown at a readable rate.
  late final IndexProgressThrottle _progress = IndexProgressThrottle(
    show: _bump,
  );

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
  int get revision => _changes.revision;

  /// Bumped after an index change that can move the tree's rows: a row
  /// added, removed or reshaped, a pin, a folder synced — not a save's new
  /// size and time, which only the field orders draw (#751).
  @override
  int get treeRevision => _changes.treeRevision;

  /// Fires with the new [revision] after every index change.
  @override
  Stream<int> get events => _changes.events;

  @override
  Set<int>? foldersMovedSince(int since, {required bool tree}) =>
      _changes.foldersMovedSince(since, tree: tree);

  /// Fires with the new [treeRevision] after a change that may move the
  /// tree's rows (#751).
  @override
  Stream<int> get treeEvents => _changes.treeEvents;

  /// Fires with the library-relative paths a re-index pruned from the tree.
  @override
  Stream<Set<String>> get removals => _changes.removals;

  @override
  Stream<Set<String>> get externalChanges => _changes.externalChanges;

  /// The app's settings database, opened once per session.
  ///
  /// Unlike the index it does not belong to a library: it holds the
  /// resume pointer, the language and the rest, and it is read before any
  /// library is open.
  Future<AppDatabase> get appDatabase {
    // Disposed, the controller opens nothing again: a late caller — a
    // rescan still running when the app or a test let it go — reopened the
    // settings file it had closed, and held it open from then on.
    if (_disposed) {
      return Future.error(StateError('the library controller is disposed'));
    }
    return _appDatabase ??= appDbFactory();
  }

  /// Whether [dispose] has run.
  bool _disposed = false;

  /// The search, the links and the other read surfaces of the open library.
  late final LibrarySources _sources = LibrarySources(
    root: () => _root,
    indexDb: () => _indexDb,
    indexer: () => _indexer,
    ops: () => _ops,
    searchDbFactory: _searchDbFactory,
    indexChanges: _changes.indexChanges,
  );

  /// CRUD ops for the open library, or null while closed.
  @override
  NoteOps? get ops => _ops;

  /// The open library's WebDAV sync, or null while closed.
  @override
  SyncService? get sync => _sync;

  /// The open library's tree, read from its index.
  @override
  late final LibraryTree tree = IndexLibraryTree(() => _indexDb);

  @override
  Future<SearchSource?> get searchSource => _sources.searchSource;

  @override
  Future<ReplaceSource?> get replaceSource => _sources.replaceSource;

  @override
  Future<TagSource?> get tagSource => _sources.tagSource;

  @override
  Future<FieldSource?> get fieldSource => _sources.fieldSource;

  @override
  Future<TemplateSource?> get templateSource => _sources.templateSource;

  @override
  Future<LibraryLinks?> get linkSource => _sources.linkSource;

  @override
  Future<WikilinkSuggester?> get wikilinkSuggester =>
      _sources.wikilinkSuggester;

  /// Resumes the last opened library (if it still exists). Best effort:
  /// safe to call repeatedly, no-op when no library has been opened yet.
  @override
  Future<void> resume() {
    _resumeFuture ??= _doResume();
    return _resumeFuture!;
  }

  Future<void> _doResume() async {
    try {
      final stored = await AppSettingsRepo(await appDatabase).lastLibraryPath();
      _log.info('resume: lastLibraryPath=$stored');
      if (stored == null) return;
      // An iPhone's container may have moved since: the library is the one
      // at the same place inside today's Documents.
      final documents = await containerDocuments();
      final last = documents == null
          ? stored
          : rebaseContainerPath(stored, documents);
      final dir = Directory(last);
      if (!await dir.exists()) {
        _log.warning('resume: root no longer exists: $last');
        return;
      }
      await open(last, create: false);
    } on Object catch (error) {
      // Resume is best effort; the open screen is reached with lastError.
      _log.error('resume failed: $error');
    }
  }

  /// Opens the library at [path]; with [create] true it is created first
  /// when missing.
  ///
  /// An index that has rows is shown at once: the library becomes ready from
  /// it and a reconciliation scan runs [resumeReconcileDelay] later, so
  /// external changes converge within seconds (the scan is a disk walk, so it
  /// must not gate the first frame) (#1073). One with no rows gets its tree
  /// first, and its notes are read behind it.
  @override
  Future<void> open(String path, {required bool create}) async {
    if (_phase != LibraryPhase.none) {
      throw StateError('A library is already open (phase: ${_phase.name})');
    }
    _phase = LibraryPhase.opening;
    _lastError = null;
    _bump();
    try {
      _log.info('open start: $path create=$create');
      final documents = await containerDocuments();
      final abs = documents == null
          ? p.normalize(path.trim())
          : rebaseContainerPath(path.trim(), documents);
      final rootDir = Directory(abs);
      if (create) {
        await rootDir.create(recursive: true);
      } else if (!await rootDir.exists()) {
        throw ArgumentError('Directory does not exist: $abs');
      }
      await _startSession(abs);
      _log.info('open complete: ready root=$abs, ${memoryNow()}');
    } on Object catch (error) {
      _log.error('open failed: $error');
      _lastError = '$error';
      _phase = LibraryPhase.none;
      _root = null;
      await _teardown();
      _bump();
    }
  }

  /// Sets a session up for the library at [abs]: the index, the indexer, the
  /// ops, the watcher and the sync.
  ///
  /// Shared by [open] and [rebuildIndex]: the first does the destination
  /// checks and sets the phase around it, the second runs it over an index
  /// file it has just deleted (#368).
  Future<void> _startSession(String abs) async {
    // This library's own index file (T-ML-03). Opening a second library
    // no longer scans over the first one's rows, so coming back to it
    // costs a reconciliation rather than a full walk.
    // [LibraryIndexFiles.open] also warms the connection's first query —
    // sqlite, the schema and its FTS table, on the connection's own
    // isolate — so a cold index does not pay for it inside the tree's first
    // flatten (`flatten: 105ms … [tree 103]`, #315), and it rebuilds a file
    // sqlite reports as damaged rather than leaving the library shut (#368).
    final indexDb = await _indexFiles.open(abs);
    _indexDb = indexDb;
    final appDb = await appDatabase;
    AppLog.enabled = await AppSettingsRepo(appDb).debugLogsEnabled();
    _updates.start(appDb);
    final config = await _settings.attach(
      abs,
      appDb,
      opening: _phase == LibraryPhase.opening,
    );
    final indexer = Indexer(indexDb);
    indexer
      ..onChanged = ((change) =>
          _changes.indexChanged(change, folders: indexer.changedFolders))
      ..onRemoved = (removed) => _onRemoved(abs, removed);
    final ops = NoteOps(
      root: abs,
      db: indexDb,
      indexer: indexer,
      config: config,
      // A home-screen note widget names its note by path, in the app's own
      // database: a rename or a move carries it too (#506).
      carryOutside: (from, to, {required isDir}) =>
          WidgetConfigStore(appDb).moved(abs, from, to, isDir: isDir),
    );
    // A library indexed for the first time opens on its tree, and its
    // notes are read behind it: the search, the tags and the links fill
    // in as they are read.
    //
    // Blocking or not: an index with no rows — a library never indexed
    // on this device, or one [LibraryIndexFiles.open] just rebuilt because
    // sqlite reported it damaged (#368) — has no last state for a fast
    // resume to show, and opening on it showed an empty library until the
    // delayed reconciliation. On an index that has rows this is one query and
    // writes nothing.
    final contentOwed = await indexer.indexTreeFirst(abs);
    final watcher = FileWatcher(
      abs,
      debounce: watcherDebounce,
      source: watchSource,
    );
    // One batch in flight, the ones that arrive meanwhile merged (#1062).
    final batches = WatchBatchQueue(_watchBatches.apply);
    _batches = batches;
    watcher.events.listen((batch) => unawaited(batches.add(batch)));
    await watcher.start();
    // Held so [_teardown] can stop it: an unheld watcher keeps its
    // recursive watch (and its event handling) alive for the whole
    // process, and every reopen adds another one.
    _watcher = watcher;
    _log.info('open: watcher started for $abs');
    final rescans = RescanScheduler(
      scan: () => indexer.fullScan(abs),
      minInterval: rescanInterval,
      watcherHealthy: () => watcher.healthy,
      onPeriodicError: (error, _) => unawaited(_onRescanFailed(abs, error)),
    )..setForeground(foreground: _foreground);
    _rescans = rescans;
    rescans.start();
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
      probe: syncProbe,
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
    AppTextScales.apply(ui: settings.uiTextScale, note: settings.noteTextScale);
    AppWeekStart.choice = settings.weekStart;
    await _themes.publishEpubLook(settings.epubLook);
    _phase = LibraryPhase.ready;
    currentRootPath = abs;
    // Warm the tree's first query while the caller still shows its
    // opening state: the first flatten otherwise paid drift's statement
    // preparation and SQLite's page cache right as the shell built
    // (78-118 ms in the log, T-PP-22).
    unawaited(_chores.warmUpTree(indexer.dao, settings.treeSort));
    await AppSettingsRepo(appDb).setLastLibraryPath(abs);
    // The list the home screen shows (T-ML-04). Opening is what puts a
    // folder on it, so a library the app has never seen needs no
    // registration step of its own.
    await LibraryRegistry(appDb).touch(abs);
    // The native widget config activity cannot read the registry (no
    // Dart engine at placement), so it reads this mirror instead.
    unawaited(_widgets.saveLibraryMirror(appDb));
    // Opening is when the trash empties itself, if the library asked
    // it to (issue #79) — behind the ready bump, because a folder full
    // of old deletions must not hold the library shut.
    unawaited(_chores.autoEmptyTrash(ops, settings.trashAutoEmptyDays));
    // And, like the trash empty, behind the ready bump: the temp files a
    // killed write left (issue #379) are swept on a background isolate so
    // a folder full of them never holds the library shut.
    unawaited(_chores.sweepStaleTemps(abs));
    // The history's upkeep (#1148) too: an old `.history/` moved in, the
    // versions packed into deltas, what no log names collected.
    unawaited(ops.history.maintain());
    _bump();
    // What a file from before the Home lacks (#671, #692) is built here,
    // with the reconciliation and behind the tree, not on open.
    _reconcileTimer = Timer(resumeReconcileDelay, () async {
      await _indexFiles.ensureDerived(indexDb);
      // A first index is a full walk already, running behind the tree.
      if (!contentOwed) await _safeRescan(abs);
    });
    if (contentOwed) unawaited(_indexContents(abs));
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
    await open(target, create: false);
  }

  /// The libraries the app knows about, most recently opened first.
  @override
  Future<List<KnownLibrary>> knownLibraries() => _known.all();

  /// The home-screen widget instances reading [libraryPath] (issue 6).
  @override
  Future<List<WidgetConfig>> widgetConfigsFor(String libraryPath) =>
      _widgets.configsFor(libraryPath);

  /// Records a placed todo widget for [libraryPath] (issue 6).
  @override
  Future<void> adoptTodoWidget(int androidWidgetId, String libraryPath) =>
      _widgets.adoptLibraryWidget(
        androidWidgetId,
        libraryPath,
        WidgetProvider.todo,
      );

  @override
  Future<void> adoptStudyWidget(int androidWidgetId, String libraryPath) =>
      _widgets.adoptLibraryWidget(
        androidWidgetId,
        libraryPath,
        WidgetProvider.study,
      );

  /// Records a placed note widget for [notePath] (issue 6).
  @override
  Future<void> adoptNoteWidget(
    int androidWidgetId,
    String libraryPath,
    String notePath,
  ) => _widgets.adoptNoteWidget(androidWidgetId, libraryPath, notePath);

  /// Drops [libraryPath]'s [provider] widget configurations whose
  /// instance is no longer placed (issue 6).
  @override
  Future<void> pruneWidgetConfigs({
    required String libraryPath,
    required WidgetProvider provider,
    required Set<int> placedIds,
  }) => _widgets.prune(
    libraryPath: libraryPath,
    provider: provider,
    placedIds: placedIds,
  );

  /// Drops [libraryPath] from the known list; the folder is untouched.
  ///
  /// The library on screen goes first (#286): the index it is reading is
  /// about to be deleted, and the shell would otherwise keep drawing a
  /// library the app no longer lists. The caller's unsaved guard still
  /// runs first — this close is the rule, not the place that saves.
  @override
  Future<void> forgetLibrary(String libraryPath) async {
    if (_root != null && p.normalize(libraryPath.trim()) == _root) {
      await close();
    }
    _log.info('forget library: $libraryPath');
    final db = await appDatabase;
    await _known.forget(db, libraryPath);
    // The mirror would otherwise keep offering a forgotten library.
    unawaited(_widgets.saveLibraryMirror(db));
    // The index is derived data and the entry that named it is gone, so
    // the file would sit there forever with nothing pointing at it.
    await _indexFiles.delete(libraryPath);
    _bump();
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
    return _rescans!.run();
  }

  /// Rebuilds the open library's index from disk (#368).
  ///
  /// The documented repair of an index (`AGENTS.md`): the file is deleted,
  /// and the notes are read again into the empty one opened in its place.
  /// Nothing outside the index moves — the registry row, the workspace
  /// (what was open in it), the per-device settings and the sync
  /// destination all stay — so repairing a damaged cache never costs the
  /// library.
  ///
  /// The session is rebuilt in place, not closed and reopened, so the
  /// library never leaves the screen; the phase a caller sees stays ready.
  /// A call that arrives while a rebuild runs joins it: the teardown and
  /// the delete happen once, and the fresh index the first is opening is
  /// not torn down and deleted under it (#493).
  @override
  Future<void> rebuildIndex() {
    final running = _rebuild;
    if (running != null) return running;
    final root = _root;
    if (root == null || _phase != LibraryPhase.ready) {
      return Future<void>.error(StateError('No library is open'));
    }
    final future = _rebuildFrom(root).whenComplete(() {
      _rebuild = null;
    });
    _rebuild = future;
    return future;
  }

  /// The one rebuild in flight, if any.
  Future<void>? _rebuild;

  Future<void> _rebuildFrom(String root) async {
    _log.info('rebuild index requested: $root');
    _lastError = null;
    await _teardown();
    await _indexFiles.delete(root);
    try {
      await _startSession(root);
      _log.info('rebuild index complete: ready root=$root');
    } on Object catch (error) {
      _log.error('rebuild index failed: $error');
      _lastError = '$error';
      _phase = LibraryPhase.none;
      _root = null;
      await _teardown();
    }
    _bump();
  }

  /// The app's own settings, in its database.
  @override
  late final AppPreferences appSettings = StoredAppPreferences(
    appDatabase: () => appDatabase,
    themes: _themes,
  );

  /// The launch + six-hourly update checks, started once per controller.
  late final SessionUpdateChecks _updates = SessionUpdateChecks(
    onUpdate: notify,
  );

  /// The latest available update the scheduler found, if any (issue #81).
  ///
  /// Read by the shell banner and the settings row; both rebuild on
  /// session events, which [SessionUpdateChecks.onUpdate] bumps.
  @override
  UpdateAvailable? get pendingUpdate => _updates.pending;

  /// Drops the pending update (the banner's dismiss action).
  @override
  void clearPendingUpdate() {
    _updates.clear();
    notify();
  }

  /// The open library's own settings, in its `.niman/settings.json`.
  @override
  late final LibraryPreferences librarySettings = OpenLibraryPreferences(
    _settings,
    _themes.publishEpubLook,
  );

  @override
  WorkspaceSlot get workspaceSlot {
    final root = this.root;
    return root == null
        ? const NoWorkspaceSlot()
        : StoredWorkspaceSlot(appDatabase, root);
  }

  /// Publishes the books' look again: a custom theme it may name was
  /// changed or deleted.
  Future<void> _republishEpubLook() async {
    if (_phase != LibraryPhase.ready) return;
    await _themes.publishEpubLook(await librarySettings.epubLook);
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
    _updates.stop();
    await close();
    _disposed = true;
    await _changes.close();
    final appDb = _appDatabase;
    _appDatabase = null;
    if (appDb != null) {
      final db = await appDb;
      await db.close();
      await forgetDefaultAppDatabase(db);
    }
  }

  /// A new revision — and a new tree revision when [tree] — which moved rows
  /// in [folders] alone, or anywhere when null ([foldersMovedSince]).
  void _bump({bool tree = true, Set<int>? folders}) =>
      _changes.bump(tree: tree, folders: folders);

  /// Fires with the paths a re-index pruned, and drops their reading
  /// positions and review states: those files are ones the library saw
  /// leave (#492, #533).
  void _onRemoved(String root, Set<String> removed) {
    if (removed.isEmpty || _changes.isClosed) return;
    _changes.removed(removed);
    unawaited(ReadingPositions(root).removed(removed));
    unawaited(ReviewStore(root).removed(removed));
  }

  /// Drops everything that belongs to the open library, the index file
  /// included: it is that library's own file (T-ML-03), so leaving it
  /// open would keep a connection — and, for the search connection, a
  /// worker isolate — per library ever opened this session.
  Future<void> _teardown() async {
    IndexingStatus.contentOwed.value = false;
    _rescans?.stop();
    _rescans = null;
    _batches?.close();
    _batches = null;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    final watcher = _watcher;
    _watcher = null;
    await watcher?.stop();
    _indexer = null;
    _ops?.history.dispose();
    _ops = null;
    _sources.forgetLinks();
    _settings.detach();
    final sync = _sync;
    _sync = null;
    // A sync going now writes through the index about to close: its
    // triggers stop, and it gets a moment to finish.
    await sync?.close();
    // The text sizes belonged to the library that just went away; the
    // home screen is nobody's library and reads at the shipped sizes.
    AppTextScales.reset();
    AppWeekStart.choice = WeekStart.system;
    EpubLooks.reset();
    // Nulled before the awaits: a caller that races us must not find a
    // half-closed database.
    final searchDb = _sources.releaseSearch();
    final indexDb = _indexDb;
    _indexDb = null;
    await searchDb?.close();
    await indexDb?.close();
  }

  /// Reads the notes of a library whose first index wrote the tree alone
  /// (`Indexer.indexTreeFirst`), once it is open.
  Future<void> _indexContents(String abs) async {
    final indexer = _indexer;
    if (indexer == null || phase != LibraryPhase.ready) return;
    try {
      _log.info('first index: reading the notes of $abs');
      // Reported while it runs: the walk is long enough to be worth
      // watching, and reporting costs a message per note.
      indexer.onProgress = _progress.report;
      IndexingStatus.contentOwed.value = true;
      try {
        await _rescans?.run();
      } finally {
        IndexingStatus.contentOwed.value = false;
        indexer.onProgress = null;
        _progress.end();
        _bump();
      }
      _log.info('first index complete');
    } on Object catch (error) {
      // The periodic rescan finds what is still missing and reads it.
      _log.error('first index failed: $error');
    }
  }

  Future<void> _safeRescan(String abs) async {
    final rescans = _rescans;
    if (rescans == null || phase != LibraryPhase.ready) return;
    try {
      _log.info('rescan start: $abs');
      await rescans.run();
      _log.info('rescan complete, ${memoryNow()}');
    } on Object catch (error) {
      await _onRescanFailed(abs, error);
    }
  }

  /// What a failed walk of [abs] leaves to do: nothing for a library that
  /// has gone, and a closed session for one whose folder has.
  Future<void> _onRescanFailed(String abs, Object error) async {
    _log.error('rescan failed: $error');
    // A rescan outliving its library — closed, switched, or the whole
    // controller disposed — has nothing left to close.
    if (_disposed || _root != abs) return;
    if (!await Directory(abs).exists()) {
      await close();
      _lastError = 'The library folder is no longer available.';
    }
  }

  /// Tells the session whether the app is on screen. A hidden app runs no
  /// periodic walk; coming back runs the one that fell due (#1067).
  @override
  void appVisibilityChanged({required bool visible}) {
    _foreground = visible;
    _rescans?.setForeground(foreground: visible);
  }
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

/// The first run's state (#266), over the app database: the welcome deck
/// reads it, the tour writes its progress back.
///
/// The seam a widget test overrides with a [MemoryWelcomeStore]; a test
/// bed with no application-support folder would otherwise fail opening
/// the database, which is why the welcome's readers tolerate a missing
/// store instead.
final welcomeStoreProvider = FutureProvider<WelcomeStore>((ref) async {
  return DbWelcomeStore(AppSettingsRepo(await defaultAppDatabase()));
});
