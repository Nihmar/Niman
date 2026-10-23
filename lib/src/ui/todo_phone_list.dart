/// The todo list where a thumb aims (#1003): a lazy list of section headers
/// and task rows.
///
/// A row keeps the gestures of the old list: a tap edits, a long press (or
/// a right click) opens the menu, a swipe towards the start deletes once
/// the user confirms, the checkbox checks or unchecks. They work the same
/// in both files -- the row says which one it was read from -- and the
/// parent decides what each does to the files.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/task_link_label.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/ui/menu_row.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_link_host.dart';
import 'package:niman/src/ui/todo_row.dart';
import 'package:niman/src/ui/todo_section_header.dart';

/// The headers and rows of the todo list, for a thumb.
final class TodoPhoneList extends StatelessWidget {
  /// Creates the list of [items].
  ///
  /// [showPriority] is off when the list is sorted by priority: its
  /// section headings already say it.
  const new({
    required this.items,
    required this.today,
    required this.showPriority,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onSwipeDelete,
    required this.onToggleSection,
    this.links,
    super.key,
  });

  /// The headers and rows, in order.
  final List<TodoListItem> items;

  /// The wall-clock day.
  final DateTime today;

  /// Whether a row shows its priority as a badge.
  final bool showPriority;

  /// Checks or unchecks a task.
  final Future<void> Function(TodoRowItem row, {required bool checked})
  onToggle;

  /// Opens the edit dialog.
  final Future<void> Function(TodoRowItem row) onEdit;

  /// Deletes a task (from the row menu).
  final Future<void> Function(TodoRowItem row) onDelete;

  /// Deletes a task that was swiped away and confirmed: the row has left
  /// the screen already, so the parent hides it until the file is written.
  final void Function(TodoRowItem row) onSwipeDelete;

  /// Folds a section, or opens it.
  final ValueChanged<String> onToggleSection;

  /// The links of the tasks, drawn as chips (#1152); null draws them dead.
  final TodoLinkHost? links;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('todo-list'),
      itemCount: items.length,
      itemBuilder: (context, index) {
        switch (items[index]) {
          case final TodoHeaderItem header:
            return TodoSectionHeader(
              key: Key('todo-section-${header.section}'),
              item: header,
              onToggle: () => onToggleSection(header.section),
            );
          case final TodoRowItem row:
            return _swipeToDelete(
              context,
              row,
              TodoRow(
                key: Key('todo-row-${row.view}-${row.entry.lineIndex}'),
                entry: row.entry,
                done: row.done,
                showPriority: showPriority,
                today: today,
                links: links,
                onToggle: (checked) =>
                    unawaited(onToggle(row, checked: checked)),
                onEdit: () => unawaited(onEdit(row)),
                onShowMenu: () => unawaited(_showRowMenu(context, row)),
                onShowMenuAt: (at) =>
                    unawaited(_showRowMenuAt(context, row, at)),
              ),
            );
        }
      },
    );
  }

  /// [child] made swipeable towards the start, which deletes [row] once the
  /// user confirms: a stray swipe on a phone must not lose a task, since a
  /// deleted line has no trash.
  Widget _swipeToDelete(BuildContext context, TodoRowItem row, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      // Per entry object, never per line index: once a line goes, the next
      // one takes its index, and must not inherit a dismissed state.
      key: ObjectKey(row.entry),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: scheme.errorContainer,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 24),
            child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          ),
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context, row),
      onDismissed: (_) => onSwipeDelete(row),
      child: child,
    );
  }

  /// Asks before a swipe deletes [row]; true deletes.
  Future<bool> _confirmDelete(BuildContext context, TodoRowItem row) async {
    final entry = row.entry;
    _log.debug('todo swipe: line ${entry.lineIndex}, asking');
    final display = taskPlainText(entry.task.description);
    final name = '“${display.isEmpty ? entry.task.raw : display}”';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.todoDeleteAction),
        content: Text(AppStrings.deleteForeverConfirm(name)),
        actions: [
          TextButton(
            key: const Key('todo-swipe-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('todo-swipe-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Long-press bottom sheet (the app's menu pattern): edit or delete.
  Future<void> _showRowMenu(BuildContext context, TodoRowItem row) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('todo-menu-edit'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppStrings.todoEditAction),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              key: const Key('todo-menu-delete'),
              leading: const Icon(Icons.delete_outline),
              title: Text(AppStrings.todoDeleteAction),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (context.mounted) {
      await _runRowMenu(row, action);
    }
  }

  /// Right-click menu (T-PP-20): the same two actions at the cursor, the
  /// shape a pointer gets (#712).
  Future<void> _showRowMenuAt(
    BuildContext context,
    TodoRowItem row,
    Offset at,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        at & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        _menuItem(
          context,
          key: const Key('todo-menu-edit'),
          icon: Icons.edit_outlined,
          label: AppStrings.todoEditAction,
          value: 'edit',
        ),
        _menuItem(
          context,
          key: const Key('todo-menu-delete'),
          icon: Icons.delete_outline,
          label: AppStrings.todoDeleteAction,
          value: 'delete',
          destructive: true,
        ),
      ],
    );
    if (context.mounted) {
      await _runRowMenu(row, action);
    }
  }

  /// One entry of the cursor menu, its icon left of its label.
  PopupMenuItem<String> _menuItem(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    bool destructive = false,
  }) {
    return menuItem<String>(
      context,
      key: key,
      value: value,
      child: MenuRow(
        icon: icon,
        label: label,
        color: destructive ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Runs what either row menu answered.
  Future<void> _runRowMenu(TodoRowItem row, String? action) async {
    switch (action) {
      case 'edit':
        await onEdit(row);
      case 'delete':
        await onDelete(row);
    }
  }
}
