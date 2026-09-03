import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/library/file_watcher.dart';
import 'package:copist/src/library/note_ops.dart';
import 'package:copist/src/library/session.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  /// Creates the controller; [dbFactory] is invoked lazily on first use.
  LibraryController(
    this.dbFactory, {
    this.rescanInterval = defaultRescanInterval,
    this.resumeReconcileDelay = defaultResumeReconcileDelay,
    this.watcherDebounce = FileWatcher.defaultDebounce,
  });

  /// Full-rescan fallback cadence (~60 s); doubles as the M5 poll cadence.
  static const defaultRescanInterval = Duration(seconds: 60);

  /// Default delay between a non-blocking resume becoming ready and its
  /// reconciliation scan, leaving the UI time to paint the tree first.
  static const defaultResumeReconcileDelay = Duration(milliseconds: 1000);

  /// Builds the database on demand (app-support location in the app).
  final Future<CopistDatabase> Function() dbFactory;

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
  Future<CopistDatabase>? _database;
  Indexer? _indexer;
  NoteOps? _ops;
  FileWatcher? _watcher;
  Timer? _rescanTimer;
  /// Reconciliation scan pending after a non-blocking resume; cancelled in
  /// [_teardown] so a stale scan can never hit a different library.
  Timer? _reconcileTimer;

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

  /// The session database; completes when the first library is opened.
  Future<CopistDatabase> get database => _database ??= dbFactory();

  /// CRUD ops for the open library, or null while closed.
  @override
  NoteOps? get ops => _ops;

  /// Children of the row with id [parentId] (0 = library root),
  /// directories first, then by name.
  @override
  Future<List<Note>> children(int parentId) async {
    final db = await database;
    return NoteDao(db).children(parentId);
  }

  /// Every indexed folder, path-ordered (for move-target pickers).
  @override
  Future<List<Note>> folders() async {
    final db = await database;
    return NoteDao(db).folders();
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
      final db = await dbFactory();
      final last = await AppSettingsRepo(db).lastLibraryPath();
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
      final db = await dbFactory();
      AppLog.enabled = await AppSettingsRepo(db).debugLogsEnabled();
      final indexer = Indexer(db)..
        onChanged = _bump;
      final ops = NoteOps(root: abs, db: db, indexer: indexer);
      if (blockingScan) {
        await indexer.fullScan(abs);
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
      await AppSettingsRepo(db).setLastLibraryPath(abs);
      _bump();
      if (!blockingScan) {
        _reconcileTimer =
            Timer(resumeReconcileDelay, () => _safeRescan(abs));
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
    try {
      final db = await dbFactory();
      await AppSettingsRepo(db).setLastLibraryPath(null);
    } on Object catch (_) {
      // Settings unavailable; nothing else to clear.
    }
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
    return indexer.fullScan(root);
  }

  /// Whether the in-app debug log buffer records events.
  @override
  Future<bool> get debugLogsEnabled async {
    final db = await database;
    final enabled = await AppSettingsRepo(db).debugLogsEnabled();
    AppLog.enabled = enabled;
    return enabled;
  }

  /// Sets (and persists) the debug log recording toggle.
  @override
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    _log.info('debug logging set to $enabled');
    final db = await database;
    await AppSettingsRepo(db).setDebugLogsEnabled(enabled: enabled);
    AppLog.enabled = enabled;
  }

  /// Notifies listeners that state changed without an index mutation
  /// (e.g. a settings change the tree UI should react to).
  @override
  void notify() => _bump();

  /// Closes the session and releases resources; call exactly once.
  @override
  Future<void> dispose() async {
    await close();
    if (!_events.isClosed) {
      await _events.close();
    }
  }

  void _bump() {
    _revision++;
    if (!_events.isClosed) {
      _events.add(_revision);
    }
  }

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

/// Creates the app database in the platform application-support directory.
///
/// The index lives OUTSIDE the library folder: it is a cache, and files are
/// the source of truth.
Future<CopistDatabase> defaultCopistDatabase() async {
  final dir = await getApplicationSupportDirectory();
  return CopistDatabase(NativeDatabase(File(p.join(dir.path, 'copist.db'))));
}

/// The single library session for the app session.
///
/// Typed as the [LibrarySession] interface so the UI (and widget tests,
/// which substitute an in-memory fake) never depends on the concrete
/// [LibraryController].
final librarySessionProvider = Provider<LibrarySession>((ref) {
  final controller = LibraryController(defaultCopistDatabase);
  ref.onDispose(controller.dispose);
  return controller;
});
