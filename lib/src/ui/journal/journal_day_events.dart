/// The goals and the events of the day the journal browser speaks for
/// (#730): the goals over the events, each event with its time, its text
/// and its reminder.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/time_display.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/ui/journal/journal_goal_label.dart';
import 'package:niman/src/ui/line_runs.dart';
import 'package:niman/src/ui/repeat_label.dart';
import 'package:niman/src/ui/strings.dart';

/// A day's goals and events, or nothing when it has neither.
final class JournalDayEvents extends StatelessWidget {
  /// The [goals] and [events] of one day, under labels in [heading].
  ///
  /// [onTapEvent] is an event's tap, null for none; [onEventMenu], when
  /// given, opens an event's menu at a right click or a long press.
  const new({
    required this.goals,
    required this.events,
    required this.heading,
    this.eventTimesClock = false,
    this.onTapEvent,
    this.onEventMenu,
    super.key,
  });

  /// The goals that apply to the day, shown over its events.
  final List<CalendarLine> goals;

  /// The day's events, in the order the journal shows them.
  final List<CalendarEntryEvent> events;

  /// The style of the section's labels.
  final TextStyle? heading;

  /// Whether an event's time is read as a clock (`09:00–12:00`) rather
  /// than as the file writes it (`9-12`) (#730).
  final bool eventTimesClock;

  /// An event's tap; null leaves the rows without one.
  final void Function(CalendarEntryEvent entry)? onTapEvent;

  /// Opens an event's menu at a global position; null offers none.
  final void Function(CalendarEntryEvent entry, Offset position)? onEventMenu;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty && events.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      key: const Key('journal-events'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        for (final goal in goals) _goalRow(context, goal, heading),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(AppStrings.journalEvents.toUpperCase(), style: heading),
          for (final event in events) _eventRow(context, event),
        ],
      ],
    );
  }

  /// One of the day's goals (#730): what it covers, and what it says. The
  /// goal's own tokens wear the editor's colours, so a line reads the same
  /// in both places.
  Widget _goalRow(BuildContext context, CalendarLine goal, TextStyle? style) {
    final text = goal.goalText;
    if (text == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final goalStyle = style?.copyWith(
      color:
          theme.extension<SyntaxColors>()?.calendarGoal ??
          theme.colorScheme.tertiary,
    );
    return Padding(
      key: Key('journal-goal-${goal.key}'),
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              journalGoalLabel(goal),
              style: goalStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: lineText(context, text, calendarLineRuns(goal.tokens)),
          ),
        ],
      ),
    );
  }

  /// An event's row (#730): its time as written, then its text with the
  /// tokens coloured and an aside dimmed, and a bell for its reminder.
  Widget _eventRow(BuildContext context, CalendarEntryEvent entry) {
    final theme = Theme.of(context);
    final syntax = theme.extension<SyntaxColors>();
    final event = entry.event;
    final onTap = onTapEvent;
    final tile = ListTile(
      key: Key('journal-event-${entry.lineIndex}-${event.start}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 56,
        child: Text(
          calendarTimeText(
            event.time,
            asClock: eventTimesClock,
            day: entry.day,
          ),
          textAlign: TextAlign.end,
          style: theme.textTheme.bodySmall?.copyWith(
            color: syntax?.calendarTime ?? theme.colorScheme.tertiary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      title: calendarEventText(context, event),
      // An event that repeats says by what, on every day it shows (#1190).
      subtitle: entry.recurrence == null
          ? null
          : RepeatLabel(
              key: Key(
                'journal-event-repeat-${entry.lineIndex}-${event.start}',
              ),
              rule: entry.recurrence!.rule,
            ),
      trailing: event.reminder == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(event.reminder!, style: theme.textTheme.bodySmall),
              ],
            ),
      onTap: onTap == null ? null : () => onTap(entry),
    );
    // The dock has no sheet: a right click, or a long press on a touch
    // screen that has the dock, opens the event's menu (#1191).
    final menu = onEventMenu;
    if (menu == null) return tile;
    return GestureDetector(
      onSecondaryTapUp: (details) => menu(entry, details.globalPosition),
      onLongPressStart: (details) => menu(entry, details.globalPosition),
      child: tile,
    );
  }
}
