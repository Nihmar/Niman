import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/import/notion.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// The Maintenance group of the settings home (issue #104): the actions
/// that are not settings — reindexing, switching and closing the
/// library — sitting together under their own heading instead of
/// scattered among the settings as though they were ones.
final class SettingsMaintenanceGroup extends StatelessWidget {
  /// Creates the group for [controller]'s library session.
  const new({
    required this.controller,
    this.unsaved,
    this.onClosed,
    this.compact = false,
    this.libraryRows = true,
    super.key,
  });

  /// The session the actions act on.
  final LibrarySession controller;

  /// The open notes, saved before the library leaves (#351): the switch
  /// screen writes them before it switches. Null where none is wired.
  final UnsavedTracker? unsaved;

  /// Fired when the library closes or switches; the shell leaves the
  /// settings behind with it.
  final VoidCallback? onClosed;

  /// Whether the rows sit in the desktop's narrow left column (#172),
  /// sized like the areas above them rather than like a phone's list.
  final bool compact;

  /// Whether to offer Switch library and Close library; the library
  /// window does both where the rail is (#203).
  final bool libraryRows;

  /// Re-reads every note from disk into the index.
  Future<void> _rescan(BuildContext context) async {
    try {
      await controller.rescanNow();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.reindexDone)));
      }
    } on Object catch (error) {
      const AppLogger(name: 'maintenance').error('re-scan failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.reindexFailed)));
      }
    }
  }

  /// Deletes the index file and reads every note from disk into a fresh one
  /// (#368): the repair for an index that went bad, which a re-index over the
  /// damaged file could not do. The library is not forgotten — its entry, its
  /// workspace, its settings and its sync destination all stay.
  Future<void> _rebuildIndex(BuildContext context) async {
    try {
      await controller.rebuildIndex();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.reindexDone)));
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  /// Imports a Notion export (#25): picks the `.zip` Notion's "Markdown &
  /// CSV" export downloads, brings its pages into a new folder of the
  /// library, and says where they landed.
  ///
  /// The export goes in as it is elsewhere too — a `.zip` shared into the
  /// app, or dropped on the window — and all three routes run the same
  /// import (`importNotionZip`).
  Future<void> _importNotion(BuildContext context) async {
    final root = controller.root;
    if (root == null) return;
    final picked = await FilePicker.pickFile(
      dialogTitle: AppStrings.notionImportTitle,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final path = picked?.path;
    if (path == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final name = p.basename(path);
    try {
      final imported = await importNotionZip(source: path, libraryRoot: root);
      if (imported == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppStrings.importFolderEmpty(name))),
        );
        return;
      }
      // Asked for now rather than waiting for the watcher: the tree is
      // where the user looks next, and the notes have just been written.
      await controller.rescanNow();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderDone(imported.folder))),
      );
    } on Object catch (error) {
      const AppLogger(name: 'maintenance')
          .error('Notion import failed: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.notionImportFailed)),
      );
    }
  }

  /// Opens the known-library list and switches to whatever is picked
  /// (T-ML-06).
  ///
  /// The switch tears down the shell this group is part of, so `onClosed`
  /// is the same exit "Close library" takes.
  Future<void> _switchLibrary(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SwitchLibraryScreen(
          controller: controller,
          unsaved: unsaved,
          onSwitched: () {
            Navigator.of(context).pop();
            onClosed?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            AppStrings.settingsGroupMaintenance,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.reindex,
          child: ListTile(
            dense: compact,
            visualDensity: compact ? VisualDensity.compact : null,
            leading: const Icon(Icons.refresh_outlined),
            title: Text(AppStrings.reindexTitle),
            onTap: () => _rescan(context),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.rebuildIndex,
          child: ListTile(
            dense: compact,
            visualDensity: compact ? VisualDensity.compact : null,
            leading: const Icon(Icons.build_outlined),
            title: Text(AppStrings.rebuildIndexTitle),
            onTap: () => _rebuildIndex(context),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.notionImport,
          child: ListTile(
            dense: compact,
            visualDensity: compact ? VisualDensity.compact : null,
            leading: const Icon(Icons.archive_outlined),
            title: Text(AppStrings.notionImportTitle),
            onTap: () => _importNotion(context),
          ),
        ),
        // Above "Close library" on purpose: switching is the common
        // move and closing is the way out of every library at once.
        if (libraryRows) ...[
          HighlightRow(
            key: SettingsKeys.switchLibrary,
            child: ListTile(
              dense: compact,
              visualDensity: compact ? VisualDensity.compact : null,
              leading: const Icon(Icons.swap_horiz_outlined),
              title: Text(AppStrings.switchLibraryTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _switchLibrary(context),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.closeLibrary,
            child: ListTile(
              dense: compact,
              visualDensity: compact ? VisualDensity.compact : null,
              leading: const Icon(Icons.link_off_outlined),
              title: Text(AppStrings.closeLibraryTitle),
              onTap: () async {
                await controller.close();
                onClosed?.call();
              },
            ),
          ),
        ],
      ],
    );
  }
}
