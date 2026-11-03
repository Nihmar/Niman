/// The task dialog's token chips: the text's own `+`/`@`/`#` tokens,
/// removable, and the buttons that start a new one (split out of
/// `todo_edit_dialog.dart` for #100).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The removable chips of [tokens] (none when empty), then one add button
/// per sigil.
final class TodoTokenChips extends StatelessWidget {
  /// The chips of [tokens]; [onRemove] drops one, [onAdd] starts a token
  /// with the sigil given.
  const new({
    required this.tokens,
    required this.onRemove,
    required this.onAdd,
    super.key,
  });

  /// The distinct tokens of the text, sigil included.
  final List<String> tokens;

  /// Removes a token from the text.
  final ValueChanged<String> onRemove;

  /// Starts a token with the sigil given (`+`, `@` or `#`).
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                    onDeleted: () => onRemove(token),
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
                  onPressed: () => onAdd(kind.$1),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
