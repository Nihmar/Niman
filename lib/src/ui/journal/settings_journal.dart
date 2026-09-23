/// Settings → Library → Journal (#7, mockup D): where the entries go,
/// how they are named, the template they are made from, and when a new
/// day begins. Library settings: they travel with the library.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/journal/journal_pattern.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/templates/repo.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Journal area.
final class SettingsJournalScreen extends StatefulWidget {
  /// The area for [controller]'s library; [highlight] is the row the
  /// settings search landed on. [clock] is the device's time (tests).
  const new({required this.controller, this.highlight, this.clock, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row to flash, or null.
  final Key? highlight;

  /// The time "today's entry" is shown for; now by default.
  final DateTime Function()? clock;

  @override
  State<SettingsJournalScreen> createState() => _SettingsJournalScreenState();
}

final class _SettingsJournalScreenState extends State<SettingsJournalScreen> {
  JournalSettings? _settings;
  Set<String> _folderPaths = const {};
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
    final ops = widget.controller.ops;
    if (ops == null) return;
    final settings = await ops.journal;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _folderPaths = {for (final folder in folders) folder.path};
    });
  }

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  Future<void> _save(JournalSettings settings) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    await ops.setJournal(settings);
    widget.controller.notify();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _pickFolder(JournalSettings settings) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    final folder = await showFolderPicker(
      context,
      title: AppStrings.journalFolderTitle,
      folders: folders,
      ops: ops,
      current: settings.folder,
    );
    if (folder == null) return;
    await _save(settings.copyWith(folder: cleanJournalFolder(folder)));
  }

  Future<void> _editEntryName(JournalSettings settings) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _EntryNameDialog(
        initial: settings.entryName,
        folder: settings.folder,
        day: settings.today(_now),
      ),
    );
    if (name == null) return;
    await _save(settings.copyWith(entryName: name));
  }

  Future<void> _pickTemplate(JournalSettings settings) async {
    final source = await widget.controller.templateSource;
    final templates = source == null
        ? const <TemplateEntry>[]
        : await source.templates();
    if (!mounted) return;
    // A record, so "none" can be told from a dismissed dialog.
    final picked = await showDialog<({String? path})>(
      context: context,
      builder: (context) => SimpleDialog(
        key: const Key('journal-template-picker'),
        title: Text(AppStrings.journalTemplateTitle),
        children: [
          SimpleDialogOption(
            key: const Key('journal-template-none'),
            onPressed: () => Navigator.pop(context, (path: null)),
            child: Text(AppStrings.journalTemplateNone),
          ),
          for (final template in templates)
            SimpleDialogOption(
              key: Key('journal-template-${template.path}'),
              onPressed: () => Navigator.pop(context, (path: template.path)),
              child: Text(template.name),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await _save(
      picked.path == null
          ? settings.copyWith(clearTemplate: true)
          : settings.copyWith(template: picked.path),
    );
  }

  Future<void> _pickDayStart(JournalSettings settings) async {
    final hour = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        key: const Key('journal-day-start-picker'),
        title: Text(AppStrings.journalDayStartTitle),
        children: [
          for (var hour = 0; hour <= maxJournalDayStartHour; hour++)
            SimpleDialogOption(
              key: Key('journal-day-start-$hour'),
              onPressed: () => Navigator.pop(context, hour),
              child: Text(_hourLabel(hour)),
            ),
        ],
      ),
    );
    if (hour == null) return;
    await _save(settings.copyWith(dayStartHour: hour));
  }

  static String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final theme = Theme.of(context);
    return SettingsAreaShell(
      title: AppStrings.paletteGroupJournal,
      controller: widget.controller,
      library: true,
      highlight: widget.highlight,
      body: settings == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    AppStrings.journalIntro,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                HighlightRow(
                  key: SettingsKeys.journalFolder,
                  child: SettingsValueRow(
                    title: AppStrings.journalFolderTitle,
                    subtitle: AppStrings.journalFolderSubtitle,
                    value: settings.folder.isEmpty
                        ? AppStrings.libraryRoot
                        : settings.folder,
                    badge:
                        settings.folder.isEmpty ||
                            _folderPaths.contains(settings.folder)
                        ? null
                        : AppStrings.settingsFolderToCreate,
                    onTap: () => _pickFolder(settings),
                  ),
                ),
                HighlightRow(
                  key: SettingsKeys.journalEntryName,
                  child: SettingsValueRow(
                    title: AppStrings.journalEntryNameTitle,
                    subtitle: AppStrings.journalEntryNamePreview(
                      settings.entryPath(settings.today(_now)),
                    ),
                    value: settings.entryName,
                    onTap: () => _editEntryName(settings),
                  ),
                ),
                HighlightRow(
                  key: SettingsKeys.journalTemplate,
                  child: SettingsValueRow(
                    title: AppStrings.journalTemplateTitle,
                    subtitle: AppStrings.journalTemplateSubtitle,
                    value: settings.template ?? AppStrings.journalTemplateNone,
                    onTap: () => _pickTemplate(settings),
                  ),
                ),
                HighlightRow(
                  key: SettingsKeys.journalDayStart,
                  child: SettingsValueRow(
                    title: AppStrings.journalDayStartTitle,
                    subtitle: AppStrings.journalDayStartSubtitle,
                    value: _hourLabel(settings.dayStartHour),
                    onTap: () => _pickDayStart(settings),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The entry name, typed, with today's entry shown as it is typed and a
/// name that cannot be one refused before it is saved.
final class _EntryNameDialog extends StatefulWidget {
  const new({required this.initial, required this.folder, required this.day});

  final String initial;
  final String folder;
  final DateTime day;

  @override
  State<_EntryNameDialog> createState() => _EntryNameDialogState();
}

final class _EntryNameDialogState extends State<_EntryNameDialog> {
  late final TextEditingController _field = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  JournalPattern? get _pattern => JournalPattern.tryParse(_field.text.trim());

  void _save() {
    if (_pattern == null) return;
    Navigator.pop(context, _field.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _pattern;
    final preview = pattern == null
        ? null
        : JournalSettings(
            folder: widget.folder,
            entryName: pattern.source,
          ).entryPath(widget.day);
    return AlertDialog(
      title: Text(AppStrings.journalEntryNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('journal-entry-name-field'),
            controller: _field,
            autofocus: true,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
              helperText: AppStrings.journalEntryNameSubtitle,
              helperMaxLines: 3,
              errorText: pattern == null
                  ? AppStrings.journalEntryNameInvalid
                  : null,
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                AppStrings.journalEntryNamePreview(preview),
                key: const Key('journal-entry-name-preview'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('journal-entry-name-save'),
          onPressed: pattern == null ? null : _save,
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}
