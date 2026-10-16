/// The token chips of a todo row (issue #131): a chip per `+project` /
/// `@context` / `#tag` the task carries, each kind in its own color.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/todo/parser.dart';

/// A chip per `+project` / `@context` / `#tag` the [task] carries.
List<Widget> todoRowTokenChips(TodoTask task) {
  return [
    for (final p in task.projects) _TokenChip(token: '+$p'),
    for (final c in task.contexts) _TokenChip(token: '@$c'),
    for (final h in task.hashtags) _TokenChip(token: '#$h'),
  ];
}

/// One token chip of the row subtitle: the token's kind color
/// (`+project` the accent, `@context` the syntax tag teal, `#tag` the
/// tertiary) behind the token text with its sigil, so what `todo.txt`
/// separates on purpose looks apart at a glance (issue #131).
final class _TokenChip extends StatelessWidget {
  const new({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tokenColor(context, token);
    return Container(
      key: Key('todo-row-token-$token'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        token,
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

/// The token's color by kind, not by name: projects wear the accent,
/// contexts the syntax tag teal, tags the tertiary.
Color tokenColor(BuildContext context, String token) {
  final scheme = Theme.of(context).colorScheme;
  if (token.startsWith('+')) return scheme.primary;
  if (token.startsWith('@')) return SyntaxColors.of(context).tag;
  return scheme.tertiary;
}
