/// What Skip, Edit and Delete write on one occurrence of a repeating event
/// (#1191), as the record decides them (`docs/records/recurring-events.md`,
/// decision 3): made of the rule's `until:` and `except:` and of ordinary
/// events, never of occurrences written out.
///
/// - Skip, or delete this one: the day joins the rule's `except:`.
/// - Edit this one: the day is `except:`ed, and a plain event with the
///   change goes on the target day's line.
/// - Edit this and following: the rule gets `until:` the day before, and a
///   new rule event, changed, goes on the day the form says (the
///   occurrence's own by default).
/// - Delete this and following: the rule gets `until:` the day before (or,
///   from its first day on, the event goes).
/// - Edit or delete all: the rule's event itself, which moves with the day
///   the form says.
///
/// Each is a pure transformation of [CalendarFileContent]: only the lines it
/// must change change, and every other keeps its bytes and its ending. Each
/// answers null when the file no longer holds what the screen showed — the
/// event gone from where it was, or a day the rule does not reach — so a
/// write is a no-op rather than an edit of the wrong thing. An event with no
/// rule is its own and only one: the scope makes no difference to it.
library;

import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_reminder_stamp.dart';
import 'package:niman/src/calendar/calendar_rule_tokens.dart';
import 'package:niman/src/calendar/calendar_series_day.dart';
import 'package:niman/src/calendar/calendar_splice.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/calendar/day_style.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// Which occurrences an Edit or a Delete means.
enum CalendarOccurrenceScope {
  /// This one only.
  thisOne,

  /// This one and every later one.
  thisAndFollowing,

  /// Every occurrence: the rule's own event.
  all,
}

/// [file] with [occurrence] added to the `except:` of the rule event [ref]
/// names, so it does not happen; null when the file no longer holds the
/// event, or the rule does not fall on that day.
CalendarFileContent? skipCalendarOccurrence(
  CalendarFileContent file,
  CalendarEventRef ref,
  DateTime occurrence,
) {
  final found = findCalendarEvent(file, ref);
  if (found == null) return null;
  if (!_occursOn(found.event, ref.day, occurrence)) return null;
  final text = calendarLineWithException(
    file.lines[found.index].text,
    found.event,
    occurrence,
  );
  if (text == null) return null;
  return withCalendarLineText(file, found.index, text);
}

/// [file] with [occurrence] of the event [ref] names deleted as [scope]
/// says; null when the file no longer holds it.
///
/// This and following ends the rule the day before; when that is before
/// the rule's first day nothing of it is left, and the event goes.
CalendarFileContent? deleteCalendarOccurrence(
  CalendarFileContent file,
  CalendarEventRef ref,
  DateTime occurrence,
  CalendarOccurrenceScope scope,
) {
  final found = findCalendarEvent(file, ref);
  if (found == null) return null;
  if (found.event.recurrence == null || scope == CalendarOccurrenceScope.all) {
    return deleteCalendarEvent(file, ref);
  }
  switch (scope) {
    case CalendarOccurrenceScope.thisOne:
      return skipCalendarOccurrence(file, ref, occurrence);
    case CalendarOccurrenceScope.thisAndFollowing:
      if (!_occursOn(found.event, ref.day, occurrence)) return null;
      if (!_isAfter(occurrence, ref.day)) {
        return deleteCalendarEvent(file, ref);
      }
      return _endedBefore(file, found.index, found.event, occurrence);
    case CalendarOccurrenceScope.all:
      return deleteCalendarEvent(file, ref);
  }
}

