import 'package:flutter/material.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/spinning_sync_icon.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';

/// The card atop a configured library's sync settings (mockup S5): where
/// the run stands, the server it talks to, what waits, and "Sync now".
final class SyncOverviewCard extends StatelessWidget {
  /// The card for [status], read at [now].
  const new({
    required this.status,
    required this.now,
    required this.onSyncNow,
    super.key,
  });

  /// The sync's status; its destination is set.
  final SyncStatus status;

  /// The moment the lines are worded for.
  final DateTime now;

  /// Starts a sync.
  final VoidCallback onSyncNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final destination = status.destination!;
    final url = Uri.tryParse(destination.url);
    final shortUrl = url == null
        ? destination.url
        : '${url.host}${url.hasPort ? ':${url.port}' : ''}${url.path}';
    return Card.filled(
      key: const Key('sync-overview-card'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // A run in flight turns, here as everywhere else: a
                // still glyph over "comparing with the server…" reads
                // as a sync that stopped.
                if (status.running)
                  SpinningSyncIcon(color: syncStatusColor(status, scheme))
                else
                  Icon(
                    syncStatusIcon(status),
                    color: syncStatusColor(status, scheme),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncStatusLine(status, now),
                        key: const Key('sync-status-line'),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        shortUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (syncQueueLine(status, now) case final queue?) ...[
              const SizedBox(height: 8),
              Text(
                queue,
                key: const Key('sync-overview-queue'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (status.aborted != null &&
                status.aborted != SyncAbort.notConfirmed) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.syncAbortNothingTouched,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('sync-now'),
              onPressed: status.running ? null : onSyncNow,
              icon: status.running
                  ? SpinningSyncIcon(
                      color: scheme.onSurface.withValues(alpha: 0.38),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                status.running
                    ? AppStrings.syncRunning
                    : AppStrings.syncNowAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
