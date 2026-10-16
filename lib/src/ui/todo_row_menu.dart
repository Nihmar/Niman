/// A desktop todo row's menu (#712): Edit…, Set due ▸, Priority ▸ and
/// Delete, at the pointer or under the row's ⋯.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/strings.dart';

/// What a row's menu picked.
enum TodoMenuPick {
  /// The edit dialog.
  edit,

  /// Due today.
  dueToday,

  /// Due tomorrow.
  dueTomorrow,

  /// Due in a week.
  dueNextWeek,

  /// Due on a day picked in the calendar.
  duePick,

  /// No due date.
  dueNone,

  /// Priority A.
  priorityA,

  /// Priority B.
  priorityB,

  /// Priority C.
  priorityC,

  /// No priority.
  priorityNone,

  /// Delete the task.
  delete,
}

/// The menu's rows.
List<Widget> todoRowMenuItems({required ValueChanged<TodoMenuPick> onPick}) {
  Widget item(TodoMenuPick pick, String label, {IconData? icon}) =>
      MenuItemButton(
        key: Key('todo-menu-${pick.name}'),
        leadingIcon: icon == null ? null : Icon(icon),
        onPressed: () => onPick(pick),
        child: Text(label),
      );
  final due = [
    item(TodoMenuPick.dueToday, AppStrings.todoDueToday),
    item(TodoMenuPick.dueTomorrow, AppStrings.todoDueTomorrow),
    item(TodoMenuPick.dueNextWeek, AppStrings.todoDueNextWeek),
    item(TodoMenuPick.duePick, AppStrings.todoPickDate),
    item(TodoMenuPick.dueNone, AppStrings.todoNoDueDate),
  ];
  return [
    item(
      TodoMenuPick.edit,
      '${AppStrings.todoEditAction}…',
      icon: Icons.edit_outlined,
    ),
    SubmenuButton(
      key: const Key('todo-menu-due'),
      leadingIcon: const Icon(Icons.event_outlined),
      menuChildren: due,
      child: Text(AppStrings.todoSetDue),
    ),
    SubmenuButton(
      key: const Key('todo-menu-priority'),
      leadingIcon: const Icon(Icons.flag_outlined),
      menuChildren: [
        item(TodoMenuPick.priorityA, '(A)'),
        item(TodoMenuPick.priorityB, '(B)'),
        item(TodoMenuPick.priorityC, '(C)'),
        item(TodoMenuPick.priorityNone, AppStrings.todoNoPriorityShort),
      ],
      child: Text(AppStrings.todoPriorityTitle),
    ),
    const Divider(height: pointerDenseDividerHeight),
    item(
      TodoMenuPick.delete,
      AppStrings.todoDeleteAction,
      icon: Icons.delete_outline,
    ),
  ];
}
