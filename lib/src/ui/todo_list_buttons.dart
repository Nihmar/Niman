/// The todo list's three icon controls -- Filter, Sort and help -- and the
/// group the phone's app bar carries (#1003).
///
/// Outline icons: a filled one would say a state is on. The one state the
/// Filter shows is "something narrows the list", which it says with the
/// accent colour and a dot, the icon itself staying an outline. The desktop
/// toolbar uses the same buttons where its pane is too narrow for labelled
/// pills.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_help.dart';
import 'package:niman/src/ui/todo_list_actions.dart';

/// The phone's app bar actions on the Todo tab: help, Filter, Sort.
final class TodoAppBarActions extends StatelessWidget {
  /// Creates the actions over [controller] and the shared [view].
  ///
  /// [clock] fixes the day the due ranges are read on (default: now).
  const new({
    required this.controller,
    required this.view,
    this.clock,
    super.key,
  });

  /// The todo state.
  final TodoController controller;

  /// The filter and sort the list draws from.
  final TodoListView view;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TodoHelpButton(),
        TodoFilterButton(controller: controller, view: view, clock: clock),
        TodoSortButton(view: view),
      ],
    );
  }
}

/// The Filter icon: the accent colour and a dot while a filter is active.
final class TodoFilterButton extends StatelessWidget {
  /// Creates the button over [controller] and [view].
  const new({
    required this.controller,
    required this.view,
    this.clock,
    super.key,
  });

  /// The todo state, whose tokens the sheet counts.
  final TodoController controller;

  /// The filter the button opens and reflects.
  final TodoListView view;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: view,
      builder: (context, _) {
        final count = view.activeFilterCount;
        final active = count > 0;
        return Builder(
          builder: (context) => IconButton(
            key: const Key('todo-filter-button'),
            tooltip: active
                ? AppStrings.todoFilterActive(count)
                : AppStrings.todoFilter,
            // The dot is a Badge without a label; its slot is always
            // there, only its visibility changes, so the icon never moves.
            icon: Badge(
              key: const Key('todo-filter-dot'),
              isLabelVisible: active,
              smallSize: 8,
              backgroundColor: scheme.primary,
              child: Icon(
                Icons.filter_alt_outlined,
                color: active ? scheme.primary : null,
              ),
            ),
            onPressed: () => unawaited(
              showTodoFilter(
                context,
                controller: controller,
                view: view,
                clock: clock,
                anchor: menuAnchorOf(context),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Sort icon: opens the menu of sort keys.
final class TodoSortButton extends StatelessWidget {
  /// Creates the button over [view].
  const new({required this.view, super.key});

  /// The sort the menu sets.
  final TodoListView view;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        key: const Key('todo-sort-button'),
        tooltip: AppStrings.todoSortTooltip,
        icon: const Icon(Icons.sort_outlined),
        onPressed: () => unawaited(
          showTodoSort(context, view: view, anchor: menuAnchorOf(context)),
        ),
      ),
    );
  }
}

/// The help icon: the todo.txt format reference, one tap from the list on
/// every layout (T-TD-08).
final class TodoHelpButton extends StatelessWidget {
  /// Creates the button.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('todo-help'),
      tooltip: AppStrings.todoHelpTooltip,
      icon: const Icon(Icons.help_outline),
      onPressed: () => unawaited(showTodoHelp(context)),
    );
  }
}
