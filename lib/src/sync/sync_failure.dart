import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

/// Why a conflict resolution or a conflict read could not complete.
final class SyncFailure implements Exception {
  /// A failure for [reason], with a [detail] safe to show.
  const new(this.reason, this.detail, {this.moved = false});

  /// A resolution refused because a side is no longer the version the
  /// user decided on; nothing was written.
  factory stale(String detail) =>
      SyncFailure(SyncAbort.failed, detail, moved: true);

  /// The failure a WebDAV [error] amounts to.
  ///
  /// A refused precondition is a side that moved: the only guarded writes
  /// here are a resolution's, against the version the user saw.
  factory of(WebDavFailure error) => SyncFailure(
    switch (error) {
      WebDavAuthFailure() => SyncAbort.authentication,
      WebDavNotFound() => SyncAbort.remoteMissing,
      WebDavUnsupported() => SyncAbort.unsupported,
      WebDavRetryable() => SyncAbort.offline,
      WebDavPrecondition() ||
      WebDavProtocolFailure() ||
      WebDavCertificateFailure() => SyncAbort.failed,
    },
    error.message,
    moved: error is WebDavPrecondition,
  );

  /// The same classification a run's abort uses.
  final SyncAbort reason;

  /// What went wrong; never a secret.
  final String detail;

  /// Whether a side moved after the user saw it: the conflict should be
  /// read again, not given up on.
  final bool moved;

  @override
  String toString() => 'SyncFailure(${moved ? 'moved' : reason.name}: $detail)';
}
