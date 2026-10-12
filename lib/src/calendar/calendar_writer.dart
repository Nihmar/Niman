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
/// moving or deleting the event moves or deletes it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/day_style.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';

/// What Add event asks the file to hold (#730): the text, a time when one
/// was chosen, and the reminder's own clock time.
@immutable
final class CalendarEventDraft {
  /// Creates a draft; [text] is what the event says, without its
  /// terminator.
  const new({
    required this.text,
    this.startMinutes,
    this.endMinutes,
    this.reminderMinutes,
  });

  /// The event's text as typed: its `+`/`@`/`#`/`key:value` tokens
  /// included.
  final String text;

  /// The start, minutes from midnight, or null for an event written with
  /// no time at all.
  final int? startMinutes;

  /// The end, when the event is a range.
  final int? endMinutes;

  /// The reminder's clock time, minutes from midnight: the lead time is
  /// the caller's arithmetic.
  final int? reminderMinutes;
}

/// Where an event is, as the snapshot that showed it measured it (#730):
/// the line, the day it belongs to, and the event's own offset in the
/// line.
///
/// The write re-reads the file before it splices, so all three are
/// checked against what is on disk then: a file that moved under the
/// screen makes the write a no-op rather than an edit of the wrong event.
@immutable
final class CalendarEventRef {
  /// Creates a reference to the event opening at [start] on [day]'s line.
  const new({required this.line, required this.day, required this.start});

  /// The 0-based line index in the file.
  final int line;

  /// The day the line heads (the line's date).
  final DateTime day;

  /// The event's first character in the line.
  final int start;
}

