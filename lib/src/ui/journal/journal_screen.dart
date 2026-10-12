/// The phone's Journal screen (#7, mockup 5): the month, the day picked
/// in a card that opens its entry or makes one, and the latest entries.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/strings.dart';

/// The screen, pushed over the shell.
final class JournalScreen extends StatelessWidget {
  /// The screen over the journal; its fields are [JournalBrowser]'s.
  const new({
    required this.today,
    required this.entryDays,
    required this.readEntry,
    required this.onOpenDay,
    this.revision = 0,
    this.eventsOn,
    this.goalsOn,
    this.eventDays = const <DateTime>{},
    this.calendarChanged,
    this.onOpenEvent,
    this.dueOn,
    this.tasksChanged,
    this.onOpenTasks,
    this.knownTokens = const <String>{},
    this.eventTimesClock = false,
    this.calendarFile,
    this.onAddEvent,
    this.onAddTask,
    this.onEditEvent,
    this.onDeleteEvent,
    super.key,
  });

  /// See [JournalBrowser.eventsOn].
  final List<CalendarEntryEvent> Function(DateTime day)? eventsOn;

  /// See [JournalBrowser.goalsOn].
  final List<CalendarLine> Function(DateTime day)? goalsOn;

  /// See [JournalBrowser.eventDays].
  final Set<DateTime> eventDays;

  /// See [JournalBrowser.calendarChanged].
  final Listenable? calendarChanged;

  /// See [JournalBrowser.onOpenEvent].
  final void Function(CalendarEntryEvent event)? onOpenEvent;

  /// See [JournalBrowser.dueOn].
  final List<String> Function(DateTime day)? dueOn;

  /// See [JournalBrowser.tasksChanged].
  final Listenable? tasksChanged;

  /// See [JournalBrowser.onOpenTasks].
  final VoidCallback? onOpenTasks;

  /// See [JournalBrowser.knownTokens].
  final Set<String> knownTokens;

  /// See [JournalBrowser.eventTimesClock].
  final bool eventTimesClock;

  /// See [JournalBrowser.calendarFile].
  final CalendarFileContent? calendarFile;

  /// See [JournalBrowser.onAddEvent].
  final void Function(DateTime day, CalendarEventDraft event)? onAddEvent;

  /// See [JournalBrowser.onAddTask].
  final void Function(DateTime day)? onAddTask;

  /// See [JournalBrowser.onEditEvent].
  final void Function(CalendarEntryEvent entry, CalendarEventDraft event)?
  onEditEvent;

  /// See [JournalBrowser.onDeleteEvent].
  final void Function(CalendarEntryEvent entry)? onDeleteEvent;

  /// See [JournalBrowser.today].
  final DateTime today;

  /// See [JournalBrowser.entryDays].
  final Future<List<DateTime>?> Function() entryDays;

  /// See [JournalBrowser.readEntry].
  final Future<String> Function(DateTime day) readEntry;

  /// See [JournalBrowser.onOpenDay].
  final void Function(DateTime day, {bool confirmed}) onOpenDay;

  /// See [JournalBrowser.revision].
  final int revision;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('journal-screen'),
      appBar: AppBar(title: Text(AppStrings.paletteGroupJournal)),
      body: JournalBrowser(
        today: today,
        entryDays: entryDays,
        readEntry: readEntry,
        onOpenDay: onOpenDay,
        revision: revision,
        large: true,
        eventsOn: eventsOn,
        goalsOn: goalsOn,
        eventDays: eventDays,
        calendarChanged: calendarChanged,
        onOpenEvent: onOpenEvent,
        dueOn: dueOn,
        tasksChanged: tasksChanged,
        onOpenTasks: onOpenTasks,
        knownTokens: knownTokens,
        eventTimesClock: eventTimesClock,
        calendarFile: calendarFile,
        onAddEvent: onAddEvent,
        onAddTask: onAddTask,
        onEditEvent: onEditEvent,
        onDeleteEvent: onDeleteEvent,
      ),
    );
  }
}
