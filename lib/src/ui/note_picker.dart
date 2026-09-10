/// Picking one note out of the library, from a dialog.
///
/// The library tree is already a lazy, reusable widget, and a picker that
/// showed anything else — a flat list, a search box — would be a second
/// way to find a note that disagrees with the first. So the dialog is the
/// tree, and a tap on a note is the answer.
library;

import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:flutter/material.dart';

/// Asks for a note, resolving to its library-relative path or null.
Future<String?> showNotePicker(
  BuildContext context, {
  required LibrarySession controller,
  required String title,
  String? currentPath,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NotePicker(
      controller: controller,
      title: title,
      currentPath: currentPath,
    ),
  );
}

/// Picks a note as the quick note; true when the quick note changed.
Future<bool> showQuickNotePicker(
  BuildContext context, {
  required LibrarySession controller,
  String? currentPath,
}) async {
  final path = await showNotePicker(
    context,
    controller: controller,
    title: AppStrings.quickNotePickerTitle,
    currentPath: currentPath,
  );
  if (path == null) return false;
  final ops = controller.ops;
  if (ops == null) return false;
  await ops.setQuickNotePath(path: path);
  return true;
}

final class _NotePicker extends StatefulWidget {
  const new({
    required this.controller,
    required this.title,
    required this.currentPath,
  });

  final LibrarySession controller;
  final String title;
  final String? currentPath;

  @override
  State<_NotePicker> createState() => _NotePickerState();
}

final class _NotePickerState extends State<_NotePicker> {
  final Set<String> _expanded = <String>{};

  void _toggle(String path) {
    setState(() {
      if (_expanded.contains(path)) {
        _expanded.remove(path);
      } else {
        _expanded.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('note-picker'),
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        height: 400,
        child: NoteTree(
          controller: widget.controller,
          selectedPath: widget.currentPath,
          expanded: _expanded,
          onToggle: _toggle,
          onSelect: (note) {
            // A folder opens; only a note is an answer.
            if (note.isDir) {
              _toggle(note.path);
            } else {
              Navigator.pop(context, note.path);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }
}
