import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

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
    this.stage,
    this.done = 0,
    this.total = 0,
    this.lastReport,
  });

  /// The destination, or null when the library does not sync.
  final SyncDestination? destination;

  /// The stored probe result, or null when never probed.
  final WebDavCapabilities? capabilities;

  /// Whether a run is going.
  final bool running;

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
      (aborted != null && aborted != SyncAbort.notConfirmed);

  /// A copy with the given fields replaced.
  SyncStatus copyWith({
    SyncDestination? destination,
    bool clearDestination = false,
    WebDavCapabilities? capabilities,
    bool clearCapabilities = false,
    bool? running,
    SyncStage? stage,
    int? done,
    int? total,
    SyncReport? lastReport,
    bool clearReport = false,
  }) => SyncStatus(
    destination: clearDestination ? null : destination ?? this.destination,
    capabilities: clearCapabilities ? null : capabilities ?? this.capabilities,
    running: running ?? this.running,
    stage: (running ?? this.running) ? stage ?? this.stage : null,
    done: done ?? this.done,
    total: total ?? this.total,
    lastReport: clearReport ? null : lastReport ?? this.lastReport,
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
}

/// [SyncService] over a real [SyncEngine].
final class LibrarySyncService extends ChangeNotifier implements SyncService {
  /// The service for the library at [root].
  new({
    required this.root,
    required this.engine,
    required this.store,
    required this.secrets,
    WebDavClient Function(Uri url, String username, String password)?
    testClientFactory,
    DateTime Function()? now,
  }) : _testClient = testClientFactory ?? _defaultTestClient,
       _now = now ?? DateTime.now;

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
  }

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
    await load();
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
  }

  @override
  Future<SyncReport> syncNow({SyncConfirm? confirm}) async {
    _set(_status.copyWith(running: true, stage: SyncStage.connecting));
    try {
      final report = await engine.run(
        confirm: confirm,
        onProgress: (stage, done, total) =>
            _set(_status.copyWith(stage: stage, done: done, total: total)),
      );
      if (report.changedLocally.isNotEmpty && !_changes.isClosed) {
        _changes.add(Set.unmodifiable(report.changedLocally));
      }
      _set(
        _status.copyWith(running: false, done: 0, total: 0, lastReport: report),
      );
      return report;
    } finally {
      if (_status.running) _set(_status.copyWith(running: false));
      await load();
    }
  }

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

  @override
  void dispose() {
    _disposed = true;
    unawaited(_changes.close());
    super.dispose();
  }
}
