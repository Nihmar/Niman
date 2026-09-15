import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/network_monitor.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_scheduler.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/sync/sync_scheduler.dart' show SyncPause;

/// How a connection test ended (mockups S3, S3b).
enum SyncTestOutcome {
  /// The folder is a usable WebDAV collection.
  ok,

  /// The address is not a valid `http(s)://host/…` URL, or carries
  /// credentials.
  invalidUrl,

  /// No answer (network, VPN, timeout).
  offline,

  /// 401 / 403.
  authentication,

  /// The folder does not exist.
  notFound,

  /// The server answers but is not WebDAV, or refuses what sync needs.
  unsupported,

  /// Anything else (a TLS failure, an unexpected answer).
  failed,
}

/// The result of [SyncService.testConnection].
@immutable
final class SyncTestResult {
  /// A test that ended with [outcome].
  const new({
    required this.outcome,
    this.capabilities,
    this.elapsedMs = 0,
    this.detail = '',
  });

  /// How it ended.
  final SyncTestOutcome outcome;

  /// What the server can do, when [outcome] is [SyncTestOutcome.ok].
  final WebDavCapabilities? capabilities;

  /// How long the probe took.
  final int elapsedMs;

  /// Technical detail for the log and a secondary line; never a secret.
  final String detail;

  /// Whether the folder can be used.
  bool get ok => outcome == SyncTestOutcome.ok;
}

/// What the UI shows about a library's sync.
@immutable
final class SyncStatus {
  /// A status; the defaults describe a library without sync.
  const new({
    this.destination,
    this.capabilities,
    this.running = false,
    this.background = false,
    this.stage,
    this.done = 0,
    this.total = 0,
    this.lastReport,
    this.pendingHints = 0,
    this.nextRetryAt,
    this.autoPaused,
    this.waitingForNetwork = false,
  });

  /// The destination, or null when the library does not sync.
  final SyncDestination? destination;

  /// The stored probe result, or null when never probed.
  final WebDavCapabilities? capabilities;

  /// Whether a run is going.
  final bool running;

  /// Whether the running sync started by itself (no progress strip).
  final bool background;

  /// Changes queued and not uploaded yet.
  final int pendingHints;

  /// When the queue or the automatic sync tries again, or null.
  final DateTime? nextRetryAt;

  /// Why the automatic sync stopped until the user acts, or null.
  final SyncPause? autoPaused;

  /// Whether the automatic sync waits for Wi-Fi (or any network).
  final bool waitingForNetwork;

  /// The running stage, while [running].
  final SyncStage? stage;

  /// Decisions applied so far, while applying.
  final int done;

  /// Decisions in the plan, while applying.
  final int total;

  /// The latest run of this session, or null before one.
  final SyncReport? lastReport;

  /// Whether the library has a destination.
  bool get configured => destination != null;

