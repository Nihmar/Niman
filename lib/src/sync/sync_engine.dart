import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

/// A path both sides changed differently, left untouched for the merge
/// (docs/dev/sync.md, "Conflicts").
@immutable
final class SyncConflict {
  /// A conflict at [path].
  const new({
    required this.path,
    required this.localSha256,
    required this.remoteSha256,
    this.baseVersion,
  });

  /// The library-relative path.
  final String path;

  /// The local content's sha256.
  final String localSha256;

  /// The remote content's sha256.
  final String remoteSha256;

  /// The pinned history version both came from, when there is one.
  final int? baseVersion;

  @override
  String toString() => 'conflict $path (base ${baseVersion ?? 'none'})';
}

/// Why a run stopped before carrying out its plan.
enum SyncAbort {
  /// The library has no destination.
  notConfigured,

  /// The destination needs a password and none is stored.
  missingPassword,

  /// The server refused the credentials.
  authentication,

  /// The server could not be reached (or went away mid-run).
  offline,

  /// The remote folder does not exist.
  remoteMissing,

  /// The folder is not a usable WebDAV collection.
  unsupported,

  /// The plan deletes too much, or it is a first sync, and the caller did
  /// not confirm it.
  notConfirmed,

  /// Something else went wrong before any file was touched.
  failed,
}

/// What a run did.
final class SyncReport {
  /// How many decisions of each kind were carried out.
  final Map<SyncActionKind, int> done = {};

  /// Paths left for the merge.
  final List<SyncConflict> conflicts = [];

  /// Paths that failed, with the reason; retried on the next run.
  final List<({String path, String error})> failures = [];

  /// Paths skipped because they changed while the run was going.
  final List<String> skipped = [];

  /// The plan the run carried out (the last hashing pass).
  SyncPlan? plan;

  /// Why the run stopped early, or null when it ran to the end.
  SyncAbort? aborted;

  /// Detail for [aborted], safe to show.
  String? abortDetail;

  /// Whether the run reached the end with nothing failed or left over.
  bool get clean => aborted == null && failures.isEmpty && conflicts.isEmpty;

  /// One line for the log.
  String summary() {
    if (aborted != null) return 'aborted: ${aborted!.name} ($abortDetail)';
    final parts = [
      for (final entry in done.entries) '${entry.key.name} ${entry.value}',
      if (conflicts.isNotEmpty) '${conflicts.length} conflicts',
      if (skipped.isNotEmpty) '${skipped.length} skipped',
      if (failures.isNotEmpty) '${failures.length} failed',
    ];
    return parts.isEmpty ? 'nothing to do' : parts.join(', ');
  }
}

/// Asked before a plan runs when it is a first sync or looks like a mass
/// deletion; true carries it out.
typedef SyncConfirm = Future<bool> Function(
  SyncPlan plan, {
  required bool firstSync,
});

