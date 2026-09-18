import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

/// The Reminders area of the settings home (issue #104): what a task's
/// reminder notification carries.
///
/// Restored from the single-column settings (the split dropped the
/// section with no UI at all): a library setting with no row is a
/// setting that cannot be changed.
final class SettingsRemindersScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsRemindersScreen> createState() =>
      _SettingsRemindersScreenState();
}

final class _SettingsRemindersScreenState
    extends State<SettingsRemindersScreen> {
  bool? _showTokens;

  /// Session events: a library setting changed somewhere else.
  StreamSubscription<int>? _sessionEvents;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _sessionEvents = widget.controller.events.listen((_) => unawaited(_load()));
  }

  @override
  void dispose() {
    unawaited(_sessionEvents?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    final showTokens = await widget.controller.reminderShowTokens;
    if (!mounted) return;
    setState(() => _showTokens = showTokens);
  }

  /// Persists the reminder-markers toggle.
  ///
  /// Takes effect on the next reconciliation, which the shell triggers on
  /// the way back from here (a settings change bumps the session, and any
  /// resume resyncs), so already-scheduled alarms pick up the new text.
  Future<void> _toggleShowTokens(bool value) async {
    final controller = widget.controller;
    await controller.setReminderShowTokens(enabled: value);
    controller.notify();
    if (mounted) {
      setState(() => _showTokens = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsSectionReminders,
      controller: widget.controller,
      library: true,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: SettingsKeys.reminderShowTokens,
            child: SwitchListTile(
              title: Text(AppStrings.reminderShowTokensTitle),
              subtitle: Text(AppStrings.reminderShowTokensSubtitle),
              value: _showTokens ?? false,
              onChanged: _toggleShowTokens,
            ),
          ),
        ],
      ),
    );
  }
}
