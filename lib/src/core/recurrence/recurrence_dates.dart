/// Date-only calendar arithmetic for recurrence rules.
///
/// Every function takes and returns local `DateTime(y, m, d)` values with no
/// time of day, and moves by calendar fields, never by `Duration`s of 24
/// hours: the day a clock changes is 23 or 25 hours long, and a date built
/// by adding elapsed hours lands a day off (#957). Pure Dart, no I/O.
library;

import 'package:niman/src/core/calendar_days.dart';

/// [day] at local midnight: its date without the time of day.
DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

/// The number of calendar days from [from] to [to] (negative when [to] is
/// earlier), whatever time of day either carries. Counted in UTC, where
/// every day is 24 hours, so a daylight-saving change cannot skew it.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The number of the last day of [month] in [year].
int lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// [day] moved [months] calendar months on (never back), keeping its day of
/// the month, or the last day of the target month when that is shorter:
/// 31 January plus one month is 28 or 29 February, and 29 February plus a
/// year is 28 February.
DateTime addMonthsClamped(DateTime day, int months) {
  assert(months >= 0, 'months only move forward');
  final total = day.year * 12 + (day.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final last = lastDayOfMonth(year, month);
  return DateTime(year, month, day.day > last ? last : day.day);
}

/// The Monday of [day]'s ISO week (Monday to Sunday), as a date.
DateTime mondayOf(DateTime day) =>
    addCalendarDays(dateOnly(day), 1 - day.weekday);

/// Whether [day] is a business day: Monday to Friday.
bool isBusinessDay(DateTime day) => day.weekday <= DateTime.friday;

/// The date [count] business days (Monday to Friday) after [day]; [count]
/// is zero or more. From a Saturday or a Sunday the first business day is
/// the Monday after, so one business day after a Saturday is that Monday,
/// exactly as it is after the Friday before it. Zero returns [day] itself,
/// weekend or not.
DateTime addBusinessDays(DateTime day, int count) {
  assert(count >= 0, 'business days only move forward');
  final from = dateOnly(day);
  if (count == 0) return from;
  // Position within the week, Monday = 0; a weekend counts as the Friday
  // that precedes it, since the next business day is the same Monday.
  final weekday = from.weekday > DateTime.friday
      ? DateTime.friday
      : from.weekday;
  final index = weekday - 1 + count;
  return addCalendarDays(mondayOf(from), 7 * (index ~/ 5) + index % 5);
}

/// The [nth] [weekday] of [month] in [year]: [nth] is 1 to 4 counted from the
/// start of the month, or -1 for the last. [weekday] is `DateTime.monday`
/// to `DateTime.sunday`. A first to fourth weekday always exists.
DateTime nthWeekdayOfMonth(int year, int month, int weekday, int nth) {
  assert(nth == -1 || (nth >= 1 && nth <= 4), 'nth is 1..4 or -1');
  if (nth > 0) {
    final offset = (weekday - DateTime(year, month).weekday) % 7;
    return DateTime(year, month, 1 + offset + 7 * (nth - 1));
  }
  final last = DateTime(year, month + 1, 0);
  return DateTime(year, month, last.day - (last.weekday - weekday) % 7);
}

/// The date written `YYYY-MM-DD`, or null when [text] is not exactly that
/// or names a day that does not exist (`2026-02-30`).
DateTime? parseIsoDate(String text) {
  final m = _isoDate.firstMatch(text);
  if (m == null) return null;
  final year = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// [day] written `YYYY-MM-DD`.
String formatIsoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
