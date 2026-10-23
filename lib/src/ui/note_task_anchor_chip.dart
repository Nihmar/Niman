import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// The heading or block a task's link names in the note whose task list the
/// task is in (#1152): `§ Boiler`.
///
/// The link to the note itself is left out of the row, being the list's own
/// subject; the place in it that the task points at stays, in the wikilink
/// colour of the chips beside it, small and without an icon.
final class NoteTaskAnchorChip extends StatelessWidget {
  /// The chip of [anchor]: a heading path (`Boiler`) or a block id (`^b7`).
  const new({required this.anchor, super.key});

  /// What the link names after the note.
  final String anchor;

  @override
  Widget build(BuildContext context) {
    final color = SyntaxColors.of(context).wikilink;
    return DecoratedBox(
      key: Key('note-task-anchor-$anchor'),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '§ $anchor',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
