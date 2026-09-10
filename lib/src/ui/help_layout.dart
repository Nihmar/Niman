/// The shape a reference screen in Copist has.
///
/// Two of them exist — the todo.txt syntax (T-TD-08) and the template
/// placeholders (T-TPL-08) — and they answer the same kind of question:
/// what may I write in this file, and what will it do. They looked the
/// same because the first was copied; they are the same now because they
/// share these four pieces.
library;

import 'package:flutter/material.dart';

/// A section heading inside a help screen.
final class HelpSection extends StatelessWidget {
  /// Creates a heading.
  const new(this.text, {super.key});

  /// The heading.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// A block of prose inside a help screen.
final class HelpParagraph extends StatelessWidget {
  /// Creates a paragraph.
  const new(this.text, {super.key});

  /// The prose.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// A monospaced sample, scrollable so a long line never clips.
final class HelpExample extends StatelessWidget {
  /// Creates a sample block showing [line].
  const new(this.line, {super.key});

  /// The sample text; may be several lines.
  final String line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          line,
          style: TextStyle(fontFamily: 'monospace', color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// One piece of syntax and what it means.
final class HelpRow extends StatelessWidget {
  /// Creates a row: [syntax] above, [meaning] under it.
  const new(this.syntax, this.meaning, {super.key});

  /// The syntax, shown monospaced.
  final String syntax;

  /// What it does.
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            syntax,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            meaning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
