import 'package:meta/meta.dart';
import 'package:niman/src/history/history_manifest.dart';

/// What a save asks of history before it overwrites a note.
///
/// Plain values only: it crosses into the isolate that does the write.
@immutable
final class SnapshotRequest {
  /// Describes the snapshot wanted for one save.
  const new({
    required this.limit,
    required this.interval,
    required this.now,
    this.sessionStart = false,
    this.forced,
  });

  /// `historyVersions`: how many unpinned versions to keep (0 = none).
  final int limit;

  /// `historyIntervalMinutes`: the least time between two versions taken
  /// while editing.
  final Duration interval;

  /// The save's time, stamped on the version.
  final DateTime now;

  /// Whether this is the first save of an editing session.
  final bool sessionStart;

  /// A reason that takes a version regardless of the interval
  /// ([HistoryReason.restore], [HistoryReason.sync],
  /// [HistoryReason.replace]); null for an ordinary save.
  final HistoryReason? forced;
}

/// Whether to keep the content about to be overwritten, and why.
@immutable
final class SnapshotDecision {
  const new _(this.reason, this.why);

  /// Take a version for [reason].
  const new take(HistoryReason reason, String why) : this._(reason, why);

  /// Take nothing.
  const new skip(String why) : this._(null, why);

  /// The reason the version is taken; null when skipped.
  final HistoryReason? reason;

  /// A log-ready explanation of the decision.
  final String why;

  /// Whether a version is taken.
  bool get take => reason != null;

  @override
  String toString() => take ? 'take ${reason!.name} ($why)' : 'skip ($why)';
}

/// Decides whether the content about to be overwritten becomes a version.
///
/// [oldSha] is the sha256 of the note's current bytes, null when the note
/// does not exist yet. Pure: the caller does the reading and the writing.
SnapshotDecision decideSnapshot({
  required HistoryManifest manifest,
  required String? oldSha,
  required SnapshotRequest request,
}) {
  if (oldSha == null) {
    return const SnapshotDecision.skip('new note, nothing to keep');
  }
  if (request.limit <= 0) {
    return const SnapshotDecision.skip('history off (historyVersions 0)');
  }
  final newest = manifest.newest;
  if (newest != null && newest.sha256 == oldSha) {
    return SnapshotDecision.skip('unchanged since v${newest.number}');
  }
  final forced = request.forced;
  if (forced != null) {
    return SnapshotDecision.take(forced, 'before ${forced.name}');
  }
  if (request.sessionStart) {
    return const SnapshotDecision.take(
      HistoryReason.session,
      'first save of the session',
    );
  }
  if (newest == null) {
    return const SnapshotDecision.take(
      HistoryReason.interval,
      'no version yet',
    );
  }
  final age = request.now.difference(newest.savedAt);
  if (age >= request.interval) {
    return SnapshotDecision.take(
      HistoryReason.interval,
      'v${newest.number} is ${age.inSeconds} s old '
      '(interval ${request.interval.inSeconds} s)',
    );
  }
  return SnapshotDecision.skip(
    'v${newest.number} is ${age.inSeconds} s old, '
    'interval ${request.interval.inSeconds} s not reached',
  );
}
