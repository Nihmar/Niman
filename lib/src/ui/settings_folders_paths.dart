import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/note_picker.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/sync/sync_settings_screen.dart';
import 'package:niman/src/ui/template_help.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';
import 'package:path/path.dart' as p;

/// The Folders and paths area of the settings home (issue #104): where
/// the library's parts live, the library itself, and the models and
/// server the library speaks to.
final class SettingsFoldersPathsScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({
    required this.controller,
    this.transcription,
    this.onClosed,
    super.key,
  });

  /// The session holding the settings.
  final LibrarySession controller;

  /// The installation's transcription models; null hides their section.
  final TranscriptionModels? transcription;

  /// Fired when the library closes; the shell closes the tab and
  /// restores whatever it held open.
  final VoidCallback? onClosed;

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
    if (!mounted) return;
    setState(() {
      _listFolder = listFolder;
      _templateFolder = templateFolder;
      _attachmentsFolder = attachmentsFolder;
      _quickNotePath = quickNotePath;
    });
  }

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

  /// Opens the known-library list and switches to whatever is picked
  /// (T-ML-06).
  ///
  /// The switch tears down the shell this screen is part of, so the
  /// settings screen leaves with it: `onClosed` is the same exit "Close
  /// library" takes, and the tab case falls back to popping the pushed
  /// route.
  Future<void> _switchLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SwitchLibraryScreen(
          controller: widget.controller,
          onSwitched: () {
            Navigator.of(context).pop();
            widget.onClosed?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SettingsAreaShell(
      title: AppStrings.settingsAreaFolders,
      controller: controller,
      library: true,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          SettingsValueRow(
            key: const Key('list-folder-setting'),
            title: AppStrings.listFolderTitle,
            value: _listFolder ?? defaultListFolder,
            onTap: _pickListFolder,
          ),
          SettingsValueRow(
            key: const Key('template-folder-setting'),
            title: AppStrings.templateFolderTitle,
            value: _templateFolder ?? defaultTemplateFolder,
            onTap: _pickTemplateFolder,
          ),
          // Next to the folder, because that is where someone setting
          // templates up is already standing (T-TPL-08).
          SettingsValueRow(
            key: const Key('template-help-setting'),
            title: AppStrings.templateHelpTitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const TemplateHelpScreen(),
              ),
            ),
          ),
          SettingsValueRow(
            key: const Key('attachments-folder-setting'),
            title: AppStrings.attachmentsFolderTitle,
            value: _attachmentsFolder ?? defaultAttachmentsFolder,
            onTap: _pickAttachmentsFolder,
          ),
          SettingsValueRow(
            key: const Key('quick-note-setting'),
            title: AppStrings.quickNoteTitle,
            value: _quickNotePath ?? AppStrings.quickNoteUnset,
            onTap: _pickQuickNote,
          ),
          // The library's path is a fact, not a setting: nobody chooses
          // it, it is where the library is (T-ML-07).
          ListTile(
            key: const Key('library-path'),
            title: Text(AppStrings.libraryPathTitle),
            subtitle: Text(controller.root ?? ''),
          ),
          // App-wide, like the models it points at, but next to the
          // library because that is where the voice notes it
          // transcribes live.
          if (widget.transcription case final transcription?)
            TranscriptionSettingsSection(models: transcription),
          if (controller.sync case final sync?) ...[
            ListenableBuilder(
              listenable: sync,
              builder: (context, _) {
                final status = sync.status;
                return ListTile(
                  key: const Key('sync-setting'),
                  leading: Icon(
                    status.configured
                        ? syncStatusIcon(status)
                        : Icons.cloud_off_outlined,
                  ),
                  title: Text(AppStrings.syncWebDavTitle),
                  subtitle: Text(syncStatusLine(status, DateTime.now())),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => SyncSettingsScreen(
                        sync: sync,
                        libraryName: p.basename(controller.root ?? ''),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          // Above "Close library" on purpose: switching is the common
          // move and closing is the way out of every library at once.
          SettingsValueRow(
            key: const Key('switch-library-setting'),
            title: AppStrings.switchLibraryTitle,
            onTap: _switchLibrary,
          ),
          ListTile(
            key: const Key('close-library-setting'),
            leading: const Icon(Icons.link_off),
            title: Text(AppStrings.closeLibraryTitle),
            onTap: () async {
              await controller.close();
              widget.onClosed?.call();
            },
          ),
        ],
      ),
    );
  }
}
