/// The reminders of `calendar.txt`'s events (#730, #1192): the half of the
/// wanted set that comes from the calendar.
///
/// An event's `rem:` is a clock time on the day its line heads
/// (`17-18 jogging @park rem:16:30.`), or a full stamp
/// (`rem:2026-10-12T16:30`) that names its own day. An event with a `rec:`
/// repeats, and so does its reminder — but an OS keeps a bounded number of
/// alarms (Android 500 per app, iOS 64), and a rule is endless. So a repeating
/// event does not schedule the series: it schedules the occurrences of the
/// next [recurringReminderHorizonDays] days, at most
/// [recurringRemindersPerRule] of them, and every reconciliation works that
/// window out again from the clock — which is what moves it forward while the
/// file is left alone.
library;

import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_reminder.dart';
import 'package:niman/src/ui/strings.dart';

/// How many days ahead a repeating event's reminders are scheduled, today
/// included.
const int recurringReminderHorizonDays = 14;

/// The most reminders one repeating event keeps scheduled: its soonest.
const int recurringRemindersPerRule = 4;

/// The schedulable reminders of the calendar: every event of [snapshot]
/// whose line carries a readable `rem:`. A `Z` in the event's own time never
/// moves it — the reminder is the clock time that was written next to it.
///
/// An event with no rule fires on its own day. An event with a rule fires on
/// the occurrences that fall in the next [recurringReminderHorizonDays] days
/// from today, the soonest [recurringRemindersPerRule] of them, each with an
/// id of its own ([calendarOccurrenceReminderId]); one the rule skips
/// (`except:`) or has ended before (`until:`) is not among them. A clock
/// `rem:` is that time on each occurrence's day; a full one keeps its
/// distance in calendar days from the first day, so a reminder written the day
/// before stays the day before every time.
///
/// A missing snapshot is no calendar file, and nothing wanted from it.
Map<int, TodoReminder> calendarWantedReminders(
  CalendarSnapshot? snapshot,
  DateTime now, {
  bool showTokens = false,
}) {
  final wanted = <int, TodoReminder>{};
  if (snapshot == null) return wanted;
  final earliest = now.subtract(reminderGrace);
  for (final entry in snapshot.entries) {
    final line = entry.line;
    final date = line.date;
    if (date == null || line.kind != CalendarLineKind.day) continue;
    final anchor = dateOnly(date);
    for (final event in line.events) {
      final time = _readReminder(event.reminder);
      if (time == null) continue;
      final recurrence = event.recurrence;
      final identity = recurrence == null
          ? event.text
          : _withoutRuleBounds(event.text);
      final days = recurrence == null
          ? [anchor]
          : _horizonDays(recurrence, anchor, time, now);
      // The same two readings a task's title gets: the managed `rem:` (and
      // any other `key:value`) is never shown, the `+`/`@`/`#` markers are
      // the user's call.
      final title = showTokens
          ? withoutKeyValueTags(event.text)
          : taskDisplayText(event.text);
      var kept = 0;
      for (final day in days) {
        final when = time.on(day, anchor);
        if (when.isBefore(earliest)) continue;
        if (recurrence != null && kept == recurringRemindersPerRule) break;
        kept++;
        final id = calendarOccurrenceReminderId(anchor, day, identity);
        wanted[id] = TodoReminder(
          id: id,
          title: title.isEmpty ? AppStrings.todoReminderFallbackTitle : title,
          body: _eventReminderBody(day, event),
          when: when,
          payload: journalReminderPayload(day),
        );
      }
    }
  }
  return wanted;
}

/// The days [recurrence] falls on that can still hold a reminder: from today
/// — earlier, when the reminder is written later than its occurrence — to the
/// end of the horizon, in order.
List<DateTime> _horizonDays(
  CalendarRecurrence recurrence,
  DateTime anchor,
  _ReminderTime time,
  DateTime now,
) {
  final today = dateOnly(now);
  final stamp = time.date;
  final after = stamp == null ? 0 : daysBetween(anchor, stamp);
  return recurrence.occurrences(
    anchor: anchor,
    from: addCalendarDays(today, after > 0 ? -after : 0),
    to: addCalendarDays(today, recurringReminderHorizonDays - 1),
  );
}

/// [text] without its `until:` and `except:` words.
///
/// The text an occurrence's id comes from: skipping a day or ending the
/// series writes one of them, and the alarms of the days that remain must not
/// change id for it — only the skipped one leaves the set.
String _withoutRuleBounds(String text) =>
    text.replaceAll(RegExp(r'(^|\s+)(until|except):\S*'), '').trim();

/// The day the event sits on, and the time it says, as one line — what a
/// notification reads under the event's own text.
String _eventReminderBody(DateTime day, CalendarEvent event) {
  final label = formatDateTime(day, 'ddd D MMM');
  final time = event.time?.raw;
  return time == null || time.isEmpty ? label : '$label · $time';
}

/// A `rem:` value read: a clock time, with or without the day it names.
final class _ReminderTime {
  const new(this.moment, this.date);

  /// The clock time (a `Z` is the instant it names, not a clock time).
  final CalendarMoment moment;

  /// The day a full stamp names, or null for a bare clock time.
  final DateTime? date;

  /// When the reminder of the occurrence on [day] fires, the event being
  /// first on [anchor]: the clock on [day], or — for a stamp — on the day as
  /// far from [day] as the stamp's own is from [anchor].
  DateTime on(DateTime day, DateTime anchor) {
    final stamp = date;
    final at = stamp == null
        ? day
        : addCalendarDays(day, daysBetween(anchor, stamp));
    if (!moment.utc) {
      return DateTime(at.year, at.month, at.day, moment.hour, moment.minute);
    }
    return DateTime.utc(
      at.year,
      at.month,
      at.day,
      moment.hour,
      moment.minute,
    ).toLocal();
  }
}

/// The stamp form of a `rem:`: a date, `T`, and a time.
final RegExp _stamp = RegExp(r'^(\d{4}-\d{2}-\d{2})T(.+)$');

/// A `rem:` value as a [_ReminderTime], or null when it is not a time at
/// all. The format's own readings of a clock are accepted (`0530`, `5:30`,
/// `5`), and so is a full `YYYY-MM-DDTHH:MM`.
_ReminderTime? _readReminder(String? reminder) {
  if (reminder == null) return null;
  final match = _stamp.firstMatch(reminder);
  if (match == null) {
    final moment = parseCalendarMoment(reminder);
    return moment == null ? null : _ReminderTime(moment, null);
  }
  final date = parseIsoDate(match.group(1)!);
  final moment = parseCalendarMoment(match.group(2)!);
  if (date == null || moment == null) return null;
  return _ReminderTime(moment, date);
}
