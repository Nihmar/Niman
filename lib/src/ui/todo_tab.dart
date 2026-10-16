/// The Todo tab: one list over `todo.txt` and `done.txt`, grouped in
/// sections (T-TD-04, #1003).
///
/// The shell owns the [TodoController] (its add action shares it) and the
/// [TodoListView] (the phone's app bar sets the filter and the sort the
/// tab draws from); the tab opens the controller on mount, applies the
/// filter to both files, cuts the open tasks into sections that follow the
/// sort key and closes the list with the Done section. It routes row
/// gestures to the file each row was read from: the checkbox checks or
/// unchecks, a tap edits (the dialog can also delete), a long press or a
/// right click opens the menu, and a swipe towards the start deletes after
/// asking.
///
/// Where a pointer aims (#712) the rows are a [TodoPointerList]: a click
/// selects, a double click or `Enter`/`F2` edits the text in place, the
/// arrows move across rows and headers, `Space` checks, `Delete` deletes,
/// and the row's menu -- Edit…, Set due ▸, Priority ▸, Delete -- opens at a
/// right click or under its ⋯. A quick-add field tops the list. A wide
/// shell has a toolbar over the list (Filter, Sort, Add task, help); the
/// phone's controls are in the shell's app bar.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_model.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/todo/todo_model_cache.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/reminder_health_banner.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_filter_strip.dart';
import 'package:niman/src/ui/todo_list_actions.dart';
import 'package:niman/src/ui/todo_phone_list.dart';
import 'package:niman/src/ui/todo_pointer_list.dart';
import 'package:niman/src/ui/todo_quick_add.dart';
import 'package:niman/src/ui/todo_toolbar.dart';

/// The Todo tab body.
final class TodoTab extends StatefulWidget {
  /// Creates the tab over [controller], drawing what [view] says.
  ///
  /// [clock] fixes the wall-clock day for due badges and the edit
  /// dialog (defaults to now; widget tests inject a fixed time).
  ///
  /// [onAddTask] is the shell's add flow: the desktop toolbar's Add button
  /// uses it (the phone's FAB owns creation there).
  const new({
    required this.controller,
    required this.view,
    this.reminders,
    this.clock,
    this.onAddTask,
    this.column = NoteColumn.off,
    super.key,
  });

  /// The note column (#171), which the list keeps to as a note's text
  /// does (0.0.8 test round).
  final NoteColumn column;

  /// The session-bound todo state (owned by the shell).
  final TodoController controller;

  /// The filter, the sort and the folded sections (owned by the shell).
  final TodoListView view;

  /// The reminder service, for the health banner (null hides it).
  final ReminderService? reminders;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  /// Creates a task; the desktop toolbar shows the button.
  final VoidCallback? onAddTask;

  @override
  State<TodoTab> createState() => _TodoTabState();
}

final class _TodoTabState extends State<TodoTab> {
  static const AppLogger _log = AppLogger(name: 'todo');

