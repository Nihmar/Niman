/// Where a rule stops (`until:`) and what it skips (`except:`).
library;

import 'package:meta/meta.dart';

import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// The `until:` and `except:` tokens of a recurring event, after RFC 5545.
///
/// Dates are date-only. Pure value type; the parsers return null for an
/// unreadable value and never throw.
@immutable
final class RecurrenceBounds {
  /// Creates bounds; [except] dates are normalised to date-only.
  new({this.until, Iterable<DateTime> except = const <DateTime>[]})
    : except = Set<DateTime>.unmodifiable(except.map(dateOnly));

  /// No end and nothing skipped.
  static final RecurrenceBounds none = RecurrenceBounds();

  /// The last day an occurrence may fall on, inclusive, or null for never.
  final DateTime? until;

  /// The dates whose occurrences do not happen.
  final Set<DateTime> except;

  /// Whether an occurrence on [day] is cut off or skipped.
  bool excludes(DateTime day) {
    final d = dateOnly(day);
    final end = until;
    if (end != null && d.isAfter(dateOnly(end))) return true;
    return except.contains(d);
  }

  /// The date of an `until:YYYY-MM-DD` [value], or null when unreadable.
  static DateTime? parseUntil(String value) => parseIsoDate(value);

  /// The dates of an `except:YYYY-MM-DD,YYYY-MM-DD` [value], in the order
  /// written and without repeats, or null when the value is empty or any
  /// entry is not a real date.
  static List<DateTime>? parseExcept(String value) {
    if (value.isEmpty) return null;
    final dates = <DateTime>[];
    for (final part in value.split(',')) {
      final date = parseIsoDate(part);
      if (date == null) return null;
      if (!dates.contains(date)) dates.add(date);
    }
    return dates;
  }

  /// The `until:` token, or null when there is no end.
  String? get untilToken {
    final end = until;
    return end == null ? null : 'until:${formatIsoDate(end)}';
  }

  /// The `except:` token with the dates in order, or null when none.
  String? get exceptToken {
    if (except.isEmpty) return null;
    final sorted = except.toList()..sort();
    return 'except:${sorted.map(formatIsoDate).join(',')}';
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceBounds &&
      other.until == until &&
      other.except.length == except.length &&
      other.except.containsAll(except);

  @override
  int get hashCode => Object.hash(until, Object.hashAllUnordered(except));
}
