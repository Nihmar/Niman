/// The dock's offer to make the entry of the empty day it picked (#712).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/strings.dart';

/// The dock's offer for the empty day it picked (#712): the phone's card
/// and dialog in one row, under the calendar they belong to.
final class JournalDockCreateRow extends StatelessWidget {
  /// The offer for [day]; [onCreate] makes its entry.
  const new({required this.day, required this.onCreate, super.key});

  /// The picked day, which has no entry.
  final DateTime day;

  /// Makes the day's entry and opens it.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      key: const Key('journal-dock-create'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(journalDayLabel(day), style: theme.textTheme.titleSmall),
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
              key: const Key('journal-dock-create-button'),
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStrings.actionCreate),
            ),
          ],
        ),
      ),
    );
  }
}
