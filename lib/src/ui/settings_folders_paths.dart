import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/note_picker.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/template_help.dart';

/// The Folders and paths area of the settings home (issue #104): where
/// the library's notes, templates, attachments and captured pages live,
/// and the library itself.
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
  String? _annotationsFolder;
  String? _captureFolder;
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
    final annotationsFolder = await ops.annotationsFolder;
    final captureFolder = await ops.captureFolder;
    final quickNotePath = await ops.quickNotePath;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    setState(() {
      _listFolder = listFolder;
      _templateFolder = templateFolder;
      _attachmentsFolder = attachmentsFolder;
      _annotationsFolder = annotationsFolder;
      _captureFolder = captureFolder;
      _quickNotePath = quickNotePath;
      _folderPaths = {for (final folder in folders) folder.path};
    });
  }

  /// Whether [folder] is one the library holds: anything else wears the
  /// "to create" badge rather than a confident value.
  bool _exists(String folder) => _folderPaths.contains(folder);

  /// Opens the folder picker for a folder setting, from the library's
  /// folders rather than typed, and keeps the answer with [save]: the
  /// value [read] then gives back (sanitized), or null when nothing was
  /// picked.
  Future<String?> _pickFolder({
    required String title,
    required String current,
    required Future<void> Function(NoteOperations ops, String folder) save,
    required Future<String> Function(NoteOperations ops) read,
  }) async {
    final ops = widget.controller.ops;
    if (ops == null) return null;
    final folders = await widget.controller.folders();
    if (!mounted) return null;
    final folder = await showFolderPicker(
      context,
      title: title,
      folders: folders,
      ops: ops,
      current: current,
    );
    if (folder == null) return null;
    await save(ops, folder);
    final saved = await read(ops);
    widget.controller.notify();
    return saved;
  }

  /// Where the notes the tree lists live (T-M4-04).
  Future<void> _pickListFolder() async {
    final saved = await _pickFolder(
      title: AppStrings.listFolderTitle,
      current: _listFolder ?? defaultListFolder,
      save: (ops, folder) => ops.setListNoteFolder(folder: folder),
      read: (ops) => ops.listNoteFolder,
    );
    if (saved != null && mounted) setState(() => _listFolder = saved);
  }

  /// Where the note templates live (T-M4-05).
  Future<void> _pickTemplateFolder() async {
    final saved = await _pickFolder(
      title: AppStrings.templateFolderTitle,
      current: _templateFolder ?? defaultTemplateFolder,
      save: (ops, folder) => ops.setTemplateFolder(folder: folder),
      read: (ops) => ops.templateFolder,
    );
    if (saved != null && mounted) setState(() => _templateFolder = saved);
  }

  /// Where images copied in by the editor and voice-note clips live
  /// (issue #56).
  Future<void> _pickAttachmentsFolder() async {
    final saved = await _pickFolder(
      title: AppStrings.attachmentsFolderTitle,
      current: _attachmentsFolder ?? defaultAttachmentsFolder,
      save: (ops, folder) => ops.setAttachmentsFolder(folder: folder),
      read: (ops) => ops.attachmentsFolder,
    );
    if (saved != null && mounted) setState(() => _attachmentsFolder = saved);
  }

  /// Where a note annotating a PDF or a book is made, when the file has
  /// none yet (#284).
  Future<void> _pickAnnotationsFolder() async {
    final saved = await _pickFolder(
      title: AppStrings.annotationsFolderTitle,
      current: _annotationsFolder ?? defaultAnnotationsFolder,
      save: (ops, folder) => ops.setAnnotationsFolder(folder: folder),
      read: (ops) => ops.annotationsFolder,
    );
    if (saved != null && mounted) setState(() => _annotationsFolder = saved);
  }

  /// Where a web page or a quote captured as a new note goes, unless the
  /// capture picks another folder.
  Future<void> _pickCaptureFolder() async {
    final saved = await _pickFolder(
      title: AppStrings.captureFolderTitle,
      current: _captureFolder ?? defaultCaptureFolder,
      save: (ops, folder) => ops.setCaptureFolder(folder: folder),
      read: (ops) => ops.captureFolder,
    );
    if (saved != null && mounted) setState(() => _captureFolder = saved);
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

  /// A folder setting's row: its [value], with the "to create" badge
  /// while the library does not hold that folder.
  Widget _folderRow({
    required Key key,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) => HighlightRow(
    key: key,
    child: SettingsValueRow(
      title: title,
      subtitle: subtitle,
      value: value,
      badge: _exists(value) ? null : AppStrings.settingsFolderToCreate,
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final listFolder = _listFolder ?? defaultListFolder;
    final templateFolder = _templateFolder ?? defaultTemplateFolder;
    final attachmentsFolder = _attachmentsFolder ?? defaultAttachmentsFolder;
    final annotationsFolder = _annotationsFolder ?? defaultAnnotationsFolder;
    final captureFolder = _captureFolder ?? defaultCaptureFolder;
    return SettingsAreaShell(
      title: AppStrings.settingsAreaFolders,
      controller: controller,
      library: true,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _folderRow(
            key: SettingsKeys.listFolder,
            title: AppStrings.listFolderTitle,
            subtitle: AppStrings.listFolderSubtitle,
            value: listFolder,
            onTap: _pickListFolder,
          ),
          _folderRow(
            key: SettingsKeys.templateFolder,
            title: AppStrings.templateFolderTitle,
            subtitle: AppStrings.templateFolderSubtitle,
            value: templateFolder,
            onTap: _pickTemplateFolder,
          ),
          // Next to the folder, because that is where someone setting
          // templates up is already standing (T-TPL-08).
          HighlightRow(
            key: SettingsKeys.templateHelp,
            child: SettingsValueRow(
              title: AppStrings.templateHelpTitle,
              subtitle: AppStrings.templateHelpSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const TemplateHelpScreen(),
                ),
              ),
            ),
          ),
          _folderRow(
            key: SettingsKeys.attachmentsFolder,
            title: AppStrings.attachmentsFolderTitle,
            subtitle: AppStrings.attachmentsFolderSubtitle,
            value: attachmentsFolder,
            onTap: _pickAttachmentsFolder,
          ),
          _folderRow(
            key: SettingsKeys.annotationsFolder,
            title: AppStrings.annotationsFolderTitle,
            subtitle: AppStrings.annotationsFolderSubtitle,
            value: annotationsFolder,
            onTap: _pickAnnotationsFolder,
          ),
          _folderRow(
            key: SettingsKeys.captureFolder,
            title: AppStrings.captureFolderTitle,
            subtitle: AppStrings.captureFolderSubtitle,
            value: captureFolder,
            onTap: _pickCaptureFolder,
          ),
          HighlightRow(
            key: SettingsKeys.quickNote,
            child: SettingsValueRow(
              title: AppStrings.quickNoteTitle,
              subtitle: AppStrings.quickNoteSubtitle,
              value: _quickNotePath ?? AppStrings.quickNoteUnset,
              onTap: _pickQuickNote,
            ),
          ),
          // The library's path is a fact, not a setting: nobody chooses
          // it, it is where the library is (T-ML-07).
          SettingsRowFrame(
            key: const Key('library-path'),
            title: AppStrings.libraryPathTitle,
            description: controller.root ?? '',
          ),
        ],
      ),
    );
  }
}
