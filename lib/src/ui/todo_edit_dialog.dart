/// Add/edit dialog over one todo.txt line (plan/todo-tab.md T-TD-06).
///
/// The dialog edits the description text (with `+`/`@`/`#` completion
/// from the known-token pool) plus three managed fields — priority,
/// due date and reminder — that rewrite only their own slot ([withKeyValueTag]
/// for `due:`/`rem:`), so unknown tags (`rec:`, `foo:bar`, …) survive
/// verbatim. A picker the user never touches leaves its text exactly
/// as typed. Resolves to the new raw line, or null on cancel.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// Shows the add ([initial] null) or edit dialog.
///
/// [today] stamps the creation date of an added task and seeds the
/// pickers. [knownTokens] (sigil-included: `+p`, `@c`, `#t`) completes
/// the word under the caret.
Future<String?> showTodoTaskDialog(
  BuildContext context, {
  required DateTime today,
  TodoTask? initial,
  Set<String> knownTokens = const <String>{},
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TodoTaskDialog(
      initial: initial,
      today: today,
      knownTokens: knownTokens,
    ),
  );
}

/// Description field with token completion, priority dropdown, due and
/// reminder pickers, Cancel/Save (Save stays disabled while the
/// description is blank).
final class _TodoTaskDialog extends StatefulWidget {
  const _TodoTaskDialog({
    required this.initial,
    required this.today,
    required this.knownTokens,
  });

  final TodoTask? initial;
  final DateTime today;
  final Set<String> knownTokens;

  @override
  State<_TodoTaskDialog> createState() => _TodoTaskDialogState();
}

final class _TodoTaskDialogState extends State<_TodoTaskDialog> {
  static const AppLogger _log = AppLogger(name: 'todo');

  late final TextEditingController _field = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final FocusNode _focus = FocusNode();

  late String? _priority = widget.initial?.priority;
  late DateTime? _due = widget.initial?.due;
  late DateTime? _reminder = widget.initial?.reminder;

  /// Whether the pickers were touched (only then is their slot
  /// rewritten — an untouched edit keeps the text byte-identical).
  bool _dueDirty = false;
  bool _reminderDirty = false;

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The word under the caret when it opens a `+`/`@`/`#` token, else
  /// null. [start] receives the word's start offset for replacement.
  String? _tokenWord(String text, int caret, List<int> start) {
    final head = caret < 0 || caret > text.length
        ? text
        : text.substring(0, caret);
    final boundary = head.lastIndexOf(RegExp(r'\s'));
    final word = head.substring(boundary + 1);
    if (word.length < 2 ||
        (word[0] != '+' && word[0] != '@' && word[0] != '#')) {
      return null;
    }
    start[0] = boundary + 1;
    return word;
  }

  /// Known tokens completing the word under the caret.
  Iterable<String> _options(TextEditingValue value) {
    final start = <int>[0];
    final word = _tokenWord(
      value.text,
      value.selection.extentOffset,
      start,
    );
    if (word == null) {
      return const Iterable<String>.empty();
    }
    return widget.knownTokens.where(
      (token) =>
          token.startsWith(word) &&
          token != word &&
          token[0] == word[0],
    );
  }

  /// Replaces the word under the caret with [selection].
  void _insertOption(String selection) {
    final text = _field.text;
    final caret = _field.selection.extentOffset;
    final start = <int>[0];
    final word = _tokenWord(text, caret, start);
    if (word == null) {
      return;
    }
    final end = caret < 0 || caret > text.length ? text.length : caret;
    _field.value = TextEditingValue(
      text: text.replaceRange(start[0], end, selection),
      selection: TextSelection.collapsed(offset: start[0] + selection.length),
    );
  }

  /// Picks the due date (writes/updates `due:` on save).
  Future<void> _pickDue() async {
    final today = _day(widget.today);
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    _log.debug('todo dialog due: ${formatTodoDate(picked)}');
    setState(() {
      _due = picked;
      _dueDirty = true;
    });
  }

