/// Which days have an entry (#7), read from the library's note paths.
///
/// Pure: the caller lists the paths (an index seek under the journal's
/// folder) and these say which of them are entries, and what comes
/// before or after a day.
library;

import 'package:niman/src/journal/journal_settings.dart';

/// The days [paths] hold an entry for, oldest first, each once.
List<DateTime> journalDays(JournalSettings settings, Iterable<String> paths) {
  final days = <DateTime>{
    for (final path in paths) ?settings.dayOfPath(path),
  }.toList()..sort();
  return days;
}

/// The narrowest folder holding every entry of [month]'s days: with the
/// default name, `Journal/2026/09`. What to list for a month's calendar,
/// so it reads that month's entries and not the whole journal.
String journalMonthFolder(JournalSettings settings, DateTime month) {
  final first = settings.entryPath(DateTime(month.year, month.month));
  final last = settings.entryPath(DateTime(month.year, month.month + 1, 0));
  var shared = 0;
  while (shared < first.length &&
      shared < last.length &&
      first[shared] == last[shared]) {
    shared++;
  }
  final slash = first.substring(0, shared).lastIndexOf('/');
  return slash < 0 ? '' : first.substring(0, slash);
}

/// The newest day in [days] (oldest first) before [day], or null.
DateTime? journalDayBefore(List<DateTime> days, DateTime day) {
  for (var i = days.length - 1; i >= 0; i--) {
    if (days[i].isBefore(day)) return days[i];
  }
  return null;
}

/// The oldest day in [days] (oldest first) after [day], or null.
DateTime? journalDayAfter(List<DateTime> days, DateTime day) {
  for (final candidate in days) {
    if (candidate.isAfter(day)) return candidate;
  }
  return null;
}
