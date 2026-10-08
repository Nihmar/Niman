/// The Home's tasks tile (#535): the open tasks, due soonest first — the
/// order the Todo tab and the home-screen widget share.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_row.dart';

/// The open tasks.
///
/// Read from the snapshot the Todo tab already holds: no disk, and it
/// follows every change to the list as the tab does.
final class TasksDueTile extends StatelessWidget {
  /// The tile over [host]'s todo list.
  const new({required this.host, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// How many tasks it lists: the tallest tile's rows.
  static const int limit = 12;

  @override
  Widget build(BuildContext context) {
    final todo = host.todo;
    return ListenableBuilder(
      listenable: todo,
      builder: (context, _) {
        final snapshot = todo.snapshot;
        final tasks = snapshot == null
            ? const <TodoEntry>[]
            : sortTodosForWidget(snapshot, limit: limit);
        if (tasks.isEmpty) return HomeTileEmpty(AppStrings.homeTasksEmpty);
        final today = DateTime.now();
        return ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final entry in tasks)
              InkWell(
                key: Key('home-task-${entry.lineIndex}'),
                borderRadius: BorderRadius.circular(6),
                onTap: host.openTodo,
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 24,
                        child: Checkbox(
                          value: entry.task.completed,
                          visualDensity: VisualDensity.compact,
                          onChanged: (_) => unawaited(todo.check(entry)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _text(entry.task),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.task.due case final due?) ...[
                        const SizedBox(width: 8),
                        TodoDueLabel(due: due, today: today),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _text(TodoTask task) {
    final display = taskDisplayText(task.description);
    return display.isEmpty ? task.raw : display;
  }
}
