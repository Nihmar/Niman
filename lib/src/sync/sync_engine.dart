import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/diff/record_merge.dart';
import 'package:niman/src/diff/three_way.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/sync/conflict_texts.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/state_merge.dart';
import 'package:niman/src/sync/sync_conflict.dart';
import 'package:niman/src/sync/sync_failure.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_step_failure.dart';
import 'package:niman/src/sync/sync_step_outcome.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:path/path.dart' as p;

/// Asked before a plan runs when it is a first sync or looks like a mass
/// deletion; true carries it out.
typedef SyncConfirm = Future<bool> Function(
  SyncPlan plan, {
  required bool firstSync,
});

/// Where a run is, for a progress indicator.
enum SyncStage {
  /// Reading the destination, probing the server when needed.
  connecting,

  /// Listing both sides.
  scanning,

  /// Hashing and planning.
  comparing,

  /// Carrying out the plan; comes with done / total.
  applying,
}

/// Reports a run's [stage] and, while applying, [done] of [total].
typedef SyncProgress = void Function(SyncStage stage, int done, int total);

/// What a call to `SyncEngine.run` got: the run's `report`, and `joined` —
/// true when the call joined a run that was already going, which is settled
/// by the caller that started it (#391).
typedef SyncRun = ({SyncReport report, bool joined});

