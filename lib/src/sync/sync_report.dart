import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_conflict.dart';

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