/// [file] with [occurrence] of the event [ref] names changed to [draft] as
/// [scope] says; null when the file no longer holds it.
///
/// [draft] is what the form held: its recurrence is the new rule, its end
/// and the days it skips, and its day (or [moveTo], when given) the day the
/// user picked (#1225). Whatever the scope, that is the day written:
///
/// - this one: the draft is written as a plain event there, on the
///   occurrence's own day when none was picked;
/// - this and following: the new rule event starts there, on the
///   occurrence's own day when none was picked, and its `except:` loses the
///   days before it — they belong to the rule that ended;
/// - all: the rule event itself moves there, which moves the rule's first
///   day and with it every occurrence.
CalendarFileContent? updateCalendarOccurrence(
  CalendarFileContent file,
  CalendarEventRef ref,
  DateTime occurrence,
  CalendarEventDraft draft,
  CalendarOccurrenceScope scope, {
  DateTime? moveTo,
  CalendarDayStyle? style,
}) {
  final found = findCalendarEvent(file, ref);
  if (found == null) return null;
  final picked = moveTo ?? draft.day;
  if (found.event.recurrence == null || scope == CalendarOccurrenceScope.all) {
    // One event, and its own, or the rule event itself: it may go to
    // another day.
    return updateCalendarEvent(file, ref, draft, moveTo: picked);
  }
  if (!_occursOn(found.event, ref.day, occurrence)) return null;
  switch (scope) {
    case CalendarOccurrenceScope.thisOne:
      final skipped = skipCalendarOccurrence(file, ref, occurrence);
      if (skipped == null) return null;
      final day = picked ?? occurrence;
      return addCalendarEvent(
        skipped,
        day,
        draft: _onDay(draft.withRecurrence(null), found.event, ref.day, day),
        style: style,
      );
    case CalendarOccurrenceScope.thisAndFollowing:
      if (!_isAfter(occurrence, ref.day)) {
        return updateCalendarEvent(file, ref, draft, moveTo: picked);
      }
      final ended = _endedBefore(file, found.index, found.event, occurrence);
      final moved = picked != null && !sameCalendarDay(picked, occurrence);
      final split = moved
          ? null
          : _splitAt(found.event, ref.day, occurrence, draft);
      if (split != null) {
        return _addSplit(ended, split, found.event, ref.day, draft, style);
      }
      final start = moved ? picked : occurrence;
      return addCalendarEvent(
        ended,
        start,
        draft: _fromDay(_onDay(draft, found.event, ref.day, start), start),
        style: style,
      );
    case CalendarOccurrenceScope.all:
      return updateCalendarEvent(file, ref, draft, moveTo: picked);
  }
}

/// [file] with line [index]'s rule event ended the day before [occurrence].
CalendarFileContent _endedBefore(
  CalendarFileContent file,
  int index,
  CalendarEvent event,
  DateTime occurrence,
) {
  final text = calendarLineWithUntil(
    file.lines[index].text,
    event,
    addCalendarDays(dateOnly(occurrence), -1),
  )!;
  return withCalendarLineText(file, index, text);
}

/// How the rule [event] (first day [anchor]) is split at [occurrence] into
/// [draft], when the series has a day of month the occurrence is not on
/// (#1224); null when the new series can begin on the occurrence.
CalendarSeriesSplit? _splitAt(
  CalendarEvent event,
  DateTime anchor,
  DateTime occurrence,
  CalendarEventDraft draft,
) {
  final old = event.recurrence;
  final recurrence = draft.recurrence;
  if (old == null || recurrence == null) return null;
  return calendarSeriesSplit(
    oldRule: old.rule,
    oldAnchor: anchor,
    occurrence: occurrence,
    recurrence: recurrence,
  );
}

/// [file] with [split] written: each day it names alone as a plain event of
/// [draft], then the new series from its anchor.
CalendarFileContent _addSplit(
  CalendarFileContent file,
  CalendarSeriesSplit split,
  CalendarEvent event,
  DateTime anchor,
  CalendarEventDraft draft,
  CalendarDayStyle? style,
) {
  var out = file;
  for (final day in split.alone) {
    out = addCalendarEvent(
      out,
      day,
      draft: _onDay(draft.withRecurrence(null), event, anchor, day),
      style: style,
    );
  }
  final start = split.anchor;
  if (start == null) return out;
  return addCalendarEvent(
    out,
    start,
    draft: _fromDay(_onDay(draft, event, anchor, start), start),
    style: style,
  );
}

/// [draft] for a copy of [event], whose first day is [anchor], written on
/// [day]: a full-stamp reminder keeps its distance from the event (#1226).
CalendarEventDraft _onDay(
  CalendarEventDraft draft,
  CalendarEvent event,
  DateTime anchor,
  DateTime day,
) => calendarDraftOnDay(draft, stamp: event.reminder, from: anchor, to: day);

/// [draft] as the rule event that starts on [day]: the days it skips before
/// [day] are the old rule's, and are dropped.
CalendarEventDraft _fromDay(CalendarEventDraft draft, DateTime day) {
  final recurrence = draft.recurrence;
  if (recurrence == null) return draft;
  final first = dateOnly(day);
  return draft.withRecurrence(
    CalendarRecurrence(
      rule: recurrence.rule,
      bounds: RecurrenceBounds(
        until: recurrence.bounds.until,
        except: {
          for (final date in recurrence.bounds.except)
            if (!date.isBefore(first)) date,
        },
      ),
    ),
  );
}

/// Whether [event], written on [anchor], happens on [day]: its rule reaches
/// the day and neither `until:` nor `except:` cuts it off.
bool _occursOn(CalendarEvent event, DateTime anchor, DateTime day) {
  final recurrence = event.recurrence;
  if (recurrence == null) return false;
  return recurrence
      .occurrences(
        anchor: dateOnly(anchor),
        from: dateOnly(day),
        to: dateOnly(day),
      )
      .isNotEmpty;
}

bool _isAfter(DateTime day, DateTime other) =>
    dateOnly(day).isAfter(dateOnly(other));
