import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/update_actions.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/update/update_service.dart';

/// The Updates area of the settings home (issue #104). Exists only on
/// the release channel (issue #106): testing builds check no release
/// channel, so the whole area is out, not just its toggles.
final class SettingsUpdatesScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({
    required this.controller,
    this.highlight,
    this.checkUpdate = checkThisDevice,
    this.downloadUpdate = downloadAndApplyUpdate,
    super.key,
  });

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  /// Asks the release channel for an update to this device; a test hands in
  /// its own answer instead of the network's.
  final Future<UpdateAvailable?> Function() checkUpdate;

  /// Fetches [UpdateAvailable] and hands it to the platform; a test counts
  /// the calls instead.
  final Future<void> Function(BuildContext context, UpdateAvailable update)
  downloadUpdate;

  @override
  State<SettingsUpdatesScreen> createState() => _SettingsUpdatesScreenState();
}

final class _SettingsUpdatesScreenState extends State<SettingsUpdatesScreen> {
  bool? _autoUpdate;
  bool _checkingUpdates = false;
  bool _downloading = false;
  String? _updateStatus;

  /// The update the last check found, or the one the scheduled check left
  /// on the session: what the Download row fetches. Null keeps it disabled.
  UpdateAvailable? _update;

  @override
  void initState() {
    super.initState();
    _update = widget.controller.pendingUpdate;
    if (_update case final update?) {
      _updateStatus = AppStrings.updateAvailableMessage(update.version);
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    final autoUpdate = await widget.controller.autoUpdateEnabled;
    if (!mounted) return;
    setState(() => _autoUpdate = autoUpdate);
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    final controller = widget.controller;
    await controller.setAutoUpdateEnabled(enabled: value);
    if (mounted) {
      setState(() => _autoUpdate = value);
    }
  }

  /// Runs a manual update check (issue #81), and only checks.
  ///
  /// Works regardless of the automatic toggle. The outcome — available, up
  /// to date, or failed — lands in the row's status line, never in a dialog;
  /// an update found enables the Download row below, and nothing is fetched
  /// until that is pressed: a check is not a download of 60-100 MB.
  Future<void> _checkUpdatesManually() async {
    if (_checkingUpdates) return;
    setState(() {
      _checkingUpdates = true;
      _updateStatus = null;
    });
    try {
      final update = await widget.checkUpdate();
      if (!mounted) return;
      if (update == null) {
        const AppLogger(name: 'update').debug('manual check: up to date');
        setState(() {
          _update = null;
          _updateStatus = AppStrings.updateUpToDate;
        });
        return;
      }
      const AppLogger(name: 'update')
          .debug('manual check: available ${update.version}');
      setState(() {
        _update = update;
        _updateStatus = AppStrings.updateAvailableMessage(update.version);
      });
    } on Object catch (error) {
      // The row stays generic; the reason goes to the debug log so an
      // exported log shows what the check tripped on (issue #81).
      const AppLogger(name: 'update').warning('manual check failed: $error');
      if (!mounted) return;
      setState(() => _updateStatus = AppStrings.updateCheckFailed);
    } finally {
      if (mounted) {
        setState(() => _checkingUpdates = false);
      }
    }
  }

  /// Downloads the update the check found and hands it to the platform.
  Future<void> _download() async {
    final update = _update;
    if (update == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      await widget.downloadUpdate(context, update);
      widget.controller.clearPendingUpdate();
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsSectionUpdates,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (!isTestingBuild) ...[
            HighlightRow(
              key: SettingsKeys.autoUpdate,
              child: SettingsSwitchRow(
                title: AppStrings.autoUpdateTitle,
                description: AppStrings.autoUpdateSubtitle,
                value: _autoUpdate ?? false,
                onChanged: _toggleAutoUpdate,
              ),
            ),
            HighlightRow(
              key: SettingsKeys.checkUpdates,
              child: SettingsActionRow(
                title: AppStrings.checkForUpdatesTitle,
                description: _updateStatus,
                busy: _checkingUpdates,
                onTap: _checkUpdatesManually,
              ),
            ),
            // Always here, enabled once a check found something: the row a
            // thumb is on does not move when the check answers.
            SettingsActionRow(
              key: const Key('settings-update-download'),
              title: AppStrings.actionDownload,
              busy: _downloading,
              enabled: _update != null && !_checkingUpdates,
              onTap: () => unawaited(_download()),
            ),
          ],
        ],
      ),
    );
  }
}

/// The manual check: the running version against the latest release, with
/// this device's asset.
Future<UpdateAvailable?> checkThisDevice() async {
  final current = await currentAppVersion();
  const AppLogger(name: 'update').debug('manual check from $current');
  return await checkNow(current: current);
}
