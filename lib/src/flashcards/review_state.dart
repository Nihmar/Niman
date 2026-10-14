/// When to show a card again (#533): SM-2's four numbers and the moment
/// they were set. One of these is a card's entry in `.niman/review.json`.
library;

import 'package:meta/meta.dart';

/// A card's review state.
@immutable
final class ReviewState {
  /// A state of ease [ef], [interval] days, [reps] correct reviews in a
  /// row, due on the calendar day [due], set [at].
  const new({
    required this.ef,
    required this.interval,
    required this.reps,
    required this.due,
    required this.at,
  });

  /// Reads an entry of the file; null for anything that is not one: a
  /// missing field, a field of the wrong type, a date that does not read.
  /// Never throws.
  static ReviewState? fromJson(Object? json) {
    if (json is! Map) return null;
    final ef = json['ef'];
    final interval = json['interval'];
    final reps = json['reps'];
    final due = _dateOf(json['due']);
    if (ef is! num || !ef.isFinite || ef < minEase || ef > 10) return null;
    if (interval is! int || interval < 0 || interval > 36500) return null;
    if (reps is! int || reps < 0 || due == null) return null;
    return ReviewState(
      ef: ef.toDouble(),
      interval: interval,
      reps: reps,
      due: due,
      at: DateTime.tryParse('${json['at']}')?.toUtc() ?? DateTime.utc(1970),
    );
  }

  /// The ease a new card starts with.
  static const double startEase = 2.5;

  /// The ease no review takes a card under.
  static const double minEase = 1.3;

  /// How easily the card is remembered, the factor an interval grows by.
  final double ef;

  /// The days between the review that set this state and [due].
  final int interval;

  /// The reviews in a row graded above Again.
  final int reps;

  /// The calendar day the card comes back, as a date at midnight.
  final DateTime due;

  /// When the review that set this state happened, in UTC: what the sync
  /// compares to keep the later of two devices' entries.
  final DateTime at;

  /// Whether the card is due on or before [today], a date at midnight.
  bool isDue(DateTime today) => !due.isAfter(today);

  /// The days from [today], a date at midnight, to [due]: negative for a
  /// card overdue.
  int daysUntilDue(DateTime today) => daysBetween(today, due);

  /// The entry as `review.json` holds it.
  Map<String, Object?> toJson() => {
    'ef': ef,
    'interval': interval,
    'reps': reps,
    'due': dateText(due),
    'at': at.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewState &&
      other.ef == ef &&
      other.interval == interval &&
      other.reps == reps &&
      other.due == due &&
      other.at == at;

  @override
  int get hashCode => Object.hash(ef, interval, reps, due, at);

  @override
  String toString() =>
      'ReviewState(ef $ef, $interval d, $reps reps, due ${dateText(due)})';

  /// [day] as `YYYY-MM-DD`.
  static String dateText(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// The whole calendar days from [from] to [to], both dates at midnight:
  /// counted on the calendar, so a daylight saving change is no missing
  /// day.
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static final RegExp _date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static DateTime? _dateOf(Object? text) {
    final match = _date.firstMatch('$text');
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    // A day that does not exist (02-30) rolls over: not a date.
    return date.month == month && date.day == day ? date : null;
  }
}
