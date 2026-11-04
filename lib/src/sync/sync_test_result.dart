import 'package:flutter/foundation.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

/// The result of [SyncService.testConnection].
@immutable
final class SyncTestResult {
  /// A test that ended with [outcome].
  const new({
    required this.outcome,
    this.capabilities,
    this.elapsedMs = 0,
    this.detail = '',
    this.host = '',
    this.fingerprint,
  });

  /// How it ended.
  final SyncTestOutcome outcome;

  /// What the server can do, when [outcome] is [SyncTestOutcome.ok].
  final WebDavCapabilities? capabilities;

  /// How long the probe took.
  final int elapsedMs;

  /// Technical detail for the log and a secondary line; never a secret.
  final String detail;

  /// The host the certificate was presented for, when [outcome] is
  /// [SyncTestOutcome.certificate] (#454).
  final String host;

  /// The certificate's SHA-256 fingerprint, when [outcome] is
  /// [SyncTestOutcome.certificate] and one is known — what the
  /// confirmation shows and stores. Null when the platform reported none.
  final String? fingerprint;

  /// Whether the folder can be used.
  bool get ok => outcome == SyncTestOutcome.ok;
}
