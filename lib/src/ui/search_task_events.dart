/// The Tasks and events group of a lone-token search (#730): the seam the
/// shell fills from the files already in memory, and the rows it draws.
///
/// A row is an event's time and text, a goal, or an open task — each with
/// the day it is about and the file it comes from, so `+thesis` reads the
/// same in the two files. The matcher itself is
/// `search/task_events.dart`; this is the screen's side of it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/time_display.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/journal/journal_browser.dart'
    show journalGoalLabel;
import 'package:niman/src/ui/line_runs.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_row.dart' show TodoDueLabel;

/// The group's data source: the rows a lone `+project`/`@context` answers
/// with, and the notifier that says the files behind them moved.
///
/// The shell builds it over the two controllers it already holds; a
/// widget test hands over a closure over a literal list. Null in the
/// screen means no group at all (and none of the files either).
@immutable
final class TaskEvents {
  /// Creates the source.
  const new({required this.hits, required this.changes});

  /// The rows a lone `+project`/`@context` token (`+thesis`, `@phone`)
  /// answers with.
  final List<TaskEventHit> Function(String token) hits;

  /// Notifies when the tasks or the calendar moved (the two controllers,
  /// merged).
  final Listenable changes;
}

/// A heading over one section of the results, upper-cased and
/// letter-spaced the way the journal heads its own sections.
Widget searchSectionHeader(BuildContext context, String label, {Key? key}) {
  final theme = Theme.of(context);
  return Padding(
    key: key,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
    child: Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// One row of the group: [hit]'s own icon, its time and text, and the day
/// and file it comes from. [onTap] opens it; [today] reads a due date;
/// [asClock] reads an event's time as a clock rather than as written
/// (#730).
Widget searchTaskEventRow(
  BuildContext context,
  TaskEventHit hit, {
  required DateTime today,
  bool asClock = false,
  VoidCallback? onTap,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final syntax = theme.extension<SyntaxColors>();
  return ListTile(
    key: _rowKey(hit),
    dense: true,
    leading: switch (hit.kind) {
      TaskEventKind.event => Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: syntax?.calendarTime ?? scheme.tertiary,
      ),
      // A goal wears the palette's own green, the colour a plan is drawn
      // in wherever the app shows one (#730).
      TaskEventKind.goal => Icon(
        Icons.flag_outlined,
        size: 18,
        color: syntax?.calendarGoal ?? scheme.tertiary,
      ),
      TaskEventKind.task => Icon(
        Icons.check_box_outline_blank,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
    },
    title: switch (hit.kind) {
      TaskEventKind.event => _eventTitle(context, hit, syntax, theme, asClock),
      TaskEventKind.goal => lineText(
        context,
        hit.goal?.goalText ?? '',
        calendarLineRuns(hit.goal?.tokens ?? const <CalendarToken>[]),
        maxLines: 1,
      ),
      TaskEventKind.task => lineText(
        context,
        hit.task?.description ?? '',
        hit.task == null ? const <LineRun>[] : todoLineRuns(hit.task!),
        maxLines: 1,
      ),
    },
    subtitle: _subtitle(context, hit, today),
    onTap: onTap,
  );
}

/// The row's key: an event twice on one line is two rows, so the event's
/// own offset tells them apart.
Key _rowKey(TaskEventHit hit) => Key(
  'search-task-event-${hit.kind.name}-${hit.lineIndex}'
  '${hit.event == null ? '' : '-${hit.event!.event.start}'}',
);

/// An event's title: its time as written, then its text in the editor's
/// colours.
Widget _eventTitle(
  BuildContext context,
  TaskEventHit hit,
  SyntaxColors? syntax,
  ThemeData theme,
  bool asClock,
) {
  final entry = hit.event!;
  final time = calendarTimeText(
    entry.event.time,
    asClock: asClock,
    day: entry.line.date,
  );
  return Row(
    children: [
      if (time.isNotEmpty) ...[
        Text(
          time,
          style: theme.textTheme.bodySmall?.copyWith(
            color: syntax?.calendarTime ?? theme.colorScheme.tertiary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(child: calendarEventText(context, entry.event, maxLines: 1)),
    ],
  );
}

/// The day a row is about, and the file it is written in: `Mon 12 Oct ·
/// calendar.txt`, `Week 42 goal · calendar.txt`, `Due today · todo.txt`.
Widget _subtitle(BuildContext context, TaskEventHit hit, DateTime today) {
  final theme = Theme.of(context);
  final style = theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
  final source = hit.kind == TaskEventKind.task
      ? todoFileName
      : calendarFileName;
  switch (hit.kind) {
    case TaskEventKind.event:
      return Text(
        '${formatDateTime(hit.day ?? today, 'ddd D MMM')} · $source',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    case TaskEventKind.goal:
      final scope = hit.goal == null ? '' : journalGoalLabel(hit.goal!);
      return Text(
        '${AppStrings.searchGoal(scope)} · $source',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    case TaskEventKind.task:
      final due = hit.task?.due;
      return Row(
        children: [
          if (due == null)
            Text(AppStrings.todoDueNoDate, style: style)
          else
            TodoDueLabel(due: due, today: today),
          Flexible(
            child: Text(
              ' · $source',
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
  }
}
