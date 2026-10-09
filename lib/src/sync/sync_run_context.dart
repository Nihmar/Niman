import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

/// What one sync run — or one conflict resolution — works with: the
/// connection, both sides as the scan saw them, the agreed rows, and the
/// report it fills in. Every step of the run reads it.
final class SyncRunContext {
  /// A context over the scan's results.
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

  /// The client for the destination.
  final WebDavClient client;

  /// What the server can do.
  final WebDavCapabilities capabilities;

  /// The local files the scan saw, by library-relative path.
  final Map<String, LocalFileState> local;

  /// The remote files the scan saw, by library-relative path.
  final Map<String, WebDavResource> remote;

  /// The rows both sides last agreed on, in the run's scope.
  final Map<String, SyncItem> rows;

  /// The local hashes the run computed.
  final Map<String, String> localSha;

  /// The remote hashes the run computed.
  final Map<String, String> remoteSha;

  /// The remote folders known to exist; grows as the run creates them.
  final Set<String> folders;

  /// What the run did so far.
  final SyncReport report;
}
