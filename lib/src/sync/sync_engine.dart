import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/diff/three_way.dart';
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

  /// Paths both sides changed that the run merged by itself.
  final List<String> merged = [];

  /// Paths that failed, with the reason; retried on the next run.
  final List<({String path, String error})> failures = [];

  /// Paths skipped because they changed while the run was going.
  final List<String> skipped = [];

  /// Local paths the run wrote, moved or trashed — what an open editor
  /// has to re-read.
  final Set<String> changedLocally = {};

  /// The plan the run carried out (the last hashing pass).
  SyncPlan? plan;

  /// Why the run stopped early, or null when it ran to the end.
  SyncAbort? aborted;

  /// Detail for [aborted], safe to show.
  String? abortDetail;

  /// Whether the run was a quick sync of the queued paths only.
  bool quick = false;

  /// What a quick sync left for the next full sync: trashing or moving a
  /// local file because a single path is missing remotely is a full
  /// sync's call, which sees the whole remote tree.
  final List<SyncDecision> deferred = [];

  /// What an automatic full sync left alone because its queued hint is
  /// still backing off (#163): the backoff holds for every run, not only
  /// the quick ones. A sync the user asks for lifts it first.
  final List<SyncDecision> waiting = [];

  /// The longest `Retry-After` the server asked for, if any.
  Duration? retryAfter;

  /// Queued hints the run settled.
  int hintsDone = 0;

  /// Queued hints the run left backing off.
  int hintsFailed = 0;

  /// Whether the run reached the end with nothing failed or left over.
  bool get clean => aborted == null && failures.isEmpty && conflicts.isEmpty;

  /// One line for the log.
  String summary() {
    if (aborted != null) return 'aborted: ${aborted!.name} ($abortDetail)';
    final parts = [
      for (final entry in done.entries) '${entry.key.name} ${entry.value}',
      if (merged.isNotEmpty) '${merged.length} merged',
      if (conflicts.isNotEmpty) '${conflicts.length} conflicts',
      if (skipped.isNotEmpty) '${skipped.length} skipped',
      if (failures.isNotEmpty) '${failures.length} failed',
      if (deferred.isNotEmpty) '${deferred.length} left for a full sync',
      if (waiting.isNotEmpty) '${waiting.length} waiting out a backoff',
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

/// Why a conflict resolution or a conflict read could not complete.
final class SyncFailure implements Exception {
  /// A failure for [reason], with a [detail] safe to show.
  const new(this.reason, this.detail);

  /// The failure a WebDAV [error] amounts to.
  factory of(WebDavFailure error) => SyncFailure(switch (error) {
    WebDavAuthFailure() => SyncAbort.authentication,
    WebDavNotFound() => SyncAbort.remoteMissing,
    WebDavUnsupported() => SyncAbort.unsupported,
    WebDavRetryable() => SyncAbort.offline,
    WebDavPrecondition() || WebDavProtocolFailure() => SyncAbort.failed,
  }, error.message);

  /// The same classification a run's abort uses.
  final SyncAbort reason;

  /// What went wrong; never a secret.
  final String detail;

  @override
  String toString() => 'SyncFailure(${reason.name}: $detail)';
}

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
  );

  /// Runs a sync. [confirm] is asked before a first sync and before a plan
  /// that looks like a mass deletion; without it a first sync goes ahead
  /// (it never deletes) and a mass deletion is refused. [onProgress] hears
  /// the stages and, while applying, the count.
  ///
  /// A full sync walks both trees; a [quick] one reconciles only the
  /// paths of the queued hints that are due (docs/dev/sync.md, "Queue and
  /// triggers"), refuses to be a first sync, and leaves local trashing
  /// and moves to the next full sync. Either settles the hints it read:
  /// done when their paths reconciled, backing off when not.
  ///
  /// A call while a full run goes joins it, as does a quick call while a
  /// quick run goes; a full call while a quick run goes waits for it and
  /// then runs.
  Future<SyncReport> run({
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
      return running;
    }
    late final Future<SyncReport> next;
    next = _exclusively(() => _run(confirm, onProgress, quick: quick))
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

    final context = _RunContext(
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
          case _Outcome.done:
            report.done.update(decision.kind, (n) => n + 1, ifAbsent: () => 1);
            if (const {
              SyncActionKind.download,
              SyncActionKind.trashLocal,
              SyncActionKind.moveLocal,
            }.contains(decision.kind)) {
              report.changedLocally.addAll([decision.path, ?decision.fromPath]);
            }
            _log.info('apply: $decision (${clock.elapsedMilliseconds} ms)');
          case _Outcome.skipped:
            report.skipped.add(decision.path);
            _log.info(
              'apply: skipped ${decision.kind.name} "${decision.path}": '
              'a side changed during the run, decided again next time',
            );
          case _Outcome.conflict:
            break;
        }
      } on WebDavAuthFailure {
        rethrow;
      } on WebDavRetryable catch (e) {
        if (e.status == null) rethrow; // the network: everything will fail
        _noteRetryAfter(report, e.retryAfter);
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

  // --- conflicts, one file at a time ---------------------------------

  /// The texts of a conflicted [path]: the local file, the server's copy,
  /// and the version both last agreed on when history still has it — what
  /// the merge view needs. Decoded as UTF-8 (malformed bytes replaced).
  /// Throws [SyncFailure].
  Future<({String local, String remote, String? base})> conflictTexts(
    String path,
  ) => _exclusively(() async {
    final connection = await _connect();
    try {
      final localBytes = await File(p.join(root, path)).readAsBytes();
      final remoteBytes = await connection.client.readBytes(path);
      final base = await _baseText(path);
      _log.info(
        'conflict $path: read ${localBytes.length} b local, '
        '${remoteBytes.length} b remote, '
        '${base == null ? 'no base' : '${base.length} chars of base'}',
      );
      return (
        local: utf8.decode(localBytes, allowMalformed: true),
        remote: utf8.decode(remoteBytes, allowMalformed: true),
        base: base,
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
  /// together: it is written here (the replaced text becomes a `sync`
  /// history version) and uploaded, and the row records the agreement.
  /// Throws [SyncFailure].
  Future<void> resolveMerged(String path, String text) =>
      _exclusively(() async {
        final clock = Stopwatch()..start();
        _log.info('resolve $path: merged text (${text.length} chars)');
        final connection = await _connect();
        final client = connection.client;
        try {
          final capabilities = await _capabilities(
            client,
            connection.destination,
          );
          final remote = await client.stat(path);
          final c = _RunContext(
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
          await ops.syncMerge(path, text);
          final local = await _stat(path);
          if (local == null) {
            throw SyncFailure(SyncAbort.failed, '$path is gone here');
          }
          final sha = (await _hashLocal(root, [path]))[path]!;
          await _ensureRemoteParent(c, path);
          await client.uploadFile(
            path,
            File(p.join(root, path)),
            ifMatch: capabilities.ifMatch ? remote?.etag : null,
          );
          final listed = await client.stat(path);
          if (listed == null) {
            throw SyncFailure(SyncAbort.failed, '$path uploaded, not listed');
          }
          await store.putItems([
            await _row(c, path, sha: sha, local: local, remote: listed),
          ]);
          _log.info('resolve $path: merged (${clock.elapsedMilliseconds} ms)');
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

  /// Resolves a conflict at [path] by keeping one whole side: with
  /// [keepLocal] the local file is uploaded over the server's (guarded by
  /// `If-Match` where the server honors it); otherwise the server's copy
  /// replaces the local file, whose text becomes a `sync` history
  /// version. Either way the agreed row and the merge base are recorded.
  /// Throws [SyncFailure].
  Future<void> resolveConflict(
    String path, {
    required bool keepLocal,
  }) => _exclusively(() async {
    final clock = Stopwatch()..start();
    _log.info('resolve $path: keep ${keepLocal ? 'local' : 'remote'}');
    final connection = await _connect();
    final client = connection.client;
    try {
      final capabilities = await _capabilities(client, connection.destination);
      final remote = await client.stat(path);
      final c = _RunContext(
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
      if (keepLocal) {
        final local = await _stat(path);
        if (local == null) {
          throw SyncFailure(SyncAbort.failed, '$path is gone here');
        }
        final sha = (await _hashLocal(root, [path]))[path]!;
        await _ensureRemoteParent(c, path);
        await client.uploadFile(
          path,
          File(p.join(root, path)),
          ifMatch: capabilities.ifMatch ? remote?.etag : null,
          ifNoneMatch: remote == null && capabilities.ifNoneMatch,
        );
        final listed = await client.stat(path);
        if (listed == null) {
          throw SyncFailure(SyncAbort.failed, '$path uploaded, not listed');
        }
        await store.putItems([
          await _row(c, path, sha: sha, local: local, remote: listed),
        ]);
      } else {
        if (remote == null) {
          throw SyncFailure(SyncAbort.failed, '$path is gone on the server');
        }
        final fetched = await _fetch(c, path);
        await ops.syncReplace(path, fetched.temp.path);
        final local = await _stat(path);
        if (local == null) {
          throw SyncFailure(SyncAbort.failed, '$path not on disk');
        }
        await store.putItems([
          await _row(
            c,
            path,
            sha: fetched.download.sha256,
            local: local,
            remote: _remoteFrom(c, path, fetched.download),
          ),
        ]);
      }
      _log.info('resolve $path: done (${clock.elapsedMilliseconds} ms)');
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
        final state = await _stat(path);
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
      // The sink is ours, not the client's (issue #103). Handing
      // `temp.openWrite()` straight in left its closing to whatever the
      // consumer did with it, and the file the download had just written
      // then went into a rename that never returned on Windows — where,
      // unlike POSIX, a file with a handle still on it cannot be
      // renamed. A note never hit it because its temp is written by
      // `writeAsBytes`, which closes on its own.
      final sink = temp.openWrite();
      final WebDavDownload download;
      try {
        download = await c.client.download(path, sink);
      } finally {
        // The consumer closes the sink; closing a closed sink is a no-op
        // that hands back the same `done`. Awaiting it is what says the
        // bytes are on disk and the handle is gone before anyone renames.
        await sink.close().catchError((Object _) {});
        await sink.done.catchError((Object _) {});
      }
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
        c.report.changedLocally.add(d.path);
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

    // Both sides changed: with the version they last agreed on, the edits
    // that do not overlap merge without asking anyone (docs/dev/sync.md,
    // "Conflicts").
    final merge = await _tryMerge(c, d, fetched.temp, remote);
    if (merge != null) {
      await fetched.temp.delete();
      c.report
        ..merged.add(d.path)
        ..changedLocally.addAll(merge.changedLocally ? [d.path] : const []);
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

  /// Merges both sides of [d] over the pinned base and writes the result
  /// on both, or returns null when there is no base, the file is not
  /// text, or the edits overlap (then the conflict stays for the user).
  Future<({bool changedLocally})?> _tryMerge(
    _RunContext c,
    SyncDecision d,
    File remoteCopy,
    WebDavResource remote,
  ) async {
    final base = d.baseVersion;
    if (base == null || !NoteOps.keepsHistory(d.path)) return null;
    final String baseText;
    try {
      baseText = await ops.readNoteVersion(d.path, base);
    } on Object catch (e) {
      _log.info('merge ${d.path}: base v$base unreadable ($e)');
      return null;
    }
    final localText = utf8.decode(
      await File(p.join(root, d.path)).readAsBytes(),
      allowMalformed: true,
    );
    final remoteText = utf8.decode(
      await remoteCopy.readAsBytes(),
      allowMalformed: true,
    );
    final merge = await _mergeTexts(baseText, localText, remoteText);
    if (!merge.clean) {
      _log.info(
        'merge ${d.path}: ${merge.conflicts.length} overlapping region(s), '
        'left for the user (${merge.describe()})',
      );
      return null;
    }
    final text = merge.text();
    final changedLocally = text != localText;
    if (changedLocally) await ops.syncMerge(d.path, text);
    // The file on disk is the merge now: hash and stat it as written.
    final local = await _stat(d.path);
    if (local == null) throw const _StepFailure('merged but not on disk');
    final sha = (await _hashLocal(root, [d.path]))[d.path];
    if (sha == null) throw const _StepFailure('merged but not hashed');
    await _ensureRemoteParent(c, d.path);
    await c.client.uploadFile(
      d.path,
      File(p.join(root, d.path)),
      ifMatch: c.capabilities.ifMatch ? remote.etag : null,
      modified: DateTime.fromMillisecondsSinceEpoch(local.mtimeMs),
    );
    final listed = await c.client.stat(d.path);
    if (listed == null) throw const _StepFailure('merged but not listed');
    await store.putItems([
      await _row(c, d.path, sha: sha, local: local, remote: listed),
    ]);
    _log.info('merge ${d.path}: ${merge.describe()}, both sides now agree');
    return (changedLocally: changedLocally);
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

  /// Texts up to this many characters (all three together) are merged on
  /// the calling isolate; an isolate costs more than the merge itself.
  static const _inlineMergeLimit = 20000;

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

/// What a scan found: files on both sides, the remote folders known to
/// exist, and the agreed rows in scope.
typedef _Scan = ({
  Map<String, LocalFileState> local,
  Map<String, WebDavResource> remote,
  Set<String> folders,
  Map<String, SyncItem> rows,
});

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
