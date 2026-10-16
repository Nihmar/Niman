import 'package:flutter/material.dart';

/// A task's priority letter as a small badge (#1003): `A`, `B`, ...
///
/// The list's sections already say the priority when it is sorted by it, so
/// the row leaves the badge out then (the caller decides); a task without a
/// priority has none.
final class TodoPriorityBadge extends StatelessWidget {
  /// Creates the badge of [priority] (`A`...`Z`).
  const new({required this.priority, super.key});

  /// The priority letter.
  final String priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const Key('todo-row-priority'),
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
