/// The journal at a glance (#7): a month with its entries dotted, a way
/// back to today, the day picked, the open tasks due on it (from
/// `todo.txt`), and the latest entries with their first words. The
/// desktop's dock pane and the phone's Journal screen are this, in two
/// sizes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
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
    this.dueOn,
    this.tasksChanged,
    this.onOpenTasks,
    this.focusDay,
    super.key,
  });

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
    } else {
      widget.onOpenDay(day);
    }
  }

  void _toToday() {
    setState(() {
      _month = DateTime(widget.today.year, widget.today.month);
      _selected = widget.today;
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
          today: widget.today,
          selected: widget.large ? _selected : null,
          cell: widget.large ? 44 : 34,
          onDay: _tap,
          onMonth: (month) => setState(() => _month = month),
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
        ],
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
            ListTile(
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
              onTap: () => widget.onOpenDay(day),
            ),
        ],
      ],
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
