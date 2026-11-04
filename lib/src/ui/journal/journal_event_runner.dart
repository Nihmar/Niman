/// What the journal browser does with one of its events (#730, #1191):
/// the phone's sheet, the dock's menu, and the action either one picks.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/journal/journal_event_actions.dart';
import 'package:niman/src/ui/journal/journal_event_sheet.dart';

/// Offers an event's actions and carries out the one picked.
final class JournalEventRunner {
  /// A runner offering [offered], writing through the callbacks.
  ///
  /// [paneDay] is the day the pane speaks for, read when an action needs
  /// it; [onEdit] opens the edit form on a day for the occurrences a
  /// scope names (null when the event does not repeat).
  const new({
    required this.offered,
    required this.paneDay,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onOpen,
  });

  /// The actions this browser can carry out: the shell gives the ways to
  /// write, and a button never promises one it has not.
  final JournalEventActions offered;

  /// The day the pane speaks for: the picked day on a phone, else the
  /// dock's focus day.
  final DateTime Function() paneDay;

  /// Opens the edit form for an entry on a day, for a scope.
  final void Function(
    DateTime day,
    CalendarEntryEvent entry,
    CalendarOccurrenceScope? scope,
  )
  onEdit;

  /// Leaves the occurrence an entry shows out of its rule (#1191).
  final void Function(CalendarEntryEvent entry) onSkip;

  /// Takes an entry's event out of the file, for a scope (#1191).
  final void Function(CalendarEntryEvent entry, CalendarOccurrenceScope scope)
  onDelete;

  /// Opens the event's line in `calendar.txt` (#730).
  final void Function(CalendarEntryEvent entry) onOpen;

  /// The phone's sheet for one event (#730): what it is, its day, its rule
  /// and its reminder, and what to do with it.
  Future<void> showSheet(BuildContext context, CalendarEntryEvent entry) async {
    final action = await showJournalEventSheet(
      context,
      entry: entry,
      offered: offered,
    );
    if (action == null || !context.mounted) return;
    await run(context, action, entry);
  }

  /// The dock's context menu of an event, at a right click (#1191).
  Future<void> showMenu(
    BuildContext context,
    CalendarEntryEvent entry,
    Offset position,
  ) async {
    if (!offered.any) return;
    final action = await showJournalEventMenu(
      context,
      entry: entry,
      offered: offered,
      position: position,
    );
    if (action == null || !context.mounted) return;
    await run(context, action, entry, anchor: menuAnchorAt(position));
  }

  /// Carries out [action] on [entry]. Edit and Delete of an event that
  /// repeats first ask which occurrences they mean (#1191); [anchor] is
  /// where a window's question opens.
  Future<void> run(
    BuildContext context,
    JournalEventAction action,
    CalendarEntryEvent entry, {
    Rect? anchor,
  }) async {
    switch (action) {
      case JournalEventAction.edit:
        final scope = await askOccurrenceScope(
          context,
          entry: entry,
          deleting: false,
          anchor: anchor,
        );
        if (scope == null || !context.mounted) return;
        // An event that does not repeat has no scope: its form moves it.
        final scoped = entry.repeats ? scope : null;
        onEdit(formDayOf(entry, scoped), entry, scoped);
      case JournalEventAction.skip:
        onSkip(entry);
      case JournalEventAction.delete:
        final scope = await askOccurrenceScope(
          context,
          entry: entry,
          deleting: true,
          anchor: anchor,
        );
        if (scope == null || !context.mounted) return;
        onDelete(entry, scope);
      case JournalEventAction.open:
        onOpen(entry);
    }
  }

  /// The day an entry is the event of, for a write that needs one: the
  /// occurrence's own day (#1191), else the day the pane speaks for.
  DateTime dayOfEntry(CalendarEntryEvent entry) => entry.day ?? paneDay();

  /// The day an edit's form opens on (#1221): the day the form writes the
  /// event on, which its Ends row counts from and its Repeat presets are
  /// taken from. For all the events of a series it is the series' first day,
  /// where the rule event is written; for the rest the occurrence's own — the
  /// one that is changed, or the one the new series starts on.
  DateTime formDayOf(
    CalendarEntryEvent entry,
    CalendarOccurrenceScope? scope,
  ) => scope == CalendarOccurrenceScope.all
      ? entry.line.date ?? dayOfEntry(entry)
      : dayOfEntry(entry);
}
