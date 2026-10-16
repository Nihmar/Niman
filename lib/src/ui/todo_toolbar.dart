/// The desktop's toolbar over the todo list (#1003): Filter and Sort at the
/// start, Add task and help at the end.
///
/// Where the pane has room the first two are labelled pills -- the Filter
/// pill carries the number of active filters and takes the accent, the Sort
/// pill names the current key -- and in a narrower pane the same four
/// controls are icon buttons, the way the phone's app bar has them. Add
/// task is here because a wide shell has no FAB.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_filter_labels.dart';
import 'package:niman/src/ui/todo_list_actions.dart';
import 'package:niman/src/ui/todo_list_buttons.dart';

/// The toolbar of the desktop's todo panel.
final class TodoToolbar extends StatelessWidget {
  /// Creates the toolbar over [controller] and the shared [view].
  ///
  /// [labelled] shows pills with words; off, the controls are icons.
  /// [onAddTask] adds a task (no button when null).
  const new({
    required this.controller,
    required this.view,
    required this.labelled,
    this.onAddTask,
    this.clock,
    super.key,
  });

  /// The todo state.
  final TodoController controller;

  /// The filter and sort the list draws from.
  final TodoListView view;

  /// Whether the pane holds labelled pills.
  final bool labelled;

  /// Creates a task.
  final VoidCallback? onAddTask;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  /// The narrowest pane that holds the labelled pills, Add task and help
  /// on one line. Under it the toolbar takes icons.
  static const double labelledMinWidth = 480;

  @override
  Widget build(BuildContext context) {
    final add = onAddTask;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (labelled)
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: _FilterPill(
                      controller: controller,
                      view: view,
                      clock: clock,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: _SortPill(view: view)),
                ],
              ),
            )
          else ...[
            TodoFilterButton(controller: controller, view: view, clock: clock),
            TodoSortButton(view: view),
            const Spacer(),
          ],
          if (add != null && labelled)
            TextButton.icon(
              key: const Key('todo-add-button'),
              onPressed: add,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStrings.todoAddTooltip),
            )
          else if (add != null)
            IconButton(
              key: const Key('todo-add-button'),
              tooltip: AppStrings.todoAddTooltip,
              icon: const Icon(Icons.add),
              onPressed: add,
            ),
          const TodoHelpButton(),
        ],
      ),
    );
  }
}

/// The Filter pill: `Filter`, or `Filter · N` with the accent while N
/// filters narrow the list.
final class _FilterPill extends StatelessWidget {
  const new({required this.controller, required this.view, this.clock});

  final TodoController controller;
  final TodoListView view;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: view,
      builder: (context, _) {
        final count = view.activeFilterCount;
        final label = count > 0
            ? AppStrings.todoFilterActive(count)
            : AppStrings.todoFilter;
        return _Pill(
          key: const Key('todo-filter-button'),
          icon: Icons.filter_alt_outlined,
          label: label,
          // The pill keeps the width of its widest label, so the Sort pill
          // beside it does not move as a filter comes and goes.
          widest: AppStrings.todoFilterActive(99),
          active: count > 0,
          onPressed: (anchor) => unawaited(
            showTodoFilter(
              context,
              controller: controller,
              view: view,
              clock: clock,
              anchor: anchor,
            ),
          ),
        );
      },
    );
  }
}

/// The Sort pill: the name of the current key.
final class _SortPill extends StatelessWidget {
  const new({required this.view});

  final TodoListView view;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: view,
      builder: (context, _) => _Pill(
        key: const Key('todo-sort-button'),
        icon: Icons.sort,
        label: todoSortLabel(view.filter.sort),
        onPressed: (anchor) =>
            unawaited(showTodoSort(context, view: view, anchor: anchor)),
      ),
    );
  }
}

/// One pill: a leading outline icon, a label and a chevron. [active] gives
/// it the primary-container look; [widest] reserves the room of the longest
/// label it will show.
final class _Pill extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.widest,
    this.active = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? widest;
  final bool active;

  /// Opens what the pill picks, given the pill's place on screen for a
  /// pop-up to grow from.
  final void Function(Rect? anchor) onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = active ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Builder(
      builder: (context) => OutlinedButton(
        onPressed: () => onPressed(menuAnchorOf(context)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: foreground,
          backgroundColor: active ? scheme.primaryContainer : null,
          side: active ? BorderSide(color: scheme.primary) : null,
          textStyle: theme.textTheme.bodySmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: widest == null
                  ? Text(label, overflow: TextOverflow.ellipsis)
                  : IndexedStack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        Text(label, overflow: TextOverflow.ellipsis),
                        Text(widest!, overflow: TextOverflow.ellipsis),
                      ],
                    ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}
