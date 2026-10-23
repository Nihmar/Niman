import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart' show pathInLibrary;
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/note_tasks_list.dart';
import 'package:niman/src/ui/note_view_handle.dart';

/// The dock's "Tasks for this note" (#1152), and the phone's sheet of the
/// same: the tasks that link the note shown beside, open ones by due date and
/// Done folded, with Add task at the head. A tick ticks the task, a tap on
/// its text opens it.
final class TasksDockPane extends StatelessWidget {
  /// The tasks of [host] that link [note], whose path is read against the
  /// library rooted at [libraryRoot].
  const new({
    required this.note,
    required this.host,
    required this.libraryRoot,
    super.key,
  });

  /// The note shown beside; null when none is open.
  final NoteViewHandle? note;

  /// The tasks, and how to tick, edit and add one.
  final NoteTasksHost host;

  /// The library's root, which the note's path is read against.
  final String? libraryRoot;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    if (note == null) return const SizedBox.shrink();
    return NoteTasksList(
      host: host,
      path: pathInLibrary(libraryRoot, note.notePath),
    );
  }
}
