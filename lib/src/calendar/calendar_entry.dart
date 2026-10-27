/// The two shapes a parsed `calendar.txt` is handed around in (#730): a
/// line with its index, and an event with the line it sits on.
///
/// An event of a rule (`rec:`, #1190) is shown on every day the rule falls
/// on, and each of those is a [CalendarEntryEvent] too: the same source
/// event and line — so a tap targets the rule's line — with `shownOn` saying
/// which day it is the occurrence of.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/parser.dart';

/// One parsed line with its 0-based index in the file.
@immutable
final class CalendarEntry {
  /// Creates an entry for [line] at file line [lineIndex].
  const new({required this.lineIndex, required this.line});

  /// The 0-based line index in `calendar.txt`.
  final int lineIndex;

  /// The parsed line.
  final CalendarLine line;

  @override
  String toString() => 'CalendarEntry($lineIndex, $line)';
}

/// One event with the line it sits on: what the journal's Events section
/// shows and what a tap opens the file at.
@immutable
final class CalendarEntryEvent {
  /// Creates an event of [line] at file line [lineIndex], shown on
  /// [shownOn] when it is a rule's occurrence (null: on the line's own
  /// day).
  const new({
    required this.lineIndex,
    required this.line,
    required this.event,
    this.shownOn,
  });

  /// The 0-based line index in `calendar.txt`.
  final int lineIndex;

  /// The line the event sits on.
  final CalendarLine line;

  /// The event itself.
  final CalendarEvent event;

  /// The day this is an occurrence of, when it is shown on a day other
  /// than the line's own (#1190); null for an event on its own day.
  final DateTime? shownOn;

  /// The day it is shown on: the occurrence's, or the line's own. What a
  /// time written in UTC is read against.
  DateTime? get day => shownOn ?? line.date;

  /// The rule the event repeats by, or null for an event that does not.
  CalendarRecurrence? get recurrence => event.recurrence;

  /// Whether the event repeats: the line it is written on carries a
  /// readable `rec:`.
  bool get repeats => recurrence != null;

  /// Whether this is a later copy of a rule's event, not the event on the
  /// day it is written (#1190).
  bool get isLaterOccurrence => !sameCalendarDay(day, line.date);

  /// The minutes the event starts at, for ordering; an event with no time
  /// written comes last.
  int get startMinutes => event.time?.first?.minutes ?? _untimed;

  static const int _untimed = 24 * 60;

  /// Whether the event carries no time at all.
  bool get untimed => event.time?.first == null;

  @override
  String toString() => 'CalendarEntryEvent($lineIndex, $event)';
}
