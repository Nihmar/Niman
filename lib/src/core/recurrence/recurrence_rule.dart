/// The `rec:` rule of a todo.txt task or a calendar.txt event.
///
/// The grammar is Simpletask's, with two extensions after a `;` (decisions
/// in `docs/records/recurring-tasks.md`):
///
/// ```text
/// rec:1w          one week on
/// rec:+1w         one week after the due date, not the completion (strict)
/// rec:3b          three business days (Monday to Friday)
/// rec:1w;mo,we,fr every week, on those weekdays
/// rec:1m;2tu      every month, on its second Tuesday
/// rec:1m;-1fr     every month, on its last Friday
/// ```
///
/// Pure Dart, no I/O. Dates are date-only local `DateTime(y, m, d)`; every
/// step is calendar arithmetic, never 24-hour `Duration`s.
library;

import 'package:meta/meta.dart';

import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_description.dart';
import 'package:niman/src/core/recurrence/recurrence_sequence.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/core/recurrence/recurrence_weekday.dart';

/// One parsed `rec:` value.
@immutable
final class RecurrenceRule {
  /// Creates a rule. The weekday list belongs to a weekly rule and the Nth
  /// weekday to a monthly one, and not both; [weekdays] are
  /// `DateTime.monday` to `DateTime.sunday`, sorted and without repeats.
  /// Prefer [RecurrenceRule.parse] for text.
  const new({
    required this.unit,
    this.interval = 1,
    this.strict = false,
    this.weekdays = const <int>[],
    this.nthWeekday,
  }) : assert(interval >= 1 && interval <= maxInterval, 'interval 1..9999'),
       assert(
         weekdays.length == 0 || unit == RecurrenceUnit.week,
         'a weekday list belongs to a weekly rule',
       ),
       assert(
         nthWeekday == null || unit == RecurrenceUnit.month,
         'an Nth weekday belongs to a monthly rule',
       );

  /// The largest interval a rule may carry (9999): beyond that a date
  /// leaves the range a `DateTime` holds, and no reader means it.
  static const int maxInterval = 9999;

  /// What [interval] counts.
  final RecurrenceUnit unit;

  /// Every how many [unit]s, 1 or more.
  final int interval;

  /// Whether the next copy of a task counts from its due date (`rec:+`)
  /// instead of its completion date. Events ignore it: nothing completes
  /// them. [nextFor] picks the base; [next] takes the one it is given.
  final bool strict;

  /// The listed weekdays of a weekly rule (`rec:1w;mo,we,fr`), as
  /// `DateTime.monday` to `DateTime.sunday` in week order; empty for none.
  final List<int> weekdays;

  /// The weekday of a monthly rule (`rec:1m;2tu`), or null.
  final NthWeekday? nthWeekday;

  /// The rule parsed from the value of a `rec:` token (what follows the
  /// colon), or null when it is not one this grammar reads: no interval, an
  /// interval of 0 or over [maxInterval], an unknown unit, an extension on
  /// a unit it does not fit, a bad weekday code. Never throws, and does not
  /// trim: a value with a space in it is not one.
  static RecurrenceRule? parse(String value) {
    final m = _ruleValue.firstMatch(value);
    if (m == null) return null;
    final interval = int.parse(m.group(2)!);
    final unit = RecurrenceUnit.fromLetter(m.group(3)!.toLowerCase());
    if (unit == null || interval < 1 || interval > maxInterval) return null;
    final strict = m.group(1) != null;
    final extension = m.group(4);
    if (extension == null) {
      return RecurrenceRule(unit: unit, interval: interval, strict: strict);
    }
    switch (unit) {
      case RecurrenceUnit.week:
        final days = <int>{};
        for (final code in extension.split(',')) {
          final weekday = weekdayFromCode(code);
          if (weekday == null) return null;
          days.add(weekday);
        }
        return RecurrenceRule(
          unit: unit,
          interval: interval,
          strict: strict,
          weekdays: List<int>.unmodifiable(days.toList()..sort()),
        );
      case RecurrenceUnit.month:
        final nth = NthWeekday.parse(extension);
        if (nth == null) return null;
        return RecurrenceRule(
          unit: unit,
          interval: interval,
          strict: strict,
          nthWeekday: nth,
        );
      case RecurrenceUnit.day:
      case RecurrenceUnit.year:
      case RecurrenceUnit.businessDay:
        return null;
    }
  }

  /// The value to write after `rec:`, in its canonical form (`+` first,
  /// unit letter and weekday codes in lower case).
  String get token {
    final buffer = StringBuffer(strict ? '+' : '')
      ..write(interval)
      ..write(unit.letter);
    if (weekdays.isNotEmpty) {
      buffer
        ..write(';')
        ..write(weekdays.map(weekdayCode).join(','));
    } else if (nthWeekday != null) {
      buffer
        ..write(';')
        ..write(nthWeekday!.token);
    }
    return buffer.toString();
  }

