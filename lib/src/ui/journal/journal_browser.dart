/// The journal at a glance (#7): a month with its entries dotted, a way
/// back to today, the day picked, the open tasks due on it (from
/// `todo.txt`), and the latest entries with their first words. The
/// desktop's dock pane and the phone's Journal screen are this, in two
/// sizes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/core/weeks.dart';
import 'package:niman/src/journal/journal_summary.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/journal/journal_calendar.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/strings.dart';

/// The browser over the journal's entries.
final class JournalBrowser extends StatefulWidget {
  /// A browser opened on [today]'s month.
  ///
  /// [entryDays] reads the days with an entry, again whenever [revision]
  /// changes; [readEntry] reads a day's entry for its first words;
  /// [onOpenDay] opens (or offers to make) a day's entry. [large] is the
  /// phone's screen: bigger days, and the picked day in a card of its
  /// own; the dock opens a day on its tap.
  const new({
    required this.today,
    required this.entryDays,
    required this.readEntry,
    required this.onOpenDay,
    this.revision = 0,
    this.large = false,
    this.eventsOn,
    this.goalsOn,
    this.eventDays = const <DateTime>{},
    this.calendarChanged,
    this.onOpenEvent,
    this.dueOn,
    this.tasksChanged,
    this.onOpenTasks,
    this.focusDay,
    this.onEntryMenu,
    super.key,
  });

  /// Opens a recent entry's menu at a right click's global position (#619):
  /// the tree's own menu for that note. Null offers none.
  final void Function(DateTime day, Offset position)? onEntryMenu;

  /// The events of a day, in the order the journal shows them — an event
  /// with no time written last; null shows none at all (#730).
  final List<CalendarEntryEvent> Function(DateTime day)? eventsOn;

  /// The goals that apply to a day (the week's, the month's, the year's),
  /// shown over its events; null shows none.
  final List<CalendarLine> Function(DateTime day)? goalsOn;

  /// The days with at least one event: the calendar's second dot (#730).
  final Set<DateTime> eventDays;

  /// Fires when the calendar file changes, so the events follow.
  final Listenable? calendarChanged;

  /// Opens the event's line in `calendar.txt` (#730).
  final void Function(CalendarEntryEvent event)? onOpenEvent;

  /// The open tasks due on a day, as they read in the task list; null
  /// shows no tasks at all.
  final List<String> Function(DateTime day)? dueOn;

  /// Fires when the tasks change, so the list follows.
  final Listenable? tasksChanged;

  /// Opens the task list, from a task's tap.
  final VoidCallback? onOpenTasks;

  /// The day the dock speaks for when nothing is picked in it: the entry
  /// on screen's, else today.
  final DateTime? focusDay;

  /// The journal's day now.
  final DateTime today;

  /// The days with an entry, oldest first.
  final Future<List<DateTime>?> Function() entryDays;

  /// The text of a day's entry.
  final Future<String> Function(DateTime day) readEntry;

  /// Opens a day's entry, making it after asking when there is none —
  /// or without asking when the making was `confirmed` by a button.
  final void Function(DateTime day, {bool confirmed}) onOpenDay;

  /// The library's revision: a change reads the entries again.
  final int revision;

  /// Whether this is the phone's full screen.
  final bool large;

  @override
  State<JournalBrowser> createState() => _JournalBrowserState();
}

