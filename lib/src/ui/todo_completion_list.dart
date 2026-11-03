/// The task dialog's known-token completion list (split out of
/// `todo_edit_dialog.dart` for #100).
library;

import 'package:flutter/material.dart';

/// The tap-to-pick list of completion [options] under the field.
///
/// A plain column (no scroll viewport): the dialog is itself intrinsic-
/// sized, and a scrolling list inside that fails the intrinsic measure.
/// The pool is already capped at six, well within the dialog's scroll.
final class TodoCompletionList extends StatelessWidget {
  /// The rows of [options]; [onPicked] hears the one tapped.
  const new({required this.options, required this.onPicked, super.key});

  /// The tokens offered, sigil included.
  final List<String> options;

  /// Hears the option tapped.
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          ListTile(
            key: Key('todo-complete-$option'),
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(option),
            onTap: () => onPicked(option),
          ),
      ],
    );
  }
}
