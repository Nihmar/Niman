import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

const _log = AppLogger(name: 'sync');

/// Runs a sync from the UI (the status icon, "Sync now"): saves the open
/// editors first, asks before a first sync and a mass deletion (mockups
/// S4, S9), and ends with a snackbar only when there is something to say
/// (S11) — files trashed here, conflicts left, or why it stopped.
///
/// [onShowTrash] opens the trash from the snackbar; [onShowPanel] opens
/// the status panel for conflicts and failures. Returns the report, or
/// null when a run was already going.
Future<SyncReport?> runSyncFromUi(
  BuildContext context,
  SyncService sync, {
  UnsavedTracker? unsaved,
  VoidCallback? onShowTrash,
  VoidCallback? onShowPanel,
}) async {
  if (sync.status.running) return null;
  _log.info('ui: sync requested');
  try {
    await unsaved?.saveAll();
  } on Object catch (e) {
    // The sync still runs: an unsaved buffer is re-read after it anyway.
    _log.warning('ui: saving open notes before sync failed: $e');
  }
  if (!context.mounted) return null;
  final messenger = ScaffoldMessenger.of(context);
  final report = await sync.syncNow(
    confirm: (plan, {required firstSync}) async {
      if (!context.mounted) return false;
      return plan.looksLikeMassDeletion
          ? await confirmMassDeletion(context, plan)
          : await confirmFirstSync(context, plan);
    },
  );
  _log.info('ui: sync finished: ${report.summary()}');
  final aborted = report.aborted;
  final trashed = report.done[SyncActionKind.trashLocal] ?? 0;
  if (aborted != null) {
    if (aborted == SyncAbort.notConfirmed) return report;
    messenger.showSnackBar(
      SnackBar(
        key: const Key('sync-aborted-snack'),
        content: Text(syncAbortTitle(aborted)),
        action: onShowPanel == null
            ? null
            : SnackBarAction(
                label: AppStrings.syncShowAction,
                onPressed: onShowPanel,
              ),
      ),
    );
  } else if (report.conflicts.isNotEmpty || report.failures.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(
        key: const Key('sync-warnings-snack'),
        content: Text(
          report.conflicts.isNotEmpty
              ? AppStrings.syncConflictsSnack(report.conflicts.length)
              : AppStrings.syncStatusWarnings,
        ),
        action: onShowPanel == null
            ? null
            : SnackBarAction(
                label: AppStrings.syncShowAction,
                onPressed: onShowPanel,
              ),
      ),
    );
  } else if (trashed > 0) {
    messenger.showSnackBar(
      SnackBar(
        key: const Key('sync-trashed-snack'),
        content: Text(AppStrings.syncTrashedSnack(trashed)),
        action: onShowTrash == null
            ? null
            : SnackBarAction(
                label: AppStrings.syncShowAction,
                onPressed: onShowTrash,
              ),
      ),
    );
  }
  return report;
}

/// The first-sync summary (mockup S4): true starts it.
Future<bool> confirmFirstSync(BuildContext context, SyncPlan plan) async {
  final both =
      plan.count(SyncActionKind.conflict) + plan.count(SyncActionKind.record);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('sync-first-dialog'),
      title: Text(AppStrings.syncFirstTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.syncFirstIntro),
            const SizedBox(height: 8),
            _CountRow(
              key: const Key('sync-first-upload'),
              icon: Icons.upload,
              label: AppStrings.syncFirstUpload,
              count: plan.count(SyncActionKind.upload),
            ),
            _CountRow(
              key: const Key('sync-first-download'),
              icon: Icons.download,
              label: AppStrings.syncFirstDownload,
              count: plan.count(SyncActionKind.download),
            ),
            _CountRow(
              key: const Key('sync-first-both'),
              icon: Icons.done_all,
              label: AppStrings.syncFirstBoth,
              hint: AppStrings.syncFirstBothHint,
              count: both,
            ),
            const Divider(height: 24),
            Text(AppStrings.syncFirstNoDelete),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.actionCancel),
        ),
        TextButton(
          key: const Key('sync-first-start'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppStrings.syncStartAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The mass-deletion question (mockup S9): true carries the plan out.
Future<bool> confirmMassDeletion(BuildContext context, SyncPlan plan) async {
  final trash = plan.count(SyncActionKind.trashLocal);
  final delete = plan.count(SyncActionKind.deleteRemote);
  final local = trash >= delete;
  final count = local ? trash : delete;
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('sync-mass-dialog'),
      title: Text(
        local
            ? AppStrings.syncMassTrashTitle(count)
            : AppStrings.syncMassDeleteTitle(count),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            local
                ? AppStrings.syncMassTrashBody(count, plan.rowCount)
                : AppStrings.syncMassDeleteBody(count, plan.rowCount),
          ),
          if (local) ...[
            const SizedBox(height: 8),
            Text(AppStrings.syncMassTrashHint),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.actionCancel),
        ),
        TextButton(
          key: const Key('sync-mass-confirm'),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            local
                ? AppStrings.syncMassTrashConfirm
                : AppStrings.syncMassDeleteConfirm,
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

final class _CountRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.count,
    this.hint,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (hint != null)
                  Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
