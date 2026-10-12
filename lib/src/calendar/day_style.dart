/// The convention a `calendar.txt` writes its day heads in (#730): whether
/// they carry the ISO week, and whose weekday names they use.
///
/// A new day line follows the file's own convention, learned from the day
/// lines already there, and English — the spec's own form, `2026-10-05
/// w41 Mon` — when the file is new or gives no clue.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';
import 'package:niman/src/core/weeks.dart';

/// How a file heads its days.
@immutable
final class CalendarDayStyle {
  /// Creates a style: [week] days carry `wNN`, [weekdayNames] are the
  /// short names to write (null = English's).
  const new({this.week = true, this.weekdayNames});

  /// What [lines] write: the convention of the day heads among them.
  ///
  /// The week number is kept when at least half the day lines carry one
  /// (a file with none, or with no day lines at all, gets none of its
  /// own); the weekday names are the ones a day line already uses, when
  /// they can be told apart — a file whose names Niman does not know is
  /// written in English, the form the parser always reads.
  factory of(Iterable<String> lines) {
    var days = 0;
    var weeks = 0;
    List<String>? names;
    for (final raw in lines) {
      final line = parseCalendarLine(raw, weekdays: calendarWeekdays);
      if (line.kind != CalendarLineKind.day) continue;
      days++;
      if (line.week != null) weeks++;
      final written = line.weekday;
      if (names == null && written != null) {
        names = weekdayNamesInTheStyleOf(written);
      }
    }
    return CalendarDayStyle(
      week: days == 0 || weeks * 2 >= days,
      weekdayNames: names,
    );
  }

  /// Whether a day head carries the week number.
  final bool week;

  /// The short weekday names a head is written with, Monday first, or null
  /// for English's own.
  final List<String>? weekdayNames;

  /// The head for [date]: `2026-10-12 w42 Mon`, without the two spaces
  /// that separate it from the day's events.
  String head(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final at = day.weekday - 1;
    final names = weekdayNames;
    final name = names == null || at >= names.length
        ? englishWeekdayShortNames[at]
        : names[at];
    return [
      '${day.year}-${_two(day.month)}-${_two(day.day)}',
      if (week) 'w${isoWeekOf(day)}',
      name,
    ].join(' ');
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
