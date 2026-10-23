/// The list of notes under a task's text field while a `[[` link is typed
/// (#1152).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/todo_link_suggestions.dart';

/// The rows of [suggestions], tap to insert.
///
/// A plain column, like the token completion's: the dialog it sits in is
/// intrinsic-sized, and a scrolling list inside that fails the measure. It
/// is inside the field's own tap region, so the tap that picks a row is not
/// one outside the field (#311).
final class TodoLinkOptions extends StatelessWidget {
  /// The list of [suggestions].
  const new({required this.suggestions, super.key});

  /// What is listed and picked.
  final TodoLinkSuggestions suggestions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: suggestions,
      builder: (context, _) {
        if (!suggestions.isOpen) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return TextFieldTapRegion(
          child: Column(
            key: const Key('todo-link-options'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < suggestions.rows.length; i++)
                ListTile(
                  key: Key('todo-link-option-$i'),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  selected: i == suggestions.selected,
                  leading: Icon(switch (suggestions.rows[i].kind) {
                    TodoLinkRowKind.note => Icons.description_outlined,
                    TodoLinkRowKind.heading => Icons.tag,
                    TodoLinkRowKind.block => Icons.link,
                  }, size: 18),
                  title: Text(
                    suggestions.rows[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: suggestions.rows[i].detail.isEmpty
                      ? null
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            suggestions.rows[i].detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                  onTap: () => suggestions.pick(i),
                ),
            ],
          ),
        );
      },
    );
  }
}
