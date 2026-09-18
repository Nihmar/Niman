import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/trash.dart';

/// The Trash and history area of the settings home (issue #104): what
/// sits in the trash, what the history keeps, and the reindex.
final class SettingsTrashHistoryScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsTrashHistoryScreen> createState() =>
      _SettingsTrashHistoryScreenState();
}

final class _SettingsTrashHistoryScreenState
    extends State<SettingsTrashHistoryScreen> {
  bool? _trash;
  int _trashAutoEmptyDays = trashAutoEmptyOff;
  int _historyVersions = defaultHistoryVersions;
  int _historyInterval = defaultHistoryIntervalMinutes;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final ops = controller.ops;
    if (ops == null) return;
    final trash = await ops.trashEnabled;
    final trashAutoEmptyDays = await controller.trashAutoEmptyDays;
    final historyVersions = await controller.historyVersions;
    final historyInterval = await controller.historyIntervalMinutes;
    if (!mounted) return;
    setState(() {
      _trash = trash;
      _trashAutoEmptyDays = trashAutoEmptyDays;
      _historyVersions = historyVersions;
      _historyInterval = historyInterval;
    });
  }

  Future<void> _toggleTrash(bool value) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    await ops.setTrashEnabled(enabled: value);
    widget.controller.notify();
    if (mounted) {
      setState(() => _trash = value);
    }
  }

  /// Asks how long a deletion may sit in the trash before the library
  /// empties it on its own (issue #79).
  Future<void> _chooseTrashAutoEmpty() async {
    final days = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('trash-auto-empty-dialog'),
      title: AppStrings.trashAutoEmptyTitle,
      subtitle: AppStrings.trashAutoEmptySubtitle,
      current: _trashAutoEmptyDays,
      options: [
        for (final choice in trashAutoEmptyChoices)
          SettingsOption(choice, AppStrings.trashAutoEmptyValue(choice)),
      ],
    );
    if (days == null) return;
    await widget.controller.setTrashAutoEmptyDays(days);
    if (mounted) setState(() => _trashAutoEmptyDays = days);
  }

  /// Asks how many versions of each note the history keeps.
  Future<void> _chooseHistoryVersions() async {
    final versions = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('history-versions-dialog'),
      title: AppStrings.historyVersionsTitle,
      subtitle: AppStrings.historyVersionsSubtitle,
      current: _historyVersions,
      options: [
        for (final count in const [0, 5, 10, 20, 50, 100])
          SettingsOption(count, AppStrings.historyVersionsValue(count)),
      ],
    );
    if (versions == null) return;
    await widget.controller.setHistoryVersions(versions);
    if (mounted) setState(() => _historyVersions = versions);
  }

  /// Asks for the least minutes between two versions kept while editing.
  Future<void> _chooseHistoryInterval() async {
    final minutes = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('history-interval-dialog'),
      title: AppStrings.historyIntervalTitle,
      subtitle: AppStrings.historyIntervalSubtitle,
      current: _historyInterval,
      options: [
        for (final choice in historyIntervalChoices)
          SettingsOption(choice, AppStrings.historyIntervalValue(choice)),
      ],
    );
    if (minutes == null) return;
    await widget.controller.setHistoryIntervalMinutes(minutes);
    if (mounted) setState(() => _historyInterval = minutes);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsAreaTrashHistory,
      controller: widget.controller,
      library: true,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: SettingsKeys.trash,
            child: SettingsSwitchRow(
              title: AppStrings.trashTitle,
              description: AppStrings.trashSubtitle,
              value: _trash ?? true,
              onChanged: _toggleTrash,
            ),
          ),
          // Under the toggle it depends on: with the trash off there is
          // nothing waiting in it to empty.
          HighlightRow(
            key: SettingsKeys.trashAutoEmpty,
            child: SettingsValueRow(
              title: AppStrings.trashAutoEmptyTitle,
              subtitle: AppStrings.trashAutoEmptySubtitle,
              value: AppStrings.trashAutoEmptyValue(_trashAutoEmptyDays),
              enabled: _trash ?? true,
              onTap: _chooseTrashAutoEmpty,
            ),
          ),
          HighlightRow(
            key: SettingsKeys.historyVersions,
            child: SettingsValueRow(
              title: AppStrings.historyVersionsTitle,
              subtitle: AppStrings.historyVersionsSubtitle,
              value: AppStrings.historyVersionsValue(_historyVersions),
              onTap: _chooseHistoryVersions,
            ),
          ),
          HighlightRow(
            key: SettingsKeys.historyInterval,
            child: SettingsValueRow(
              title: AppStrings.historyIntervalTitle,
              subtitle: AppStrings.historyIntervalSubtitle,
              value: AppStrings.historyIntervalValue(_historyInterval),
              enabled: _historyVersions > 0,
              onTap: _chooseHistoryInterval,
            ),
          ),
          // The trash itself opens from here too: the setting and what
          // it governs sit on the same screen.
          HighlightRow(
            key: const Key('open-trash-setting'),
            child: SettingsValueRow(
              title: AppStrings.trashTitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) =>
                      TrashScreen(controller: widget.controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
