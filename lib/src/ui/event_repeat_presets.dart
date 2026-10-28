/// The rules the event form's Repeat menu offers besides Custom (#1191).
library;

import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/core/recurrence/recurrence_weekday.dart';

/// [rule], for an event that was on [from] and is now on [to] (#1219).
///
/// A preset is tied to its day: the weekday of the weekly one, the Nth
/// weekday of the monthly one. When [rule] is one of the presets of [from] it
/// becomes the same preset of [to]; a rule the user built, which no preset
/// says, stays as it is.
RecurrenceRule eventRuleOnDay(
  RecurrenceRule rule, {
  required DateTime from,
  required DateTime to,
}) {
  final index = eventRepeatPresets(from).indexOf(rule);
  return index < 0 ? rule : eventRepeatPresets(to)[index];
}

/// Daily, weekdays, weekly, monthly (on the date and on the Nth weekday) and
/// yearly, counted from [anchor], the event's own day.
///
/// Weekly is on the anchor's weekday. Monthly on the Nth weekday is the
/// anchor's own — the second Tuesday, say — or the last one when the anchor
/// is a fifth, which not every month has. Nothing counts from a completion:
/// an event is never done, so none of these is strict.
List<RecurrenceRule> eventRepeatPresets(DateTime anchor) {
  final nth = (anchor.day - 1) ~/ 7 + 1;
  return <RecurrenceRule>[
    RecurrenceRule(unit: RecurrenceUnit.day),
    RecurrenceRule(unit: RecurrenceUnit.businessDay),
    RecurrenceRule(unit: RecurrenceUnit.week, weekdays: [anchor.weekday]),
    RecurrenceRule(unit: RecurrenceUnit.month),
    RecurrenceRule(
      unit: RecurrenceUnit.month,
      nthWeekday: NthWeekday(nth <= 4 ? nth : -1, anchor.weekday),
    ),
    RecurrenceRule(unit: RecurrenceUnit.year),
  ];
}
