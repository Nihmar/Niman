/// The ISO-8601 week number of a date: 1 .. 53.
///
/// A week belongs to the year owning its Thursday, which is why the
/// calculation goes through that day rather than through 1 January. Shared
/// by the template engine's `WW` token and calendar.txt's day heads
/// (#730).
library;

/// The ISO-8601 week number of [when]: 1 .. 53.
int isoWeekOf(DateTime when) {
  final day = DateTime.utc(when.year, when.month, when.day);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final firstOfYear = DateTime.utc(thursday.year);
  return thursday.difference(firstOfYear).inDays ~/ 7 + 1;
}
