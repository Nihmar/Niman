import 'dart:async';

import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:flutter/material.dart';

/// Picks a note as the quick note: the dialog shows the library tree
/// (lazy, reusable [NoteTree]) and a tap on a note row sets it
/// immediately. Returns true when the quick note changed.
Future<bool> showQuickNotePicker(
  BuildContext context, {
  required LibrarySession controller,
  String? currentPath,
}) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (context) =>
        QuickNotePicker(controller: controller, currentPath: currentPath),
  );
  return changed == true;
}

/// The picker dialog body.
final class QuickNotePicker extends StatefulWidget {
  /// Creates the picker dialog.
  const new({required this.controller, required this.currentPath, super.key});

  /// The session providing the tree rows and the ops.
  final LibrarySession controller;

  /// The currently quick note path (highlighted in the tree).
  final String? currentPath;

  @override
  State<QuickNotePicker> createState() => _QuickNotePickerState();
}

final class _QuickNotePickerState extends State<QuickNotePicker> {
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

  Future<void> _choose(Note note) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    await ops.setQuickNotePath(path: note.path);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.quickNotePickerTitle),
      content: SizedBox(
        width: 320,
        height: 400,
        child: NoteTree(
          controller: widget.controller,
          selectedPath: widget.currentPath,
          expanded: _expanded,
          onToggle: _toggle,
          onSelect: (note) {
            if (note.isDir) {
              _toggle(note.path);
            } else {
              unawaited(_choose(note));
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }
}
