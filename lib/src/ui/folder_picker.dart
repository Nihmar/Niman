import 'dart:async';

import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/name_dialog.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// Picks one of the library's folders; resolves to its library-relative
/// path, or null when dismissed.
///
/// The list is the indexed folders, flat and sorted by path; a folder
/// that does not exist yet is created from the dialog itself, so the
/// caller never has to accept a typed path.
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

  /// The folder selected when the dialog opens, if any.
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
    _selected = widget.current;
  }

  /// Creates a folder inside the selected one (or at the library root)
  /// and selects it, so a library without the wanted folder still needs
  /// no typed path.
  Future<void> _newFolder() async {
    final parent = _selected ?? '';
    final name = await showNameDialog(
      context,
      title: AppStrings.folderPickerNewFolder,
      initial: 'Lists',
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
