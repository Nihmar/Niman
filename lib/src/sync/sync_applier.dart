import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_step_failure.dart';
import 'package:niman/src/sync/sync_step_outcome.dart';
import 'package:niman/src/sync/sync_step_pool.dart';
import 'package:niman/src/sync/sync_steps.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

/// Carries out a run's plan: each decision through the [SyncStepRunner],
/// its outcome and its failure recorded in the run's report, the transfers
/// among them a few at a time (#1107).
///
/// Uploads and downloads of distinct paths overlap, up to the pool's width;
/// every other kind of step — a delete, a move, a conflict, a record — is a
/// barrier that waits for everything in flight and runs alone, so the plan's
/// order holds wherever it matters ([SyncStepPool]). A failure of one path
/// is recorded and the run goes on; a refused login, or no answer from a
/// server that answers no other request either, ends the run, cancelling
/// what is in flight.
final class SyncApplier {
  /// An applier whose steps come from [steps], with [concurrency] transfers
  /// at once at most.
  new({required this.steps, this.concurrency = kSyncTransferConcurrency});

  /// Carries out one decision.
  final SyncStepRunner steps;

  /// How many transfers go on at once.
  final int concurrency;

  static const _log = AppLogger(name: 'sync');

  /// A probe of the server that is going on, which the steps that fail
  /// together wait on instead of each sending their own.
  Future<bool>? _probing;

  /// Carries out the decisions of [plan] within the run [c]; [onStep] hears
  /// each step as it starts, with how many have started of how many there
  /// are. Throws the failure that ends the run: [WebDavAuthFailure], or a
  /// [WebDavRetryable] the network gave and the server is silent about.
  Future<void> apply(
    SyncRunContext c,
    SyncPlan plan, {
    void Function(int started, int total)? onStep,
  }) async {
    final total = plan.decisions.length;
    var started = 0;
    final pool = SyncStepPool<SyncDecision>(
      concurrency: concurrency,
      isParallel: _isTransfer,
      keyOf: (d) => d.path,
      // The others in flight stop where they are: the run is over.
      onFatal: (_) => c.transfers.cancel(),
    );
    await pool.run(plan.decisions, (decision) {
      onStep?.call(started++, total);
      return _step(c, decision, pool);
    });
  }

  static bool _isTransfer(SyncDecision d) =>
      d.kind == SyncActionKind.upload || d.kind == SyncActionKind.download;

  /// One decision, its outcome or its failure in the report. What ends the
  /// run is thrown; a failure that only comes of the run having been
  /// stopped is not recorded — the path did not fail, it was cut short, and
  /// the next run decides it again.
  Future<void> _step(
    SyncRunContext c,
    SyncDecision decision,
    SyncStepPool<SyncDecision> pool,
  ) async {
    final report = c.report;
    final clock = Stopwatch()..start();
    try {
      final outcome = await steps.apply(c, decision);
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
      if (pool.aborted) return;
      // No answer at all: the network, and everything will fail — unless
      // the server still answers, and dropped this one request (#617).
      if (e.status == null && !await _serverAnswers(c)) rethrow;
      if (pool.aborted) return;
      report.noteRetryAfter(e.retryAfter);
      _failed(
        c,
        decision,
        e.status == null ? _refused(c, decision, e.message) : e.message,
      );
    } on WebDavFailure catch (e) {
      if (pool.aborted) return;
      _failed(
        c,
        decision,
        e.status == 413 ? _refused(c, decision, e.message) : e.message,
      );
    } on FileSystemException catch (e) {
      if (pool.aborted) return;
      _failed(c, decision, 'local: ${e.message}');
    } on SyncStepFailure catch (e) {
      if (pool.aborted) return;
      _failed(c, decision, e.message);
    }
  }

  /// Whether the server answers a `PROPFIND` of the destination: after a
  /// request lost its connection, what tells a network that is down from
  /// a server that dropped that one request (#617). Steps that fail at the
  /// same moment share one probe.
  Future<bool> _serverAnswers(SyncRunContext c) {
    final going = _probing;
    if (going != null) return going;
    final probe = _probe(c);
    _probing = probe;
    return probe.whenComplete(() => _probing = null);
  }

  Future<bool> _probe(SyncRunContext c) async {
    try {
      await c.client.propfind('', depth: 0, collection: true);
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

  void _failed(SyncRunContext c, SyncDecision decision, String error) {
    c.report.failures.add((path: decision.path, error: error));
    _log.warning(
      'apply failed: ${decision.kind.name} ${decision.path}: $error',
    );
  }
}
