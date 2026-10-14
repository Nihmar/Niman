/// The quick-add field at the top of a desktop's task list (#712): type a
/// task, `Enter` adds it and the field stays for the next one. The dialog
/// is for the details — dates picked, a reminder, the priority.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_token_completion.dart';

/// A one-line field that adds a task per `Enter`.
final class TodoQuickAdd extends StatefulWidget {
  /// Creates the field; [onAdd] gets the text typed, trimmed and never
  /// empty, and [knownTokens] complete a `+`/`@`/`#` word under the caret.
  const new({required this.onAdd, required this.knownTokens, super.key});

  /// Adds a task written as the text given, as todo.txt reads it.
  final void Function(String text) onAdd;

  /// The tokens the list already uses.
  final Set<String> Function() knownTokens;

  @override
  State<TodoQuickAdd> createState() => _TodoQuickAddState();
}

final class _TodoQuickAddState extends State<TodoQuickAdd> {
  final TextEditingController _field = TextEditingController();
  late final FocusNode _focus = FocusNode()..addListener(() => setState(() {}));

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _field.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final options = _focus.hasFocus
        ? todoTokenOptions(_field.value, widget.knownTokens()).take(6).toList()
        : const <String>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextFieldTapRegion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              // `Tab` takes the first completion, as an editor's does.
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent ||
                    event.logicalKey != LogicalKeyboardKey.tab ||
                    options.isEmpty) {
                  return KeyEventResult.ignored;
                }
                _pick(options.first);
                return KeyEventResult.handled;
              },
              child: TextField(
                key: const Key('todo-quick-add'),
                controller: _field,
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.add, size: 20),
                  hintText: AppStrings.todoQuickAddHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                // The field keeps the cursor for the next task.
                onEditingComplete: () {},
                onSubmitted: (_) => _add(),
              ),
            ),
            for (final option in options)
              ListTile(
                key: Key('todo-quick-complete-$option'),
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(option),
                onTap: () => _pick(option),
              ),
          ],
        ),
      ),
    );
  }

  void _pick(String option) {
    final next = withTodoTokenOption(_field.value, option);
    if (next == null) return;
    _field.value = next;
    _focus.requestFocus();
    setState(() {});
  }
}
