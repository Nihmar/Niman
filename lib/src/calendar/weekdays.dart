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

/// The names, mapped to ISO weekday numbers (1 = Monday).
Map<String, int> get calendarWeekdays {
  return _cached ??= weekdayNamesFrom([
    // The short names first: an abbreviation shared by two languages keeps
    // the first meaning, and the short form is what a file writes.
    for (final strings in AppStrings.allStrings) strings.weekdayNamesShort,
    for (final strings in AppStrings.allStrings) strings.weekdayNames,
  ]);
}
