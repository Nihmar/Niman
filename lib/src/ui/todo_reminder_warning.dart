/// The task dialog's warning under the reminder row (split out of
/// `todo_edit_dialog.dart` for #100).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/ui/reminder_health_message.dart';
import 'package:niman/src/ui/strings.dart';

/// A warning under the reminder row: a reminder is set while a
/// precondition fails, so it would be scheduled silently and never reach
/// the user (T-TD-07). The same sentence the Todo tab's banner shows,
/// with the way to the system screen that fixes it.
final class TodoReminderWarning extends StatelessWidget {
  /// The warning for [health]; [onOpenSettings] null leaves the action out.
  const new({required this.health, required this.onOpenSettings, super.key});

  /// The failing precondition.
  final ReminderHealth health;

  /// Opens the system screen that fixes [health], or null.
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = onOpenSettings;
    return Padding(
      key: const Key('todo-dialog-reminder-warning'),
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_outlined,
              size: 16,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reminderHealthMessage(health),
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (reminderHealthFixable(health) && open != null)
            TextButton(
              key: const Key('todo-dialog-reminder-settings'),
              onPressed: () => unawaited(open()),
              child: Text(AppStrings.todoReminderFixAction),
            ),
        ],
      ),
    );
  }
}
