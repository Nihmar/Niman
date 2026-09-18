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
import 'package:niman/src/update/update_service.dart';

/// The Updates area of the settings home (issue #104). Exists only on
/// the release channel (issue #106): testing builds check no release
/// channel, so the whole area is out, not just its toggles.
final class SettingsUpdatesScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsUpdatesScreen> createState() => _SettingsUpdatesScreenState();
}

final class _SettingsUpdatesScreenState extends State<SettingsUpdatesScreen> {
  bool? _autoUpdate;
  bool _checkingUpdates = false;
  String? _updateStatus;

  @override
  void initState() {
    super.initState();
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

  /// Runs a manual update check (issue #81) and downloads when newer.
  ///
  /// Works regardless of the automatic toggle. The outcome — available
  /// (then downloaded), up to date, or failed — lands in the row's
  /// status line, never in a dialog.
  Future<void> _checkUpdatesManually() async {
    if (_checkingUpdates) return;
    setState(() {
      _checkingUpdates = true;
      _updateStatus = null;
    });
    try {
      final current = await currentAppVersion();
      const AppLogger(name: 'update').debug('manual check from $current');
      final update = await checkNow(current: current);
      if (!mounted) return;
      if (update == null) {
        const AppLogger(name: 'update').debug('manual check: up to date');
        setState(() => _updateStatus = AppStrings.updateUpToDate);
        return;
      }
      const AppLogger(name: 'update')
          .debug('manual check: available ${update.version}');
      setState(
        () => _updateStatus = AppStrings.updateAvailableMessage(update.version),
      );
      await downloadAndApplyUpdate(context, update);
      widget.controller.clearPendingUpdate();
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
          ],
        ],
      ),
    );
  }
}
