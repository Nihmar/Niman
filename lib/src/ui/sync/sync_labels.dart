import 'package:flutter/material.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/strings.dart';

/// How the sync of a library reads in one line (mockup S1 subtitle, S7
/// header): running, never synced, synced at a time, or what stopped it.
String syncStatusLine(SyncStatus status, DateTime now) {
  if (!status.configured) return AppStrings.syncNotConfigured;
  if (status.running) return syncStageLine(status);
  final aborted = status.aborted;
  if (aborted != null && aborted != SyncAbort.notConfirmed) {
    return syncAbortTitle(aborted);
  }
  if (status.conflicts.isNotEmpty || status.failures.isNotEmpty) {
    return AppStrings.syncStatusWarnings;
  }
  final last = status.lastSyncAt;
  if (last == null) return AppStrings.syncNeverSynced;
  return AppStrings.syncLastSynced(historyWhen(last, now));
}

/// The progress line of a running sync (mockup S6).
String syncStageLine(SyncStatus status) => switch (status.stage) {
  SyncStage.applying when status.total > 0 => AppStrings.syncStageApplying(
    status.done + 1 > status.total ? status.total : status.done + 1,
    status.total,
  ),
  SyncStage.scanning ||
  SyncStage.comparing ||
  SyncStage.applying => AppStrings.syncStageComparing,
  SyncStage.connecting || null => AppStrings.syncStageConnecting,
};

/// What a stopped run says (mockup S10).
String syncAbortTitle(SyncAbort abort) => switch (abort) {
  SyncAbort.authentication => AppStrings.syncAbortAuth,
  SyncAbort.missingPassword => AppStrings.syncAbortMissingPassword,
  SyncAbort.offline => AppStrings.syncAbortOffline,
  SyncAbort.remoteMissing => AppStrings.syncAbortRemoteMissing,
  SyncAbort.unsupported => AppStrings.syncAbortUnsupported,
  SyncAbort.notConfirmed => AppStrings.syncAbortNotConfirmed,
  SyncAbort.notConfigured => AppStrings.syncNotConfigured,
  SyncAbort.failed => AppStrings.syncAbortFailed,
};

/// The icon of a status (the legend under mockups S6–S11).
IconData syncStatusIcon(SyncStatus status) {
  if (status.running) return Icons.sync;
  final aborted = status.aborted;
  if (aborted == SyncAbort.offline) return Icons.cloud_off;
  if (aborted != null && aborted != SyncAbort.notConfirmed) {
    return Icons.error_outline;
  }
  if (status.conflicts.isNotEmpty || status.failures.isNotEmpty) {
    return Icons.sync_problem;
  }
  return status.lastSyncAt == null ? Icons.cloud_queue : Icons.cloud_done;
}

/// The color of [syncStatusIcon]: neutral when fine, the scheme's error
/// for what needs the user, a warm tertiary for warnings.
Color syncStatusColor(SyncStatus status, ColorScheme scheme) {
  if (status.running) return scheme.primary;
  final aborted = status.aborted;
  if (aborted == SyncAbort.offline) return scheme.tertiary;
  if (aborted != null && aborted != SyncAbort.notConfirmed) {
    return scheme.error;
  }
  if (status.conflicts.isNotEmpty || status.failures.isNotEmpty) {
    return scheme.tertiary;
  }
  return scheme.onSurfaceVariant;
}

/// The title and hint of a failed connection test (mockup S3b).
({String title, String hint, IconData icon}) syncTestFailure(
  SyncTestOutcome outcome,
) => switch (outcome) {
  SyncTestOutcome.invalidUrl => (
    title: AppStrings.syncTestInvalidUrl,
    hint: AppStrings.syncTestInvalidUrlHint,
    icon: Icons.link_off,
  ),
  SyncTestOutcome.offline => (
    title: AppStrings.syncTestOffline,
    hint: AppStrings.syncTestOfflineHint,
    icon: Icons.cloud_off,
  ),
  SyncTestOutcome.authentication => (
    title: AppStrings.syncTestAuth,
    hint: AppStrings.syncTestAuthHint,
    icon: Icons.lock_outline,
  ),
  SyncTestOutcome.notFound => (
    title: AppStrings.syncTestNotFound,
    hint: AppStrings.syncTestNotFoundHint,
    icon: Icons.folder_off_outlined,
  ),
  SyncTestOutcome.unsupported => (
    title: AppStrings.syncTestUnsupported,
    hint: AppStrings.syncTestUnsupportedHint,
    icon: Icons.block,
  ),
  SyncTestOutcome.failed || SyncTestOutcome.ok => (
    title: AppStrings.syncTestFailed,
    hint: '',
    icon: Icons.error_outline,
  ),
};

/// Whether the server lacks anything that puts sync in compatible mode.
bool syncIsCompatibleMode(WebDavCapabilities caps) =>
    !caps.fileEtags || !caps.ifMatch || !caps.ifNoneMatch;

/// The capability lines of a successful test (mockup S3): whether the
/// server has it, its label, and the fallback when it does not.
List<({bool has, String label, String? detail})> syncCapabilityLines(
  WebDavCapabilities caps,
) => [
  (has: true, label: AppStrings.syncCapBasic, detail: null),
  if (caps.move)
    (has: true, label: AppStrings.syncCapMove, detail: null)
  else
    (
      has: false,
      label: AppStrings.syncCapNoMove,
      detail: AppStrings.syncCapNoMoveDetail,
    ),
  if (caps.fileEtags)
    (has: true, label: AppStrings.syncCapEtags, detail: null)
  else
    (
      has: false,
      label: AppStrings.syncCapNoEtags,
      detail: AppStrings.syncCapNoEtagsDetail,
    ),
  if (caps.ifMatch && caps.ifNoneMatch)
    (has: true, label: AppStrings.syncCapGuarded, detail: null)
  else
    (
      has: false,
      label: AppStrings.syncCapUnguarded,
      detail: AppStrings.syncCapUnguardedDetail,
    ),
];
