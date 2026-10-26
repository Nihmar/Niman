/// The line as the event form will write it (#730): the writer's own answer,
/// with the new event picked out, so the preview can never promise something
/// the file would not hold.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// [line] in a box, with [body] — the event as written — in the goal colour.
final class CalendarEventPreview extends StatelessWidget {
  /// A preview of [line], picking out [body].
  const new({required this.line, required this.body, super.key});

  /// The day's line as it will be written.
  final String line;

  /// The event within it, as the writer writes it.
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final syntax = theme.extension<SyntaxColors>();
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 11.5,
      color: scheme.onSurface,
    );
    final at = body.isEmpty ? -1 : line.indexOf(body);
    return Container(
      key: const Key('calendar-event-preview'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: at < 0
          ? Text(line, style: style)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: line.substring(0, at), style: style),
                  TextSpan(
                    text: body,
                    style: style?.copyWith(
                      color: syntax?.calendarGoal ?? scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: line.substring(at + body.length),
                    style: style,
                  ),
                ],
              ),
            ),
    );
  }
}
