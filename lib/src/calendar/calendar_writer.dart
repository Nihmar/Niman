/// Writing `calendar.txt` (#730): a new event, an edit, a delete.
///
/// A write is a splice into the parsed file ([CalendarFileContent], the
/// lines with their own endings), so every line not touched comes back
/// byte for byte — its ending included — and the line that is touched is
/// rebuilt around the event alone. Nothing here reads or writes disk: the
/// store hands the bytes in and writes the bytes out.
///
/// The format's own shape is kept: events are separated by `. ` and the
/// line's last one is closed by a `.`; a new event goes in time order, an
/// event with no time after the timed ones; a day with no line yet gets
/// one, headed the way the file heads its days ([CalendarDayStyle]), in
/// date order. A reminder rides on its event's line (`rem:HH:MM`), so
/// moving or deleting the event moves or deletes it, and so does a rule
/// (`rec:`, `until:`, `except:`, #1191).
///
/// What an action on one occurrence of a repeating event writes is
/// `calendar_occurrence_edits.dart`'s; the pieces it and this file share
/// are `calendar_splice.dart`'s.
library;

import 'package:niman/src/calendar/calendar_event_draft.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_reminder_stamp.dart';
import 'package:niman/src/calendar/calendar_rule_tokens.dart';
import 'package:niman/src/calendar/calendar_splice.dart';
import 'package:niman/src/calendar/day_style.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';

export 'package:niman/src/calendar/calendar_event_draft.dart';

/// [draft] as the line writes it: `15-16 meeting +thesis rec:1w rem:14:45`,
/// without the terminator that closes it.
String calendarEventAsText(CalendarEventDraft draft) {
  final time = calendarTimeRange(draft.startMinutes, draft.endMinutes);
  final reminder = draft.reminderMinutes;
  final recurrence = draft.recurrence;
  return [
    ?time,
    // A draft that carries a rule is the only one that writes it: any
    // `rec:`, `until:` or `except:` left in its text would be read first.
    cleanCalendarEventText(
      recurrence == null
          ? draft.text
          : calendarTextWithoutRuleTokens(draft.text),
    ),
    if (recurrence != null) ...[
      'rec:${recurrence.rule.token}',
      ?recurrence.bounds.untilToken,
      ?recurrence.bounds.exceptToken,
    ],
    if (reminder != null) 'rem:${calendarClockStamp(reminder)}',
  ].where((part) => part.isNotEmpty).join(' ');
}

/// A time range as the file writes it: `15-16` when both ends are whole
/// hours, `13:30-14` otherwise, and `15` alone for an event with no end.
String? calendarTimeRange(int? start, int? end) {
  if (start == null) return null;
  final from = calendarClockCompact(start);
  return end == null ? from : '$from-${calendarClockCompact(end)}';
}

/// A time as a line writes it: `15` for a whole hour, `13:30` otherwise.
String calendarClockCompact(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return minute == 0 ? '$hour' : '$hour:${_two(minute)}';
}

/// A clock time as a `rem:` writes it: `13:30`, `08:45`.
String calendarClockStamp(int minutes) =>
    '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

/// [text] as a line holds it: trimmed, and without the `.`/`;` that would
/// close the event early — what the writer adds back is the terminator
/// itself.
String cleanCalendarEventText(String text) {
  var out = text.trim();
  while (out.endsWith('.') || out.endsWith(';')) {
    out = out.substring(0, out.length - 1).trimRight();
  }
  return out;
}

/// [file] with [draft] added to [day]: into the day's own line, in time
/// order, or into a line made for it — and a file made for it, when there
/// is none.
CalendarFileContent addCalendarEvent(
  CalendarFileContent file,
  DateTime day, {
  required CalendarEventDraft draft,
  CalendarDayStyle? style,
}) {
  final body = calendarEventAsText(draft);
  if (body.isEmpty) {
    throw ArgumentError('an event needs a text or a time');
  }
  final wanted = calendarDayOf(day);
  final lines = [...file.lines];
  final found = findCalendarDayLine(file, wanted);
  if (found != null) {
    final line = lines[found.index];
    lines[found.index] = CalendarRawLine(
      withCalendarEventIn(line.text, found.line, body, draft.startMinutes),
      line.ending,
    );
    return copyCalendarFile(file, lines);
  }
  final head = (style ?? CalendarDayStyle.of(calendarLineTexts(file))).head(
    wanted,
  );
  return insertCalendarLine(
    file,
    calendarLineIndexFor(file, wanted),
    '$head  $body.',
  );
}

/// [file] with the event at [ref] replaced by [draft], or null when the
/// file no longer holds it.
///
/// The event is taken out and written back in time order, so an edited
/// time moves it where the line keeps its events: an edit touches its own
/// line, and nothing else. With [moveTo] a day other than the event's own,
/// the event leaves its line and is written on that day's, made when it is
/// missing (#1191): two lines change, and no other.
CalendarFileContent? updateCalendarEvent(
  CalendarFileContent file,
  CalendarEventRef ref,
  CalendarEventDraft draft, {
  DateTime? moveTo,
}) {
  final body = calendarEventAsText(draft);
  if (body.isEmpty) {
    throw ArgumentError('an event needs a text or a time');
  }
  final found = findCalendarEvent(file, ref);
  if (found == null) return null;
  if (moveTo != null && !sameCalendarDay(moveTo, ref.day)) {
    final removed = deleteCalendarEvent(file, ref);
    if (removed == null) return null;
    return addCalendarEvent(
      removed,
      moveTo,
      draft: calendarDraftOnDay(
        draft,
        stamp: found.event.reminder,
        from: ref.day,
        to: moveTo,
      ),
    );
  }
  final lines = [...file.lines];
  final without = withoutCalendarEventIn(lines[found.index].text, found.event);
  final line = parseCalendarLine(without, weekdays: calendarWeekdays);
  lines[found.index] = CalendarRawLine(
    withCalendarEventIn(without, line, body, draft.startMinutes),
    lines[found.index].ending,
  );
  return copyCalendarFile(file, lines);
}

/// [file] with the event at [ref] taken out — its terminator, and the
/// space that separated it, too — or null when the file no longer holds
/// it. A day left with no event keeps its head, the way the spec's own
/// empty days do.
CalendarFileContent? deleteCalendarEvent(
  CalendarFileContent file,
  CalendarEventRef ref,
) {
  final found = findCalendarEvent(file, ref);
  if (found == null) return null;
  final lines = [...file.lines];
  lines[found.index] = CalendarRawLine(
    withoutCalendarEventIn(lines[found.index].text, found.event),
    lines[found.index].ending,
  );
  return copyCalendarFile(file, lines);
}

String _two(int value) => value.toString().padLeft(2, '0');
