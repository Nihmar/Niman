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
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_controller.dart';
import 'package:copist/src/todo/todo_filter.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/reminder_health_banner.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/todo_edit_dialog.dart';
import 'package:copist/src/ui/todo_filter_bar.dart';
import 'package:copist/src/ui/todo_filter_sheet.dart';
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
    this.reminders,
    this.clock,
    super.key,
  });

  /// The session-bound todo state (owned by the shell).
  final TodoController controller;

  /// The reminder service, for the health banner (null hides it).
  final ReminderService? reminders;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  @override
  State<TodoTab> createState() => _TodoTabState();
}

final class _TodoTabState extends State<TodoTab> {
  static const AppLogger _log = AppLogger(name: 'todo');

  /// Whether the Done list shows (false = the Open list).
  bool _showDone = false;

  /// The list filter (due range + token chips + sort key).
  TodoFilter _filter = const TodoFilter();

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
        final reminders = widget.reminders;
        return Column(
          children: [
            if (reminders != null) ReminderHealthBanner(service: reminders),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<bool>(
                key: const Key('todo-view-switch'),
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.todoOpen),
                  ),
                  ButtonSegment(value: true, label: Text(AppStrings.todoDone)),
                ],
                selected: {_showDone},
                onSelectionChanged: (selected) => _selectView(selected.single),
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

  /// Switches the visible file, pruning token chips absent from it so
  /// a stale chip never dead-ends the list.
  void _selectView(bool done) {
    final snapshot = widget.controller.snapshot;
    var filter = _filter;
    if (snapshot != null) {
      final entries = done ? snapshot.done : snapshot.todo;
      final available = <String>{
        for (final chip in tokenCountsFor(
          entries,
          TodoDueRange.all,
          _today,
        ))
          chip.token,
      };
      filter = filter.pruneTokens(available);
    }
    _log.debug('todo view: ${done ? 'done' : 'open'}');
    setState(() {
      _showDone = done;
      _filter = filter;
    });
  }

  /// The list (or loading/empty state) for the visible file.
  Widget _body(TodoSnapshot? snapshot) {
    if (snapshot == null) {
      return const Center(
        key: Key('todo-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final fileEntries = [
      for (final entry in (_showDone ? snapshot.done : snapshot.todo))
        if (entry.task.raw.trim().isNotEmpty) entry,
    ];
    final visible = applyTodoFilter(fileEntries, _filter, _today);
    return Column(
      children: [
        TodoFilterBar(
          filter: _filter,
          showDone: _showDone,
          count: fileEntries.length,
          onDueRange: (range) {
            _log.debug('todo filter due: ${range.name}');
            setState(() => _filter = _filter.copyWith(dueRange: range));
          },
          onOpenFilter: () => _openFilterSheet(fileEntries),
        ),
        Expanded(
          child: visible.isEmpty
              ? _emptyList(fileEntries.isEmpty)
              : ListView.builder(
                  key: const Key('todo-list'),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    final view = _showDone ? 'done' : 'open';
                    return TodoRow(
                      key: Key(
                        'todo-row-$view-${entry.lineIndex}',
                      ),
                      entry: entry,
                      today: _today,
                      onToggle: (checked) => _toggle(entry, checked),
                      onEdit: () => _edit(entry),
                      onShowMenu: () => _showRowMenu(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Opens the token + sort sheet (T-TDM-03) over the visible file.
  void _openFilterSheet(List<TodoEntry> fileEntries) {
    final counts = tokenCountsFor(fileEntries, _filter.dueRange, _today);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => TodoFilterSheet(
          filter: _filter,
          counts: counts,
          onToggleToken: (token) {
            final tokens = {..._filter.tokens};
            if (!tokens.remove(token)) {
              tokens.add(token);
            }
            _log.debug('todo filter tokens: $tokens');
            setState(() => _filter = _filter.copyWith(tokens: tokens));
          },
          onSort: (sort) {
            setState(() => _filter = _filter.copyWith(sort: sort));
          },
        ),
      ),
    );
  }

  /// The empty state: the file's own when it holds nothing, the filtered
  /// one when chips hide every row.
  Widget _emptyList(bool fileEmpty) {
    final text = fileEmpty
        ? (_showDone ? AppStrings.todoEmptyDone : AppStrings.todoEmptyOpen)
        : AppStrings.todoEmptyFiltered;
    return Center(child: Text(text));
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
      knownTokens: _knownTokens(),
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

  /// The completion pool for the edit dialog: every token in both
  /// files.
  Set<String> _knownTokens() {
    final snapshot = widget.controller.snapshot;
    return snapshot == null ? const <String>{} : snapshotTokens(snapshot);
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
