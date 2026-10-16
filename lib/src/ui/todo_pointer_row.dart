/// A todo row where a pointer aims (#712, #1003): one line -- the checkbox,
/// the text, then the priority badge, the tokens and the due date (the
/// completion date, for a done row) on the right -- and the row's `⋯` menu
/// at its end.
///
/// A click selects the row and a double click edits its text in place; a
/// hover or the selection shows the menu button, and a right click opens
/// that menu at the pointer. The button keeps its room while hidden, so
/// nothing moves as the pointer comes and goes. No swipe: a mouse does not
/// swipe. The phone keeps `TodoRow`.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/ui/todo_priority_badge.dart';
import 'package:niman/src/ui/todo_row_timing.dart';
import 'package:niman/src/ui/todo_row_tokens.dart';
import 'package:niman/src/ui/tree_rename_field.dart';

/// One row of a desktop's todo list.
final class TodoPointerRow extends StatefulWidget {
  /// Creates the row for [row]; the parent owns the selection, the edit and
  /// every action, the row reports them.
  const new({
    required this.row,
    required this.today,
    required this.selected,
    required this.editing,
    required this.showPriority,
    required this.onToggle,
    required this.onClick,
    required this.onSubmitText,
    required this.onCancelEdit,
    required this.onMenuAt,
    super.key,
  });

  /// The task with its file line index and its file.
  final TodoRowItem row;

  /// The wall-clock day for the due state.
  final DateTime today;

  /// Whether the keyboard's selection is on this row.
  final bool selected;

  /// Whether the row's text is a field.
  final bool editing;

  /// Whether the priority shows as a badge (off when the list is sorted by
  /// priority: its sections say it).
  final bool showPriority;

  /// Flips the checkbox.
  final ValueChanged<bool> onToggle;

  /// A click on the row: the parent tells a double one.
  final VoidCallback onClick;

  /// Writes the text edited in place.
  final ValueChanged<String> onSubmitText;

  /// Leaves the text as it was.
  final VoidCallback onCancelEdit;

  /// Opens the row's menu at a point on screen.
  final ValueChanged<Offset> onMenuAt;

  @override
  State<TodoPointerRow> createState() => _TodoPointerRowState();
}

final class _TodoPointerRowState extends State<TodoPointerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.row.entry;
    final task = entry.task;
    final display = taskDisplayText(task.description);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final priority = task.priority;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            widget.onMenuAt(details.globalPosition),
        child: DecoratedBox(
          // The keyboard's row: a bar at its start (M3).
          decoration: BoxDecoration(
            color: widget.selected
                ? scheme.secondaryContainer.withValues(alpha: 0.4)
                : null,
            border: BorderDirectional(
              start: BorderSide(
                width: 2,
                color: widget.selected ? scheme.primary : Colors.transparent,
              ),
            ),
          ),
          child: InkWell(
            onTap: widget.onClick,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 32,
                      child: Checkbox(
                        value: task.completed,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) => widget.onToggle(value ?? false),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: widget.editing
                          ? TreeRenameField(
                              key: const Key('todo-edit-in-place'),
                              name: task.description,
                              isDir: true,
                              onSubmit: (text) async {
                                widget.onSubmitText(text);
                                return null;
                              },
                              onCancel: widget.onCancelEdit,
                            )
                          : Text(
                              display.isEmpty ? task.raw : display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: task.completed
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                    )
                                  : null,
                            ),
                    ),
                    // What the task says about itself, at most half the
                    // row: the text keeps the rest.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth / 2,
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            if (widget.showPriority && priority != null)
                              TodoPriorityBadge(priority: priority),
                            ...todoRowTokenChips(task),
                            ...todoRowTiming(
                              task,
                              widget.today,
                              done: widget.row.done,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // The menu keeps its room while hidden: the text does not
                    // move as the pointer comes and goes.
                    Visibility.maintain(
                      visible: _hover || widget.selected,
                      child: Builder(
                        builder: (context) => IconButton(
                          key: const Key('todo-row-more'),
                          tooltip: MaterialLocalizations.of(context)
                              .moreButtonTooltip,
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(32),
                            padding: const EdgeInsets.all(6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.more_horiz, size: 20),
                          onPressed: () {
                            final box =
                                context.findRenderObject()! as RenderBox;
                            widget.onMenuAt(
                              box.localToGlobal(
                                box.size.bottomLeft(Offset.zero),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