/// Carries out sync runs for one library (docs/dev/sync.md): scans both
/// sides, plans with `reconcile.dart`, and applies the plan through
/// [NoteOps] locally and a [WebDavClient] remotely, recording what both
/// sides agreed on in [SyncStore].
///
/// One run at a time per engine; a second call while one is going gets
/// the same run. Every step is logged under `sync`.
final class SyncEngine {
  /// An engine for the library at [root].
  ///
  /// [clientFactory] builds the client for the destination (tests point it
  /// at a fake server or shorten timeouts); [now] is the device clock for
  /// history snapshots and rows.
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this.secrets,
    WebDavClient Function(SyncDestination destination, String password)?
    clientFactory,
    DateTime Function()? now,
  }) : _clientFactory = clientFactory ?? _defaultClient,
       _now = now ?? DateTime.now;

  /// Absolute path of the library root (as stored: normalized).
  final String root;

  /// The library's operations: downloads, trash and moves go through them.
  final NoteOps ops;

  /// The sync state.
  final SyncStore store;

  /// Where the password is.
  final SyncSecretStore secrets;

  final WebDavClient Function(SyncDestination, String) _clientFactory;
  final DateTime Function() _now;

  static const _log = AppLogger(name: 'sync');

  /// How many hashing passes a run makes before giving up on the paths
  /// still waiting for one.
  static const _hashPasses = 3;

  Future<SyncReport>? _running;

  static WebDavClient _defaultClient(
    SyncDestination destination,
    String password,
  ) => WebDavClient(
    url: Uri.parse(destination.url),
    username: destination.username,
    password: password,
  );

  /// Runs a full sync. [confirm] is asked before a first sync and before a
  /// plan that looks like a mass deletion; without it a first sync goes
  /// ahead (it never deletes) and a mass deletion is refused.
  Future<SyncReport> run({SyncConfirm? confirm}) {
    final running = _running;
    if (running != null) {
      _log.info('run: already running for $root, joining it');
      return running;
    }
    final next = _run(confirm).whenComplete(() => _running = null);
    _running = next;
    return next;
  }

  Future<SyncReport> _run(SyncConfirm? confirm) async {
    final clock = Stopwatch()..start();
    final report = SyncReport();
    _log.info('run: start for $root');
    final destination = await store.destination(root);
    if (destination == null) {
      return await _finish(
        report,
        SyncAbort.notConfigured,
        'no destination',
        clock,
      );
    }
    final password = await secrets.read(root) ?? '';
    if (destination.username.isNotEmpty && password.isEmpty) {
      return await _finish(
        report,
        SyncAbort.missingPassword,
        'no password stored',
        clock,
      );
    }
    final client = _clientFactory(destination, password);
    try {
      await _runWith(client, destination, report, confirm);
    } on WebDavAuthFailure catch (e) {
      _abort(report, SyncAbort.authentication, e.message);
    } on WebDavNotFound catch (e) {
      _abort(report, SyncAbort.remoteMissing, e.message);
    } on WebDavUnsupported catch (e) {
      _abort(report, SyncAbort.unsupported, e.message);
    } on WebDavRetryable catch (e) {
      _abort(report, SyncAbort.offline, e.message);
    } on WebDavFailure catch (e) {
      _abort(report, SyncAbort.failed, e.message);
    } on FileSystemException catch (e) {
      _abort(report, SyncAbort.failed, 'local: ${e.message} (${e.path})');
    } finally {
      client.close();
    }
    return await _finish(report, report.aborted, report.abortDetail, clock);
  }

  void _abort(SyncReport report, SyncAbort why, String detail) {
    report
      ..aborted = why
      ..abortDetail = detail;
  }

  Future<SyncReport> _finish(
    SyncReport report,
    SyncAbort? why,
    String? detail,
    Stopwatch clock,
  ) async {
    if (why != null) _abort(report, why, detail ?? why.name);
    final error = report.aborted != null
        ? '${report.aborted!.name}: ${report.abortDetail}'
        : report.failures.isNotEmpty
        ? '${report.failures.length} files failed, '
              'first: ${report.failures.first.path}: '
              '${report.failures.first.error}'
        : null;
    if (report.aborted != SyncAbort.notConfigured) {
      await store.recordSyncResult(root, error: error);
    }
    final line =
        'run: done for $root in ${clock.elapsedMilliseconds} ms: '
        '${report.summary()}';
    if (report.clean) {
      _log.info(line);
    } else {
      _log.warning(line);
    }
    return report;
  }

  Future<void> _runWith(
    WebDavClient client,
    SyncDestination destination,
    SyncReport report,
    SyncConfirm? confirm,
  ) async {
    final capabilities = await _capabilities(client, destination);

    final scanClock = Stopwatch()..start();
    final local = await _scanLocal(root);
    final localMs = scanClock.elapsedMilliseconds;
    final remoteScan = await _scanRemote(client);
    final remote = remoteScan.files;
    final rows = await store.items(root);
    _log.info(
      'scan: ${local.length} local files ($localMs ms), '
      '${remote.length} remote files in ${remoteScan.folders.length} '
      'folders (${scanClock.elapsedMilliseconds - localMs} ms), '
      '${rows.length} agreed rows',
    );

    final localSha = <String, String>{};
    final remoteSha = <String, String>{};
    var plan = planSync(
      local: local,
      remote: remote,
      rows: rows,
      capabilities: capabilities,
    );
    for (var pass = 1; plan.needsHashes && pass <= _hashPasses; pass++) {
      await _hash(client, plan, localSha, remoteSha);
      plan = planSync(
        local: local,
        remote: remote,
        rows: rows,
        capabilities: capabilities,
        localSha256: localSha,
        remoteSha256: remoteSha,
      );
    }
    report.plan = plan;
    _log.info(
      'plan: ${plan.summary()} (${plan.destructiveCount} destructive of '
      '${plan.rowCount} rows)',
    );

    final firstSync = rows.isEmpty && destination.lastSyncAtMs == null;
    if (plan.looksLikeMassDeletion ||
        (firstSync && plan.decisions.isNotEmpty)) {
      final approved = confirm == null
          ? !plan.looksLikeMassDeletion
          : await confirm(plan, firstSync: firstSync);
      _log.info(
        'plan: ${plan.looksLikeMassDeletion ? 'mass deletion' : 'first sync'}'
        ' ${approved ? 'confirmed' : 'not confirmed'}',
      );
      if (!approved) {
        _abort(
          report,
          SyncAbort.notConfirmed,
          plan.looksLikeMassDeletion
              ? 'would remove ${plan.destructiveCount} files'
              : 'first sync not confirmed',
        );
        return;
      }
    }

    final context = _RunContext(
      client: client,
      capabilities: capabilities,
      local: local,
      remote: remote,
      rows: rows,
      localSha: localSha,
      remoteSha: remoteSha,
      folders: remoteScan.folders,
      report: report,
    );
    for (final decision in plan.decisions) {
      final clock = Stopwatch()..start();
      try {
        final outcome = await _apply(context, decision);
        switch (outcome) {
          case _Outcome.done:
            report.done.update(decision.kind, (n) => n + 1, ifAbsent: () => 1);
            _log.info('apply: $decision (${clock.elapsedMilliseconds} ms)');
          case _Outcome.skipped:
            report.skipped.add(decision.path);
          case _Outcome.conflict:
            break;
        }
      } on WebDavAuthFailure {
        rethrow;
      } on WebDavRetryable catch (e) {
        if (e.status == null) rethrow; // the network: everything will fail
        _failed(report, decision, e.message);
      } on WebDavFailure catch (e) {
        _failed(report, decision, e.message);
      } on FileSystemException catch (e) {
        _failed(report, decision, 'local: ${e.message}');
      } on _StepFailure catch (e) {
        _failed(report, decision, e.message);
      }
    }
  }

  void _failed(SyncReport report, SyncDecision decision, String error) {
    report.failures.add((path: decision.path, error: error));
    _log.warning(
      'apply failed: ${decision.kind.name} ${decision.path}: $error',
    );
  }

  // --- capabilities ---------------------------------------------------

  Future<WebDavCapabilities> _capabilities(
    WebDavClient client,
    SyncDestination destination,
  ) async {
    final stored = WebDavCapabilities.decode(destination.capabilities);
    if (stored != null && !stored.isStale(_now())) {
      _log.debug('capabilities: stored, ${stored.describe()}');
      return stored;
    }
    _log.info(
      'capabilities: ${stored == null ? 'never probed' : 'stale'}, probing',
    );
    final probed = await probeWebDav(client, now: _now);
    await store.setCapabilities(root, probed);
    return probed;
  }

  // --- scanning -------------------------------------------------------

  static Future<Map<String, LocalFileState>> _scanLocal(String root) =>
      Isolate.run(() => scanLocalFiles(root));

  Future<({Map<String, WebDavResource> files, Set<String> folders})>
  _scanRemote(WebDavClient client) async {
    final files = <String, WebDavResource>{};
    final folders = <String>{''};
    final queue = [''];
    while (queue.isNotEmpty) {
      final folder = queue.removeLast();
      for (final item in await client.list(folder)) {
        if (item.isCollection) {
          if (_descends(item.path)) {
            folders.add(item.path);
            queue.add(item.path);
          }
        } else if (isSyncablePath(item.path)) {
          files[item.path] = item;
        }
      }
    }
    return (files: files, folders: folders);
  }

  // --- hashing --------------------------------------------------------

  Future<void> _hash(
    WebDavClient client,
    SyncPlan plan,
    Map<String, String> localSha,
    Map<String, String> remoteSha,
  ) async {
    final clock = Stopwatch()..start();
    final localPaths = [
      for (final d in plan.decisions)
        if (d.kind == SyncActionKind.hashLocal) d.path,
    ];
    if (localPaths.isNotEmpty) {
      localSha.addAll(await _hashLocal(root, localPaths));
    }
    final remotePaths = [
      for (final d in plan.decisions)
        if (d.kind == SyncActionKind.hashRemote) d.path,
    ];
    for (final path in remotePaths) {
      try {
        final download = await client.download(path, _DiscardSink());
        remoteSha[path] = download.sha256;
      } on WebDavNotFound {
        // Gone since the listing: it stays unhashed and fails as a path,
        // not as a missing destination.
        _log.info('hash: remote $path vanished since the listing');
      }
    }
    _log.info(
      'hash: ${localPaths.length} local, ${remotePaths.length} remote '
      '(${clock.elapsedMilliseconds} ms)',
    );
  }

  static Future<Map<String, String>> _hashLocal(
    String root,
    List<String> paths,
  ) => Isolate.run(() => hashLocalFiles(root, paths));

  // --- applying -------------------------------------------------------

  Future<_Outcome> _apply(_RunContext c, SyncDecision d) async {
    switch (d.kind) {
      case SyncActionKind.nothing:
        return _Outcome.done;
      case SyncActionKind.hashLocal:
      case SyncActionKind.hashRemote:
        throw const _StepFailure(
          'still waiting for a hash after $_hashPasses passes',
        );
      case SyncActionKind.upload:
        return await _upload(c, d);
      case SyncActionKind.download:
        return await _download(c, d);
      case SyncActionKind.deleteRemote:
        return await _deleteRemote(c, d);
      case SyncActionKind.trashLocal:
        return await _trashLocal(c, d);
      case SyncActionKind.dropRow:
        await store.removeItems(root, [d.path]);
        return _Outcome.done;
      case SyncActionKind.record:
        return await _record(c, d);
      case SyncActionKind.conflict:
        return await _conflict(c, d);
      case SyncActionKind.moveRemote:
        return await _moveRemote(c, d);
      case SyncActionKind.moveLocal:
        return await _moveLocal(c, d);
    }
  }

  /// The file at [path] still is what the scan saw (both absent counts).
  Future<LocalFileState?> _localStillAsPlanned(
    _RunContext c,
    String path,
  ) async {
    final now = await _stat(path);
    final planned = c.local[path];
    final same = now == null
        ? planned == null
        : planned != null &&
              planned.size == now.size &&
              planned.mtimeMs == now.mtimeMs;
    if (!same) throw const _ChangedDuringSync();
    return now;
  }

  Future<LocalFileState?> _stat(String path) async {
    final stat = await FileStat.stat(p.join(root, path));
    if (stat.type != FileSystemEntityType.file) return null;
    return LocalFileState(
      size: stat.size,
      mtimeMs: stat.modified.millisecondsSinceEpoch,
    );
  }

  /// The remote still is what the scan saw, checked with a PROPFIND when
  /// the write has no precondition to guard it.
  Future<void> _remoteStillAsPlanned(_RunContext c, SyncDecision d) async {
    if (!d.checkRemoteFirst) return;
    final path = d.fromPath ?? d.path;
    final now = await c.client.stat(path);
    final planned = c.remote[path];
    final same = now == null
        ? planned == null
        : planned != null &&
              now.etag == planned.etag &&
              now.size == planned.size &&
              now.modified == planned.modified;
    if (!same) throw const _ChangedDuringSync();
  }

  String _localShaOf(_RunContext c, String path) {
    final sha =
        c.local[path]?.sha256 ?? c.localSha[path] ?? c.rows[path]?.localSha256;
    if (sha == null) throw _StepFailure('no hash for $path');
    return sha;
  }

  /// Whether a listing of [modified] cannot rule out a second write within
  /// the same second: no file ETags, and the mtime is the server's current
  /// second (or the server sends no clock at all).
  bool _unverified(_RunContext c, DateTime? modified) {
    if (c.capabilities.fileEtags) return false;
    final serverNow = c.client.serverDate;
    if (modified == null || serverNow == null) return true;
    return serverNow.difference(modified).inMilliseconds < 2000;
  }

  Future<SyncItem> _row(
    _RunContext c,
    String path, {
    required String sha,
    required LocalFileState local,
    required WebDavResource remote,
    int? baseVersion,
    bool pinBase = true,
  }) async {
    var base = baseVersion;
    if (pinBase) {
      try {
        base = await ops.pinSyncBase(path, sha);
      } on Object catch (e) {
        _log.warning('sync base "$path" not pinned: $e');
      }
    }
    return SyncItem(
      libraryPath: root,
      path: path,
      localSha256: sha,
      localSize: local.size,
      localMtimeMs: local.mtimeMs,
      remoteEtag: remote.etag,
      remoteSize: remote.size ?? local.size,
      remoteMtimeMs: remote.modified?.millisecondsSinceEpoch ?? 0,
      remoteUnverified: _unverified(c, remote.modified),
      remoteFileId: remote.fileId,
      baseVersion: base,
      syncedAtMs: _now().millisecondsSinceEpoch,
    );
  }

  Future<_Outcome> _guarded(Future<_Outcome> Function() action) async {
    try {
      return await action();
    } on _ChangedDuringSync {
      return _Outcome.skipped;
    }
  }

  Future<_Outcome> _upload(_RunContext c, SyncDecision d) => _guarded(() async {
    final local = (await _localStillAsPlanned(c, d.path))!;
    await _remoteStillAsPlanned(c, d);
    final sha = _localShaOf(c, d.path);
    await _ensureRemoteParent(c, d.path);
    await c.client.uploadFile(
      d.path,
      File(p.join(root, d.path)),
      ifMatch: d.ifMatch,
      ifNoneMatch: d.ifNoneMatch,
      modified: DateTime.fromMillisecondsSinceEpoch(local.mtimeMs),
    );
    final remote = await c.client.stat(d.path);
    if (remote == null) {
      throw const _StepFailure('uploaded but not listed');
    }
    await store.putItems([
      await _row(c, d.path, sha: sha, local: local, remote: remote),
    ]);
    return _Outcome.done;
  });

  Future<void> _ensureRemoteParent(_RunContext c, String path) async {
    final slash = path.lastIndexOf('/');
    if (slash < 0) return;
    final parent = path.substring(0, slash);
    if (c.folders.contains(parent)) return;
    await c.client.createFolders(parent);
    var folder = parent;
    while (folder.isNotEmpty) {
      c.folders.add(folder);
      final up = folder.lastIndexOf('/');
      folder = up < 0 ? '' : folder.substring(0, up);
    }
  }

  /// GETs [path] into a temp file next to its target; returns it with the
  /// response's metadata. The temp file is removed on failure.
  Future<({File temp, WebDavDownload download})> _fetch(
    _RunContext c,
    String path,
  ) async {
    final target = p.join(root, path);
    await Directory(p.dirname(target)).create(recursive: true);
    final temp = File(
      p.join(
        p.dirname(target),
        '.${p.basename(target)}.niman-tmp-sync-'
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      final download = await c.client.download(path, temp.openWrite());
      // The client already checked Content-Length. A chunked answer has none,
      // so compare with the listing too — unless the ETag says the file was
      // rewritten since, which makes a different size legitimate.
      final listed = c.remote[path];
      final expected = listed?.size;
      final rewritten = download.etag != null && download.etag != listed?.etag;
      if (expected != null && download.bytes != expected && !rewritten) {
        throw WebDavProtocolFailure(
          'GET $path: ${download.bytes} bytes, the listing said $expected',
        );
      }
      return (temp: temp, download: download);
    } on Object {
      if (temp.existsSync()) await temp.delete();
      rethrow;
    }
  }

  WebDavResource _remoteFrom(
    _RunContext c,
    String path,
    WebDavDownload download,
  ) {
    final listed = c.remote[path];
    return WebDavResource(
      path: path,
      isCollection: false,
      etag: download.etag ?? listed?.etag,
      size: download.bytes,
      modified: download.modified ?? listed?.modified,
      fileId: listed?.fileId,
    );
  }

  Future<_Outcome> _download(_RunContext c, SyncDecision d) => _guarded(
    () async {
      final fetched = await _fetch(c, d.path);
      try {
        await _localStillAsPlanned(c, d.path);
      } on Object {
        if (fetched.temp.existsSync()) await fetched.temp.delete();
        rethrow;
      }
      await ops.syncReplace(d.path, fetched.temp.path);
      final local = await _stat(d.path);
      if (local == null) throw const _StepFailure('downloaded but not on disk');
      await store.putItems([
        await _row(
          c,
          d.path,
          sha: fetched.download.sha256,
          local: local,
          remote: _remoteFrom(c, d.path, fetched.download),
        ),
      ]);
      return _Outcome.done;
    },
  );

  Future<_Outcome> _deleteRemote(_RunContext c, SyncDecision d) =>
      _guarded(() async {
        await _localStillAsPlanned(c, d.path);
        await _remoteStillAsPlanned(c, d);
        await c.client.delete(d.path, ifMatch: d.ifMatch);
        await store.removeItems(root, [d.path]);
        return _Outcome.done;
      });

  Future<_Outcome> _trashLocal(_RunContext c, SyncDecision d) =>
      _guarded(() async {
        await _localStillAsPlanned(c, d.path);
        await ops.syncTrash(d.path);
        await store.removeItems(root, [d.path]);
        return _Outcome.done;
      });

  Future<_Outcome> _record(_RunContext c, SyncDecision d) => _guarded(() async {
    final local = (await _localStillAsPlanned(c, d.path))!;
    final sha = _localShaOf(c, d.path);
    final row = c.rows[d.path];
    final remote = c.remote[d.path]!;
    final contentChanged = row == null || row.localSha256 != sha;
    await store.putItems([
      await _row(
        c,
        d.path,
        sha: sha,
        local: local,
        remote: remote,
        baseVersion: row?.baseVersion,
        pinBase: contentChanged,
      ),
    ]);
    return _Outcome.done;
  });

  Future<_Outcome> _conflict(
    _RunContext c,
    SyncDecision d,
  ) => _guarded(() async {
    final local = (await _localStillAsPlanned(c, d.path))!;
    final localSha = _localShaOf(c, d.path);
    final fetched = await _fetch(c, d.path);
    final remote = _remoteFrom(c, d.path, fetched.download);
    final remoteSha = fetched.download.sha256;

    if (remoteSha == localSha) {
      await fetched.temp.delete();
      await store.putItems([
        await _row(c, d.path, sha: localSha, local: local, remote: remote),
      ]);
      _log.info('conflict ${d.path}: same content on both sides, recorded');
      return _Outcome.done;
    }

    if (d.path.startsWith('.niman/')) {
      // Settings and counters are JSON: a line merge could break them,
      // so the newer side wins whole.
      final remoteMs = remote.modified?.millisecondsSinceEpoch ?? 0;
      if (remoteMs > local.mtimeMs) {
        await _localStillAsPlanned(c, d.path);
        await ops.syncReplace(d.path, fetched.temp.path);
        final after = (await _stat(d.path))!;
        await store.putItems([
          await _row(c, d.path, sha: remoteSha, local: after, remote: remote),
        ]);
        _log.info('conflict ${d.path}: remote is newer, taken');
      } else {
        await fetched.temp.delete();
        await c.client.uploadFile(
          d.path,
          File(p.join(root, d.path)),
          ifMatch: c.capabilities.ifMatch ? remote.etag : null,
        );
        final listed = await c.client.stat(d.path);
        if (listed == null) throw const _StepFailure('uploaded but not listed');
        await store.putItems([
          await _row(c, d.path, sha: localSha, local: local, remote: listed),
        ]);
        _log.info('conflict ${d.path}: local is newer, uploaded');
      }
      return _Outcome.done;
    }

    await fetched.temp.delete();
    final conflict = SyncConflict(
      path: d.path,
      localSha256: localSha,
      remoteSha256: remoteSha,
      baseVersion: d.baseVersion,
    );
    c.report.conflicts.add(conflict);
    _log.warning(
      'conflict ${d.path}: both changed (local ${_short(localSha)}, '
      'remote ${_short(remoteSha)}, base ${d.baseVersion ?? 'none'}); '
      'left for the merge',
    );
    return _Outcome.conflict;
  });

  Future<_Outcome> _moveRemote(_RunContext c, SyncDecision d) =>
      _guarded(() async {
        final from = d.fromPath!;
        final local = (await _localStillAsPlanned(c, d.path))!;
        await _localStillAsPlanned(c, from);
        await _remoteStillAsPlanned(c, d);
        await _ensureRemoteParent(c, d.path);
        try {
          await c.client.move(from, d.path);
        } on WebDavUnsupported {
          // The probe said MOVE works; it does not any more. Probe again on
          // the next run, and let it plan DELETE + PUT.
          await store.setCapabilities(
            root,
            WebDavCapabilities.fromJson({
                  ...c.capabilities.toJson(),
                  'move': false,
                }) ??
                c.capabilities,
          );
          rethrow;
        }
        await store.moveItems(root, from, d.path);
        final remote = await c.client.stat(d.path);
        if (remote == null) throw const _StepFailure('moved but not listed');
        final row = c.rows[from]!;
        await store.putItems([
          await _row(
            c,
            d.path,
            sha: row.localSha256,
            local: local,
            remote: remote,
            baseVersion: row.baseVersion,
            pinBase: false,
          ),
        ]);
        return _Outcome.done;
      });

  Future<_Outcome> _moveLocal(_RunContext c, SyncDecision d) =>
      _guarded(() async {
        final from = d.fromPath!;
        await _localStillAsPlanned(c, from);
        await _localStillAsPlanned(c, d.path);
        await ops.syncMove(from, d.path);
        await store.moveItems(root, from, d.path);
        final local = await _stat(d.path);
        if (local == null) throw const _StepFailure('moved but not on disk');
        final row = c.rows[from]!;
        await store.putItems([
          await _row(
            c,
            d.path,
            sha: row.localSha256,
            local: local,
            remote: c.remote[d.path]!,
            baseVersion: row.baseVersion,
            pinBase: false,
          ),
        ]);
        return _Outcome.done;
      });
}