/// Carries out sync runs for one library (docs/records/sync.md): scans both
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

  /// Reads, checks and records both sides of a path.
  late final _sides = SyncSides(root: root, ops: ops, store: store, now: _now);

  static const _log = AppLogger(name: 'sync');

  /// How many hashing passes a run makes before giving up on the paths
  /// still waiting for one.
  static const _hashPasses = 3;

  Future<SyncRun>? _running;
  bool _runningQuick = false;

  /// Runs and conflict resolutions go one at a time.
  Future<void> _lock = Future<void>.value();

  /// Completes when the run or resolution going now (if any) and those
  /// already waiting have finished.
  Future<void> get idle => _lock;

  Future<T> _exclusively<T>(Future<T> Function() body) {
    final next = _lock.then((_) => body());
    _lock = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// The destination and a client for it; throws [SyncFailure] when the
  /// library has none or its password is missing.
  Future<({SyncDestination destination, WebDavClient client})>
  _connect() async {
    final destination = await store.destination(root);
    if (destination == null) {
      throw const SyncFailure(SyncAbort.notConfigured, 'no destination');
    }
    final password = await secrets.read(root) ?? '';
    if (destination.username.isNotEmpty && password.isEmpty) {
      throw const SyncFailure(SyncAbort.missingPassword, 'no password stored');
    }
    return (
      destination: destination,
      client: _clientFactory(destination, password),
    );
  }

  static WebDavClient _defaultClient(
    SyncDestination destination,
    String password,
  ) => WebDavClient(
    url: Uri.parse(destination.url),
    username: destination.username,
    password: password,
    // The certificate the user confirmed for this destination, if any:
    // the device state that makes a self-signed server usable (#454).
    trustedCertificateFingerprint: destination.trustedCertFingerprint,
  );

  /// Runs a sync. [confirm] is asked before a first sync and before a plan
  /// that looks like a mass deletion; without it a first sync goes ahead
  /// (it never deletes) and a mass deletion is refused. [onProgress] hears
  /// the stages and, while applying, the count.
  ///
  /// A full sync walks both trees; a [quick] one reconciles only the
  /// paths of the queued hints that are due (docs/records/sync.md, "Queue and
  /// triggers"), refuses to be a first sync, and leaves local trashing
  /// and moves to the next full sync. Either settles the hints it read:
  /// done when their paths reconciled, backing off when not.
  ///
  /// A call while a full run goes joins it, as does a quick call while a
  /// quick run goes; a full call while a quick run goes waits for it and
  /// then runs. The result says whether this call joined a run already
  /// going: one run is settled once, by the caller that started it, and a
  /// joined call only reads the report.
  Future<SyncRun> run({
    SyncConfirm? confirm,
    SyncProgress? onProgress,
    bool quick = false,
  }) {
    final running = _running;
    if (running != null && (!_runningQuick || quick)) {
      _log.info(
        'run: a ${_runningQuick ? 'quick' : 'full'} run is going for $root, '
        'joining it',
      );
      return running.then((run) => (report: run.report, joined: true));
    }
    late final Future<SyncRun> next;
    next = _exclusively(() => _run(confirm, onProgress, quick: quick))
        .then((report) => (report: report, joined: false))
        .whenComplete(() {
          if (identical(_running, next)) _running = null;
        });
    _running = next;
    _runningQuick = quick;
    return next;
  }

  Future<SyncReport> _run(
    SyncConfirm? confirm,
    SyncProgress? onProgress, {
    required bool quick,
  }) async {
    final clock = Stopwatch()..start();
    final report = SyncReport()..quick = quick;
    final pending = quick
        ? await store.dueOps(root)
        : await store.pendingOps(root);
    // A full run settles only the hints that are due; the others keep
    // their backoff, and their paths wait with them (#163).
    final nowMs = _now().millisecondsSinceEpoch;
    final hints = [
      for (final hint in pending)
        if (hint.nextAttemptAtMs <= nowMs) hint,
    ];
    final held = [
      for (final hint in pending)
        if (hint.nextAttemptAtMs > nowMs) hint,
    ];
    if (held.isNotEmpty) {
      _log.info('run: ${held.length} queued hints still backing off');
    }
    final kind = quick ? 'quick' : 'full';
    _log.info('run: $kind start for $root (${hints.length} queued hints)');
    if (quick && hints.isEmpty) {
      _log.info('run: quick, nothing due in the queue');
      return report;
    }
    onProgress?.call(SyncStage.connecting, 0, 0);
    final ({SyncDestination destination, WebDavClient client}) connection;
    try {
      connection = await _connect();
    } on SyncFailure catch (e) {
      return await _finish(report, hints, e.reason, e.detail, clock);
    }
    final client = connection.client;
    try {
      await _runWith(
        client,
        connection.destination,
        report,
        hints,
        confirm,
        onProgress,
        held: held,
      );
    } on WebDavAuthFailure catch (e) {
      _abort(report, SyncAbort.authentication, e.message);
    } on WebDavNotFound catch (e) {
      _abort(report, SyncAbort.remoteMissing, e.message);
    } on WebDavUnsupported catch (e) {
      _abort(report, SyncAbort.unsupported, e.message);
    } on WebDavRetryable catch (e) {
      _noteRetryAfter(report, e.retryAfter);
      _abort(report, SyncAbort.offline, e.message);
    } on WebDavFailure catch (e) {
      _abort(report, SyncAbort.failed, e.message);
    } on FileSystemException catch (e) {
      _abort(report, SyncAbort.failed, 'local: ${e.message} (${e.path})');
    } finally {
      client.close();
    }
    return await _finish(
      report,
      hints,
      report.aborted,
      report.abortDetail,
      clock,
    );
  }

  void _abort(SyncReport report, SyncAbort why, String detail) {
    report
      ..aborted = why
      ..abortDetail = detail;
  }

  static void _noteRetryAfter(SyncReport report, Duration? wait) {
    if (wait == null) return;
    final known = report.retryAfter;
    if (known == null || wait > known) report.retryAfter = wait;
  }

  /// Settles the [hints] a run read: none when the run did not get to
  /// look (no destination, no password, not confirmed); all backing off
  /// when it stopped; otherwise each done unless a path it covers failed
  /// or changed during the run. A conflict settles its hint: the report
  /// carries it, and the next full sync finds it again.
  Future<void> _settleHints(SyncReport report, List<SyncOp> hints) async {
    if (hints.isEmpty) return;
    final why = report.aborted;
    if (why == SyncAbort.notConfigured ||
        why == SyncAbort.missingPassword ||
        why == SyncAbort.notConfirmed) {
      _log.info('queue: ${hints.length} hints left as they are (${why!.name})');
      return;
    }
    if (why != null) {
      for (final hint in hints) {
        if (await store.failOp(hint, '${why.name}: ${report.abortDetail}') !=
            null) {
          report.hintsFailed++;
        }
      }
      return;
    }
    final troubles = <String, String>{
      for (final path in report.skipped) path: 'changed during the sync',
      for (final failure in report.failures) failure.path: failure.error,
    };
    final failed = {for (final failure in report.failures) failure.path};
    for (final hint in hints) {
      final error = _troubleFor(troubles, hint);
      if (error == null) {
        if (await store.completeOp(hint)) report.hintsDone++;
        continue;
      }
      final updated = await store.failOp(hint, error);
      if (updated == null) continue;
      report.hintsFailed++;
      // A path skipped run after run is not a passing hiccup: it is
      // failing, and the run says so instead of calling itself a success
      // (#163). A real failure is in the report already.
      if (updated.attempts >= stuckAfter && !failed.contains(hint.path)) {
        report.failures.add((
          path: hint.path,
          error: '$error (${updated.attempts} runs in a row)',
        ));
        _log.warning(
          'queue: ${hint.path} skipped ${updated.attempts} runs in a row, '
          'reported as failing',
        );
      }
    }
  }

  /// How many runs in a row a path may be skipped before the run reports
  /// it as failing (#163).
  static const int stuckAfter = 3;

  /// Whether [decision] touches a path one of the [held] hints covers:
  /// its path or its move source, the hint's own or anything under it.
  static bool _heldBy(List<SyncOp> held, SyncDecision decision) {
    final touched = [decision.path, ?decision.fromPath];
    for (final hint in held) {
      for (final covered in [hint.path, ?hint.fromPath]) {
        for (final path in touched) {
          if (path == covered || path.startsWith('$covered/')) return true;
        }
      }
    }
    return false;
  }

  /// The error of the first troubled path [hint] covers (its path, its
  /// move source, or anything under either), or null.
  static String? _troubleFor(Map<String, String> troubles, SyncOp hint) {
    final covered = [hint.path, ?hint.fromPath];
    for (final entry in troubles.entries) {
      for (final path in covered) {
        if (entry.key == path || entry.key.startsWith('$path/')) {
          return entry.value;
        }
      }
    }
    return null;
  }

  Future<SyncReport> _finish(
    SyncReport report,
    List<SyncOp> hints,
    SyncAbort? why,
    String? detail,
    Stopwatch clock,
  ) async {
    if (why != null) _abort(report, why, detail ?? why.name);
    await _settleHints(report, hints);
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
        'run: ${report.quick ? 'quick' : 'full'} done for $root in '
        '${clock.elapsedMilliseconds} ms: ${report.summary()}'
        '${hints.isEmpty ? '' : '; hints ${report.hintsDone} done, '
                  '${report.hintsFailed} backing off'}'
        '${report.retryAfter == null ? '' : '; server asked to wait '
                  '${report.retryAfter!.inSeconds}s'}';
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
    List<SyncOp> hints,
    SyncConfirm? confirm,
    SyncProgress? onProgress, {
    List<SyncOp> held = const [],
  }) async {
    final allRows = await store.items(root);
    final firstSync = allRows.isEmpty && destination.lastSyncAtMs == null;
    if (report.quick && firstSync) {
      _abort(report, SyncAbort.notConfirmed, 'no quick sync before the first');
      return;
    }
    final capabilities = await _capabilities(client, destination);

    onProgress?.call(SyncStage.scanning, 0, 0);
    final scanClock = Stopwatch()..start();
    final _Scan scan;
    if (report.quick) {
      scan = await _scanQuick(client, hints, allRows);
    } else {
      final local = await _scanLocal(root);
      final remoteScan = await _scanRemote(client);
      scan = (
        local: local,
        remote: remoteScan.files,
        folders: remoteScan.folders,
        rows: allRows,
      );
    }
    final local = scan.local;
    final remote = scan.remote;
    final rows = scan.rows;
    _log.info(
      'scan: ${report.quick ? 'quick, ' : ''}${local.length} local files, '
      '${remote.length} remote files, ${scan.folders.length} remote folders '
      'known, ${rows.length} of ${allRows.length} agreed rows '
      '(${scanClock.elapsedMilliseconds} ms)',
    );

    onProgress?.call(SyncStage.comparing, 0, 0);
    final localSha = <String, String>{};
    final remoteSha = <String, String>{};
    final rowCount = allRows.keys.where(isSyncablePath).length;
    var plan = planSync(
      local: local,
      remote: remote,
      rows: rows,
      capabilities: capabilities,
      rowCount: rowCount,
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
        rowCount: rowCount,
      );
    }
    if (report.quick) {
      final kept = <SyncDecision>[];
      for (final decision in plan.decisions) {
        if (decision.kind == SyncActionKind.trashLocal ||
            decision.kind == SyncActionKind.moveLocal) {
          report.deferred.add(decision);
        } else {
          kept.add(decision);
        }
      }
      if (report.deferred.isNotEmpty) {
        _log.info(
          'plan: quick sync leaves ${report.deferred.length} for a full '
          'sync (${report.deferred.take(3).join('; ')}'
          '${report.deferred.length > 3 ? '; …' : ''})',
        );
        plan = SyncPlan(kept, rowCount: plan.rowCount);
      }
    }
    if (held.isNotEmpty) {
      final kept = <SyncDecision>[];
      for (final decision in plan.decisions) {
        if (_heldBy(held, decision)) {
          report.waiting.add(decision);
        } else {
          kept.add(decision);
        }
      }
      if (report.waiting.isNotEmpty) {
        _log.info(
          'plan: ${report.waiting.length} wait out their backoff '
          '(${report.waiting.take(3).join('; ')}'
          '${report.waiting.length > 3 ? '; …' : ''})',
        );
        plan = SyncPlan(kept, rowCount: plan.rowCount);
      }
    }
    report.plan = plan;
    _log.info(
      'plan: ${plan.summary()} (${plan.destructiveCount} destructive of '
      '${plan.rowCount} rows)',
    );
    for (final decision in plan.decisions) {
      _log.debug('plan: $decision');
    }

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

    final context = SyncRunContext(
      client: client,
      capabilities: capabilities,
      local: local,
      remote: remote,
      rows: rows,
      localSha: localSha,
      remoteSha: remoteSha,
      folders: scan.folders,
      report: report,
    );
    final total = plan.decisions.length;
    var index = 0;
    for (final decision in plan.decisions) {
      onProgress?.call(SyncStage.applying, index++, total);
      final clock = Stopwatch()..start();
      try {
        final outcome = await _apply(context, decision);
        switch (outcome) {
          case SyncStepOutcome.done:
            report.done.update(decision.kind, (n) => n + 1, ifAbsent: () => 1);
            if (const {
              SyncActionKind.download,
              SyncActionKind.trashLocal,
              SyncActionKind.moveLocal,
            }.contains(decision.kind)) {
              report.changedLocally.addAll([decision.path, ?decision.fromPath]);
            }
            _log.info('apply: $decision (${clock.elapsedMilliseconds} ms)');
          case SyncStepOutcome.skipped:
            report.skipped.add(decision.path);
            _log.info(
              'apply: skipped ${decision.kind.name} "${decision.path}": '
              'a side changed during the run, decided again next time',
            );
          case SyncStepOutcome.conflict:
            break;
        }
      } on WebDavAuthFailure {
        rethrow;
      } on WebDavRetryable catch (e) {
        // No answer at all: the network, and everything will fail — unless
        // the server still answers, and dropped this one request (#617).
        if (e.status == null && !await _serverAnswers(client)) rethrow;
        _noteRetryAfter(report, e.retryAfter);
        _failed(
          report,
          decision,
          e.status == null ? _refused(context, decision, e.message) : e.message,
        );
      } on WebDavFailure catch (e) {
        _failed(
          report,
          decision,
          e.status == 413 ? _refused(context, decision, e.message) : e.message,
        );
      } on FileSystemException catch (e) {
        _failed(report, decision, 'local: ${e.message}');
      } on SyncStepFailure catch (e) {
        _failed(report, decision, e.message);
      }
    }
  }

  /// Whether the server answers a `PROPFIND` of the destination: after a
  /// request lost its connection, what tells a network that is down from
  /// a server that dropped that one request (#617).
  Future<bool> _serverAnswers(WebDavClient client) async {
    try {
      await client.propfind('', depth: 0, collection: true);
      _log.info('apply: the server still answers, one request was dropped');
      return true;
    } on Object catch (e) {
      _log.info('apply: the server does not answer either ($e)');
      return false;
    }
  }

  /// [error] for a request the server refused while answering others: an
  /// upload says its size, the usual reason — a server or proxy limit on
  /// the size of a request (nginx's `client_max_body_size` is 1 MB unless
  /// set), met with a reset or a 413 (#617).
  static String _refused(
    SyncRunContext context,
    SyncDecision decision,
    String error,
  ) {
    final size = context.local[decision.path]?.size;
    if (decision.kind != SyncActionKind.upload || size == null) {
      return '$error (the server answers other requests)';
    }
    return '$error (the server refused an upload of ${_megabytes(size)}: '
        'it may limit the size of uploads)';
  }

  static String _megabytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb < 10 ? mb.toStringAsFixed(1) : mb.round()} MB';
  }

  void _failed(SyncReport report, SyncDecision decision, String error) {
    report.failures.add((path: decision.path, error: error));
    _log.warning(
      'apply failed: ${decision.kind.name} ${decision.path}: $error',
    );
  }

  // --- conflicts, one file at a time ---------------------------------

  /// The texts of a conflicted [path]: the local file, the server's copy,
  /// and the version both last agreed on when history still has it — what
  /// the merge view needs, and which versions they were, for the
  /// resolution to check against. Decoded as UTF-8 (malformed bytes
  /// replaced). Throws [SyncFailure].
  Future<ConflictTexts> conflictTexts(String path) => _exclusively(() async {
    final connection = await _connect();
    try {
      final localBytes = await File(p.join(root, path)).readAsBytes();
      // The listing's ETag, read first: it is what the resolution compares
      // with, and what its upload's If-Match sends.
      final listed = await connection.client.stat(path);
      final remoteBytes = await connection.client.readBytes(path);
      final base = await _baseText(path);
      _log.info(
        'conflict $path: read ${localBytes.length} b local, '
        '${remoteBytes.length} b remote, '
        '${base == null ? 'no base' : '${base.length} chars of base'}',
      );
      return ConflictTexts(
        local: decodeNoteText(localBytes),
        remote: decodeNoteText(remoteBytes),
        base: base,
        localSha256: sha256.convert(localBytes).toString(),
        remoteSha256: sha256.convert(remoteBytes).toString(),
        remoteEtag: listed?.etag,
      );
    } on WebDavFailure catch (e) {
      throw SyncFailure.of(e);
    } on FileSystemException catch (e) {
      throw SyncFailure(SyncAbort.failed, 'local: ${e.message}');
    } finally {
      connection.client.close();
    }
  });

  /// The text of the history version pinned as the sync base of [path],
  /// or null when there is none (or it rotated away).
  Future<String?> _baseText(String path) async {
    final row = await store.item(root, path);
    final version = row?.baseVersion;
    if (version == null || !NoteOps.keepsHistory(path)) return null;
    try {
      return await ops.readNoteVersion(path, version);
    } on Object catch (e) {
      _log.info('conflict $path: base v$version unreadable ($e)');
      return null;
    }
  }

  /// Resolves a conflicted [path] with the merged [text] the user put
  /// together from the versions [shown]: it is written here (the replaced
  /// text becomes a `sync` history version) and uploaded, and the row
  /// records the agreement. Throws [SyncFailure], a `moved` one when
  /// either side is no longer what [shown] holds.
  Future<void> resolveMerged(
    String path,
    String text, {
    required ConflictTexts shown,
  }) => _resolve(
    path,
    intent: 'merged text (${text.length} chars)',
    outcome: 'merged',
    shown: shown,
    (c, remote) async {
      await ops.syncMerge(path, text);
      final local = await _sides.stat(path);
      if (local == null) {
        throw SyncFailure(SyncAbort.failed, '$path is gone here');
      }
      final sha = (await _sides.hashLocal([path]))[path]!;
      await _sides.uploadAndRecord(
        c,
        path,
        sha: sha,
        local: local,
        notListed: SyncFailure(SyncAbort.failed, '$path uploaded, not listed'),
        ifMatch: c.capabilities.ifMatch ? remote?.guardEtag : null,
      );
    },
  );

  /// Resolves a conflict at [path] by keeping one whole side: with
  /// [keepLocal] the local file is uploaded over the server's (guarded by
  /// `If-Match` where the server honors it); otherwise the server's copy
  /// replaces the local file, whose text becomes a `sync` history
  /// version. Either way the agreed row and the merge base are recorded.
  /// With [shown], the versions the user decided on, a side that moved
  /// since fails as a `moved` [SyncFailure] and nothing is written.
  /// Throws [SyncFailure].
  Future<void> resolveConflict(
    String path, {
    required bool keepLocal,
    ConflictTexts? shown,
  }) => _resolve(
    path,
    intent: 'keep ${keepLocal ? 'local' : 'remote'}',
    outcome: 'done',
    shown: shown,
    (c, remote) async {
      if (keepLocal) {
        final local = await _sides.stat(path);
        if (local == null) {
          throw SyncFailure(SyncAbort.failed, '$path is gone here');
        }
        final sha = (await _sides.hashLocal([path]))[path]!;
        await _sides.uploadAndRecord(
          c,
          path,
          sha: sha,
          local: local,
          notListed: SyncFailure(
            SyncAbort.failed,
            '$path uploaded, not listed',
          ),
          ifMatch: c.capabilities.ifMatch ? remote?.guardEtag : null,
          ifNoneMatch: remote == null && c.capabilities.ifNoneMatch,
        );
      } else {
        if (remote == null) {
          throw SyncFailure(SyncAbort.failed, '$path is gone on the server');
        }
        final fetched = await _sides.fetch(c, path);
        if (shown != null && fetched.download.sha256 != shown.remoteSha256) {
          // Rewritten between the check and this read.
          await fetched.temp.delete();
          throw SyncFailure.stale('$path changed on the server');
        }
        await ops.syncReplace(path, fetched.temp.path);
        final local = await _sides.stat(path);
        if (local == null) {
          throw SyncFailure(SyncAbort.failed, '$path not on disk');
        }
        await store.putItems([
          await _sides.row(
            c,
            path,
            sha: fetched.download.sha256,
            local: local,
            remote: _sides.remoteFrom(c, path, fetched.download),
          ),
        ]);
      }
    },
  );

  /// Runs a conflict resolution of [path] on its own: logs [intent],
  /// connects, lists the server's copy, refuses a side that moved since
  /// [shown] (when given), and hands [body] a context of that one path
  /// and the listing; logs [outcome] when it went through. A WebDAV or a
  /// local failure is thrown as a [SyncFailure].
  Future<void> _resolve(
    String path,
    Future<void> Function(SyncRunContext c, WebDavResource? remote) body, {
    required String intent,
    required String outcome,
    ConflictTexts? shown,
  }) => _exclusively(() async {
    final clock = Stopwatch()..start();
    _log.info('resolve $path: $intent');
    final connection = await _connect();
    final client = connection.client;
    try {
      final capabilities = await _capabilities(client, connection.destination);
      final remote = await client.stat(path);
      if (shown != null) await _stillAsShown(client, path, shown, remote);
      final c = SyncRunContext(
        client: client,
        capabilities: capabilities,
        local: const {},
        remote: {path: ?remote},
        rows: const {},
        localSha: const {},
        remoteSha: const {},
        folders: {''},
        report: SyncReport(),
      );
      await body(c, remote);
      _log.info('resolve $path: $outcome (${clock.elapsedMilliseconds} ms)');
    } on WebDavFailure catch (e) {
      _log.warning('resolve $path failed: ${e.message}');
      throw SyncFailure.of(e);
    } on FileSystemException catch (e) {
      _log.warning('resolve $path failed: ${e.message}');
      throw SyncFailure(SyncAbort.failed, 'local: ${e.message}');
    } finally {
      client.close();
    }
  });

  /// Throws a `moved` [SyncFailure] unless both sides of [path] are
  /// still the versions [shown]: the local bytes by hash, the server's
  /// copy ([remote], just listed) by ETag when both have one, else by
  /// hashing a fresh download.
  Future<void> _stillAsShown(
    WebDavClient client,
    String path,
    ConflictTexts shown,
    WebDavResource? remote,
  ) async {
    final localSha = (await _sides.hashLocal([path]))[path];
    if (localSha != shown.localSha256) {
      _log.info('resolve $path: refused, changed here since it was shown');
      throw SyncFailure.stale('$path changed on this device');
    }
    final String? remoteSha;
    if (remote == null) {
      remoteSha = null;
    } else if (shown.remoteEtag != null && remote.etag != null) {
      remoteSha = remote.etag == shown.remoteEtag ? shown.remoteSha256 : null;
    } else {
      remoteSha = await _sides.remoteSha(client, path);
    }
    if (remoteSha != shown.remoteSha256) {
      _log.info('resolve $path: refused, changed on the server since shown');
      throw SyncFailure.stale('$path changed on the server');
    }
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

  static Future<Map<String, LocalFileState>> _scanLocal(
    String root, {
    String under = '',
  }) => Isolate.run(() => scanLocalFiles(root, under: under));

  /// The sides of the queued [hints]' paths only: each path (and a move's
  /// source) is a file or a folder on either side; a folder brings every
  /// file under it, locally, remotely and in the rows. One `PROPFIND
  /// Depth: 0` per path, plus the walk of the folders among them.
  Future<_Scan> _scanQuick(
    WebDavClient client,
    List<SyncOp> hints,
    Map<String, SyncItem> allRows,
  ) async {
    // A missing destination must stop the run, not read as "every hinted
    // file is gone remotely".
    final top = await client.stat('', collection: true);
    if (top == null || !top.isCollection) {
      throw const WebDavNotFound('the destination folder is gone');
    }
    final scope = <String>{
      for (final hint in hints) ...[hint.path, ?hint.fromPath],
    }..removeWhere((path) => path.isEmpty || !_inSyncScope(path));
    final local = <String, LocalFileState>{};
    final remote = <String, WebDavResource>{};
    final rows = <String, SyncItem>{};
    final folders = <String>{''};
    for (final path in scope) {
      final under = '$path/';
      for (final entry in allRows.entries) {
        if (entry.key == path || entry.key.startsWith(under)) {
          rows[entry.key] = entry.value;
        }
      }
      final localDir = Directory(p.join(root, path)).existsSync();
      if (localDir) {
        local.addAll(await _scanLocal(root, under: path));
      } else {
        final state = await _sides.stat(path);
        if (state != null && isSyncablePath(path)) local[path] = state;
      }
      final folderLike =
          localDir || allRows.keys.any((key) => key.startsWith(under));
      final item = await client.stat(path, collection: folderLike);
      if (item == null) continue;
      _addFolderChain(folders, _parentOf(path));
      if (item.isCollection) {
        final walked = await _scanRemote(client, from: path);
        remote.addAll(walked.files);
        folders.addAll(walked.folders);
      } else if (isSyncablePath(path)) {
        remote[path] = item;
      }
    }
    return (local: local, remote: remote, folders: folders, rows: rows);
  }

  /// Whether [path] can hold syncable files: a syncable file, or a folder
  /// the scans walk.
  static bool _inSyncScope(String path) =>
      isSyncablePath(path) || _descends(path);

  static String _parentOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? '' : path.substring(0, slash);
  }

  static void _addFolderChain(Set<String> folders, String folder) {
    var current = folder;
    while (current.isNotEmpty && folders.add(current)) {
      current = _parentOf(current);
    }
  }

  Future<({Map<String, WebDavResource> files, Set<String> folders})>
  _scanRemote(WebDavClient client, {String from = ''}) async {
    final files = <String, WebDavResource>{};
    final folders = <String>{from};
    final queue = [from];
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
    // The library's own files live in a dot folder, and some servers — or
    // the proxy in front of them — leave dot entries out of a folder listing
    // while still serving them by path. The listing then says the file is not
    // there, the check before the upload finds it, and the upload is skipped
    // as "changed during the sync" on every run. So a walk from the root that
    // did not see their folder asks for them by name: at most four `Depth: 0`
    // requests, and only when the listing hid them.
    if (from.isEmpty) {
      for (final path in libraryStateFiles) {
        if (files.containsKey(path) || folders.contains(_parentOf(path))) {
          continue;
        }
        final item = await client.stat(path);
        if (item == null || item.isCollection) continue;
        files[path] = item;
        _addFolderChain(folders, _parentOf(path));
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
      localSha.addAll(await _sides.hashLocal(localPaths));
    }
    final remotePaths = [
      for (final d in plan.decisions)
        if (d.kind == SyncActionKind.hashRemote) d.path,
    ];
    for (final path in remotePaths) {
      try {
        remoteSha[path] = await _sides.remoteSha(client, path);
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

  // --- applying -------------------------------------------------------

  Future<SyncStepOutcome> _apply(SyncRunContext c, SyncDecision d) async {
    switch (d.kind) {
      case SyncActionKind.nothing:
        return SyncStepOutcome.done;
      case SyncActionKind.hashLocal:
      case SyncActionKind.hashRemote:
        throw const SyncStepFailure(
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
        return SyncStepOutcome.done;
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

  /// The remote still is what the scan saw, checked with a PROPFIND when
  /// the write has no precondition to guard it.
  Future<void> _remoteStillAsPlanned(
    SyncRunContext c,
    SyncDecision d, {
    String? expectedSha,
  }) async {
    if (!d.checkRemoteFirst) return;
    await _sides.remoteUnchangedSince(
      c,
      d.fromPath ?? d.path,
      expectedSha: expectedSha,
    );
  }

  /// Whether [file] holds a JSON object — what a [jsonStateFiles] side has to
  /// be before the sync may replace the other with it (#336).
  static Future<bool> _isJsonObject(File file) async {
    try {
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      return jsonDecode(text) is Map;
    } on Object {
      return false;
    }
  }

  Future<SyncStepOutcome> _upload(
    SyncRunContext c,
    SyncDecision d,
  ) => _sides.guarded(() async {
    final local = (await _sides.localStillAsPlanned(c, d.path))!;
    await _remoteStillAsPlanned(c, d);
    final sha = _sides.localShaOf(c, d.path);
    // The #336 rule holds both ways: a JSON state file that does not parse
    // here — a hand edit with a syntax error — is not a newer version of the
    // remote copy either, and `.niman/*` has no history to bring that one
    // back. Both sides stay, and the path is reported for the merge.
    if (jsonStateFiles.contains(d.path) &&
        c.remote[d.path] != null &&
        !await _isJsonObject(File(p.join(root, d.path)))) {
      return _sides.reportConflict(
        c,
        d,
        localSha: sha,
        remoteSha: c.rows[d.path]?.localSha256 ?? '',
        why: 'the local copy is not a JSON object',
      );
    }
    await _sides.uploadAndRecord(
      c,
      d.path,
      sha: sha,
      local: local,
      notListed: const SyncStepFailure('uploaded but not listed'),
      ifMatch: d.ifMatch,
      ifNoneMatch: d.ifNoneMatch,
      modified: DateTime.fromMillisecondsSinceEpoch(local.mtimeMs),
    );
    return SyncStepOutcome.done;
  });

  Future<SyncStepOutcome> _download(SyncRunContext c, SyncDecision d) =>
      _sides.guarded(() async {
        final fetched = await _sides.fetch(c, d.path);
        try {
          await _sides.localStillAsPlanned(c, d.path);
        } on Object {
          if (fetched.temp.existsSync()) await fetched.temp.delete();
          rethrow;
        }
        // A JSON state file whose remote copy does not parse is not a newer
        // version of this device's: replacing a good local copy with it —
        // there is no history for `.niman/*` — is how a half-written settings
        // file wiped every setting on the run after (#336). Both sides stay,
        // and the path is reported for the merge.
        if (jsonStateFiles.contains(d.path) &&
            // The async stat is on purpose: a blocking one on the UI isolate
            // is the FUSE round trip this engine keeps off its frames.
            // ignore: avoid_slow_async_io
            await File(p.join(root, d.path)).exists() &&
            !await _isJsonObject(fetched.temp)) {
          await fetched.temp.delete();
          return _sides.reportConflict(
            c,
            d,
            localSha: c.rows[d.path]?.localSha256 ?? '',
            remoteSha: fetched.download.sha256,
            why: 'the remote copy is not a JSON object',
          );
        }
        await ops.syncReplace(d.path, fetched.temp.path);
        final local = await _sides.stat(d.path);
        if (local == null) {
          throw const SyncStepFailure('downloaded but not on disk');
        }
        await store.putItems([
          await _sides.row(
            c,
            d.path,
            sha: fetched.download.sha256,
            local: local,
            remote: _sides.remoteFrom(c, d.path, fetched.download),
          ),
        ]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _deleteRemote(SyncRunContext c, SyncDecision d) =>
      _sides.guarded(() async {
        await _sides.localStillAsPlanned(c, d.path);
        await _remoteStillAsPlanned(c, d);
        await c.client.delete(d.path, ifMatch: d.ifMatch);
        await store.removeItems(root, [d.path]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _trashLocal(SyncRunContext c, SyncDecision d) =>
      _sides.guarded(() async {
        await _sides.localStillAsPlanned(c, d.path);
        await ops.syncTrash(d.path);
        await store.removeItems(root, [d.path]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _record(SyncRunContext c, SyncDecision d) =>
      _sides.guarded(() async {
        final local = (await _sides.localStillAsPlanned(c, d.path))!;
        final sha = _sides.localShaOf(c, d.path);
        final row = c.rows[d.path];
        final remote = c.remote[d.path]!;
        final contentChanged = row == null || row.localSha256 != sha;
        await store.putItems([
          await _sides.row(
            c,
            d.path,
            sha: sha,
            local: local,
            remote: remote,
            baseVersion: row?.baseVersion,
            pinBase: contentChanged,
          ),
        ]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _conflict(
    SyncRunContext c,
    SyncDecision d,
  ) => _sides.guarded(() async {
    final local = (await _sides.localStillAsPlanned(c, d.path))!;
    final localSha = _sides.localShaOf(c, d.path);
    final fetched = await _sides.fetch(c, d.path);
    // The fetch wrote the remote body into a temp next to the target,
    // and every end below — the swapped-in download, the merge's
    // write-back through the temp, the path left for the merge screen —
    // consumes it or deletes it. What none of them covered was stopping
    // between the two: a merge the guard stops on a `_ChangedDuringSync`
    // threw past them all and left the full remote body in the library
    // folder as `.x.md.niman-tmp-sync-<µs>`, one more on every retry
    // until the next open's sweep (#495). The temp is this method's to
    // clean up whatever it returns or throws.
    try {
      final remote = _sides.remoteFrom(c, d.path, fetched.download);
      final remoteSha = fetched.download.sha256;

      if (remoteSha == localSha) {
        await store.putItems([
          await _sides.row(
            c,
            d.path,
            sha: localSha,
            local: local,
            remote: remote,
          ),
        ]);
        _log.info('conflict ${d.path}: same content on both sides, recorded');
        return SyncStepOutcome.done;
      }

      if (d.path.startsWith('.niman/')) {
        // Settings and counters are JSON: merged key by key, not by line,
        // which could break them. A side that does not parse is not a
        // merge: taking the newer file whole replaced the other device's
        // copy — and this device's good copy on the run after — with no
        // history and no way back (#336), so both sides are left as they
        // are and the path is reported like any other conflict.
        final merge = await _mergeState(
          c,
          d,
          fetched.temp,
          remote,
          remoteSha: remoteSha,
        );
        switch (merge) {
          case _StateMerge.merged:
            return SyncStepOutcome.done;
          case _StateMerge.notJson:
            return _sides.reportConflict(
              c,
              d,
              localSha: localSha,
              remoteSha: remoteSha,
              why: 'a side is not a JSON object',
            );
          case _StateMerge.clockDecides:
            return _sides.reportConflict(
              c,
              d,
              localSha: localSha,
              remoteSha: remoteSha,
              why:
                  'a key both sides changed, which no device clock can '
                  'decide',
            );
        }
      }

      // Both sides changed: with the version they last agreed on, the
      // edits that do not overlap merge without asking anyone
      // (docs/records/sync.md, "Conflicts").
      final merge = await _tryMerge(
        c,
        d,
        fetched.temp,
        remote,
        remoteSha: remoteSha,
      );
      if (merge != null) {
        c.report
          ..merged.add(d.path)
          ..changedLocally.addAll(merge.changedLocally ? [d.path] : const []);
        return SyncStepOutcome.done;
      }

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
      return SyncStepOutcome.conflict;
    } finally {
      if (fetched.temp.existsSync()) await fetched.temp.delete();
    }
  });

  /// Merges a library state file ([mergeSettingsJson] key by key, for the
  /// settings and for the Home's tiles (#535), [mergeCountersJson],
  /// [mergeWordList] word by word, [mergeReadingJson] book by book) and
  /// writes the result on whichever side lacks it; [_StateMerge.notJson]
  /// when a JSON side does not parse, and [_StateMerge.clockDecides] when
  /// a settings key or a Home tile both sides changed differently, which
  /// only the file mtimes could settle — and the remote one is the
  /// uploading device's clock (#350). Both cases touch nothing and leave
  /// the path to the caller.
  Future<_StateMerge> _mergeState(
    SyncRunContext c,
    SyncDecision d,
    File remoteCopy,
    WebDavResource remote, {
    required String remoteSha,
  }) async {
    final file = File(p.join(root, d.path));
    final localText = utf8.decode(
      await file.readAsBytes(),
      allowMalformed: true,
    );
    final remoteText = utf8.decode(
      await remoteCopy.readAsBytes(),
      allowMalformed: true,
    );
    final base = c.rows[d.path]?.baseText;
    final String? text;
    if (d.path == NoteOps.settingsFilePath || d.path == HomeFile.filePath) {
      // The clock's vote each way: when the two merges differ, the clock
      // was what picked the disputed key's side — no outcome may rest on
      // it, so the key is left for the user instead.
      final asLocal = mergeSettingsJson(
        base: base,
        local: localText,
        remote: remoteText,
        localNewer: true,
      );
      final asRemote = mergeSettingsJson(
        base: base,
        local: localText,
        remote: remoteText,
        localNewer: false,
      );
      if (asLocal == null || asRemote == null) return _StateMerge.notJson;
      if (asLocal != asRemote) {
        _log.info(
          'merge ${d.path}: a key both sides changed, left for the user',
        );
        return _StateMerge.clockDecides;
      }
      text = asLocal;
    } else if (d.path == _personalDictionaryPath) {
      text = mergeWordList(base: base, local: localText, remote: remoteText);
    } else if (d.path == ReadingPositions.filePath) {
      text = mergeReadingJson(base: base, local: localText, remote: remoteText);
    } else {
      text = mergeCountersJson(local: localText, remote: remoteText);
    }
    if (text == null) {
      _log.info('merge ${d.path}: a side is not a JSON object');
      return _StateMerge.notJson;
    }
    final uploads = text != remoteText;
    if (uploads) {
      await _sides.guardMergeUpload(c, d, remote, expectedSha: remoteSha);
    }
    final changedLocally = text != localText;
    if (changedLocally) {
      // Through the temp the download left: syncReplace swaps it in the
      // way a download goes, reloading the settings.
      await remoteCopy.writeAsString(text);
      await _sides.localStillAsPlanned(c, d.path);
      await ops.syncReplace(d.path, remoteCopy.path);
      c.report.changedLocally.add(d.path);
    } else {
      await remoteCopy.delete();
    }
    var listed = remote;
    if (uploads) {
      await c.client.uploadFile(
        d.path,
        file,
        ifMatch: c.capabilities.ifMatch ? remote.guardEtag : null,
      );
      listed =
          await c.client.stat(d.path) ??
          (throw const SyncStepFailure('merged but not listed'));
    }
    final after = await _sides.stat(d.path);
    if (after == null) throw const SyncStepFailure('merged but not on disk');
    final sha = (await _sides.hashLocal([d.path]))[d.path];
    if (sha == null) throw const SyncStepFailure('merged but not hashed');
    await store.putItems([
      await _sides.row(c, d.path, sha: sha, local: after, remote: listed),
    ]);
    _log.info(
      'merge ${d.path}: ${base == null ? 'no base' : 'on the base'}'
      '${changedLocally ? ', written here' : ''}'
      '${uploads ? ', uploaded' : ''}',
    );
    return _StateMerge.merged;
  }

  static const _personalDictionaryPath = '.niman/dictionary.txt';

  /// Merges both sides of [d] over the pinned base and writes the result
  /// on both, or returns null when there is no base, the file is not
  /// text, or the edits overlap (then the conflict stays for the user).
  ///
  /// A side that is not valid UTF-8 is not merged either: a lossy decode
  /// would write U+FFFD over bytes nobody touched, here and on the server
  /// (#350). Both sides stay and the path is reported.
  ///
  /// The task files always merge: their lines are records, merged one by
  /// one ([mergeRecords]), and without a base they are the union of both.
  Future<({bool changedLocally})?> _tryMerge(
    SyncRunContext c,
    SyncDecision d,
    File remoteCopy,
    WebDavResource remote, {
    required String remoteSha,
  }) async {
    final base = d.baseVersion;
    final records = _isRecordFile(d.path);
    if (!NoteOps.keepsHistory(d.path)) return null;
    if (base == null && !records) return null;
    var baseText = '';
    if (base != null) {
      try {
        baseText = await ops.readNoteVersion(d.path, base);
      } on Object catch (e) {
        _log.info('merge ${d.path}: base v$base unreadable ($e)');
        if (!records) return null;
      }
    }
    final localText = _decodeUtf8(
      await File(p.join(root, d.path)).readAsBytes(),
    );
    final remoteText = _decodeUtf8(await remoteCopy.readAsBytes());
    if (localText == null || remoteText == null) {
      _log.info('merge ${d.path}: a side is not UTF-8, left for the user');
      return null;
    }
    final String text;
    final String how;
    if (records) {
      text = await _mergeRecordTexts(baseText, localText, remoteText);
      how = 'task lines, ${base == null ? 'no base: union' : 'base v$base'}';
    } else {
      final merge = await _mergeTexts(baseText, localText, remoteText);
      if (!merge.clean) {
        _log.info(
          'merge ${d.path}: ${merge.conflicts.length} overlapping region(s), '
          'left for the user (${merge.describe()})',
        );
        return null;
      }
      text = merge.text();
      how = merge.describe();
    }
    // Guarded before anything is written: a remote that moved since the
    // merge was built would be written over, and on a server without
    // preconditions this is the only guard there is (#350).
    await _sides.guardMergeUpload(c, d, remote, expectedSha: remoteSha);
    final changedLocally = text != localText;
    if (changedLocally) await ops.syncMerge(d.path, text);
    // The file on disk is the merge now: hash and stat it as written.
    final local = await _sides.stat(d.path);
    if (local == null) throw const SyncStepFailure('merged but not on disk');
    final sha = (await _sides.hashLocal([d.path]))[d.path];
    if (sha == null) throw const SyncStepFailure('merged but not hashed');
    await _sides.uploadAndRecord(
      c,
      d.path,
      sha: sha,
      local: local,
      notListed: const SyncStepFailure('merged but not listed'),
      ifMatch: c.capabilities.ifMatch ? remote.guardEtag : null,
      modified: DateTime.fromMillisecondsSinceEpoch(local.mtimeMs),
    );
    _log.info('merge ${d.path}: $how, both sides now agree');
    return (changedLocally: changedLocally);
  }

  /// [bytes] as UTF-8, or null when they are not valid UTF-8: merging a
  /// side that decoded only through `allowMalformed` would write U+FFFD
  /// over every invalid byte, in regions nobody touched (#350).
  static String? _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  /// Merges three texts, off the UI isolate when they are long.
  static Future<MergeResult> _mergeTexts(
    String base,
    String local,
    String remote,
  ) {
    final size = base.length + local.length + remote.length;
    if (size <= _inlineMergeLimit) {
      return Future.value(mergeThreeWay(base, local, remote));
    }
    return Isolate.run(() => mergeThreeWay(base, local, remote));
  }

  /// Merges three versions of a task file, off the UI isolate when long.
  static Future<String> _mergeRecordTexts(
    String base,
    String local,
    String remote,
  ) {
    final size = base.length + local.length + remote.length;
    if (size <= _inlineMergeLimit) {
      return Future.value(mergeRecords(base, local, remote));
    }
    return Isolate.run(() => mergeRecords(base, local, remote));
  }

  /// Whether [path] is one of the library's task files, whose lines are
  /// records rather than prose.
  static bool _isRecordFile(String path) =>
      path == todoFileName || path == doneFileName;

  /// Texts up to this many characters (all three together) are merged on
  /// the calling isolate; an isolate costs more than the merge itself.
  static const _inlineMergeLimit = 20000;

  Future<SyncStepOutcome> _moveRemote(SyncRunContext c, SyncDecision d) =>
      _sides.guarded(() async {
        final from = d.fromPath!;
        final local = (await _sides.localStillAsPlanned(c, d.path))!;
        await _sides.localStillAsPlanned(c, from);
        await _remoteStillAsPlanned(c, d);
        await _sides.ensureRemoteParent(c, d.path);
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
        if (remote == null) throw const SyncStepFailure('moved but not listed');
        final row = c.rows[from]!;
        await store.putItems([
          await _sides.row(
            c,
            d.path,
            sha: row.localSha256,
            local: local,
            remote: remote,
            baseVersion: row.baseVersion,
            pinBase: false,
          ),
        ]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _moveLocal(SyncRunContext c, SyncDecision d) =>
      _sides.guarded(() async {
        final from = d.fromPath!;
        await _sides.localStillAsPlanned(c, from);
        await _sides.localStillAsPlanned(c, d.path);
        await ops.syncMove(from, d.path);
        await store.moveItems(root, from, d.path);
        final local = await _sides.stat(d.path);
        if (local == null) throw const SyncStepFailure('moved but not on disk');
        final row = c.rows[from]!;
        await store.putItems([
          await _sides.row(
            c,
            d.path,
            sha: row.localSha256,
            local: local,
            remote: c.remote[d.path]!,
            baseVersion: row.baseVersion,
            pinBase: false,
          ),
        ]);
        return SyncStepOutcome.done;
      });
}

/// What merging a library state file did.
enum _StateMerge {
  /// The merge went through and the row was recorded.
  merged,

  /// A side is not a JSON object; both sides stay.
  notJson,

  /// A `.niman/settings.json` key both sides changed differently, which
  /// only the file mtimes could settle: both sides stay and the path is
  /// reported (#350).
  clockDecides,
}

/// What a scan found: files on both sides, the remote folders known to
/// exist, and the agreed rows in scope.
typedef _Scan = ({
  Map<String, LocalFileState> local,
  Map<String, WebDavResource> remote,
  Set<String> folders,
  Map<String, SyncItem> rows,
});

String _short(String sha) => sha.length <= 8 ? sha : sha.substring(0, 8);

/// Whether a folder at library-relative [path] is walked: not a dot
/// folder, except `.niman` at the root (for its two synced files).
bool _descends(String path) {
  if (path == '.niman') return true;
  return !path.split('/').any((s) => s.startsWith('.'));
}

/// Every syncable file under [root] — or only under its folder [under] —
/// with size and mtime (no hashes).
///
/// Top-level so `Isolate.run` can take it. Symlinks are not followed.
Future<Map<String, LocalFileState>> scanLocalFiles(
  String root, {
  String under = '',
}) async {
  final files = <String, LocalFileState>{};
  if (under.isNotEmpty &&
      (!_descends(under) || !Directory(p.join(root, under)).existsSync())) {
    return files;
  }
  final queue = [under];
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
