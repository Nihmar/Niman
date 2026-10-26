/// The repeat part of a row (#1189, #1190): the outline repeat icon and the
/// rule in words, "every 2 weeks".
///
/// A task row, an event row, the Home's tile and a search hit draw it the
/// same way, so a rule reads alike wherever it shows.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/ui/recurrence_words.dart';

/// The label of something that repeats by [rule].
final class RepeatLabel extends StatelessWidget {
  /// The label of [rule].
  const new({required this.rule, super.key});

  /// The rule it repeats by.
  final RecurrenceRule rule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.repeat, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            recurrenceWords(rule.description),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
