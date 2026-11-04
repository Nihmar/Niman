import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/sync/sync_overview_card.dart';

const _log = AppLogger(name: 'sync');

/// The sync settings of a library with a destination (mockup S5): the
/// status card, when it syncs, and the server with its test, certificate
/// and disconnect.
final class SyncOverview extends StatelessWidget {
  /// The overview of [sync], which has a destination.
  const new({
    required this.sync,
    required this.testing,
    required this.onSyncNow,
    required this.onEditServer,
    required this.onRetest,
    required this.onForgetCertificate,
    required this.onDisconnect,
    super.key,
  });

  /// The library's sync.
  final SyncService sync;

  /// Whether the stored destination is being tested again.
  final bool testing;

  /// Starts a sync.
  final VoidCallback onSyncNow;

  /// Opens the server form over the stored destination.
  final VoidCallback onEditServer;

  /// Tests the stored destination again.
  final VoidCallback onRetest;

  /// Forgets the certificate trusted for the destination.
  final VoidCallback onForgetCertificate;

  /// Disconnects the library from its destination.
  final VoidCallback onDisconnect;

  Future<void> _setTriggers({
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  }) async {
    try {
      await sync.setTriggers(
        autoSync: autoSync,
        intervalSeconds: intervalSeconds,
        wifiOnly: wifiOnly,
      );
    } on Object catch (e) {
      _log.error('settings: trigger options not saved: $e');
    }
  }

  Future<void> _chooseInterval(BuildContext context) async {
    final destination = sync.status.destination;
    if (destination == null) return;
    final seconds = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('sync-interval-dialog'),
      title: AppStrings.syncIntervalTitle,
      subtitle: AppStrings.syncIntervalDialogBody,
      current: destination.intervalSeconds,
      options: [
        for (final choice in syncIntervalChoices)
          SettingsOption(choice, syncIntervalLabel(choice)),
      ],
    );
    if (seconds != null) await _setTriggers(intervalSeconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    final status = sync.status;
    final destination = status.destination!;
    final now = DateTime.now();
    final caps = status.capabilities;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SyncOverviewCard(status: status, now: now, onSyncNow: onSyncNow),
        SettingsSection(AppStrings.syncSectionWhen),
        SettingsSwitchRow(
          key: const Key('sync-auto'),
          title: AppStrings.syncAutoTitle,
          description: AppStrings.syncAutoSubtitle,
          value: destination.autoSync,
          onChanged: (on) => _setTriggers(autoSync: on),
        ),
        SettingsValueRow(
          key: const Key('sync-interval'),
          title: AppStrings.syncIntervalTitle,
          subtitle: AppStrings.syncIntervalSubtitle,
          value: syncIntervalLabel(destination.intervalSeconds),
          enabled: destination.autoSync,
          onTap: () => _chooseInterval(context),
        ),
        if (sync.offersWifiOnly)
          SettingsSwitchRow(
            key: const Key('sync-wifi-only'),
            title: AppStrings.syncWifiOnlyTitle,
            description: AppStrings.syncWifiOnlySubtitle,
            value: destination.wifiOnly,
            onChanged: destination.autoSync
                ? (on) => _setTriggers(wifiOnly: on)
                : null,
          ),
        SettingsSection(AppStrings.syncSectionServer),
        SettingsValueRow(
          key: const Key('sync-edit-server'),
          title: AppStrings.syncServerRow,
          subtitle: [
            if (destination.username.isNotEmpty) destination.username,
            if (caps != null && syncIsCompatibleMode(caps))
              AppStrings.syncModeCompatible
            else if (caps != null)
              AppStrings.syncModeFull,
          ].join(' · '),
          onTap: status.running ? () {} : onEditServer,
        ),
        SettingsActionRow(
          key: const Key('sync-retest'),
          enabled: !status.running,
          busy: testing,
          title: AppStrings.syncRetestTitle,
          description: caps == null
              ? null
              : AppStrings.syncProbedAgo(historyWhen(caps.probedAt, now)),
          onTap: onRetest,
        ),
        // The one certificate this destination may present, and the way
        // back out of trusting it (#454).
        if (destination.trustedCertFingerprint case final fingerprint?)
          SettingsActionRow(
            key: const Key('sync-forget-certificate'),
            enabled: !status.running,
            title: AppStrings.syncCertTrustedTitle,
            description: AppStrings.syncCertTrustedSubtitle(fingerprint),
            onTap: onForgetCertificate,
          ),
        const Divider(height: 24),
        SettingsActionRow(
          key: const Key('sync-disconnect'),
          enabled: !status.running,
          destructive: true,
          title: AppStrings.syncDisconnectTitle,
          description: AppStrings.syncDisconnectSubtitle,
          onTap: onDisconnect,
        ),
      ],
    );
  }
}
