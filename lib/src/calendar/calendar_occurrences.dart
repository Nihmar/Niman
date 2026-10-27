/// The events of `calendar.txt` on a day, and the days with events in a
/// range, rule events expanded (#1190).
///
/// The file writes one line per day and an event on the line it happens on;
/// an event with a `rec:` happens on every day its rule reaches from the day
/// it is written on. Nothing here writes those days out: they are worked out
/// from the rule when a day or a range is asked for — the visible month, the
/// day on the card — so the cost is the rule events' (few) times the range's
/// days, never the file's.
///
/// The index is built in one pass over the parsed lines, with the snapshot:
/// plain events are bucketed by their day, rule events set apart with their
/// rule read once.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_entry.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// One event with a readable `rec:`: where it is written, and the rule.
@immutable
final class _RuleEvent {
  const new(this.source, this.recurrence, this.anchor);

  /// The event on its own day's line.
  final CalendarEntryEvent source;

  /// What it repeats by.
  final CalendarRecurrence recurrence;

  /// The day it is written on: the first occurrence.
  final DateTime anchor;
}

/// The events of one parsed file, by day, with every rule expanded on
/// demand.
final class CalendarOccurrences {
  new _(this._plain, this._rules);

  /// Indexes [entries] (the file's lines, in order).
  factory of(List<CalendarEntry> entries) {
    final plain = <DateTime, List<CalendarEntryEvent>>{};
    final rules = <_RuleEvent>[];
    for (final entry in entries) {
      final line = entry.line;
      if (line.kind != CalendarLineKind.day) continue;
      final date = line.date;
      if (date == null) continue;
      final day = dateOnly(date);
      for (final event in line.events) {
        final source = CalendarEntryEvent(
          lineIndex: entry.lineIndex,
          line: line,
          event: event,
        );
        final recurrence = event.recurrence;
        if (recurrence == null) {
          plain.putIfAbsent(day, () => []).add(source);
        } else {
          rules.add(_RuleEvent(source, recurrence, day));
        }
      }
    }
    return CalendarOccurrences._(plain, rules);
  }

  final Map<DateTime, List<CalendarEntryEvent>> _plain;
  final List<_RuleEvent> _rules;

  /// The days the file writes an event on, a rule event's own day included
  /// whether or not its rule keeps it.
  Set<DateTime> get writtenDays => {
    ..._plain.keys,
    for (final rule in _rules) rule.anchor,
  };

  /// Whether any event of the file repeats.
  bool get hasRules => _rules.isNotEmpty;

  /// Every event on [date], in time order — an event with no time written
  /// last, in the order the file writes them.
  List<CalendarEntryEvent> eventsOn(DateTime date) {
    final day = dateOnly(date);
    final events = <CalendarEntryEvent>[...?_plain[day]];
    for (final rule in _rules) {
      if (day.isBefore(rule.anchor)) continue;
      final hit = rule.recurrence.occurrences(
        anchor: rule.anchor,
        from: day,
        to: day,
      );
      if (hit.isEmpty) continue;
      events.add(_shown(rule, day));
    }
    events.sort(_byTime);
    return events;
  }

  /// The days from [from] to [to] (inclusive) with at least one event.
  Set<DateTime> daysIn(DateTime from, DateTime to) {
    final first = dateOnly(from);
    final last = dateOnly(to);
    final days = <DateTime>{};
    for (var day = first; !day.isAfter(last); day = _nextDay(day)) {
      if (_plain.containsKey(day)) days.add(day);
    }
    for (final rule in _rules) {
      if (last.isBefore(rule.anchor)) continue;
      days.addAll(
        rule.recurrence.occurrences(anchor: rule.anchor, from: first, to: last),
      );
    }
    return days;
  }

  /// [rule]'s event as the occurrence of [day]: the event itself on the day
  /// it is written on.
  CalendarEntryEvent _shown(_RuleEvent rule, DateTime day) {
    if (day == rule.anchor) return rule.source;
    final source = rule.source;
    return CalendarEntryEvent(
      lineIndex: source.lineIndex,
      line: source.line,
      event: source.event,
      shownOn: day,
    );
  }
}

DateTime _nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

/// Time order; the file's own order decides between two at the same time
/// (or with none at all), so the list never jumps between two builds.
int _byTime(CalendarEntryEvent a, CalendarEntryEvent b) {
  final order = a.startMinutes.compareTo(b.startMinutes);
  if (order != 0) return order;
  final line = a.lineIndex.compareTo(b.lineIndex);
  if (line != 0) return line;
  return a.event.start.compareTo(b.event.start);
}