  /// The last clean sync, or null.
  DateTime? get lastSyncAt {
    final ms = destination?.lastSyncAtMs;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// The stored error of the latest run, or null.
  String? get lastError => destination?.lastError;

  /// Why the latest run of this session stopped, if it did.
  SyncAbort? get aborted => lastReport?.aborted;

  /// Conflicts the latest run left, still unresolved.
  List<SyncConflict> get conflicts => lastReport?.conflicts ?? const [];

  /// Paths that failed in the latest run.
  List<({String path, String error})> get failures =>
      lastReport?.failures ?? const [];

  /// Whether the status has something the user should look at.
  bool get needsAttention =>
      conflicts.isNotEmpty ||
      failures.isNotEmpty ||
      autoPaused != null ||
      (aborted != null && aborted != SyncAbort.notConfirmed);

  /// A copy with the given fields replaced.
  SyncStatus copyWith({
    SyncDestination? destination,
    bool clearDestination = false,
    WebDavCapabilities? capabilities,
    bool clearCapabilities = false,
    bool? running,
    bool? background,
    SyncStage? stage,
    int? done,
    int? total,
    SyncReport? lastReport,
    bool clearReport = false,
    int? pendingHints,
    DateTime? nextRetryAt,
    bool clearRetry = false,
    SyncPause? autoPaused,
    bool clearPause = false,
    bool? waitingForNetwork,
  }) => SyncStatus(
    destination: clearDestination ? null : destination ?? this.destination,
    capabilities: clearCapabilities ? null : capabilities ?? this.capabilities,
    running: running ?? this.running,
    background: (running ?? this.running) && (background ?? this.background),
    stage: (running ?? this.running) ? stage ?? this.stage : null,
    done: done ?? this.done,
    total: total ?? this.total,
    lastReport: clearReport ? null : lastReport ?? this.lastReport,
    pendingHints: pendingHints ?? this.pendingHints,
    nextRetryAt: clearRetry ? null : nextRetryAt ?? this.nextRetryAt,
    autoPaused: clearPause ? null : autoPaused ?? this.autoPaused,
    waitingForNetwork: waitingForNetwork ?? this.waitingForNetwork,
  );
}

/// A library's sync, as the UI drives it (mockups S1–S11): configure,
/// test, run, resolve. Listeners hear every status change.
abstract interface class SyncService implements Listenable {
  /// The current status.
  SyncStatus get status;

  /// Local paths a run or a resolution just changed (an open note among
  /// them has to be re-read).
  Stream<Set<String>> get localChanges;

  /// Reads the stored destination into [status].
  Future<void> load();

  /// Probes the folder at [url] with [username] and [password] (null uses
  /// the stored password). Stores nothing.
  Future<SyncTestResult> testConnection({
    required String url,
    required String username,
    String? password,
  });

  /// Stores the destination: [password] null keeps the stored one, empty
  /// removes it; [capabilities] from the test just run. A different URL
  /// or user makes the next sync a first sync.
  Future<void> save({
    required String url,
    required String username,
    String? password,
    WebDavCapabilities? capabilities,
  });

  /// Forgets the destination, the sync state and the password; no file is
  /// touched on either side.
  Future<void> disconnect();

  /// Runs a sync now. [confirm] is asked before a first sync and a plan
  /// that looks like a mass deletion.
  Future<SyncReport> syncNow({SyncConfirm? confirm});

  /// Both texts of a conflicted [path]; throws [SyncFailure].
  Future<({String local, String remote})> conflictTexts(String path);

  /// Keeps one whole side of a conflicted [path]; throws [SyncFailure].
  Future<void> resolveConflict(String path, {required bool keepLocal});

  /// Whether the "Wi-Fi only" option means anything on this device.
  bool get offersWifiOnly;

  /// Changes the automatic trigger options of the destination.
  Future<void> setTriggers({
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  });

  /// The app came back to the foreground.
  void appResumed();

  /// The app went to the background.
  void appBackgrounded();
}

/// [SyncService] over a real [SyncEngine], with its [SyncScheduler].
final class LibrarySyncService extends ChangeNotifier implements SyncService {
  /// The service for the library at [root].
  ///
  /// [network] and [phone] go to the scheduler; [start] starts it.
  new({
    required this.root,
    required this.engine,
    required this.store,
    required this.secrets,
    NetworkMonitor? network,
    this.phone = false,
    WebDavClient Function(Uri url, String username, String password)?
    testClientFactory,
    DateTime Function()? now,
    Duration quickDelay = const Duration(seconds: 5),
  }) : _testClient = testClientFactory ?? _defaultTestClient,
       _now = now ?? DateTime.now {
    scheduler = SyncScheduler(
      run: ({required quick}) => _runEngine(quick: quick, background: true),
      triggers: _triggers,
      hasDueHints: () async => (await store.dueOps(root)).isNotEmpty,
      retryNow: () => store.retryNow(root),
      network: network,
      phone: phone,
      onChanged: () => unawaited(_refreshQueue()),
      now: _now,
      quickDelay: quickDelay,
    );
  }

