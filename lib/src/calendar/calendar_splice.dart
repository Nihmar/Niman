/// The line-level splices the writers of `calendar.txt` are built from
/// (#730, #1191): find an event in the file as it is now, put one into a
/// day's line in time order, take one out, make a line.
///
/// Every function works on [CalendarFileContent] — the lines with their own
/// endings — and hands back a file in which only the line it was asked to
/// touch has changed: the rest comes back byte for byte. Nothing here reads
/// or writes disk.
library;

import 'package:niman/src/calendar/calendar_event_draft.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';

/// [file]'s lines replaced by [lines], with its BOM and its UTF-8 state as
/// they were.
CalendarFileContent copyCalendarFile(
  CalendarFileContent file,
  List<CalendarRawLine> lines,
) =>
    CalendarFileContent(lines: lines, bom: file.bom, validUtf8: file.validUtf8);

/// [file] with line [index]'s text replaced by [text], its ending kept.
CalendarFileContent withCalendarLineText(
  CalendarFileContent file,
  int index,
  String text,
) {
  final lines = [...file.lines];
  lines[index] = CalendarRawLine(text, lines[index].ending);
  return copyCalendarFile(file, lines);
}

/// The text of every line of [file].
List<String> calendarLineTexts(CalendarFileContent file) => [
  for (final line in file.lines) line.text,
];

/// The first day line of [day], with its index, or null.
({int index, CalendarLine line})? findCalendarDayLine(
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
({int index, CalendarLine line, CalendarEvent event})? findCalendarEvent(
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
int calendarLineIndexFor(CalendarFileContent file, DateTime day) {
  for (var index = 0; index < file.lines.length; index++) {
    final line = parseCalendarLine(
      file.lines[index].text,
      weekdays: calendarWeekdays,
    );
    final date = line.date;
    if (date != null && calendarDayOf(date).isAfter(day)) return index;
  }
  return file.lines.length;
}

/// [raw] with [body] added in time order: after every event that starts no
/// later than [startMinutes], and at the end for an event with no time.
String withCalendarEventIn(
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
String withoutCalendarEventIn(String raw, CalendarEvent event) {
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
CalendarFileContent insertCalendarLine(
  CalendarFileContent file,
  int at,
  String text,
) {
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
  return copyCalendarFile(file, lines);
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

/// [date] at local midnight.
DateTime calendarDayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// What an event with no time starts at, for ordering: after every timed
/// one.
const int _untimed = 24 * 60;
