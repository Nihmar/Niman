/// The dates a rule falls on, counted from an anchor, generated lazily.
library;

import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

/// The series of a [RecurrenceRule] from its [anchor]: the k-th date is the
/// anchor plus k steps of the rule, worked out from the anchor each time and
/// clamped on its own, so nothing drifts (the semantics of an event).
///
/// [from] starts the series near a date by arithmetic, however long ago the
/// anchor is, so a month of a ten-year-old event costs a month of work.
final class RecurrenceSequence {
  /// The series of [rule] from [anchor] (its time of day is ignored).
  new(this.rule, DateTime anchor) : anchor = dateOnly(anchor);

  /// The rule the series follows.
  final RecurrenceRule rule;

  /// The first day of the series, date-only.
  final DateTime anchor;

  /// Whether the anchor is itself one of the dates [from] yields: always
  /// for a plain step, and for a weekday list or an Nth weekday only when
  /// the anchor is on one. When it is not, the anchor still begins the
  /// series, but [from] does not yield it.
  bool get anchorFollowsRule {
    if (rule.weekdays.isNotEmpty) {
      return rule.weekdays.contains(anchor.weekday);
    }
    final nth = rule.nthWeekday;
    if (nth != null) return nth.matches(anchor);
    return true;
  }

  /// The dates of the series on or after [start], in ascending order and
  /// without end: take them while they are in range. A weekday list or an
  /// Nth weekday that the anchor does not fall on leaves the anchor out
  /// (see [anchorFollowsRule]) and yields only the dates after it.
  Iterable<DateTime> from(DateTime start) {
    final first = dateOnly(start);
    if (rule.unit == RecurrenceUnit.week && rule.weekdays.isNotEmpty) {
      return _weekdayDates(first);
    }
    if (rule.unit == RecurrenceUnit.month && rule.nthWeekday != null) {
      return _nthWeekdayDates(first);
    }
    return _steppedDates(first);
  }

  /// The k-th date of a plain rule, k = 0 being the anchor.
  DateTime _dateAt(int k) {
    final n = rule.interval * k;
    switch (rule.unit) {
      case RecurrenceUnit.day:
        return addCalendarDays(anchor, n);
      case RecurrenceUnit.week:
        return addCalendarDays(anchor, 7 * n);
      case RecurrenceUnit.month:
        return addMonthsClamped(anchor, n);
      case RecurrenceUnit.year:
        return addMonthsClamped(anchor, 12 * n);
      case RecurrenceUnit.businessDay:
        return addBusinessDays(anchor, n);
    }
  }

  /// An index whose date is on or before [start], so no date on or after
  /// it is skipped, and not far from it.
  int _startIndex(DateTime start) {
    final days = daysBetween(anchor, start);
    if (days <= 0) return 0;
    final n = rule.interval;
    final int k;
    switch (rule.unit) {
      case RecurrenceUnit.day:
        k = days ~/ n;
      case RecurrenceUnit.week:
        k = days ~/ (7 * n);
      case RecurrenceUnit.month:
        k = _monthsBetween(anchor, start) ~/ n;
      case RecurrenceUnit.year:
        k = (start.year - anchor.year) ~/ n;
      case RecurrenceUnit.businessDay:
        // n * k business days span at most 7 * (n * k + 4) / 5 calendar
        // days from the anchor.
        k = ((5 * days) ~/ 7 - 4) ~/ n;
    }
    return k < 0 ? 0 : k;
  }

  Iterable<DateTime> _steppedDates(DateTime start) sync* {
    for (var k = _startIndex(start); ; k++) {
      final day = _dateAt(k);
      if (!day.isBefore(start)) yield day;
    }
  }

  Iterable<DateTime> _weekdayDates(DateTime start) sync* {
    final firstMonday = mondayOf(anchor);
    final from = start.isBefore(anchor) ? anchor : start;
    final weeks = daysBetween(firstMonday, mondayOf(from)) ~/ 7;
    final n = rule.interval;
    for (var week = weeks ~/ n * n; ; week += n) {
      final monday = addCalendarDays(firstMonday, 7 * week);
      for (final weekday in rule.weekdays) {
        final day = addCalendarDays(monday, weekday - 1);
        if (!day.isBefore(anchor) && !day.isBefore(start)) yield day;
      }
    }
  }

  Iterable<DateTime> _nthWeekdayDates(DateTime start) sync* {
    final nth = rule.nthWeekday!;
    final n = rule.interval;
    final monthIndex = anchor.year * 12 + (anchor.month - 1);
    final from = start.isBefore(anchor) ? anchor : start;
    for (var k = _monthsBetween(anchor, from) ~/ n; ; k++) {
      final total = monthIndex + n * k;
      final day = nth.dateIn(total ~/ 12, total % 12 + 1);
      if (!day.isBefore(anchor) && !day.isBefore(start)) yield day;
    }
  }
}

/// The calendar months from [from]'s month to [to]'s (negative if earlier).
int _monthsBetween(DateTime from, DateTime to) =>
    (to.year * 12 + to.month) - (from.year * 12 + from.month);