/// [draft] as the line writes it: `15-16 meeting +thesis rem:14:45`,
/// without the terminator that closes it.
String calendarEventAsText(CalendarEventDraft draft) {
  final time = calendarTimeRange(draft.startMinutes, draft.endMinutes);
  final reminder = draft.reminderMinutes;
  return [
    ?time,
    cleanCalendarEventText(draft.text),
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
  final wanted = _dayOf(day);
  final lines = [...file.lines];
  final found = _dayLine(file, wanted);
  if (found != null) {
    final line = lines[found.index];
    lines[found.index] = CalendarRawLine(
      _withEvent(line.text, found.line, body, draft.startMinutes),
      line.ending,
    );
    return _copy(file, lines);
  }
  final head = (style ?? CalendarDayStyle.of(_texts(file))).head(wanted);
  return _insertLine(file, _afterDate(file, wanted), '$head  $body.');
}

/// [file] with the event at [ref] replaced by [draft], or null when the
/// file no longer holds it.
///
/// The event is taken out and written back in time order, so an edited
/// time moves it where the line keeps its events: an edit touches its own
/// line, and nothing else.
CalendarFileContent? updateCalendarEvent(
  CalendarFileContent file,
  CalendarEventRef ref,
  CalendarEventDraft draft,
) {
  final body = calendarEventAsText(draft);
  if (body.isEmpty) {
    throw ArgumentError('an event needs a text or a time');
  }
  final found = _eventAt(file, ref);
  if (found == null) return null;
  final lines = [...file.lines];
  final without = _withoutEvent(lines[found.index].text, found.event);
  final line = parseCalendarLine(without, weekdays: calendarWeekdays);
  lines[found.index] = CalendarRawLine(
    _withEvent(without, line, body, draft.startMinutes),
    lines[found.index].ending,
  );
  return _copy(file, lines);
}

/// [file] with the event at [ref] taken out — its terminator, and the
/// space that separated it, too — or null when the file no longer holds
/// it. A day left with no event keeps its head, the way the spec's own
/// empty days do.
CalendarFileContent? deleteCalendarEvent(
  CalendarFileContent file,
  CalendarEventRef ref,
) {
  final found = _eventAt(file, ref);
  if (found == null) return null;
  final lines = [...file.lines];
  lines[found.index] = CalendarRawLine(
    _withoutEvent(lines[found.index].text, found.event),
    lines[found.index].ending,
  );
  return _copy(file, lines);
}

/// [file]'s lines back, with its BOM and its UTF-8 state as they were.
CalendarFileContent _copy(
  CalendarFileContent file,
  List<CalendarRawLine> lines,
) =>
    CalendarFileContent(lines: lines, bom: file.bom, validUtf8: file.validUtf8);

List<String> _texts(CalendarFileContent file) => [
  for (final line in file.lines) line.text,
];

/// The first day line of [day], with its index, or null.
({int index, CalendarLine line})? _dayLine(
  CalendarFileContent file,
  DateTime day,
) {
  for (var index = 0; index < file.lines.length; index++) {
    final line = parseCalendarLine(
      file.lines[index].text,
      weekdays: calendarWeekdays,
    );
    if (line.kind != CalendarLineKind.day) continue;
    if (sameCalendarDay(line.date, day)) return (index: index, line: line);
  }
  return null;
}

/// The event [ref] names, in the file as it is now, or null.
({int index, CalendarLine line, CalendarEvent event})? _eventAt(
  CalendarFileContent file,
  CalendarEventRef ref,
) {
  if (ref.line < 0 || ref.line >= file.lines.length) return null;
  final line = parseCalendarLine(
    file.lines[ref.line].text,
    weekdays: calendarWeekdays,
  );
  if (line.kind != CalendarLineKind.day) return null;
  if (!sameCalendarDay(line.date, ref.day)) return null;
  for (final event in line.events) {
    if (event.start == ref.start) {
      return (index: ref.line, line: line, event: event);
    }
  }
  return null;
}

/// Where a line for [day] belongs: before the first day line that heads a
/// later date, or at the end.
int _afterDate(CalendarFileContent file, DateTime day) {
  for (var index = 0; index < file.lines.length; index++) {
    final line = parseCalendarLine(
      file.lines[index].text,
      weekdays: calendarWeekdays,
    );
    final date = line.date;
    if (date != null && _dayOf(date).isAfter(day)) return index;
  }
  return file.lines.length;
}

/// [raw] with [body] added in time order: after every event that starts no
/// later than [startMinutes], and at the end for an event with no time.
String _withEvent(
  String raw,
  CalendarLine line,
  String body,
  int? startMinutes,
) {
  final event = '$body.';
  final events = line.events;
  if (events.isEmpty) {
    final head = raw.trimRight();
    return '$head  $event';
  }
  final mine = startMinutes ?? _untimed;
  final at = events.indexWhere(
    (event) => (event.time?.first?.minutes ?? _untimed) > mine,
  );
  if (at < 0) {
    // The line's last event: its own terminator closes it already, when it
    // has one.
    final trimmed = raw.trimRight();
    final closed = trimmed.length > events.last.end;
    return closed ? '$trimmed $event' : '$trimmed. $event';
  }
  final target = events[at];
  return '${raw.substring(0, target.start)}'
      '$event ${raw.substring(target.start)}';
}

/// [raw] without [event]: its characters, the terminator that closed it
/// and the spaces around the gap.
String _withoutEvent(String raw, CalendarEvent event) {
  var from = event.start;
  var to = event.end;
  var at = to;
  while (at < raw.length && raw[at] == ' ') {
    at++;
  }
  final closes =
      at < raw.length &&
      (raw[at] == '.' || raw[at] == ';') &&
      (at + 1 == raw.length || raw[at + 1] == ' ');
  if (closes) {
    at++;
    while (at < raw.length && raw[at] == ' ') {
      at++;
    }
    to = at;
  } else {
    // No terminator after it (a hand-written last event): the space before
    // it goes instead, so the previous event's terminator still ends the
    // line.
    while (from > 0 && raw[from - 1] == ' ') {
      from--;
    }
  }
  return (raw.substring(0, from) + raw.substring(to)).trimRight();
}

/// [file] with [text] as a whole new line at [at], taking the file's own
/// ending; the line that was last gains one when the file ended without
/// it. A file made here ends with a newline, the way the spec's own does.
CalendarFileContent _insertLine(CalendarFileContent file, int at, String text) {
  final lines = [...file.lines];
  if (at >= lines.length) {
    if (lines.isEmpty) {
      lines.add(CalendarRawLine(text, _ending(file)));
    } else if (lines.last.ending.isEmpty) {
      lines[lines.length - 1] = CalendarRawLine(lines.last.text, _ending(file));
      lines.add(CalendarRawLine(text, ''));
    } else {
      lines.add(CalendarRawLine(text, _ending(file)));
    }
  } else {
    if (at > 0 && lines[at - 1].ending.isEmpty) {
      lines[at - 1] = CalendarRawLine(lines[at - 1].text, _ending(file));
    }
    lines.insert(at, CalendarRawLine(text, _ending(file)));
  }
  return _copy(file, lines);
}

/// The ending the file mostly uses (`\n` when it has none to go by).
String _ending(CalendarFileContent file) {
  var crlf = 0;
  var lf = 0;
  for (final line in file.lines) {
    if (line.ending == '\r\n') {
      crlf++;
    } else if (line.ending == '\n') {
      lf++;
    }
  }
  return crlf > 0 && crlf >= lf ? '\r\n' : '\n';
}

DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

String _two(int value) => value.toString().padLeft(2, '0');

/// What an event with no time starts at, for ordering: after every timed
/// one.
const int _untimed = 24 * 60;