  /// Whether this is a phone (Wi-Fi only, background rules).
  final bool phone;

  /// Starts the automatic syncs.
  late final SyncScheduler scheduler;

  /// Absolute, normalized library root.
  final String root;

  /// The engine that runs and resolves.
  final SyncEngine engine;

  /// The sync state.
  final SyncStore store;

  /// Where the password is.
  final SyncSecretStore secrets;

  final WebDavClient Function(Uri, String, String) _testClient;
  final DateTime Function() _now;
  final StreamController<Set<String>> _changes =
      StreamController<Set<String>>.broadcast();
  bool _disposed = false;

  static const _log = AppLogger(name: 'sync');

  static WebDavClient _defaultTestClient(
    Uri url,
    String username,
    String password,
  ) => WebDavClient(url: url, username: username, password: password);

  SyncStatus _status = const SyncStatus();

  @override
  SyncStatus get status => _status;

  @override
  Stream<Set<String>> get localChanges => _changes.stream;

  void _set(SyncStatus next) {
    _status = next;
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> load() async {
    final destination = await store.destination(root);
    final capabilities = destination == null
        ? null
        : WebDavCapabilities.decode(destination.capabilities);
    _set(
      _status.copyWith(
        destination: destination,
        clearDestination: destination == null,
        capabilities: capabilities,
        clearCapabilities: capabilities == null,
      ),
    );
    await _refreshQueue();
  }

  /// Loads the status and starts the automatic syncs.
  Future<void> start() async {
    await load();
    if (_disposed) return;
    await scheduler.start();
  }

  Future<SyncTriggers?> _triggers() async {
    final row = await store.destination(root);
    if (row == null) return null;
    return SyncTriggers(
      enabled: row.enabled,
      autoSync: row.autoSync,
      intervalSeconds: row.intervalSeconds,
      wifiOnly: row.wifiOnly,
      everSynced: row.lastSyncAtMs != null,
    );
  }

  /// Re-reads the queue and the scheduler's state into [status].
  Future<void> _refreshQueue() async {
    if (_disposed) return;
    final pending = await store.pendingOps(root);
    final queueRetry = await store.nextRetryAt(root);
    if (_disposed) return;
    final backoff = scheduler.backoffUntil;
    final retry = backoff != null && backoff.isAfter(_now())
        ? backoff
        : queueRetry;
    final destination = _status.destination;
    final waiting =
        destination != null &&
        destination.autoSync &&
        !scheduler.networkAllows(SyncTriggers(wifiOnly: destination.wifiOnly));
    _set(
      _status.copyWith(
        pendingHints: pending.length,
        nextRetryAt: retry,
        clearRetry: retry == null,
        autoPaused: scheduler.paused,
        clearPause: scheduler.paused == null,
        waitingForNetwork: waiting,
      ),
    );
  }

  static const _pathSeparator = '/';

  /// Queues a hint from `NoteOps` and tells the scheduler.
  void hint(String path, SyncOpKind kind, {String? fromPath}) {
    if (_disposed || !_inScope(path)) return;
    unawaited(
      store.enqueue(root, path, kind, fromPath: fromPath).then(
        (_) {
          scheduler.hinted();
          return _refreshQueue();
        },
        onError: (Object e) =>
            _log.warning('queue: hint for "$path" not stored: $e'),
      ),
    );
  }

  /// Queues hints for what the file watcher saw: [paths] changed (or
  /// vanished), [folders] need a look as a whole. Echoes of the sync's
  /// own writes are dropped.
  void watched(List<String> paths, List<String> folders) {
    if (_disposed || _status.destination == null) return;
    var queued = 0;
    for (final abs in {...paths, ...folders}) {
      final rel = _relative(abs);
      if (rel == null || rel.isEmpty || !_inScope(rel)) continue;
      if (engine.ops.changedBySync(rel)) continue;
      final exists = File(abs).existsSync() || Directory(abs).existsSync();
      hint(rel, exists ? SyncOpKind.changed : SyncOpKind.deleted);
      queued++;
    }
    if (queued > 0) _log.debug('queue: $queued hints from the watcher');
  }

  String? _relative(String abs) {
    final rel = p.relative(p.normalize(abs), from: root);
    if (rel == '.') return '';
    if (rel.startsWith('..') || p.isAbsolute(rel)) return null;
    return p.split(rel).join(_pathSeparator);
  }

  /// Whether [path] can concern the sync: a syncable file, or a folder
  /// outside the dot folders.
  static bool _inScope(String path) =>
      isSyncablePath(path) ||
      !path.split(_pathSeparator).any((s) => s.startsWith('.'));

  /// The URL in [text], or null with the reason for the log.
  static ({Uri? url, String reason}) parseUrl(String text) {
    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return (url: null, reason: 'not a URL');
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return (url: null, reason: 'needs http:// or https://');
    }
    if (uri.host.isEmpty) return (url: null, reason: 'no host');
    if (uri.userInfo.isNotEmpty) {
      return (url: null, reason: 'credentials in the address');
    }
    return (url: uri, reason: '');
  }

