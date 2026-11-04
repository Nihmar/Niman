/// The task dialog's description entry field (split out of
/// `todo_edit_dialog.dart` for #100).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_link_suggestions.dart';

/// The description entry field: it wraps and grows downward up to
/// [_fieldMaxLines] lines, then scrolls inside itself (#267).
///
/// It is still one todo.txt line. A soft keyboard shows Done, which
/// saves; a hardware Enter saves too, caught before the field would
/// break the line, unless an input method is composing a word, which
/// Enter commits. A line break that comes in anyway (a paste) becomes a
/// space.
final class TodoDescriptionField extends StatelessWidget {
  /// The field over [controller]; [onSave] saves the task, [onEdited]
  /// hears every edit typed.
  const new({
    required this.controller,
    required this.focusNode,
    required this.links,
    required this.onSave,
    required this.onEdited,
    super.key,
  });

  /// The description text.
  final TextEditingController controller;

  /// The field's focus.
  final FocusNode focusNode;

  /// The notes offered while a `[[` link is typed (#1152).
  final TodoLinkSuggestions links;

  /// Saves the task.
  final VoidCallback onSave;

  /// Hears an edit typed into the field.
  final VoidCallback onEdited;

  /// How far the description grows before it scrolls.
  static const int _fieldMaxLines = 6;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        // A list of notes under the field takes the keys it needs (#1152).
        final listed = links.handleKey(event);
        if (listed == KeyEventResult.handled) return listed;
        final enter =
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter;
        if (!enter || controller.value.composing.isValid) {
          return KeyEventResult.ignored;
        }
        if (event is KeyDownEvent) onSave();
        return KeyEventResult.handled;
      },
      child: TextField(
        key: const Key('todo-dialog-field'),
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        minLines: 1,
        maxLines: _fieldMaxLines,
        keyboardType: TextInputType.text,
        inputFormatters: const [_NoLineBreaks()],
        decoration: InputDecoration(hintText: AppStrings.todoDescriptionHint),
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          links.edited();
          onEdited();
        },
        onSubmitted: (_) {
          // The break of the `Enter` that picked a note is not a save.
          if (!links.justPicked) onSave();
        },
      ),
    );
  }
}

/// Turns every line break into a space, one for one, so the caret and
/// the selection keep their offsets: a task is one todo.txt line.
final class _NoLineBreaks extends TextInputFormatter {
  const new();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains(RegExp('[\r\n]'))) return newValue;
    return newValue.copyWith(
      text: newValue.text.replaceAll(RegExp('[\r\n]'), ' '),
    );
  }
}
