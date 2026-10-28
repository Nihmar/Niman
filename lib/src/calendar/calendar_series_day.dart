/// Keeping a series' day of month through a "this and following" (#1224).
///
/// A monthly or yearly rule has no way to say its day: the k-th occurrence is
/// the *first day* plus k steps, each clamped on its own, so a rule that
/// began on 31 January is on the 30th of April and back on the 31st in May.
/// "This and following" starts the new series at the occurrence, and the
/// occurrence's day becomes the new first day — so splitting at the clamped
/// 30 April would make it the 30th of every month from then on, and a series
/// begun on 29 February would never see one again.
///
/// The token format cannot carry the day apart from the first day, so the
/// new series cannot begin on a day the month does not have. It begins on the
/// first occurrence the old first day's own day falls on (31 May), and the
/// clamped occurrences before it are written as the plain events they would
/// have been: the edited event, once each, the way *This event* writes one.
library;

import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_sequence.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

/// How a series split at a clamped occurrence is written: the occurrences
/// that stand alone, and where the series begins again.
final class CalendarSeriesSplit {
  /// Creates a split.
  const new({required this.alone, required this.anchor});

  /// The days written as plain events, in order: the occurrence the edit
  /// was made on, and the clamped ones after it.
  final List<DateTime> alone;

  /// The first day of the new series, or null when the rule ends before a
  /// day that keeps the original one.
  final DateTime? anchor;
}

/// How far the search for the first unclamped occurrence goes: a monthly
/// rule finds one within a year of steps, a yearly one within the leap gap.
const int _searchSteps = 100;

/// The split of a series of [oldRule] (first day [oldAnchor]) edited from
/// [occurrence] on into [recurrence], or null when the occurrence is on the
/// series' own day and the new series can simply begin on it.
///
/// Only a monthly rule on the date and a yearly one have a day to keep, and
/// only when the edit leaves the rule of the same kind.
CalendarSeriesSplit? calendarSeriesSplit({
  required RecurrenceRule oldRule,
  required DateTime oldAnchor,
  required DateTime occurrence,
  required CalendarRecurrence recurrence,
}) {
  final rule = recurrence.rule;
  if (!_keepsDay(oldRule, rule)) return null;
  final first = dateOnly(occurrence);
  final anchor = dateOnly(oldAnchor);
  if (!_clamped(rule, anchor, first)) return null;
  final alone = <DateTime>[first];
  final until = recurrence.bounds.until;
  var steps = 0;
  for (final day in RecurrenceSequence(rule, anchor).from(first)) {
    if (until != null && day.isAfter(dateOnly(until))) break;
    if (++steps > _searchSteps) break;
    if (day == first || recurrence.bounds.except.contains(day)) continue;
    if (!_clamped(rule, anchor, day)) {
      return CalendarSeriesSplit(alone: alone, anchor: day);
    }
    alone.add(day);
  }
  return CalendarSeriesSplit(alone: alone, anchor: null);
}

/// Whether [oldRule] and [rule] are both the monthly-on-the-date rule, or
/// both the yearly one: the series' day outlives the edit.
bool _keepsDay(RecurrenceRule oldRule, RecurrenceRule rule) {
  if (oldRule.unit != rule.unit) return false;
  return switch (rule.unit) {
    RecurrenceUnit.year => true,
    RecurrenceUnit.month =>
      oldRule.nthWeekday == null && rule.nthWeekday == null,
    _ => false,
  };
}

/// Whether [day], an occurrence of [rule] counted from [anchor], is not on
/// the anchor's own day (of the month, or of the year): the month was too
/// short for it.
bool _clamped(RecurrenceRule rule, DateTime anchor, DateTime day) =>
    rule.unit == RecurrenceUnit.year
    ? day.month != anchor.month || day.day != anchor.day
    : day.day != anchor.day;
