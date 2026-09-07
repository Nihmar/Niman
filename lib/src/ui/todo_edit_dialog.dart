/// Add/edit dialog over one todo.txt line (plan/todo-tab.md T-TD-04
/// shell, enriched with pickers in T-TD-06).
///
/// The dialog edits the description text only: priority and dates ride
/// along untouched, and an add stamps the creation date with the given
/// day. Resolves to the new raw line, or null on cancel.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// Shows the add ([initial] null) or edit dialog.
///
/// [today] stamps the creation date of an added task.
Future<String?> showTodoTaskDialog(
  BuildContext context, {
  required DateTime today,
  TodoTask? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TodoTaskDialog(initial: initial, today: today),
  );
}

/// Description field + Cancel/Save; Save stays disabled while the
/// description is blank.
final class _TodoTaskDialog extends StatefulWidget {
  const _TodoTaskDialog({required this.initial, required this.today});

  final TodoTask? initial;
  final DateTime today;

  @override
  State<_TodoTaskDialog> createState() => _TodoTaskDialogState();
}

final class _TodoTaskDialogState extends State<_TodoTaskDialog> {
  static const AppLogger _log = AppLogger(name: 'todo');

  late final TextEditingController _field = TextEditingController(
    text: widget.initial?.description ?? '',
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Builds the result line from the field text.
  String _result(String text) {
    final initial = widget.initial;
    final day = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
    if (initial == null) {
      return formatTodoLine(
        completed: false,
        creationDate: day,
        description: text,
      );
    }
    return formatTodoLine(
      completed: initial.completed,
      priority: initial.priority,
      completionDate: initial.completionDate,
      creationDate: initial.creationDate,
      description: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adding = widget.initial == null;
    return AlertDialog(
      title: Text(
        adding ? AppStrings.todoAddTitle : AppStrings.todoEditTitle,
      ),
      content: TextField(
        key: const Key('todo-dialog-field'),
        controller: _field,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: AppStrings.todoDescriptionHint,
        ),
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (text) {
          if (text.trim().isNotEmpty) {
            _log.debug('todo dialog saved (keyboard)');
            Navigator.pop(context, _result(text.trim()));
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.todoCancel),
        ),
        FilledButton(
          key: const Key('todo-dialog-save'),
          onPressed: _field.text.trim().isEmpty
              ? null
              : () {
                  _log.debug('todo dialog saved');
                  Navigator.pop(context, _result(_field.text.trim()));
                },
          child: const Text(AppStrings.todoSave),
        ),
      ],
    );
  }
}