final class _JournalBrowserState extends State<JournalBrowser> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);
  late DateTime _selected = widget.today;

  /// Whether the dock picked [_selected] itself (#712): an empty day is
  /// picked, not opened, and the offer to make it sits under the calendar.
  bool _picked = false;

  List<DateTime> _days = const [];
  Map<DateTime, String> _summaries = const {};

  /// How many of the latest entries the list shows.
  static const _recent = 5;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant JournalBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) unawaited(_load());
  }

  Future<void> _load() async {
    final days = await widget.entryDays();
    if (!mounted || days == null) return;
    setState(() => _days = days);
    final latest = days.reversed.take(_recent).toList();
    final summaries = <DateTime, String>{};
    for (final day in latest) {
      try {
        summaries[day] = journalSummary(await widget.readEntry(day));
      } on Object {
        summaries[day] = '';
      }
    }
    if (mounted) setState(() => _summaries = summaries);
  }

  void _tap(DateTime day) {
    if (widget.large) {
      setState(() => _selected = day);
      return;
    }
    if (day == widget.today || _days.contains(day)) {
      _open(day);
      return;
    }
    // A dock tap on an empty day picks it instead of opening it: the
    // question the phone answers with a dialog is answered here under the
    // calendar (#712).
    setState(() {
      _selected = day;
      _picked = true;
    });
  }

  /// Opens [day], letting go of an empty day the dock picked before
  /// (#788): the pick is a question about that day, and opening another
  /// one answers it — its highlight and its Create row go.
  void _open(DateTime day) {
    if (_picked) setState(() => _picked = false);
    widget.onOpenDay(day);
  }

  /// Shows [month]. In the dock, a pick in the month left behind goes
  /// with it (#788): the Create row would speak for a day no longer on
  /// screen.
  void _showMonth(DateTime month) {
    setState(() {
      _month = month;
      if (!widget.large) _picked = false;
    });
  }

  void _toToday() {
    setState(() {
      _month = DateTime(widget.today.year, widget.today.month);
      _selected = widget.today;
      _picked = false;
    });
    if (!widget.large) widget.onOpenDay(widget.today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final words = MaterialLocalizations.of(context);
    final entries = _days.toSet();
    final heading = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    final latest = _days.reversed.take(_recent).toList();
    return ListView(
      key: const Key('journal-browser'),
      padding: EdgeInsets.all(widget.large ? 18 : 12),
      children: [
        JournalCalendar(
          month: _month,
          entries: entries,
          daysWithEvents: widget.eventDays,
          eventColour: Theme.of(context)
              .extension<SyntaxColors>()
              ?.calendarTime,
          today: widget.today,
          selected: widget.large || _picked ? _selected : null,
          cell: widget.large ? 44 : 34,
          onDay: _tap,
          onMonth: _showMonth,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('journal-to-today'),
            onPressed: _toToday,
            icon: const Icon(Icons.today_outlined, size: 18),
            label: Text(words.currentDateLabel),
          ),
        ),
        if (widget.large) ...[
          const SizedBox(height: 14),
          _dayCard(context, entries.contains(_selected)),
        ] else if (_picked && !entries.contains(_selected)) ...[
          const SizedBox(height: 12),
          _dockCreateRow(context),
        ],
        if (widget.eventsOn case final eventsOn?)
          ListenableBuilder(
            listenable: widget.calendarChanged ?? const _Never(),
            builder: (context, _) {
              final day = widget.large
                  ? _selected
                  : widget.focusDay ?? widget.today;
              final goals = widget.goalsOn?.call(day) ?? const <CalendarLine>[];
              final events = eventsOn(day);
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
                    Text(
                      AppStrings.journalEvents.toUpperCase(),
                      style: heading,
                    ),
                    for (final event in events)
                      _eventRow(context, event, heading),
                  ],
                ],
              );
            },
          ),
        if (widget.dueOn case final dueOn?)
          ListenableBuilder(
            listenable: widget.tasksChanged ?? const _Never(),
            builder: (context, _) {
              final day = widget.large
                  ? _selected
                  : widget.focusDay ?? widget.today;
              final tasks = dueOn(day);
              if (tasks.isEmpty) return const SizedBox.shrink();
              return Column(
                key: const Key('journal-due'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.journalDueOn(formatDateTime(day, 'ddd D'))
                        .toUpperCase(),
                    style: heading,
                  ),
                  for (final task in tasks)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.check_box_outline_blank,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      title: Text(task),
                      onTap: widget.onOpenTasks,
                    ),
                ],
              );
            },
          ),
        if (latest.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(AppStrings.journalRecent.toUpperCase(), style: heading),
          const SizedBox(height: 4),
          for (final day in latest)
            GestureDetector(
              onSecondaryTapUp: switch (widget.onEntryMenu) {
                final menu? => (details) => menu(day, details.globalPosition),
                null => null,
              },
              child: ListTile(
                key: Key('journal-recent-${formatDateTime(day, 'YYYY-MM-DD')}'),
                dense: !widget.large,
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formatDateTime(day, 'ddd').toUpperCase(),
                        style: heading,
                      ),
                      Text(
                        '${day.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  _summaries[day]?.isNotEmpty ?? false
                      ? _summaries[day]!
                      : formatDateTime(day, 'D MMMM YYYY'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _open(day),
              ),
            ),
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
    return Padding(
      key: Key('journal-goal-${goal.key}'),
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              _goalLabel(goal),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _goalText(context, text, goal.tokens)),
        ],
      ),
    );
  }

  /// What a goal covers: the week's number, the month's name, the year.
  String _goalLabel(CalendarLine goal) => journalGoalLabel(goal);

  /// An event's row (#730): its time as written, then its text with the
  /// tokens coloured and an aside dimmed, and a bell for its reminder.
  Widget _eventRow(
    BuildContext context,
    CalendarEntryEvent entry,
    TextStyle? heading,
  ) {
    final theme = Theme.of(context);
    final syntax = theme.extension<SyntaxColors>();
    final event = entry.event;
    return ListTile(
      key: Key('journal-event-${entry.lineIndex}-${event.start}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 56,
        child: Text(
          event.time?.raw ?? '',
          textAlign: TextAlign.end,
          style: theme.textTheme.bodySmall?.copyWith(
            color: syntax?.calendarTime ?? theme.colorScheme.tertiary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      title: _eventText(context, event),
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
      onTap: widget.onOpenEvent == null
          ? null
          : () => widget.onOpenEvent!(entry),
    );
  }

  /// The event's text with its tokens and asides in the editor's colours
  /// (#730): the same runs, from the same parse.
  Widget _eventText(BuildContext context, CalendarEvent event) {
    final theme = Theme.of(context);
    final syntax = theme.extension<SyntaxColors>();
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final text = event.text;
    final runs = <({int start, int end, TextStyle style})>[];
    if (syntax != null) {
      for (final token in event.tokens) {
        final start = token.start - event.textStart;
        final end = token.end - event.textStart;
        if (start < 0 || end > text.length || start >= end) {
          continue;
        }
        runs.add((
          start: start,
          end: end,
          style: _tokenStyle(syntax, token.kind),
        ));
      }
      for (final aside in event.asides) {
        final start = aside.start - event.textStart;
        final end = aside.end - event.textStart;
        if (start < 0 || end > text.length || start >= end) {
          continue;
        }
        runs.add((
          start: start,
          end: end,
          style: TextStyle(
            color: syntax.calendarAside,
            fontStyle: FontStyle.italic,
          ),
        ));
      }
    }
    runs.sort((a, b) => a.start.compareTo(b.start));
    final spans = <TextSpan>[];
    var at = 0;
    for (final run in runs) {
      if (run.start < at) {
        continue;
      }
      if (run.start > at) {
        spans.add(TextSpan(text: text.substring(at, run.start), style: base));
      }
      spans.add(
        TextSpan(text: text.substring(run.start, run.end), style: run.style),
      );
      at = run.end;
    }
    if (at < text.length) {
      spans.add(TextSpan(text: text.substring(at), style: base));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// A goal's text with its tokens coloured: found by the token's own
  /// spelling, since a goal's text is what the line holds after its head.
  Widget _goalText(
    BuildContext context,
    String text,
    List<CalendarToken> tokens,
  ) {
    final theme = Theme.of(context);
    final syntax = theme.extension<SyntaxColors>();
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    if (syntax == null || tokens.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final runs = <({int start, int end, TextStyle style})>[];
    var from = 0;
    for (final token in tokens) {
      final spelling = switch (token.kind) {
        CalendarTokenKind.project => '+${token.value}',
        CalendarTokenKind.context => '@${token.value}',
        CalendarTokenKind.tag => '#${token.value}',
        CalendarTokenKind.keyValue => token.value,
      };
      final start = text.indexOf(spelling, from);
      if (start < 0) {
        continue;
      }
      final end = start + spelling.length;
      runs.add((
        start: start,
        end: end,
        style: _tokenStyle(syntax, token.kind),
      ));
      from = end;
    }
    runs.sort((a, b) => a.start.compareTo(b.start));
    final spans = <TextSpan>[];
    var at = 0;
    for (final run in runs) {
      if (run.start < at) {
        continue;
      }
      if (run.start > at) {
        spans.add(TextSpan(text: text.substring(at, run.start), style: base));
      }
      spans.add(
        TextSpan(text: text.substring(run.start, run.end), style: run.style),
      );
      at = run.end;
    }
    if (at < text.length) {
      spans.add(TextSpan(text: text.substring(at), style: base));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// The editor's own colour for a calendar token (#730): the two files
  /// share the vocabulary, so they share the roles.
  TextStyle _tokenStyle(SyntaxColors syntax, CalendarTokenKind kind) =>
      switch (kind) {
        CalendarTokenKind.project => TextStyle(color: syntax.todoProject),
        CalendarTokenKind.context => TextStyle(color: syntax.todoContext),
        CalendarTokenKind.tag => TextStyle(color: syntax.tag),
        CalendarTokenKind.keyValue => TextStyle(color: syntax.todoKeyValue),
      };

  /// The dock's offer for the empty day it picked (#712): the phone's
  /// card and dialog in one row, under the calendar they belong to.
  Widget _dockCreateRow(BuildContext context) {
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
                  Text(
                    journalDayLabel(_selected),
                    style: theme.textTheme.titleSmall,
                  ),
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
              onPressed: () => widget.onOpenDay(_selected, confirmed: true),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStrings.actionCreate),
            ),
          ],
        ),
      ),
    );
  }

  /// The phone's card for the picked day: open its entry, or make one.
  Widget _dayCard(BuildContext context, bool hasEntry) {
    final theme = Theme.of(context);
    return Card.filled(
      key: const Key('journal-day-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journalDayLabel(_selected),
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
              onPressed: () => widget.onOpenDay(_selected, confirmed: true),
              icon: Icon(hasEntry ? Icons.arrow_forward : Icons.add, size: 18),
              label: Text(
                hasEntry
                    ? AppStrings.journalOpenEntry
                    : AppStrings.actionCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A listenable that never fires, for a browser with no tasks to follow.
final class _Never implements Listenable {
  const new();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// What a goal covers: the week's number, the month's name, the year
/// (#730). Shared with the Home's events tile, so both name a goal alike.
String journalGoalLabel(CalendarLine goal) {
  final date = goal.date;
  if (date == null) return '';
  return switch (goal.kind) {
    CalendarLineKind.weekGoal => AppStrings.journalWeek(
      goal.week ?? isoWeekOf(date),
    ),
    CalendarLineKind.monthGoal => AppStrings.monthNames[date.month - 1],
    CalendarLineKind.yearGoal => '${date.year}',
    _ => '',
  };
}
