import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/note_picker.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/template_help.dart';

/// The Folders and paths area of the settings home (issue #104): where
/// the library's notes, templates and attachments live, and the library
/// itself.
final class SettingsFoldersPathsScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsFoldersPathsScreen> createState() =>
      _SettingsFoldersPathsScreenState();
}

final class _SettingsFoldersPathsScreenState
    extends State<SettingsFoldersPathsScreen> {
  String? _listFolder;
  String? _templateFolder;
  String? _attachmentsFolder;
  String? _quickNotePath;

  /// The folders the library actually holds, for the "to create" badge:
  /// a configured value outside this set names a folder that is not
  /// there yet.
  Set<String> _folderPaths = const {};

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
    final ops = widget.controller.ops;
    if (ops == null) return;
    final listFolder = await ops.listNoteFolder;
    final templateFolder = await ops.templateFolder;
    final attachmentsFolder = await ops.attachmentsFolder;
    final quickNotePath = await ops.quickNotePath;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    setState(() {
      _listFolder = listFolder;
      _templateFolder = templateFolder;
      _attachmentsFolder = attachmentsFolder;
      _quickNotePath = quickNotePath;
      _folderPaths = {for (final folder in folders) folder.path};
    });
  }

  /// Whether [folder] is one the library holds: anything else wears the
  /// "to create" badge rather than a confident value.
  bool _exists(String folder) => _folderPaths.contains(folder);

  /// Opens the list-folder picker (T-M4-04): where the notes the tree
  /// lists live, chosen from the library's folders rather than typed.
  Future<void> _pickListFolder() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    final folder = await showFolderPicker(
      context,
      title: AppStrings.listFolderTitle,
      folders: folders,
      ops: ops,
      current: _listFolder ?? defaultListFolder,
    );
    if (folder == null) return;
    await ops.setListNoteFolder(folder: folder);
    final saved = await ops.listNoteFolder;
    widget.controller.notify();
    if (mounted) {
      setState(() => _listFolder = saved);
    }
  }

  /// Opens the template-folder picker (T-M4-05): where the note
  /// templates live, chosen from the library's folders rather than
  /// typed.
  Future<void> _pickTemplateFolder() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    final folder = await showFolderPicker(
      context,
      title: AppStrings.templateFolderTitle,
      folders: folders,
      ops: ops,
      current: _templateFolder ?? defaultTemplateFolder,
    );
    if (folder == null) return;
    await ops.setTemplateFolder(folder: folder);
    final saved = await ops.templateFolder;
    widget.controller.notify();
    if (mounted) {
      setState(() => _templateFolder = saved);
    }
  }

  /// Opens the attachments-folder picker (issue #56): where images
  /// copied in by the editor and voice-note clips live, chosen from the
  /// library's folders rather than typed.
  Future<void> _pickAttachmentsFolder() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    final folder = await showFolderPicker(
      context,
      title: AppStrings.attachmentsFolderTitle,
      folders: folders,
      ops: ops,
      current: _attachmentsFolder ?? defaultAttachmentsFolder,
    );
    if (folder == null) return;
    await ops.setAttachmentsFolder(folder: folder);
    final saved = await ops.attachmentsFolder;
    widget.controller.notify();
    if (mounted) {
      setState(() => _attachmentsFolder = saved);
    }
  }

  /// Opens the quick-note picker (the chosen note is set from the tree
  /// dialog); the shell picks the value up through the session.
  Future<void> _pickQuickNote() async {
    final oldPath = _quickNotePath;
    final changed = await showQuickNotePicker(
      context,
      controller: widget.controller,
      currentPath: oldPath,
    );
    if (!changed || !mounted) return;
    final path = await widget.controller.ops?.quickNotePath;
    if (mounted) {
      setState(() => _quickNotePath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final listFolder = _listFolder ?? defaultListFolder;
    final templateFolder = _templateFolder ?? defaultTemplateFolder;
    final attachmentsFolder = _attachmentsFolder ?? defaultAttachmentsFolder;
    return SettingsAreaShell(
      title: AppStrings.settingsAreaFolders,
      controller: controller,
      library: true,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: const Key('list-folder-setting'),
            child: SettingsValueRow(
              title: AppStrings.listFolderTitle,
              value: listFolder,
              badge: _exists(listFolder)
                  ? null
                  : AppStrings.settingsFolderToCreate,
              onTap: _pickListFolder,
            ),
          ),
          HighlightRow(
            key: const Key('template-folder-setting'),
            child: SettingsValueRow(
              title: AppStrings.templateFolderTitle,
              value: templateFolder,
              badge: _exists(templateFolder)
                  ? null
                  : AppStrings.settingsFolderToCreate,
              onTap: _pickTemplateFolder,
            ),
          ),
          // Next to the folder, because that is where someone setting
          // templates up is already standing (T-TPL-08).
          HighlightRow(
            key: const Key('template-help-setting'),
            child: SettingsValueRow(
              title: AppStrings.templateHelpTitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const TemplateHelpScreen(),
                ),
              ),
            ),
          ),
          HighlightRow(
            key: const Key('attachments-folder-setting'),
            child: SettingsValueRow(
              title: AppStrings.attachmentsFolderTitle,
              value: attachmentsFolder,
              badge: _exists(attachmentsFolder)
                  ? null
                  : AppStrings.settingsFolderToCreate,
              onTap: _pickAttachmentsFolder,
            ),
          ),
          HighlightRow(
            key: const Key('quick-note-setting'),
            child: SettingsValueRow(
              title: AppStrings.quickNoteTitle,
              value: _quickNotePath ?? AppStrings.quickNoteUnset,
              onTap: _pickQuickNote,
            ),
          ),
          // The library's path is a fact, not a setting: nobody chooses
          // it, it is where the library is (T-ML-07).
          ListTile(
            key: const Key('library-path'),
            title: Text(AppStrings.libraryPathTitle),
            subtitle: Text(controller.root ?? ''),
          ),
        ],
      ),
    );
  }
}
