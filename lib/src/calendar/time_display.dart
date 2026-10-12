/// An event's time as the app shows it (#730): as the file writes it
/// (`9-12`, `0600Z`), or as a clock — `09:00–12:00`, in the device's own
/// zone, so a `0600Z` call reads as the hour the phone is in.
///
/// Nothing here touches the file: the setting is a way of reading a line,
/// never a way of writing one.
library;

import 'package:niman/src/calendar/parser.dart';

/// [time] as the journal shows it.
///
/// [asClock] false answers exactly what the line says. True answers the
/// clock time: zero-padded 24-hour, a range with an en dash, and a `Z`
/// moment turned into the device's zone — [day] is the day the line heads,
/// which a `Z` time needs to land on the right instant (`2300Z` on one day
/// is the next day east of Greenwich).
String calendarTimeText(
  CalendarEventTime? time, {
  required bool asClock,
  DateTime? day,
  DateTime? now,
}) {
  if (time == null) return '';
  if (!asClock) return time.raw;
  final start = time.start;
  final end = time.end;
  if (start == null && end != null) return '–${_clock(end, day, now)}';
  if (start != null && end == null) return _clock(start, day, now);
  if (start == null || end == null) return time.raw;
  return '${_clock(start, day, now)}–${_clock(end, day, now)}';
}

/// One moment as `HH:MM` in the device's zone.
String _clock(CalendarMoment moment, DateTime? day, DateTime? now) {
  if (!moment.utc) {
    return '${_two(moment.hour)}:${_two(moment.minute)}';
  }
  final on = day ?? now ?? DateTime.now();
  final utc = DateTime.utc(
    on.year,
    on.month,
    on.day,
    moment.hour,
    moment.minute,
  );
  final local = utc.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
