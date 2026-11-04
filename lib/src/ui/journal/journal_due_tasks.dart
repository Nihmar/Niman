/// The open tasks due on the day the journal browser speaks for, as they
/// read in `todo.txt`'s task list (#7).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/strings.dart';

/// A day's due tasks, or nothing when none is due.
final class JournalDueTasks extends StatelessWidget {
  /// The [tasks] due on [day], under a label in [heading]; [onOpenTasks]
  /// is a task's tap.
  const new({
    required this.day,
    required this.tasks,
    required this.heading,
    this.onOpenTasks,
    super.key,
  });

  /// The day the tasks are due on.
  final DateTime day;

  /// The open tasks due on [day], as they read in the task list.
  final List<String> tasks;

  /// The style of the section's label.
  final TextStyle? heading;

  /// Opens the task list, from a task's tap.
  final VoidCallback? onOpenTasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('journal-due'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          AppStrings.journalDueOn(formatDateTime(day, 'ddd D')).toUpperCase(),
          style: heading,
        ),
        for (final task in tasks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.check_box_outline_blank,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            title: Text(task),
            onTap: onOpenTasks,
          ),
      ],
    );
  }
}
