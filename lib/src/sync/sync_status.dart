import 'package:flutter/foundation.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/network_monitor.dart';
import 'package:niman/src/sync/sync_conflict.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_scheduler.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

/// What the UI shows about a library's sync.
@immutable
final class SyncStatus {
  /// A status; the defaults describe a library without sync.
  const new({
    this.destination,
    this.capabilities,
    this.running = false,
    this.background = false,
    this.stage,
    this.done = 0,
    this.total = 0,
    this.lastReport,
    this.pendingHints = 0,
    this.nextRetryAt,
    this.autoPaused,
    this.waitingForNetwork = false,
    this.network = SyncNetwork.unknown,
  });

  /// The destination, or null when the library does not sync.
  final SyncDestination? destination;

  /// The stored probe result, or null when never probed.
  final WebDavCapabilities? capabilities;

  /// Whether a run is going.
  final bool running;

  /// Whether the running sync started by itself (no progress strip).
  final bool background;

  /// Changes queued and not uploaded yet.
  final int pendingHints;

  /// When the queue or the automatic sync tries again, or null.
  final DateTime? nextRetryAt;

  /// Why the automatic sync stopped until the user acts, or null.
  final SyncPause? autoPaused;

  /// Whether the automatic sync waits for Wi-Fi (or any network).
  final bool waitingForNetwork;

  /// The network last seen (unknown off phones).
  final SyncNetwork network;

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
      autoPaused != null ||
      (aborted != null && aborted != SyncAbort.notConfirmed);

  /// A copy with the given fields replaced.
  SyncStatus copyWith({
    SyncDestination? destination,
    bool clearDestination = false,
    WebDavCapabilities? capabilities,
    bool clearCapabilities = false,
    bool? running,
    bool? background,
    SyncStage? stage,
    int? done,
    int? total,
    SyncReport? lastReport,
    bool clearReport = false,
    int? pendingHints,
    DateTime? nextRetryAt,
    bool clearRetry = false,
    SyncPause? autoPaused,
    bool clearPause = false,
    bool? waitingForNetwork,
    SyncNetwork? network,
  }) => SyncStatus(
    destination: clearDestination ? null : destination ?? this.destination,
    capabilities: clearCapabilities ? null : capabilities ?? this.capabilities,
    running: running ?? this.running,
    background: (running ?? this.running) && (background ?? this.background),
    stage: (running ?? this.running) ? stage ?? this.stage : null,
    done: done ?? this.done,
    total: total ?? this.total,
    lastReport: clearReport ? null : lastReport ?? this.lastReport,
    pendingHints: pendingHints ?? this.pendingHints,
    nextRetryAt: clearRetry ? null : nextRetryAt ?? this.nextRetryAt,
    autoPaused: clearPause ? null : autoPaused ?? this.autoPaused,
    waitingForNetwork: waitingForNetwork ?? this.waitingForNetwork,
    network: network ?? this.network,
  );
}
