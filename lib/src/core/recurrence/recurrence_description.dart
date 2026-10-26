/// A rule as data the UI turns into words.
library;

import 'package:meta/meta.dart';

import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/core/recurrence/recurrence_weekday.dart';

/// The language-free shape of a recurrence rule: what "every 2 weeks" or
/// "every month, 2nd Tuesday" is built from. The words live in the app
/// strings, not here.
@immutable
final class RecurrenceDescription {
  /// Creates a description; read one from `RecurrenceRule.description`.
  const new({
    required this.unit,
    required this.interval,
    required this.strict,
    required this.weekdays,
    required this.nthWeekday,
  });

  /// What [interval] counts.
  final RecurrenceUnit unit;

  /// Every how many [unit]s, 1 or more.
  final int interval;

  /// Whether the next copy counts from the due date, not the completion.
  final bool strict;

  /// The listed weekdays (`DateTime.monday` to `DateTime.sunday`) in week
  /// order, empty unless [unit] is a week with a weekday list.
  final List<int> weekdays;

  /// The Nth weekday of the month, or null.
  final NthWeekday? nthWeekday;

  /// Every business day: the preset "Weekdays" (`rec:1b`).
  bool get isEveryBusinessDay =>
      unit == RecurrenceUnit.businessDay && interval == 1;

  /// A plain step with nothing but [unit] and [interval] to say.
  bool get isPlain => weekdays.isEmpty && nthWeekday == null;
}
