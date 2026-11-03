import 'package:flutter/material.dart';

/// A section's heading in the palette's list: pinned, commands, notes.
final class PaletteHeading extends StatelessWidget {
  /// A heading reading [text], upper-cased.
  const new(this.text, {super.key});

  /// What the heading says.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
