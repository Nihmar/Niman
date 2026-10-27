/// Weekdays in a recurrence rule: RFC 5545's two-letter codes and the Nth
/// weekday of a month.
library;

import 'package:meta/meta.dart';

import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// The RFC 5545 code of [weekday] (`DateTime.monday` to `DateTime.sunday`):
/// `mo`, `tu`, `we`, `th`, `fr`, `sa`, `su`. The file is not localised, so
/// these are the same in every app language.
String weekdayCode(int weekday) => _codes[weekday - 1];

/// The weekday (`DateTime.monday` to `DateTime.sunday`) a two-letter [code]
/// names, in any case, or null.
int? weekdayFromCode(String code) {
  final index = _codes.indexOf(code.toLowerCase());
  return index < 0 ? null : index + 1;
}

const List<String> _codes = <String>['mo', 'tu', 'we', 'th', 'fr', 'sa', 'su'];

/// A weekday counted within a month: the second Tuesday (`2tu`) or the last
/// Friday (`-1fr`).
@immutable
final class NthWeekday {
  /// Creates the [nth] [weekday]; [nth] is 1 to 4, or -1 for the last (a
  /// fifth weekday is missing from some months, so it is not offered).
  const new(this.nth, this.weekday)
    : assert(nth == -1 || (nth >= 1 && nth <= 4), 'nth is 1..4 or -1'),
      assert(
        weekday >= DateTime.monday && weekday <= DateTime.sunday,
        'weekday is 1..7',
      );

  /// Which one in the month: 1 to 4 from its start, or -1 for the last.
  final int nth;

  /// The weekday, `DateTime.monday` to `DateTime.sunday`.
  final int weekday;

  /// Whether this is the last such weekday of its month.
  bool get isLast => nth == -1;

  /// This weekday in [month] of [year], as a date.
  DateTime dateIn(int year, int month) =>
      nthWeekdayOfMonth(year, month, weekday, nth);

  /// Whether [day] is this weekday of its month.
  bool matches(DateTime day) => dateIn(day.year, day.month).day == day.day;

  /// The `2tu` / `-1fr` form written after the `;` of a `rec:` value.
  String get token => '$nth${weekdayCode(weekday)}';

  /// The `[-]Nxx` form, or null when [text] is not one.
  static NthWeekday? parse(String text) {
    final m = _nthToken.firstMatch(text);
    if (m == null) return null;
    final weekday = weekdayFromCode(m.group(2)!);
    if (weekday == null) return null;
    return NthWeekday(int.parse(m.group(1)!), weekday);
  }

  @override
  bool operator ==(Object other) =>
      other is NthWeekday && other.nth == nth && other.weekday == weekday;

  @override
  int get hashCode => Object.hash(nth, weekday);

  @override
  String toString() => 'NthWeekday($token)';
}

final RegExp _nthToken = RegExp(r'^(-1|[1-4])([a-zA-Z]{2})$');
