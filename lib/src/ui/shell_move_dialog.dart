/// The move-target picker (#51): a folder dropdown resolving to the
/// target parent path ('' = root) or null.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/strings.dart';

/// A move-target picker over all indexed folders; resolves to the target
/// parent path ('' = root) or null.
Future<String?> showMoveDialog(
  BuildContext context, {
  required String name,
  required List<Note> folders,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => MovePicker(name: name, folders: folders),
  );
}

/// Move-target picker shell: the note's name, the folders to choose from.
final class MovePicker extends StatefulWidget {
  /// Creates the picker.
  const new({required this.name, required this.folders, super.key});

  /// The note being moved.
  final String name;

  /// The indexed folders to choose from.
  final List<Note> folders;

  @override
  State<MovePicker> createState() => MovePickerState();
}

/// The picker's state: the chosen target, if any.
final class MovePickerState extends State<MovePicker> {
  String? _target;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.moveTitle(widget.name)),
      content: SizedBox(
        width: 320,
        child: DropdownButton<String>(
          value: _target,
          hint: Text(AppStrings.chooseDestination),
          onChanged: (value) => setState(() => _target = value),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(AppStrings.libraryRoot),
            ),
            for (final folder in widget.folders)
              DropdownMenuItem<String>(
                value: folder.path,
                child: Text(folder.path),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: _target == null
              ? null
              : () => Navigator.pop(context, _target),
          child: Text(AppStrings.actionMove),
        ),
      ],
    );
  }
}