enum _Outcome { done, skipped, conflict }

/// Thrown inside an action when a side no longer looks like the plan: the
/// path is skipped and the next run decides again.
final class _ChangedDuringSync implements Exception {
  const new();
}

/// A step that cannot complete (nothing listed after an upload, a hash
/// still missing); the path is reported as failed.
final class _StepFailure implements Exception {
  const new(this.message);

  final String message;
}

final class _RunContext {
  new({
    required this.client,
    required this.capabilities,
    required this.local,
    required this.remote,
    required this.rows,
    required this.localSha,
    required this.remoteSha,
    required this.folders,
    required this.report,
  });

  final WebDavClient client;
  final WebDavCapabilities capabilities;
  final Map<String, LocalFileState> local;
  final Map<String, WebDavResource> remote;
  final Map<String, SyncItem> rows;
  final Map<String, String> localSha;
  final Map<String, String> remoteSha;
  final Set<String> folders;
  final SyncReport report;
}

final class _DiscardSink implements StreamConsumer<List<int>> {
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<void> close() async {}
}

String _short(String sha) => sha.length <= 8 ? sha : sha.substring(0, 8);

/// Whether a folder at library-relative [path] is walked: not a dot
/// folder, except `.niman` at the root (for its two synced files).
bool _descends(String path) {
  if (path == '.niman') return true;
  return !path.split('/').any((s) => s.startsWith('.'));
}

