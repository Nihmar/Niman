/// The phone's sheet for one event (#730): what it is, its day, the rule it
/// repeats by and its reminder, and the things to do with it (#1191).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_entry.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/ui/journal/journal_event_actions.dart';
import 'package:niman/src/ui/journal/journal_flow.dart' show journalDayLabel;
import 'package:niman/src/ui/line_runs.dart';
import 'package:niman/src/ui/repeat_label.dart';
import 'package:niman/src/ui/strings.dart';

/// Opens the sheet of [entry]: the action picked from it, or null when it
/// was dismissed. [offered] are the actions the screen can carry out.
Future<JournalEventAction?> showJournalEventSheet(
  BuildContext context, {
  required CalendarEntryEvent entry,
  required JournalEventActions offered,
}) {
  return showModalBottomSheet<JournalEventAction>(
    context: context,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  key: const Key('journal-event-sheet-grab'),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _EventHead(entry: entry),
              const Divider(height: 24),
              ...journalEventActionRows(sheet, entry: entry, offered: offered),
            ],
          ),
        ),
      );
    },
  );
}

/// What the event is: its time and text, its day, its rule and its reminder.
final class _EventHead extends StatelessWidget {
  const new({required this.entry});

  final CalendarEntryEvent entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syntax = theme.extension<SyntaxColors>();
    final time = syntax?.calendarTime ?? theme.colorScheme.tertiary;
    final event = entry.event;
    final day = entry.day;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.event_outlined, size: 22, color: time),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: theme.textTheme.titleMedium ?? const TextStyle(),
                child: Row(
                  children: [
                    if (event.time != null) ...[
                      Text(
                        event.time!.raw,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: time,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: calendarEventText(context, event)),
                  ],
                ),
              ),
              if (day != null)
                Text(
                  journalDayLabel(day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (entry.recurrence case final recurrence?)
                RepeatLabel(
                  key: const Key('journal-event-sheet-repeat'),
                  rule: recurrence.rule,
                ),
              if (event.reminder case final reminder?)
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.calendarReminderAt(reminder),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
