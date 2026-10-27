/// What can be done with an event of the journal (#730, #1191): Edit, Skip,
/// Delete and Open in calendar.txt — as a context menu on the desktop's dock
/// and as the rows of the phone's event sheet — and, for an event that
/// repeats, the question Edit and Delete ask first: this event, this and
/// following, or all.
///
/// A choice made on a phone is under the thumb and one made with a mouse is a
/// pop-up at the pointer: both are the app's one list of choices
/// ([showActionSheet]), so the three-way question is a sheet on a phone and a
/// small menu on a window, the way every other list of choices is.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_entry.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// One thing to do with an event.
enum JournalEventAction {
  /// Open the form on it.
  edit,

  /// Leave this occurrence out (a repeating event's).
  skip,

  /// Take it out.
  delete,

  /// Go to its line in calendar.txt.
  open,
}

/// Which of the actions a screen can carry out: the shell gives the ways to
/// write, so a screen without one never offers it.
@immutable
final class JournalEventActions {
  /// The actions that are [edit]able, [skip]pable, [delete]able and
  /// [open]able.
  const new({
    this.edit = false,
    this.skip = false,
    this.delete = false,
    this.open = false,
  });

  /// Whether Edit is offered.
  final bool edit;

  /// Whether Skip is offered.
  final bool skip;

  /// Whether Delete is offered.
  final bool delete;

  /// Whether Open in calendar.txt is offered.
  final bool open;

  /// Whether there is anything to offer at all.
  bool get any => edit || skip || delete || open;
}

/// The rows of an event's menu or sheet: each closes it with its action.
///
/// Skip belongs to an event that repeats. For one that does not it stays
/// where it is, off, so the rows do not move with the event shown.
List<Widget> journalEventActionRows(
  BuildContext context, {
  required CalendarEntryEvent entry,
  required JournalEventActions offered,
}) {
  final scheme = Theme.of(context).colorScheme;
  void close(JournalEventAction action) => Navigator.of(context).pop(action);
  return [
    if (offered.edit)
      ListTile(
        key: const Key('journal-event-edit'),
        leading: const Icon(Icons.edit_outlined),
        title: Text(AppStrings.todoEditAction),
        onTap: () => close(JournalEventAction.edit),
      ),
    if (offered.skip)
      ListTile(
        key: const Key('journal-event-skip'),
        enabled: entry.repeats,
        leading: const Icon(Icons.event_busy_outlined),
        title: Text(AppStrings.calendarSkipAction),
        onTap: entry.repeats ? () => close(JournalEventAction.skip) : null,
      ),
    if (offered.delete)
      ListTile(
        key: const Key('journal-event-delete'),
        leading: Icon(Icons.delete_outline, color: scheme.error),
        title: Text(
          AppStrings.todoDeleteAction,
          style: TextStyle(color: scheme.error),
        ),
        onTap: () => close(JournalEventAction.delete),
      ),
    if (offered.open)
      ListTile(
        key: const Key('journal-event-open'),
        leading: const Icon(Icons.description_outlined),
        title: Text(AppStrings.calendarOpenInFile),
        onTap: () => close(JournalEventAction.open),
      ),
  ];
}

/// The desktop's context menu of an event, at [position] (a right click's
/// global one): the action picked, or null when it was dismissed.
Future<JournalEventAction?> showJournalEventMenu(
  BuildContext context, {
  required CalendarEntryEvent entry,
  required JournalEventActions offered,
  required Offset position,
}) {
  return showActionSheet<JournalEventAction>(
    context,
    sheetKey: const Key('journal-event-menu'),
    anchor: menuAnchorAt(position),
    items: (menu) =>
        journalEventActionRows(menu, entry: entry, offered: offered),
  );
}

/// Asks which occurrences an Edit or, when [deleting], a Delete of the
/// repeating event means: the scope picked, or null when it was dismissed.
///
/// An event that does not repeat is not asked: there is one of it, and the
/// answer is [CalendarOccurrenceScope.all].
Future<CalendarOccurrenceScope?> askOccurrenceScope(
  BuildContext context, {
  required CalendarEntryEvent entry,
  required bool deleting,
  Rect? anchor,
}) {
  if (!entry.repeats) return Future.value(CalendarOccurrenceScope.all);
  return showActionSheet<CalendarOccurrenceScope>(
    context,
    sheetKey: const Key('journal-event-scope'),
    anchor: anchor,
    title: deleting
        ? AppStrings.calendarScopeDeleteTitle
        : AppStrings.calendarScopeEditTitle,
    items: (menu) => [
      ListTile(
        key: const Key('journal-event-scope-this'),
        title: Text(AppStrings.calendarScopeThis),
        onTap: () => Navigator.of(menu).pop(CalendarOccurrenceScope.thisOne),
      ),
      ListTile(
        key: const Key('journal-event-scope-following'),
        title: Text(AppStrings.calendarScopeFollowing),
        onTap: () =>
            Navigator.of(menu).pop(CalendarOccurrenceScope.thisAndFollowing),
      ),
      ListTile(
        key: const Key('journal-event-scope-all'),
        title: Text(AppStrings.calendarScopeAll),
        onTap: () => Navigator.of(menu).pop(CalendarOccurrenceScope.all),
      ),
    ],
  );
}
