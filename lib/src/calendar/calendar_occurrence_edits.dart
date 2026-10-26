/// What Skip, Edit and Delete write on one occurrence of a repeating event
/// (#1191), as the record decides them (`docs/records/recurring-events.md`,
/// decision 3): made of the rule's `until:` and `except:` and of ordinary
/// events, never of occurrences written out.
///
/// - Skip, or delete this one: the day joins the rule's `except:`.
/// - Edit this one: the day is `except:`ed, and a plain event with the
///   change goes on the target day's line.
/// - Edit this and following: the rule gets `until:` the day before, and a
///   new rule event, changed, goes on the occurrence's day line.
/// - Delete this and following: the rule gets `until:` the day before (or,
///   from its first day on, the event goes).
/// - Edit or delete all: the rule's event itself.
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
import 'package:niman/src/calendar/calendar_rule_tokens.dart';
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
/// and the days it skips. For this one only the draft is written as a plain
/// event, on [moveTo] when given and on the occurrence's own day otherwise.
/// For this and following the draft's `except:` loses the days before the
/// occurrence — they belong to the rule that ended — and the new rule event
/// goes on the occurrence's day line.
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
  if (found.event.recurrence == null || scope == CalendarOccurrenceScope.all) {
    return updateCalendarEvent(file, ref, draft);
  }
  if (!_occursOn(found.event, ref.day, occurrence)) return null;
  switch (scope) {
    case CalendarOccurrenceScope.thisOne:
      final skipped = skipCalendarOccurrence(file, ref, occurrence);
      if (skipped == null) return null;
      return addCalendarEvent(
        skipped,
        moveTo ?? occurrence,
        draft: draft.withRecurrence(null),
        style: style,
      );
    case CalendarOccurrenceScope.thisAndFollowing:
      if (!_isAfter(occurrence, ref.day)) {
        return updateCalendarEvent(file, ref, draft);
      }
      final ended = _endedBefore(file, found.index, found.event, occurrence);
      return addCalendarEvent(
        ended,
        occurrence,
        draft: _fromDay(draft, occurrence),
        style: style,
      );
    case CalendarOccurrenceScope.all:
      return updateCalendarEvent(file, ref, draft);
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
