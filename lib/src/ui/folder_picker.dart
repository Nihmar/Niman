import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/name_dialog.dart';
import 'package:niman/src/ui/strings.dart';

/// Picks one of the library's folders; resolves to its library-relative
/// path, or null when dismissed.
///
/// The list is the indexed folders, flat and sorted by path; a folder
/// that does not exist yet is created from the dialog itself, so the
/// caller never has to accept a typed path. [current] starts out
/// selected only if the library holds it, so the new folder lands where
/// the user put it and not inside a setting's default that was never
/// created (issue #94).
Future<String?> showFolderPicker(
  BuildContext context, {
  required String title,
  required List<Note> folders,
  required NoteOperations ops,
  String? current,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => FolderPicker(
      title: title,
      folders: folders,
      ops: ops,
      current: current,
    ),
  );
}

/// The folder picker dialog body.
final class FolderPicker extends StatefulWidget {
  /// Creates the dialog.
  const new({
    required this.title,
    required this.folders,
    required this.ops,
    required this.current,
    super.key,
  });

  /// The dialog title.
  final String title;

  /// The library's folders (any order).
  final List<Note> folders;

  /// Used to create a folder from within the dialog.
  final NoteOperations ops;

  /// The setting's folder, selected when the dialog opens — but only
  /// when [folders] holds it; otherwise it merely names what *New
  /// folder* offers to create.
  final String? current;

  @override
  State<FolderPicker> createState() => _FolderPickerState();
}

final class _FolderPickerState extends State<FolderPicker> {
  late List<String> _paths;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _paths = [for (final folder in widget.folders) folder.path]..sort();
    // Only a folder the library actually holds can start out selected.
    // A setting carries its default whether or not that folder was ever
    // created — `assets` for the attachments, `Lists` for the lists — and
    // selecting one that is not there both offered it as a choice and
    // made *New folder* nest inside it: `assets/attachments` instead of
    // `attachments`, with `assets/` brought into being on the way
    // (issue #94).
    _selected = _paths.contains(widget.current) ? widget.current : null;
  }

  /// The name *New folder* opens with: the folder the setting points at
  /// while the library has none, so the library that never created its
  /// `assets` is one tap from having it. Nothing to offer once a real
  /// folder is selected — that one is a parent, not a name.
  String get _suggestedName {
    final current = widget.current;
    if (current == null || _selected != null) return '';
    return current.split('/').last;
  }

  /// Creates a folder inside the selected one (or at the library root)
  /// and selects it, so a library without the wanted folder still needs
  /// no typed path.
  Future<void> _newFolder() async {
    final parent = _selected ?? '';
    final name = await showNameDialog(
      context,
      title: AppStrings.folderPickerNewFolder,
      initial: _suggestedName,
    );
    if (name == null) return;
    final created = await widget.ops.createFolder(
      parentPath: parent,
      name: name,
    );
    if (!mounted) return;
    setState(() {
      if (!_paths.contains(created.path)) {
        _paths = [..._paths, created.path]..sort();
      }
      _selected = created.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        height: 400,
        child: _paths.isEmpty
            ? Center(child: Text(AppStrings.folderPickerEmpty))
            : ListView.builder(
                itemCount: _paths.length,
                itemBuilder: (context, index) {
                  final path = _paths[index];
                  final selected = path == _selected;
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(path),
                    selected: selected,
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => setState(() => _selected = path),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => unawaited(_newFolder()),
          child: Text(AppStrings.folderPickerNewFolder),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('folder-picker-choose'),
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: Text(AppStrings.actionChoose),
        ),
      ],
    );
  }
}
