/// A todo row where a pointer aims (#712): a click selects it and a
/// double click edits its text in place, a hover shows Set due, Delete and
/// the row's menu at its end, and a right click opens that menu at the
/// pointer. No swipe: a mouse does not swipe. The phone keeps [TodoRow].
library;

import 'package:flutter/material.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_row.dart';
import 'package:niman/src/ui/tree_rename_field.dart';

/// One row of a desktop's todo list.
final class TodoPointerRow extends StatefulWidget {
  /// Creates the row for [entry]; the parent owns the selection, the edit
  /// and every action, the row reports them.
  const new({
    required this.entry,
    required this.today,
    required this.selected,
    required this.editing,
    required this.onToggle,
    required this.onClick,
    required this.onSubmitText,
    required this.onCancelEdit,
    required this.onMenuAt,
    required this.onDueMenuAt,
    required this.onDelete,
    super.key,
  });

  /// The task with its file line index.
  final TodoEntry entry;

  /// The wall-clock day for the due state.
  final DateTime today;

  /// Whether the keyboard's selection is on this row.
  final bool selected;

  /// Whether the row's text is a field.
  final bool editing;

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

  /// Opens the due choices at a point on screen.
  final ValueChanged<Offset> onDueMenuAt;

  /// Deletes the task.
  final VoidCallback onDelete;

  @override
  State<TodoPointerRow> createState() => _TodoPointerRowState();
}

final class _TodoPointerRowState extends State<TodoPointerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.entry.task;
    final display = taskDisplayText(task.description);
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            widget.onMenuAt(details.globalPosition),
        child: DecoratedBox(
          // The keyboard's row: a bar at its start (M3).
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                width: 2,
                color: widget.selected ? scheme.primary : Colors.transparent,
              ),
            ),
          ),
          child: ListTile(
            selected: widget.selected,
            leading: Checkbox(
              value: task.completed,
              onChanged: (value) => widget.onToggle(value ?? false),
            ),
            title: widget.editing
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
                    style: task.completed
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
            subtitle: TodoRowSubtitle(task: task, today: widget.today),
            // The buttons keep their room while hidden: the text does not
            // move as the pointer comes and goes.
            trailing: Visibility.maintain(
              visible: _hover || widget.selected,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _button(
                    const Key('todo-row-due'),
                    Icons.event_outlined,
                    AppStrings.todoSetDue,
                    widget.onDueMenuAt,
                  ),
                  IconButton(
                    key: const Key('todo-row-delete'),
                    tooltip: AppStrings.todoDeleteAction,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: widget.onDelete,
                  ),
                  _button(
                    const Key('todo-row-more'),
                    Icons.more_horiz,
                    MaterialLocalizations.of(context).moreButtonTooltip,
                    widget.onMenuAt,
                  ),
                ],
              ),
            ),
            onTap: widget.onClick,
          ),
        ),
      ),
    );
  }

  /// A button that opens a menu under itself.
  Widget _button(
    Key key,
    IconData icon,
    String tooltip,
    ValueChanged<Offset> open,
  ) => Builder(
    builder: (context) => IconButton(
      key: key,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      onPressed: () {
        final box = context.findRenderObject()! as RenderBox;
        open(box.localToGlobal(box.size.bottomLeft(Offset.zero)));
      },
    ),
  );
}
