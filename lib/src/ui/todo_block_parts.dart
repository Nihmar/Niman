import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The head of a `todo` block: what it lists and how many (#1152).
///
/// A tap on it shows the block's source where there is one to show.
final class TodoBlockHead extends StatelessWidget {
  /// A head saying [text].
  const new({required this.text, this.onTap, super.key});

  /// `Tasks · project house · due within 7 days · 2`.
  final String text;

  /// Shows the source; null where there is none.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parts = text.split(' · ');
    return InkWell(
      key: const Key('todo-block-head'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Icon(Icons.checklist_outlined, size: 16, color: scheme.outline),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: parts.first,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: parts.skip(1).map((part) => ' · $part').join(),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a block says when it lists no task: one short line.
final class TodoBlockEmpty extends StatelessWidget {
  /// The line; a tap on it shows the source where there is one.
  const new({this.onTap, super.key});

  /// Shows the source; null where there is none.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Text(
          AppStrings.todoEmptyFiltered,
          key: const Key('todo-block-empty'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A line of a block that cannot be read, and where it is: the row an error
/// takes the place of the list with.
final class TodoBlockProblem extends StatelessWidget {
  /// The problem [text], on line [line] of the block (1-based; 0 for none).
  const new({required this.text, required this.line, this.onTap, super.key});

  /// What is wrong.
  final String text;

  /// The block's line.
  final int line;

  /// Shows the line in the source; null where there is none.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      key: Key('todo-block-error-$line'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.error_outline, size: 18, color: scheme.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: theme.textTheme.bodyMedium),
                  if (line > 0)
                    Text(
                      AppStrings.todoBlockLine(line),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add task, the foot of a block.
final class TodoBlockFoot extends StatelessWidget {
  /// A foot whose button calls [onAdd].
  const new({required this.onAdd, super.key});

  /// Opens the task dialog.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const Key('todo-block-add'),
        onPressed: onAdd,
        icon: const Icon(Icons.add_task_outlined, size: 18),
        label: Text(AppStrings.todoAddTooltip),
      ),
    );
  }
}
