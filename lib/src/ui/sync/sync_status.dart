import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/spinning_sync_icon.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';

/// The sync icon in the tree's bar (mockups S6–S11), shown only for a
/// library with a destination: a tap syncs, or opens the panel when the
/// last run left something to look at; a long press always opens it.
final class SyncStatusButton extends StatelessWidget {
  /// A button over [sync].
  const new({
    required this.sync,
    required this.onSync,
    required this.onOpenPanel,
    super.key,
  });

  /// The library's sync.
  final SyncService sync;

  /// Starts a sync.
  final VoidCallback onSync;

  /// Opens the status panel.
  final VoidCallback onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final status = sync.status;
        if (!status.configured) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final attention = status.needsAttention && !status.running;
        return Tooltip(
          message:
              '${AppStrings.syncTooltip} · '
              '${syncStatusLine(status, DateTime.now())}',
          // The button's own tooltip would take the long press for
          // itself (its trigger is a long press on touch), and the panel
          // would never open. Hovering still shows it.
          triggerMode: TooltipTriggerMode.manual,
          child: GestureDetector(
            onLongPress: onOpenPanel,
            child: IconButton(
              key: const Key('sync-status-button'),
              onPressed: status.running
                  ? onOpenPanel
                  : attention
                  ? onOpenPanel
                  : onSync,
              icon: Badge(
                isLabelVisible: attention,
                backgroundColor: syncStatusColor(status, scheme),
                smallSize: 8,
                child: status.running
                    ? const SpinningSyncIcon()
                    : Icon(
                        syncStatusIcon(status),
                        color: syncStatusColor(status, scheme),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The progress strip under the tree while a sync runs (mockup S6).
final class SyncProgressStrip extends StatelessWidget {
  /// A strip over [sync]; nothing while it is idle.
  const new({required this.sync, super.key});

  /// The library's sync.
  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final status = sync.status;
        // An automatic sync works quietly: the icon turns, nothing more.
        if (!status.running || status.background) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final applying = status.stage == SyncStage.applying && status.total > 0;
        return Material(
          key: const Key('sync-progress-strip'),
          color: theme.colorScheme.surfaceContainer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                minHeight: 3,
                value: applying ? status.done / status.total : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    SpinningSyncIcon(
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncStageLine(status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Opens the status panel (mockups S7, S10) for [sync].
///
/// [onSyncNow] runs a sync; [onOpenSettings] opens the WebDAV settings
/// (also for "Update password"); [onResolve] opens a conflict.
Future<void> showSyncPanel(
  BuildContext context, {
  required SyncService sync,
  required VoidCallback onSyncNow,
  required VoidCallback onOpenSettings,
  required void Function(String path) onResolve,
}) {
  const AppLogger(name: 'sync').info(
    'ui: status panel opened (${sync.status.pendingHints} queued, '
    '${sync.status.conflicts.length} conflicts, '
    '${sync.status.failures.length} failed, '
    'paused ${sync.status.autoPaused?.name ?? 'no'})',
  );
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: sync,
      builder: (context, _) => _SyncPanel(
        status: sync.status,
        onSyncNow: () {
          Navigator.pop(context);
          onSyncNow();
        },
        onOpenSettings: () {
          Navigator.pop(context);
          onOpenSettings();
        },
        onResolve: (path) {
          Navigator.pop(context);
          onResolve(path);
        },
      ),
    ),
  );
}

final class _SyncPanel extends StatefulWidget {
  const new({
    required this.status,
    required this.onSyncNow,
    required this.onOpenSettings,
    required this.onResolve,
  });

  final SyncStatus status;
  final VoidCallback onSyncNow;
  final VoidCallback onOpenSettings;
  final void Function(String path) onResolve;

  @override
  State<_SyncPanel> createState() => _SyncPanelState();
}

final class _SyncPanelState extends State<_SyncPanel> {
  /// Keeps "retrying in 40 s" counting down while a retry is ahead.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _armTick();
  }

  @override
  void didUpdateWidget(_SyncPanel old) {
    super.didUpdateWidget(old);
    _armTick();
  }

  void _armTick() {
    final retry = widget.status.nextRetryAt;
    final ahead = retry != null && retry.isAfter(DateTime.now());
    if (!ahead) {
      _tick?.cancel();
      _tick = null;
    } else {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(_armTick);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final aborted = status.aborted;
    final stopped = aborted != null && aborted != SyncAbort.notConfirmed;
    final last = status.lastSyncAt;
    final needsPassword =
        aborted == SyncAbort.authentication ||
        aborted == SyncAbort.missingPassword ||
        status.autoPaused == SyncPause.authentication;
    final queue = syncQueueLine(status, now);
    final queueHint = syncQueueHint(status);
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
      ),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: SingleChildScrollView(
          key: const Key('sync-panel'),
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: Icon(
                  syncStatusIcon(status),
                  color: syncStatusColor(status, scheme),
                ),
                title: Text(syncStatusLine(status, now)),
                subtitle:
                    stopped ||
                        status.running ||
                        status.waitingForNetwork ||
                        status.autoPaused != null
                    ? Text(
                        last == null
                            ? AppStrings.syncNoSuccessYet
                            : AppStrings.syncLastSuccess(
                                historyWhen(last, now),
                              ),
                      )
                    : null,
              ),
              if (queue != null)
                Card.filled(
                  key: const Key('sync-queue'),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      status.autoPaused != null
                          ? Icons.pause_circle_outline
                          : Icons.schedule,
                    ),
                    title: Text(queue),
                  ),
                ),
              if (queueHint != null)
                Padding(
                  key: const Key('sync-queue-hint'),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(queueHint, style: muted),
                )
              else if (stopped)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(AppStrings.syncAbortNothingTouched, style: muted),
                ),
              if (status.conflicts.isNotEmpty) ...[
                header(AppStrings.syncConflictsHeader(status.conflicts.length)),
                for (final conflict in status.conflicts)
                  ListTile(
                    key: Key('sync-conflict-${conflict.path}'),
                    dense: true,
                    leading: Icon(Icons.call_split, color: scheme.tertiary),
                    title: Text(conflict.path),
                    subtitle: Text(AppStrings.syncConflictHint),
                    trailing: TextButton(
                      onPressed: () => widget.onResolve(conflict.path),
                      child: Text(AppStrings.syncResolveAction),
                    ),
                  ),
              ],
              if (status.failures.isNotEmpty) ...[
                header(AppStrings.syncFailuresHeader(status.failures.length)),
                for (final failure in status.failures)
                  ListTile(
                    key: Key('sync-failure-${failure.path}'),
                    dense: true,
                    leading: Icon(Icons.error_outline, color: scheme.error),
                    title: Text(failure.path),
                    subtitle: Text(
                      failure.error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(AppStrings.syncFailuresHint, style: muted),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('sync-panel-settings'),
                        onPressed: widget.onOpenSettings,
                        child: Text(
                          needsPassword
                              ? AppStrings.syncUpdatePasswordAction
                              : AppStrings.syncOpenSettingsAction,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('sync-panel-sync'),
                        onPressed: status.running ? null : widget.onSyncNow,
                        icon: const Icon(Icons.sync),
                        label: Text(
                          stopped
                              ? AppStrings.syncRetryAction
                              : AppStrings.syncNowAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