  /// This rule as data for the UI to put into words.
  RecurrenceDescription get description => RecurrenceDescription(
    unit: unit,
    interval: interval,
    strict: strict,
    weekdays: weekdays,
    nthWeekday: nthWeekday,
  );

  /// The next occurrence after [base], the way a task repeats (the chain
  /// follows the previous date, so it can drift from a clamped day):
  ///
  /// - days, weeks, months, years: [interval] of them on; a month or year
  ///   step that lands past the end of a shorter month takes its last day
  ///   (31 January + 1m is 28 or 29 February);
  /// - business days: [interval] of them on, Monday to Friday; from a
  ///   weekend the first business day is the Monday after;
  /// - a weekly rule with weekdays: the next listed weekday after [base]
  ///   in its own week (Monday to Sunday), or else the first listed one,
  ///   [interval] weeks after the week of [base];
  /// - a monthly rule with an Nth weekday: that weekday of the month
  ///   [interval] months after [base]'s.
  ///
  /// [base] is date-only in effect: any time of day is ignored.
  DateTime next(DateTime base) {
    final from = dateOnly(base);
    switch (unit) {
      case RecurrenceUnit.day:
        return addCalendarDays(from, interval);
      case RecurrenceUnit.week:
        if (weekdays.isEmpty) return addCalendarDays(from, 7 * interval);
        for (final weekday in weekdays) {
          if (weekday > from.weekday) {
            return addCalendarDays(from, weekday - from.weekday);
          }
        }
        return addCalendarDays(
          mondayOf(from),
          7 * interval + weekdays.first - 1,
        );
      case RecurrenceUnit.month:
        final nth = nthWeekday;
        if (nth == null) return addMonthsClamped(from, interval);
        final total = from.year * 12 + (from.month - 1) + interval;
        return nth.dateIn(total ~/ 12, total % 12 + 1);
      case RecurrenceUnit.year:
        return addMonthsClamped(from, 12 * interval);
      case RecurrenceUnit.businessDay:
        return addBusinessDays(from, interval);
    }
  }

  /// The next date of a task completed on [completed]: counted from [due]
  /// for a [strict] rule that has one, from the completion otherwise (a
  /// task with no due date, and any rule that is not strict).
  DateTime nextFor({required DateTime completed, DateTime? due}) =>
      next(strict && due != null ? due : completed);

  /// The occurrences from [from] to [to], both inclusive, of an event whose
  /// first day is [anchor], the way an event repeats: the k-th is [anchor]
  /// plus k steps, each worked out from the anchor and clamped on its own,
  /// so a monthly event on the 31st is on the 30th of April and back on the
  /// 31st in May. [bounds] cuts the series off at `until:` (inclusive) and
  /// drops the `except:` dates.
  ///
  /// The anchor is always the first occurrence, even when it is not on a
  /// listed weekday or the Nth weekday of its month; the others follow the
  /// rule from it. In ascending order. The cost depends on the length of
  /// the range, not on how long ago [anchor] was.
  List<DateTime> occurrences({
    required DateTime anchor,
    required DateTime from,
    required DateTime to,
    RecurrenceBounds? bounds,
  }) {
    final first = dateOnly(from);
    final last = dateOnly(to);
    if (last.isBefore(first)) return const <DateTime>[];
    final sequence = RecurrenceSequence(this, anchor);
    final until = bounds?.until;
    final end = until == null ? last : _earlier(last, until);
    final result = <DateTime>[];
    void take(DateTime day) {
      if (bounds == null || !bounds.except.contains(day)) result.add(day);
    }

    if (!sequence.anchorFollowsRule &&
        !sequence.anchor.isBefore(first) &&
        !sequence.anchor.isAfter(end)) {
      take(sequence.anchor);
    }
    for (final day in sequence.from(first)) {
      if (day.isAfter(end)) break;
      take(day);
    }
    return result;
  }

  /// Whether the rule has an occurrence on [day], counted from [anchor].
  bool occursOn({
    required DateTime anchor,
    required DateTime day,
    RecurrenceBounds? bounds,
  }) => occurrences(
    anchor: anchor,
    from: day,
    to: day,
    bounds: bounds,
  ).isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.unit == unit &&
      other.interval == interval &&
      other.strict == strict &&
      other.nthWeekday == nthWeekday &&
      _sameDays(other.weekdays, weekdays);

  @override
  int get hashCode =>
      Object.hash(unit, interval, strict, nthWeekday, Object.hashAll(weekdays));

  @override
  String toString() => 'RecurrenceRule(rec:$token)';
}

DateTime _earlier(DateTime a, DateTime b) {
  final other = dateOnly(b);
  return a.isBefore(other) ? a : other;
}

bool _sameDays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

final RegExp _ruleValue = RegExp(r'^(\+)?(\d{1,4})([a-zA-Z])(?:;(.+))?$');
