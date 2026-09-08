/// Add/edit dialog over one todo.txt line (plan/todo-tab.md T-TD-06).
///
/// The dialog edits the description text (with `+`/`@`/`#` completion
/// from the known-token pool; the current tokens also show as removable
/// chips, and three add buttons start a new token even on a fresh task)
/// plus three managed fields — priority, due date and reminder —
/// that rewrite only their own slot ([withKeyValueTag] for `due:`/`rem:`),
/// so unknown tags (`rec:`, `foo:bar`, …) survive verbatim. A picker the
/// user never touches leaves its text exactly as typed. Resolves to the
/// new raw line, or null on cancel.
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
  void initState() {
    super.initState();
    // Rebuild on focus change so the inline completion suggestions appear
    // and disappear with the field's focus (they must not linger after a
    // pick, which leaves the caret past any token).
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// [FocusNode] callback: [setState] when focus toggles (see [initState]).
  void _onFocusChanged() {
    setState(() {});
  }

  /// The word under the caret when it opens a `+`/`@`/`#` token, else
  /// null. [start] receives the word's start offset for replacement.
  ///
  /// A lone sigil (e.g. `+`) counts too: right after the toolbar's add
  /// buttons insert a sigil, the whole pool of that kind shows so an
  /// already-used project/context/tag can be tapped without typing,
  /// or typing can narrow it.
  String? _tokenWord(String text, int caret, List<int> start) {
    final head = caret < 0 || caret > text.length
        ? text
        : text.substring(0, caret);
    final boundary = head.lastIndexOf(RegExp(r'\s'));
    final word = head.substring(boundary + 1);
    if (word.isEmpty || (word[0] != '+' && word[0] != '@' && word[0] != '#')) {
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
      (token) => token.startsWith(word) && token != word && token[0] == word[0],
    );
  }

  /// Replaces the word under the caret with [selection] (the known-token
  /// completion pick), keeping the rest of the description untouched.
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

  /// The distinct `+`/`@`/`#` tokens of the current field text (parsed
  /// live, so typed tokens appear as chips immediately).
  List<String> _fieldTokens() {
    final task = parseTodoLine(_field.text);
    return <String>{
      for (final value in task.projects) '+$value',
      for (final value in task.contexts) '@$value',
      for (final value in task.hashtags) '#$value',
    }.toList();
  }

  /// Removes [token] from the field text.
  void _removeToken(String token) {
    _log.debug('todo dialog token removed: $token');
    final text = withoutToken(_field.text, token);
    _field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  /// Starts a `+`/`@`/`#` token at the end of the field text and
  /// focuses it: typing continues the token, with the known-token
  /// completion popup offering matches (T-TD-06). The explicit buttons
  /// matter on a fresh task, where no chips exist yet to reveal that
  /// tokens can be typed.
  void _insertSigil(String sigil) {
    _log.debug('todo dialog token add: $sigil');
    final head = _field.text;
    final spaced = head.isEmpty || head.endsWith(' ') || head.endsWith('\t')
        ? head
        : '$head ';
    final text = '$spaced$sigil';
    _field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focus.requestFocus();
    setState(() {});
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
    final tokens = _fieldTokens();
    return AlertDialog(
      title: Text(
        adding ? AppStrings.todoAddTitle : AppStrings.todoEditTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Completion is per-token, not whole-value: the word under the
            // caret is replaced, so a fresh task can type a description and
            // then pick `+project`/`@context`/`#tag` without losing it.
            // (flutter's RawAutocomplete would clobber the whole field with
            // the option, so this inline list replaces it as the overlay.)
            _fieldBox(context),
            if (_focus.hasFocus && _completions.isNotEmpty)
              _completionList(_completions),
            if (tokens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final token in tokens)
                      InputChip(
                        key: Key('todo-token-chip-$token'),
                        label: Text(token),
                        deleteIcon: const Icon(Icons.cancel_outlined),
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => _removeToken(token),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final kind in <(String, String)>[
                    ('+', AppStrings.todoAddProject),
                    ('@', AppStrings.todoAddContext),
                    ('#', AppStrings.todoAddHashtag),
                  ])
                    ActionChip(
                      key: Key('todo-token-add-${kind.$1}'),
                      label: Text(kind.$2),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _insertSigil(kind.$1),
                    ),
                ],
              ),
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
                      DropdownMenuItem<String?>(
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
          child: Text(AppStrings.todoCancel),
        ),
        FilledButton(
          key: const Key('todo-dialog-save'),
          onPressed: _field.text.trim().isEmpty ? null : _save,
          child: Text(AppStrings.todoSave),
        ),
      ],
    );
  }

  /// The known tokens completing the word under the caret, capped so a huge
  /// vocabulary never floods the dialog.
  List<String> get _completions => _options(_field.value).take(6).toList();

  /// The description entry field (single line, Enter saves).
  Widget _fieldBox(BuildContext context) {
    return TextField(
      key: const Key('todo-dialog-field'),
      controller: _field,
      focusNode: _focus,
      autofocus: true,
      decoration: InputDecoration(
        hintText: AppStrings.todoDescriptionHint,
      ),
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
    );
  }

  /// The tap-to-pick list of completion [options] under the field.
  ///
  /// A plain column (no scroll viewport): the dialog is itself intrinsic-
  /// sized, and a scrolling list inside that fails the intrinsic measure.
  /// The pool is already capped at six, well within the dialog's scroll.
  Widget _completionList(List<String> options) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          ListTile(
            key: Key('todo-complete-$option'),
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(option),
            onTap: () {
              _log.debug('todo dialog completion: $option');
              _insertOption(option);
            },
          ),
      ],
    );
  }

  /// Truncates [date] to day precision.
  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
}
