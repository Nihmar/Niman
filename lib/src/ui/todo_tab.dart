/// The Todo tab: Open/Done lists over `todo.txt` / `done.txt`
/// (plan/todo-tab.md T-TD-04).
///
/// The shell owns the [TodoController] (so the tab's app-bar add action
/// shares it); the tab opens the controller on mount, renders the
/// Open/Done switch over the same list shape, and routes row gestures:
/// checkbox toggles check/uncheck, tap edits, long-press opens the
/// bottom sheet (the app's menu pattern) with edit/delete.
library;

import 'dart:async';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/todo_controller.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/todo_edit_dialog.dart';
import 'package:copist/src/ui/todo_row.dart';
import 'package:flutter/material.dart';

/// The Todo tab body.
final class TodoTab extends StatefulWidget {
  /// Creates the tab over [controller].
  ///
  /// [clock] fixes the wall-clock day for due badges and the edit
  /// dialog (defaults to now; widget tests inject a fixed time).
  const TodoTab({
    required this.controller,
    this.clock,
    super.key,
  });

  /// The session-bound todo state (owned by the shell).
  final TodoController controller;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  @override
  State<TodoTab> createState() => _TodoTabState();
}

final class _TodoTabState extends State<TodoTab> {
  static const AppLogger _log = AppLogger(name: 'todo');

  /// Whether the Done list shows (false = the Open list).
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.open());
  }

  DateTime get _today {
    final now = widget.clock?.call() ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final snapshot = controller.snapshot;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<bool>(
                key: const Key('todo-view-switch'),
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.todoOpen),
                  ),
                  ButtonSegment(value: true, label: Text(AppStrings.todoDone)),
                ],
                selected: {_showDone},
                onSelectionChanged: (selected) {
                  _log.debug(
                    'todo view: ${selected.single ? 'done' : 'open'}',
                  );
                  setState(() => _showDone = selected.single);
                },
              ),
            ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  key: const Key('todo-error'),
                  controller.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Expanded(child: _body(snapshot)),
          ],
        );
      },
    );
  }

  /// The list (or loading/empty state) for the visible file.
  Widget _body(TodoSnapshot? snapshot) {
    if (snapshot == null) {
      return const Center(
        key: Key('todo-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final entries = [
      for (final entry in (_showDone ? snapshot.done : snapshot.todo))
        if (entry.task.raw.trim().isNotEmpty) entry,
    ];
    if (entries.isEmpty) {
      return Center(
        child: Text(
          _showDone ? AppStrings.todoEmptyDone : AppStrings.todoEmptyOpen,
        ),
      );
    }
    return ListView.builder(
      key: const Key('todo-list'),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return TodoRow(
          key: Key(
            'todo-row-${_showDone ? 'done' : 'open'}-${entry.lineIndex}',
          ),
          entry: entry,
          today: _today,
          onToggle: (checked) => _toggle(entry, checked),
          onEdit: () => _edit(entry),
          onShowMenu: () => _showRowMenu(entry),
        );
      },
    );
  }

  /// Flips a task: check from Open, uncheck from Done. A checkbox that
  /// disagrees with its view (a stray `x` line awaiting migration)
  /// still does the useful thing.
  Future<void> _toggle(TodoEntry entry, bool checked) {
    _log.debug('todo toggle: line ${entry.lineIndex} -> $checked');
    return checked
        ? widget.controller.check(entry)
        : widget.controller.uncheck(entry);
  }

  /// Opens the edit dialog and applies the result to the visible file.
  Future<void> _edit(TodoEntry entry) async {
    final line = await showTodoTaskDialog(
      context,
      initial: entry.task,
      today: _today,
    );
    if (line == null || !mounted) {
      return;
    }
    _log.debug('todo edit applied: line ${entry.lineIndex}');
    if (_showDone) {
      await widget.controller.updateDone(entry, line);
    } else {
      await widget.controller.updateTodo(entry, line);
    }
  }

  /// Long-press bottom sheet (the app's menu pattern): edit or delete.
  Future<void> _showRowMenu(TodoEntry entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('todo-menu-edit'),
              leading: const Icon(Icons.edit),
              title: const Text(AppStrings.todoEditAction),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              key: const Key('todo-menu-delete'),
              leading: const Icon(Icons.delete_outline),
              title: const Text(AppStrings.todoDeleteAction),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) {
      return;
    }
    switch (action) {
      case 'edit':
        await _edit(entry);
      case 'delete':
        _log.debug('todo delete: line ${entry.lineIndex}');
        if (_showDone) {
          await widget.controller.deleteDone(entry);
        } else {
          await widget.controller.deleteTodo(entry);
        }
    }
  }
}
