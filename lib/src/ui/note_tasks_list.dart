import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/todo/note_task_order.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/note_task_row.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// The tasks that link a note (#1152), the same list in the three places it
/// lives in: under the note, in the side panel, in the phone's sheet.
///
/// Add task heads it. The open tasks follow, the soonest due first and the
/// undated last, then *Done (n)* folded, from `done.txt`. The rows come from
/// the host's map, which the list listens to, so a task edited elsewhere — or
/// a note renamed, which makes a link live or dead — shows at once. With no
/// task at all the list says so in a line, under Add task.
final class NoteTasksList extends StatefulWidget {
  /// The tasks of [host] that link the note at library-relative [path].
  const new({
    required this.host,
    required this.path,
    this.shrinkWrap = false,
    super.key,
  });

  /// The tasks, and how to tick, edit and add one.
  final NoteTasksHost host;

  /// The note's library-relative path, or null for a note outside a library.
  final String? path;

  /// Whether the list is as tall as its rows (inside the note view's section,
  /// which bounds it) rather than as tall as the room it is given.
  final bool shrinkWrap;

  @override
  State<NoteTasksList> createState() => _NoteTasksListState();
}

final class _NoteTasksListState extends State<NoteTasksList> {
  bool _doneOpen = false;

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    if (path == null) return const SizedBox.shrink();
    final host = widget.host;
    return ListenableBuilder(
      listenable: host.map,
      builder: (context, _) {
        final tasks = host.map.tasksFor(path);
        final open = sortedByDue(tasks.open);
        final today = host.today;
        final rows = <Widget>[
          _AddTask(onPressed: () => unawaited(host.add(path))),
          if (tasks.isEmpty) const _Empty(),
          for (final entry in open) _row(host, path, today, entry, done: false),
          if (tasks.done.isNotEmpty)
            _DoneHeader(
              count: tasks.done.length,
              open: _doneOpen,
              onTap: () => setState(() => _doneOpen = !_doneOpen),
            ),
          if (_doneOpen && tasks.done.isNotEmpty)
            for (final entry in tasks.done)
              _row(host, path, today, entry, done: true),
        ];
        return ListView(
          key: const Key('tasks-for-note'),
          shrinkWrap: widget.shrinkWrap,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: rows,
        );
      },
    );
  }

  Widget _row(
    NoteTasksHost host,
    String path,
    DateTime today,
    TodoEntry entry, {
    required bool done,
  }) {
    return NoteTaskRow(
      // A row is a line of one file: a tick moves the task to the other.
      key: ValueKey('${done ? 'done' : 'open'}|${entry.lineIndex}'),
      entry: entry,
      done: done,
      notePath: path,
      today: today,
      links: host.links,
      onToggle: (_) => unawaited(host.toggle(entry, done: done)),
      onEdit: () => unawaited(host.edit(context, entry, done: done)),
    );
  }
}

/// Add task, the head of the list.
final class _AddTask extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const Key('tasks-for-note-add'),
          onPressed: onPressed,
          icon: const Icon(Icons.add_task_outlined, size: 18),
          label: Text(AppStrings.todoAddTooltip),
        ),
      ),
    );
  }
}

/// What the list says when no task links the note.
final class _Empty extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        AppStrings.tasksForNoteEmpty,
        key: const Key('tasks-for-note-empty'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// *Done (n)*: folds the completed tasks of `done.txt` away, or opens them.
final class _DoneHeader extends StatelessWidget {
  const new({required this.count, required this.open, required this.onTap});

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      expanded: open,
      label: '${AppStrings.todoDone}, $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: const Key('tasks-for-note-done'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: pointerDense(theme) ? 32 : thumbTarget,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 0),
            child: Row(
              children: [
                Icon(
                  open ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${AppStrings.todoDone} ($count)',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
