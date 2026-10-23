/// The `due` filter of a `todo` block (#1152).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/calendar_days.dart';

/// Which due dates a `todo` block lists: `today`, `overdue`, `<=+Nd`, a date
/// or a range of dates. A task with no due date matches none of them.
@immutable
sealed class TodoBlockDue {
  const new();

  /// [value] as a filter, or null when it is none of the forms.
  static TodoBlockDue? parse(String value) {
    final text = value.trim();
    switch (text.toLowerCase()) {
      case 'today':
        return const DueToday();
      case 'overdue':
        return const DueOverdue();
    }
    final within = _within.firstMatch(text);
    if (within != null) return DueWithin(int.parse(within.group(1)!));
    final range = _range.firstMatch(text);
    if (range != null) {
      final from = _date(range.group(1)!);
      final to = _date(range.group(2)!);
      return from == null || to == null || to.isBefore(from)
          ? null
          : DueBetween(from, to);
    }
    final day = _date(text);
    return day == null ? null : DueOn(day);
  }

  /// Whether a task due on [due] (a day; null for none) is listed, [today]
  /// being the day it is told against.
  bool matches(DateTime? due, DateTime today);

  static final RegExp _within = RegExp(r'^<=\s*\+(\d{1,4})d$');
  static final RegExp _range = RegExp(
    r'^(\d{4}-\d{2}-\d{2})\s*\.\.\s*(\d{4}-\d{2}-\d{2})$',
  );
  static final RegExp _day = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// The calendar day `YYYY-MM-DD`, or null when it is no date (a month 13,
  /// a 31st of June).
  static DateTime? _date(String text) {
    final match = _day.firstMatch(text);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}

DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

/// `due: today`.
final class DueToday extends TodoBlockDue {
  /// Tasks due today.
  const new();

  @override
  bool matches(DateTime? due, DateTime today) =>
      due != null && _dayOf(due) == _dayOf(today);
}

/// `due: overdue`.
final class DueOverdue extends TodoBlockDue {
  /// Tasks due before today.
  const new();

  @override
  bool matches(DateTime? due, DateTime today) =>
      due != null && _dayOf(due).isBefore(_dayOf(today));
}

/// `due: <=+Nd`: today and the [days] after it, and everything overdue.
final class DueWithin extends TodoBlockDue {
  /// Tasks due no later than [days] days from today.
  const new(this.days);

  /// How many days ahead.
  final int days;

  @override
  bool matches(DateTime? due, DateTime today) =>
      due != null && !_dayOf(due).isAfter(addCalendarDays(_dayOf(today), days));
}

/// `due: 2026-11-02`.
final class DueOn extends TodoBlockDue {
  /// Tasks due on [day].
  const new(this.day);

  /// The day.
  final DateTime day;

  @override
  bool matches(DateTime? due, DateTime today) =>
      due != null && _dayOf(due) == day;
}

/// `due: 2026-11-01..2026-11-07`.
final class DueBetween extends TodoBlockDue {
  /// Tasks due from [from] to [to], both included.
  const new(this.from, this.to);

  /// The first day.
  final DateTime from;

  /// The last day.
  final DateTime to;

  @override
  bool matches(DateTime? due, DateTime today) {
    if (due == null) return false;
    final day = _dayOf(due);
    return !day.isBefore(from) && !day.isAfter(to);
  }
}