  /// The derived model and items, and the rows swiped away whose delete has
  /// not published yet.
  final TodoModelCache _cache = TodoModelCache();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPublished);
    unawaited(widget.controller.open());
  }

  @override
  void didUpdateWidget(TodoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPublished);
      widget.controller.addListener(_onPublished);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPublished);
    super.dispose();
  }

  /// A publish: swiped rows are settled, and a token chip neither file
  /// carries any more is dropped so it never dead-ends the list. Both files
  /// count: the filter narrows the Done section too.
  void _onPublished() {
    _cache.settle();
    final snapshot = widget.controller.snapshot;
    if (snapshot != null && widget.view.filter.tokens.isNotEmpty) {
      widget.view.pruneTokens(snapshotTokens(snapshot));
    }
  }

  DateTime get _today => todoDayOf(widget.clock);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The pane the tab lives in decides the shape, and the shell
        // too: the phone's controls are in the app bar, while a wide
        // shell has no app bar and the tab carries a toolbar -- labelled
        // pills where the pane holds them, icons under that.
        final shellWide = isWideShell(context);
        final labelled =
            shellWide && constraints.maxWidth >= TodoToolbar.labelledMinWidth;
        return ListenableBuilder(
          listenable: Listenable.merge([widget.controller, widget.view]),
          builder: (context, _) {
            final controller = widget.controller;
            final snapshot = controller.snapshot;
            final reminders = widget.reminders;
            final model = snapshot == null ? null : _modelOf(snapshot);
            return Column(
              children: [
                if (reminders != null) ReminderHealthBanner(service: reminders),
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
                Expanded(
                  child: NoteColumnPadding(
                    column: _column,
                    child: Column(
                      children: [
                        if (shellWide)
                          TodoToolbar(
                            controller: controller,
                            view: widget.view,
                            labelled: labelled,
                            onAddTask: widget.onAddTask,
                            clock: widget.clock,
                          ),
                        if (model != null)
                          TodoFilterStrip(
                            view: widget.view,
                            shown: model.openShown,
                            total: model.openTotal,
                          ),
                        Expanded(child: _body(model)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// The note column, never narrower than the toolbar needs: the pills, Add
  /// and help on one line.
  NoteColumn get _column {
    final column = widget.column;
    if (!column.enabled || column.width >= _minColumnWidth) return column;
    return const NoteColumn(width: _minColumnWidth);
  }

  static const double _minColumnWidth = 800;

  /// The model of [snapshot] under the view's filter.
  TodoListModel _modelOf(TodoSnapshot snapshot) {
    return _cache.modelOf(snapshot, widget.view.filter, _today);
  }

  /// The headers and rows of [model] under the sections folded now.
  List<TodoListItem> _itemsOf(TodoListModel model) {
    return _cache.itemsOf(model, widget.view.collapsed);
  }

  /// The list (or loading/empty state) of [model].
  Widget _body(TodoListModel? model) {
    if (model == null) {
      return const Center(
        key: Key('todo-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final pointer = pointerDense(Theme.of(context));
    final showPriority = widget.view.filter.sort != TodoSort.priority;
    return Column(
      children: [
        if (pointer)
          TodoQuickAdd(
            key: const Key('todo-quick-add-row'),
            onAdd: _quickAdd,
            knownTokens: _knownTokens,
          ),
        Expanded(
          child: model.isEmpty
              ? _emptyList(noTasks: model.hasNoTasks)
              : pointer
              ? TodoPointerList(
                  items: _itemsOf(model),
                  today: _today,
                  showPriority: showPriority,
                  onToggle: _toggle,
                  onEdit: _edit,
                  onDelete: _delete,
                  onRewrite: _rewrite,
                  onToggleSection: _toggleSection,
                )
              : TodoPhoneList(
                  items: _itemsOf(model),
                  today: _today,
                  showPriority: showPriority,
                  onToggle: _toggle,
                  onEdit: _edit,
                  onDelete: _delete,
                  onSwipeDelete: _swipeDelete,
                  onToggleSection: _toggleSection,
                ),
        ),
      ],
    );
  }

  /// The empty state: the lists' own when there is no task at all, the
  /// filtered one when the filter hides every row.
  Widget _emptyList({required bool noTasks}) {
    return Center(
      child: Text(
        noTasks ? AppStrings.todoEmptyOpen : AppStrings.todoEmptyFiltered,
      ),
    );
  }

  /// Folds the section [id], or opens it.
  void _toggleSection(String id) {
    _log.debug('todo section: $id');
    widget.view.toggleSection(id);
  }

  /// A row swiped away and confirmed: it leaves the screen now, and the
  /// delete follows into the file it was read from.
  void _swipeDelete(TodoRowItem row) {
    setState(() => _cache.hide(row.entry));
    unawaited(_delete(row));
  }

  /// Adds the task typed in the quick-add field (#712), created today.
  void _quickAdd(String text) {
    _log.debug('todo quick add');
    unawaited(
      widget.controller.add(
        formatTodoLine(
          completed: false,
          creationDate: _today,
          description: text,
        ),
      ),
    );
  }

  /// Writes [line] in place of [row]'s, in the file it was read from.
  Future<void> _rewrite(TodoRowItem row, String line) {
    _log.debug('todo row rewritten: ${row.view} line ${row.entry.lineIndex}');
    return row.done
        ? widget.controller.updateDone(row.entry, line)
        : widget.controller.updateTodo(row.entry, line);
  }

  /// Flips a task: an open one is checked, a done one reopened -- by the
  /// file it is in, whatever the checkbox says.
  Future<void> _toggle(TodoRowItem row, {required bool checked}) {
    _log.debug(
      'todo toggle: ${row.view} line ${row.entry.lineIndex} -> $checked',
    );
    return row.done
        ? widget.controller.uncheck(row.entry)
        : widget.controller.check(row.entry);
  }

  /// Opens the edit dialog and applies the result to [row]'s file.
  Future<void> _edit(TodoRowItem row) async {
    final reminders = widget.reminders;
    final line = await showTodoTaskDialog(
      context,
      initial: row.entry.task,
      today: _today,
      knownTokens: _knownTokens(),
      onDelete: () => unawaited(_delete(row)),
      health: reminders?.health.value ?? ReminderHealth.ok,
      onOpenReminderSettings: reminders?.openHealthSettings,
    );
    if (line == null || !mounted) {
      return;
    }
    await _rewrite(row, line);
  }

  /// The completion pool for the edit dialog: every token in both
  /// files.
  Set<String> _knownTokens() {
    final snapshot = widget.controller.snapshot;
    return snapshot == null ? const <String>{} : snapshotTokens(snapshot);
  }

  /// Removes [row]'s line from the file it was read from.
  Future<void> _delete(TodoRowItem row) {
    _log.debug('todo delete: ${row.view} line ${row.entry.lineIndex}');
    return row.done
        ? widget.controller.deleteDone(row.entry)
        : widget.controller.deleteTodo(row.entry);
  }
}
