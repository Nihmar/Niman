/// The journal at a glance (#7): a month with its entries dotted, a way
/// back to today, the day picked, the open tasks due on it (from
/// `todo.txt`), and the latest entries with their first words. The
/// desktop's dock pane and the phone's Journal screen are this, in two
/// sizes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/time_display.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/core/weeks.dart';
import 'package:niman/src/journal/journal_summary.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/calendar_event_form.dart';
import 'package:niman/src/ui/journal/journal_calendar.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/line_runs.dart';
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
    this.onEditEvent,
    this.onDeleteEvent,
    this.dueOn,
    this.tasksChanged,
    this.onOpenTasks,
    this.knownTokens = const <String>{},
    this.eventTimesClock = false,
    this.calendarFile,
    this.onAddEvent,
    this.onAddTask,
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

  /// Replaces an entry's event with the draft the form handed over
  /// (#730): the phone's sheet is where an event is edited without
  /// leaving the journal.
  final void Function(CalendarEntryEvent entry, CalendarEventDraft event)?
  onEditEvent;

  /// Takes an entry's event out of the file (#730).
  final void Function(CalendarEntryEvent entry)? onDeleteEvent;

  /// The open tasks due on a day, as they read in the task list; null
  /// shows no tasks at all.
  final List<String> Function(DateTime day)? dueOn;

  /// Fires when the tasks change, so the list follows.
  final Listenable? tasksChanged;

  /// Opens the task list, from a task's tap.
  final VoidCallback? onOpenTasks;

  /// Whether an event's time is read as a clock (`09:00–12:00`) rather
  /// than as the file writes it (`9-12`) (#730).
  final bool eventTimesClock;

  /// The `+`/`@`/`#` tokens the two files already use, for the Add event
  /// form's suggestions (#730).
  final Set<String> knownTokens;

  /// The calendar file as it is now: the Add event form previews the line
  /// the writer would make of it.
  final CalendarFileContent? calendarFile;

  /// Writes a new event on a day: the shell owns the controller, the
  /// browser owns the form (#730). Null shows no Add event.
  final void Function(DateTime day, CalendarEventDraft event)? onAddEvent;

  /// Opens the todo add with a day as its due date (#730). Null shows no
  /// Add task.
  final void Function(DateTime day)? onAddTask;

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

  /// The day the Add event form is open for, or null when it is closed: a
  /// window gets the form inline in this pane, a phone a sheet (#730).
  DateTime? _addingEvent;

  /// The event the open form is editing, or null when it is adding one.
  CalendarEntryEvent? _editingEvent;

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
        // A wrap, not a row: the dock's island is narrow and a phone's
        // card narrower still, and a control that cannot be reached is
        // worse than one on the next line.
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('journal-to-today'),
              onPressed: _toToday,
              icon: const Icon(Icons.today_outlined, size: 18),
              label: Text(words.currentDateLabel),
            ),
            // Beside Today in the dock; a phone gets them in the day card's
            // own second row, where the thumb already is (#730).
            if (!widget.large) ..._dayActions(context),
          ],
        ),
        if (widget.large) ...[
          const SizedBox(height: 14),
          _dayCard(context, entries.contains(_selected)),
        ] else ...[
          if (_picked && !entries.contains(_selected)) ...[
            const SizedBox(height: 12),
            _dockCreateRow(context),
          ],
          // The form sits where the calendar is, under it: a dialog would
          // go over the very thing the day was picked on (#712).
          if (_addingEvent case final day?) ...[
            const SizedBox(height: 12),
            _eventForm(context, day, _editingEvent),
          ],
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
              _goalLabel(goal),
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
          calendarTimeText(
            event.time,
            asClock: widget.eventTimesClock,
            day: entry.line.date,
          ),
          textAlign: TextAlign.end,
          style: theme.textTheme.bodySmall?.copyWith(
            color: syntax?.calendarTime ?? theme.colorScheme.tertiary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      title: calendarEventText(context, event),
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
      // A phone taps through to the sheet (Edit, Delete, the file); a
      // window goes straight to the file, which is where it is edited
      // (#730).
      onTap: widget.large && _sheetOffered
          ? () => _showEventSheet(entry)
          : (widget.onOpenEvent == null
                ? null
                : () => widget.onOpenEvent!(entry)),
    );
  }

  /// Whether the event sheet has anything to offer.
  bool get _sheetOffered =>
      widget.onEditEvent != null || widget.onDeleteEvent != null;

  /// The phone's sheet for one event (#730): what it is, its day, its
  /// reminder, and the three things to do with it.
  void _showEventSheet(CalendarEntryEvent entry) {
    final event = entry.event;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) {
          final theme = Theme.of(sheet);
          final syntax = theme.extension<SyntaxColors>();
          final time = syntax?.calendarTime ?? theme.colorScheme.tertiary;
          final day = entry.line.date;
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.event_outlined, size: 22, color: time),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle(
                              style:
                                  theme.textTheme.titleMedium ??
                                  const TextStyle(),
                              child: Row(
                                children: [
                                  if (event.time != null) ...[
                                    Text(
                                      event.time!.raw,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(color: time),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: calendarEventText(sheet, event),
                                  ),
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
                  ),
                  const Divider(height: 24),
                  if (widget.onEditEvent != null)
                    ListTile(
                      key: const Key('journal-event-edit'),
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(AppStrings.todoEditAction),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        _openForm(day: _dayOfEntry(entry), editing: entry);
                      },
                    ),
                  if (widget.onDeleteEvent != null)
                    ListTile(
                      key: const Key('journal-event-delete'),
                      leading: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        AppStrings.todoDeleteAction,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        widget.onDeleteEvent!(entry);
                      },
                    ),
                  if (widget.onOpenEvent != null)
                    ListTile(
                      key: const Key('journal-event-open'),
                      leading: const Icon(Icons.description_outlined),
                      title: Text(AppStrings.calendarOpenInFile),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        widget.onOpenEvent!(entry);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The day an entry's line heads, for a write that needs one: the
  /// line's own date, else the day the pane speaks for.
  DateTime _dayOfEntry(CalendarEntryEvent entry) =>
      entry.line.date ??
      (widget.large ? _selected : widget.focusDay ?? widget.today);

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
            if (_dayActions(context).isNotEmpty)
              Wrap(spacing: 4, children: _dayActions(context)),
          ],
        ),
      ),
    );
  }

  /// Add event and Add task for the picked day (#730), each only when the
  /// shell gave the way to write it: the buttons never promise a write the
  /// app cannot make.
  List<Widget> _dayActions(BuildContext context) {
    return [
      if (widget.onAddEvent != null)
        TextButton.icon(
          key: const Key('journal-add-event'),
          onPressed: () => _openForm(day: _selected),
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(AppStrings.calendarAddEvent),
        ),
      if (widget.onAddTask != null)
        TextButton.icon(
          key: const Key('journal-add-task'),
          onPressed: () => widget.onAddTask!(_selected),
          icon: const Icon(Icons.check_box_outlined, size: 18),
          label: Text(AppStrings.todoAddTooltip),
        ),
    ];
  }

  /// Opens the Add event form for [day] — or the edit form for [editing]
  /// — inline in the dock, where the calendar is; a sheet on a phone,
  /// where the card is small (#730).
  void _openForm({required DateTime day, CalendarEntryEvent? editing}) {
    if (!widget.large) {
      setState(() {
        _addingEvent = day;
        _editingEvent = editing;
      });
      return;
    }
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheet) => Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.viewInsetsOf(sheet).bottom + 12,
          ),
          child: _eventForm(sheet, day, editing),
        ),
      ),
    );
  }

  /// The form itself, writing when it is told to and closing either way.
  Widget _eventForm(
    BuildContext context,
    DateTime day,
    CalendarEntryEvent? editing,
  ) {
    return CalendarEventForm(
      day: day,
      knownTokens: widget.knownTokens,
      draft: editing == null ? null : _draftOf(editing.event),
      preview: (draft) => _previewLine(day, draft, editing: editing),
      onCancel: () {
        if (widget.large) {
          Navigator.of(context).maybePop();
        } else {
          setState(() {
            _addingEvent = null;
            _editingEvent = null;
          });
        }
      },
      onSave: (draft) {
        if (editing != null) {
          widget.onEditEvent?.call(editing, draft);
        } else {
          widget.onAddEvent?.call(day, draft);
        }
        if (widget.large) {
          Navigator.of(context).maybePop();
        } else {
          setState(() {
            _addingEvent = null;
            _editingEvent = null;
          });
        }
      },
    );
  }

  /// An event as the form fills itself from it: its text, its times and
  /// its reminder.
  CalendarEventDraft _draftOf(CalendarEvent event) {
    final start = event.time?.first;
    final end = event.time?.isRange == true ? event.time?.end : null;
    return CalendarEventDraft(
      text: event.text,
      startMinutes: start?.minutes,
      endMinutes: end?.minutes,
      reminderMinutes: _reminderMinutes(event.reminder),
    );
  }

  /// `HH:MM` as minutes from midnight, or null.
  static int? _reminderMinutes(String? reminder) {
    if (reminder == null) return null;
    final parts = reminder.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  /// The day's line as an added [draft] would leave it, from the file as
  /// the shell last read it: the writer's own answer, so the preview
  /// promises exactly what the write does.
  String _previewLine(
    DateTime day,
    CalendarEventDraft draft, {
    CalendarEntryEvent? editing,
  }) {
    final file =
        widget.calendarFile ??
        const CalendarFileContent(lines: <CalendarRawLine>[]);
    final next = editing == null
        ? addCalendarEvent(file, day, draft: draft)
        : updateCalendarEvent(
                file,
                CalendarEventRef(
                  line: editing.lineIndex,
                  day: day,
                  start: editing.event.start,
                ),
                draft,
              ) ??
              file;
    final body = calendarEventAsText(draft);
    for (final line in next.lines) {
      if (line.text.contains(body)) return line.text;
    }
    return '';
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
