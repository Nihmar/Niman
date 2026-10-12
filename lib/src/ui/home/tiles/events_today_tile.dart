/// The Home's events tile (#730): the day's goals over its events, read
/// from `calendar.txt` — the same file, and the same parse, as the
/// journal's own section.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/line_runs.dart';
import 'package:niman/src/ui/strings.dart';

/// Today's events.
final class EventsTodayTile extends StatelessWidget {
  /// The tile over [host]'s calendar file.
  const new({required this.host, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// How many events the tile lists: what a short tile has room for.
  static const int limit = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: host.calendar,
      builder: (context, _) {
        final snapshot = host.calendar.snapshot;
        final today = DateTime.now();
        final goals = snapshot?.goalsFor(today) ?? const <CalendarEntry>[];
        final events =
            snapshot?.eventsFor(today) ?? const <CalendarEntryEvent>[];
        if (goals.isEmpty && events.isEmpty) {
          return HomeTileEmpty(AppStrings.homeEventsEmpty);
        }
        final time = theme.extension<SyntaxColors>()?.calendarTime;
        // A goal is its label in the goal's green, then what it says in
        // the tile's own muted body, its tokens in the editor's colours
        // (#730).
        final muted = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
        final goalColour =
            theme.extension<SyntaxColors>()?.calendarGoal ??
            theme.colorScheme.tertiary;
        return InkWell(
          key: const Key('home-events-open'),
          onTap: host.openJournal,
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final goal in goals)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${journalGoalLabel(goal.line)} · ',
                        style: muted?.copyWith(color: goalColour),
                      ),
                      ...lineSpans(
                        context,
                        goal.line.goalText ?? '',
                        calendarLineRuns(goal.line.tokens),
                        base: muted,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              for (final event in events.take(limit))
                SizedBox(
                  height: 28,
                  child: InkWell(
                    key: Key(
                      'home-event-${event.lineIndex}-${event.event.start}',
                    ),
                    onTap: () => host.openEvent(event),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            event.event.time?.raw ?? '',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: time ?? theme.colorScheme.tertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.event.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
