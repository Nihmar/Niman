/// The weekday names `calendar.txt`'s parser recognises (#730): English's
/// abbreviations plus every language the app ships, so a file written in
/// any of them reads its own day heads.
///
/// Built once and cached: the parser is given this map, and stays pure
/// Dart ([weekdayNumberFor]).
library;

import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/ui/strings.dart';

Map<String, int>? _cached;

/// The short weekday names of a locale that spells [name] the way the
/// file does — `lun.` an Italian (or Spanish) Monday — or null when no
/// locale the app ships does. A new day line is written with these, so a
/// file that already spells its days in a language keeps spelling them in
/// it (#730).
List<String>? weekdayNamesInTheStyleOf(String name) {
  final wanted = name.toLowerCase().trim();
  if (wanted.isEmpty) return null;
  final plain = wanted.endsWith('.')
      ? wanted.substring(0, wanted.length - 1)
      : wanted;
  for (final strings in AppStrings.allStrings) {
    final names = strings.weekdayNamesShort;
    for (final candidate in names) {
      final lower = candidate.toLowerCase().trim();
      if (lower == wanted ||
          (lower.endsWith('.') &&
              lower.substring(0, lower.length - 1) == plain)) {
        return names;
      }
    }
  }
  return null;
}

/// The names, mapped to ISO weekday numbers (1 = Monday).
Map<String, int> get calendarWeekdays {
  return _cached ??= weekdayNamesFrom([
    // The short names first: an abbreviation shared by two languages keeps
    // the first meaning, and the short form is what a file writes.
    for (final strings in AppStrings.allStrings) strings.weekdayNamesShort,
    for (final strings in AppStrings.allStrings) strings.weekdayNames,
  ]);
}
