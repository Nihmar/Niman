import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/ui/kinds/flashcards/next_label.dart';

/// One of the four grades: its name, when it brings the card back, and
/// its key where there is a keyboard.
final class GradeButton extends StatelessWidget {
  /// The button of [grade], which brings the card back [when], with its
  /// [shortcut] key if any; [onPressed] grades.
  const new({
    required this.grade,
    required this.when,
    required this.shortcut,
    required this.onPressed,
    super.key,
  });

  /// The grade.
  final Grade grade;

  /// When it brings the card back, in words.
  final String when;

  /// Its key, where there is a keyboard.
  final String? shortcut;

  /// What it does.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return OutlinedButton(
      key: Key('review-grade-${grade.name}'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        foregroundColor: grade == Grade.again ? scheme.error : null,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(gradeName(grade), overflow: TextOverflow.ellipsis),
          Text(when, style: small, overflow: TextOverflow.ellipsis),
          if (shortcut case final key?) Text(key, style: small),
        ],
      ),
    );
  }
}