  /// Picks the reminder day and time (writes `rem:` on save).
  Future<void> _pickReminder() async {
    final today = _day(widget.today);
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminder ?? widget.today),
    );
    if (time == null || !mounted) {
      return;
    }
    final stamp = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _log.debug('todo dialog reminder: ${formatTodoStamp(stamp)}');
    setState(() {
      _reminder = stamp;
      _reminderDirty = true;
    });
  }

  /// Builds the result line from the field text and the managed fields.
  String _result(String text) {
    var description = text;
    final initial = widget.initial;
    if (initial == null || _dueDirty) {
      description = withKeyValueTag(
        description,
        'due',
        _due == null ? null : formatTodoDate(_due!),
      );
    }
    if (initial == null || _reminderDirty) {
      description = withKeyValueTag(
        description,
        'rem',
        _reminder == null ? null : formatTodoStamp(_reminder!),
      );
    }
    if (initial == null) {
      return formatTodoLine(
        completed: false,
        creationDate: _day(widget.today),
        description: description,
      );
    }
    return formatTodoLine(
      completed: initial.completed,
      priority: _priority,
      completionDate: initial.completionDate,
      creationDate: initial.creationDate,
      description: description,
    );
  }

  void _save() {
    final text = _field.text.trim();
    if (text.isEmpty) {
      return;
    }
    _log.debug('todo dialog saved');
    Navigator.pop(context, _result(text));
  }

  @override
  Widget build(BuildContext context) {
    final adding = widget.initial == null;
    return AlertDialog(
      title: Text(
        adding ? AppStrings.todoAddTitle : AppStrings.todoEditTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RawAutocomplete<String>(
              textEditingController: _field,
              focusNode: _focus,
              optionsBuilder: _options,
              onSelected: _insertOption,
              fieldViewBuilder:
                  (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      key: const Key('todo-dialog-field'),
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: AppStrings.todoDescriptionHint,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            key: Key('todo-complete-$option'),
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String?>(
                    key: const Key('todo-dialog-priority'),
                    value: _priority,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        child: Text(AppStrings.todoNoPriority),
                      ),
                      for (var code = 65; code <= 90; code++)
                        DropdownMenuItem<String?>(
                          value: String.fromCharCode(code),
                          child: Text('(${String.fromCharCode(code)})'),
                        ),
                    ],
                    onChanged: (priority) {
                      _log.debug('todo dialog priority: $priority');
                      setState(() => _priority = priority);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    key: const Key('todo-dialog-due'),
                    onPressed: _pickDue,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      _due == null
                          ? AppStrings.todoNoDueDate
                          : formatTodoDate(_due!),
                    ),
                  ),
                ),
                if (_due != null)
                  IconButton(
                    key: const Key('todo-dialog-due-clear'),
                    tooltip: AppStrings.todoNoDueDate,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _log.debug('todo dialog due cleared');
                      setState(() {
                        _due = null;
                        _dueDirty = true;
                      });
                    },
                  ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.alarm_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    key: const Key('todo-dialog-reminder'),
                    onPressed: _pickReminder,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      _reminder == null
                          ? AppStrings.todoNoReminder
                          : formatTodoStamp(_reminder!),
                    ),
                  ),
                ),
                if (_reminder != null)
                  IconButton(
                    key: const Key('todo-dialog-reminder-clear'),
                    tooltip: AppStrings.todoNoReminder,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _log.debug('todo dialog reminder cleared');
                      setState(() {
                        _reminder = null;
                        _reminderDirty = true;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.todoCancel),
        ),
        FilledButton(
          key: const Key('todo-dialog-save'),
          onPressed: _field.text.trim().isEmpty ? null : _save,
          child: const Text(AppStrings.todoSave),
        ),
      ],
    );
  }

  /// Truncates [date] to day precision.
  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
}