/// Every syncable file under [root], with size and mtime (no hashes).
///
/// Top-level so `Isolate.run` can take it. Symlinks are not followed.
Future<Map<String, LocalFileState>> scanLocalFiles(String root) async {
  final files = <String, LocalFileState>{};
  final queue = [''];
  while (queue.isNotEmpty) {
    final folder = queue.removeLast();
    final dir = Directory(folder.isEmpty ? root : p.join(root, folder));
    await for (final entity in dir.list(followLinks: false)) {
      final name = p.basename(entity.path);
      final rel = folder.isEmpty ? name : '$folder/$name';
      if (entity is Directory) {
        if (_descends(rel)) queue.add(rel);
      } else if (entity is File && isSyncablePath(rel)) {
        final stat = entity.statSync();
        files[rel] = LocalFileState(
          size: stat.size,
          mtimeMs: stat.modified.millisecondsSinceEpoch,
        );
      }
    }
  }
  return files;
}

/// The sha256 of each of [paths] under [root], streamed; a file that
/// vanished is left out.
///
/// Top-level so `Isolate.run` can take it.
Future<Map<String, String>> hashLocalFiles(
  String root,
  List<String> paths,
) async {
  final hashes = <String, String>{};
  for (final path in paths) {
    final file = File(p.join(root, path));
    if (!file.existsSync()) continue;
    hashes[path] = (await sha256.bind(file.openRead()).first).toString();
  }
  return hashes;
}
