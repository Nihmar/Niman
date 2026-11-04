/// The phone's card for the day picked in the journal browser (#730).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/strings.dart';

/// The phone's card for the picked day: open its entry, or make one.
final class JournalDayCard extends StatelessWidget {
  /// The card for [day], which [hasEntry] or not.
  ///
  /// [onOpen] opens the day's entry, or makes it; [actions] ride in the
  /// card's second row, which shows only when there are some.
  const new({
    required this.day,
    required this.hasEntry,
    required this.onOpen,
    this.actions = const <Widget>[],
    super.key,
  });

  /// The picked day.
  final DateTime day;

  /// Whether the day has an entry to open.
  final bool hasEntry;

  /// Opens the day's entry, or makes it.
  final VoidCallback onOpen;

  /// The day's own actions, under its first row.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      key: const Key('journal-day-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The first row keeps its height whether the day has an entry
            // or not, so nothing moves under a thumb already on it (#730).
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journalDayLabel(day),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (!hasEntry)
                        Text(
                          AppStrings.journalNoEntry,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: const Key('journal-day-open'),
                  onPressed: onOpen,
                  icon: Icon(
                    hasEntry ? Icons.arrow_forward : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    hasEntry
                        ? AppStrings.journalOpenEntry
                        : AppStrings.actionCreate,
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) Wrap(spacing: 4, children: actions),
          ],
        ),
      ),
    );
  }
}