  @override
  Future<SyncTestResult> testConnection({
    required String url,
    required String username,
    String? password,
  }) async {
    final parsed = parseUrl(url);
    final uri = parsed.url;
    if (uri == null) {
      _log.info('test: invalid address (${parsed.reason})');
      return SyncTestResult(
        outcome: SyncTestOutcome.invalidUrl,
        detail: parsed.reason,
      );
    }
    final secret = password ?? await secrets.read(root) ?? '';
    final clock = Stopwatch()..start();
    _log.info(
      'test: ${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}'
      '${uri.path}, ${username.isEmpty ? 'no user' : 'user set'}, '
      '${password == null ? 'stored password' : 'typed password'}',
    );
    final client = _testClient(uri, username.trim(), secret);
    try {
      final capabilities = await probeWebDav(client, now: _now);
      final result = SyncTestResult(
        outcome: SyncTestOutcome.ok,
        capabilities: capabilities,
        elapsedMs: clock.elapsedMilliseconds,
      );
      _log.info('test: ok in ${result.elapsedMs} ms');
      return result;
    } on WebDavFailure catch (e) {
      final outcome = switch (e) {
        WebDavAuthFailure() => SyncTestOutcome.authentication,
        WebDavNotFound() => SyncTestOutcome.notFound,
        WebDavUnsupported() => SyncTestOutcome.unsupported,
        WebDavRetryable() => SyncTestOutcome.offline,
        WebDavPrecondition() ||
        WebDavProtocolFailure() => SyncTestOutcome.failed,
      };
      _log.warning('test: ${outcome.name}: ${e.message}');
      return SyncTestResult(
        outcome: outcome,
        elapsedMs: clock.elapsedMilliseconds,
        detail: e.message,
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<void> save({
    required String url,
    required String username,
    String? password,
    WebDavCapabilities? capabilities,
  }) async {
    final uri = parseUrl(url).url;
    if (uri == null) throw ArgumentError('Not a usable address');
    final previous = _status.destination;
    await store.saveDestination(
      libraryPath: root,
      url: uri,
      username: username.trim(),
      enabled: previous?.enabled ?? true,
      autoSync: previous?.autoSync ?? true,
      intervalSeconds: previous?.intervalSeconds ?? 60,
      wifiOnly: previous?.wifiOnly ?? false,
    );
    if (password != null) {
      if (password.isEmpty) {
        await secrets.delete(root);
      } else {
        await secrets.write(root, password);
      }
    }
    if (capabilities != null) await store.setCapabilities(root, capabilities);
    scheduler.clearPause();
    await load();
    await scheduler.settingsChanged();
  }

  @override
  Future<void> disconnect() async {
    _log.info('disconnect $root');
    await store.removeLibrary(root);
    try {
      await secrets.delete(root);
    } on Exception catch (e) {
      _log.warning('disconnect: password not deleted: $e');
    }
    _set(const SyncStatus());
    await scheduler.settingsChanged();
  }

  @override
  Future<SyncReport> syncNow({SyncConfirm? confirm}) async {
    await scheduler.manualRunStarting();
    final report = await _runEngine(
      quick: false,
      background: false,
      confirm: confirm,
    );
    scheduler.runFinished(report);
    await _refreshQueue();
    return report;
  }

  /// Runs going, and how many of them the user started.
  int _runs = 0;
  int _manualRuns = 0;

  Future<SyncReport> _runEngine({
    required bool quick,
    required bool background,
    SyncConfirm? confirm,
  }) async {
    _runs++;
    if (!background) _manualRuns++;
    _set(
      _status.copyWith(
        running: true,
        background: _manualRuns == 0,
        stage: _status.running ? null : SyncStage.connecting,
      ),
    );
    try {
      final report = await engine.run(
        quick: quick,
        confirm: confirm,
        onProgress: (stage, done, total) =>
            _set(_status.copyWith(stage: stage, done: done, total: total)),
      );
      if (report.changedLocally.isNotEmpty && !_changes.isClosed) {
        _changes.add(Set.unmodifiable(report.changedLocally));
      }
      final idle = _runs == 1;
      _set(
        _status.copyWith(
          running: !idle,
          done: idle ? 0 : null,
          total: idle ? 0 : null,
          lastReport: _reportToShow(report),
        ),
      );
      return report;
    } finally {
      _runs--;
      if (!background) _manualRuns--;
      if (_runs == 0 && _status.running) {
        _set(_status.copyWith(running: false));
      } else if (_runs > 0) {
        _set(_status.copyWith(background: _manualRuns == 0));
      }
      await load();
    }
  }

  /// What the panel shows after [report]: a quick sync that had nothing
  /// to do keeps the previous result, and one that ran keeps the earlier
  /// conflicts it did not look at.
  SyncReport? _reportToShow(SyncReport report) {
    final previous = _status.lastReport;
    if (!report.quick || previous == null) return report;
    if (report.plan == null && report.aborted == null) return previous;
    final looked = {
      for (final d in report.plan?.decisions ?? const <SyncDecision>[]) d.path,
      for (final c in report.conflicts) c.path,
    };
    report.conflicts.addAll(
      previous.conflicts.where((c) => !looked.contains(c.path)),
    );
    return report;
  }

  @override
  bool get offersWifiOnly => phone;

  @override
  Future<void> setTriggers({
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  }) async {
    await store.setTriggers(
      root,
      autoSync: autoSync,
      intervalSeconds: intervalSeconds,
      wifiOnly: wifiOnly,
    );
    await load();
    await scheduler.settingsChanged();
  }

  @override
  void appResumed() => scheduler.resumed();

  @override
  void appBackgrounded() => scheduler.backgrounded();

  @override
  Future<({String local, String remote})> conflictTexts(String path) =>
      engine.conflictTexts(path);

  @override
  Future<void> resolveConflict(String path, {required bool keepLocal}) async {
    await engine.resolveConflict(path, keepLocal: keepLocal);
    final report = _status.lastReport;
    report?.conflicts.removeWhere((c) => c.path == path);
    if (!keepLocal && !_changes.isClosed) _changes.add({path});
    await load();
    _set(_status.copyWith());
  }

  /// Stops the triggers and waits, up to [wait], for a run that is going
  /// (the library's databases close next).
  Future<void> close({Duration wait = const Duration(seconds: 10)}) async {
    dispose();
    try {
      await engine.idle.timeout(wait);
    } on TimeoutException {
      _log.warning('close: a sync still runs after ${wait.inSeconds}s');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    scheduler.dispose();
    unawaited(_changes.close());
    super.dispose();
  }
}
