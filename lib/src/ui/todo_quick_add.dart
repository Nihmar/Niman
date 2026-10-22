/// The quick-add field at the top of a desktop's task list (#712): type a
/// task, `Enter` adds it and the field stays for the next one. The dialog
/// is for the details — dates picked, a reminder, the priority.
///
/// Typing `[[` lists the library's notes, as in the dialog (#1152).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_link_options.dart';
import 'package:niman/src/ui/todo_link_suggestions.dart';
import 'package:niman/src/ui/todo_token_completion.dart';

/// A one-line field that adds a task per `Enter`.
final class TodoQuickAdd extends StatefulWidget {
  /// Creates the field; [onAdd] gets the text typed, trimmed and never
  /// empty, and [knownTokens] complete a `+`/`@`/`#` word under the caret;
  /// [linkSuggester] gives the notes a `[[` link can name (null offers none).
  const new({
    required this.onAdd,
    required this.knownTokens,
    this.linkSuggester,
    super.key,
  });

  /// Adds a task written as the text given, as todo.txt reads it.
  final void Function(String text) onAdd;

  /// The tokens the list already uses.
  final Set<String> Function() knownTokens;

  /// The library's notes, for a `[[` link.
  final WikilinkSuggester? Function()? linkSuggester;

  @override
  State<TodoQuickAdd> createState() => _TodoQuickAddState();
}

final class _TodoQuickAddState extends State<TodoQuickAdd> {
  final TextEditingController _field = TextEditingController();
  late final FocusNode _focus = FocusNode()
    ..addListener(() {
      if (!_focus.hasFocus) _links.close();
      setState(() {});
    });
  late final TodoLinkSuggestions _links = TodoLinkSuggestions(
    _field,
    () => widget.linkSuggester?.call(),
  );

  @override
  void dispose() {
    _links.dispose();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    if (_links.justPicked) return;
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
              // `Tab` takes the first completion, as an editor's does; a list
              // of notes under the field takes its own keys first.
              onKeyEvent: (node, event) {
                final listed = _links.handleKey(event);
                if (listed == KeyEventResult.handled) return listed;
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
                onChanged: (_) {
                  _links.edited();
                  setState(() {});
                },
                // The field keeps the cursor for the next task.
                onEditingComplete: () {},
                onSubmitted: (_) => _add(),
              ),
            ),
            TodoLinkOptions(suggestions: _links),
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
