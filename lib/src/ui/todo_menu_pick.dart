import 'package:flutter/widgets.dart';
import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/todo/line_edits.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/todo_row_menu.dart';

/// Runs what the row menu picked for [row] (#712): the edit and the delete
/// go to the list's own handlers, every other pick rewrites the task's line
/// through [onRewrite].
///
/// [today] is the wall-clock day the due picks count from; [context] opens
/// the day picker for [TodoMenuPick.duePick].
Future<void> runTodoMenuPick(
  BuildContext context,
  TodoRowItem row,
  TodoMenuPick pick, {
  required DateTime today,
  required Future<void> Function(TodoRowItem row) onEdit,
  required Future<void> Function(TodoRowItem row) onDelete,
  required Future<void> Function(TodoRowItem row, String line) onRewrite,
}) async {
  final task = row.entry.task;
  switch (pick) {
    case TodoMenuPick.edit:
      await onEdit(row);
    case TodoMenuPick.delete:
      await onDelete(row);
    case TodoMenuPick.dueToday:
      await onRewrite(row, todoLineWithDue(task, today));
    case TodoMenuPick.dueTomorrow:
      await onRewrite(row, todoLineWithDue(task, addCalendarDays(today, 1)));
    case TodoMenuPick.dueNextWeek:
      await onRewrite(row, todoLineWithDue(task, addCalendarDays(today, 7)));
    case TodoMenuPick.dueNone:
      await onRewrite(row, todoLineWithDue(task, null));
    case TodoMenuPick.duePick:
      final day = await showDayPicker(
        context,
        initialDate: task.due ?? today,
        firstDate: DateTime(today.year - 5),
        lastDate: DateTime(today.year + 10),
      );
      if (day != null) {
        await onRewrite(row, todoLineWithDue(task, day));
      }
    case TodoMenuPick.priorityA:
      await onRewrite(row, todoLineWithPriority(task, 'A'));
    case TodoMenuPick.priorityB:
      await onRewrite(row, todoLineWithPriority(task, 'B'));
    case TodoMenuPick.priorityC:
      await onRewrite(row, todoLineWithPriority(task, 'C'));
    case TodoMenuPick.priorityNone:
      await onRewrite(row, todoLineWithPriority(task, null));
  }
}
