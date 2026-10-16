/// What the todo list's Filter and Sort controls open (#1003).
///
/// The phone's app bar and the desktop's toolbar both carry these controls
/// and open the same things, so the opening lives here once, taking the
/// controller and the shared [TodoListView]: neither caller knows what a
/// sheet holds.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/todo_filter_labels.dart';
import 'package:niman/src/ui/todo_filter_sheet.dart';

const AppLogger _log = AppLogger(name: 'todo');

/// The calendar day on [clock] (now when null): what "today" means to the
/// list's due ranges and sections.
DateTime todoDayOf(DateTime Function()? clock) {
  final now = clock?.call() ?? DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Opens the Filter sheet: a bottom sheet on a phone, a pop-up grown from
/// [anchor] (the control that opened it) where a pointer aims.
///
/// Resolves when the sheet closes; the choices were applied to [view] as
/// they were made.
Future<void> showTodoFilter(
  BuildContext context, {
  required TodoController controller,
  required TodoListView view,
  DateTime Function()? clock,
  Rect? anchor,
}) {
  _log.debug('todo filter sheet: open');
  final today = todoDayOf(clock);
  return showActionSheet<void>(
    context,
    sheetKey: const Key('todo-filter-sheet'),
    anchor: anchor,
    items: (context) => [
      TodoFilterSheet(controller: controller, view: view, today: today),
    ],
  );
}

/// Opens the Sort menu, the current key checked, and applies the pick to
/// [view].
Future<void> showTodoSort(
  BuildContext context, {
  required TodoListView view,
  Rect? anchor,
}) async {
  final current = view.filter.sort;
  final picked = await showActionSheet<TodoSort>(
    context,
    sheetKey: const Key('todo-sort-menu'),
    anchor: anchor,
    items: (context) => [
      for (final sort in TodoSort.values)
        ListTile(
          key: Key('todo-sort-${sort.name}'),
          title: Text(todoSortLabel(sort)),
          trailing: sort == current ? const Icon(Icons.check) : null,
          selected: sort == current,
          onTap: () => Navigator.of(context).pop(sort),
        ),
    ],
  );
  if (picked != null) {
    _log.debug('todo sort: ${picked.name}');
    view.setSort(picked);
  }
}
