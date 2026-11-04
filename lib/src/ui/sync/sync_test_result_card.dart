import 'package:flutter/material.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';

/// The outcome of a connection test, under the sync form's buttons: what
/// went wrong, with the certificate to trust when that is the trouble
/// (#454), or what the server can do.
final class SyncTestResultCard extends StatelessWidget {
  /// The card for [result].
  const new({
    required this.result,
    required this.current,
    required this.onTrust,
    super.key,
  });

  /// The test's outcome.
  final SyncTestResult result;

  /// Whether [result] was measured against the fields the form holds now.
  final bool current;

  /// Trusts the certificate [result] reported; null while a test runs.
  final VoidCallback? onTrust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final caps = result.capabilities;
    if (!result.ok || caps == null) {
      final failure = syncTestFailure(result.outcome);
      final fingerprint = result.fingerprint;
      // The fingerprint belongs to the address this result was measured
      // against. A result left over from another one still says what went
      // wrong there, but it is not offered for trust: what would be stored
      // is the certificate of an address the form no longer holds (#454).
      final trustable = fingerprint != null && current;
      return Card.filled(
        key: const Key('sync-test-result'),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ListTile(
          leading: Icon(failure.icon, color: scheme.error),
          title: Text(failure.title),
          subtitle: failure.hint.isEmpty && !trustable
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (failure.hint.isNotEmpty) Text(failure.hint),
                    // The certificate the user may trust, by its
                    // fingerprint, for this one destination (#454).
                    if (trustable) ...[
                      const SizedBox(height: 6),
                      SelectableText(
                        fingerprint,
                        key: const Key('sync-test-fingerprint'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilledButton.icon(
                          key: const Key('sync-trust-certificate'),
                          onPressed: onTrust,
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(AppStrings.syncCertTrustAction),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      );
    }
    final compatible = syncIsCompatibleMode(caps);
    return Card.filled(
      key: const Key('sync-test-result'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.syncTestOk,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        AppStrings.syncTestOkSubtitle(
                          compatible
                              ? AppStrings.syncModeCompatible
                              : AppStrings.syncModeFull,
                          result.elapsedMs,
                        ),
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in syncCapabilityLines(caps))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      line.has ? Icons.check : Icons.remove,
                      size: 18,
                      color: line.has
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.label),
                          if (line.detail != null)
                            Text(line.detail!, style: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (compatible) ...[
              const SizedBox(height: 10),
              Text(AppStrings.syncCompatibleNote, style: muted),
            ],
          ],
        ),
      ),
    );
  }
}
