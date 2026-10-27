/// The rules the task dialog's Repeat menu offers besides Custom (#1189).
library;

import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

/// Daily, weekdays, weekly, monthly and yearly, as the menu lists them.
///
/// [anchor] is the task's due date, or today when it has none: weekly is on
/// its weekday, and monthly and yearly count from the due date (strict), so
/// "monthly on this day" stays on the day when the task is done late. Daily
/// and weekdays count from the completion, which is what a daily chore
/// wants: done late, it is due tomorrow, not still overdue.
List<RecurrenceRule> todoRepeatPresets(DateTime anchor) => <RecurrenceRule>[
  RecurrenceRule(unit: RecurrenceUnit.day),
  RecurrenceRule(unit: RecurrenceUnit.businessDay),
  RecurrenceRule(unit: RecurrenceUnit.week, weekdays: [anchor.weekday]),
  RecurrenceRule(unit: RecurrenceUnit.month, strict: true),
  RecurrenceRule(unit: RecurrenceUnit.year, strict: true),
];
