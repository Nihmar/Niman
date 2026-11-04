/// The name of what a calendar goal covers, as the journal, the Home's
/// events tile and search all say it (#730).
library;

import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/weeks.dart';
import 'package:niman/src/ui/strings.dart';

/// What a goal covers: the week's number, the month's name, the year
/// (#730). Shared with the Home's events tile, so both name a goal alike.
String journalGoalLabel(CalendarLine goal) {
  final date = goal.date;
  if (date == null) return '';
  return switch (goal.kind) {
    CalendarLineKind.weekGoal => AppStrings.journalWeek(
      goal.week ?? isoWeekOf(date),
    ),
    CalendarLineKind.monthGoal => AppStrings.monthNames[date.month - 1],
    CalendarLineKind.yearGoal => '${date.year}',
    _ => '',
  };
}
