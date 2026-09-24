/// A month of the journal (#7, mockups B and 5): the days in a grid, a
/// dot under each day with an entry, today ringed, one day selected.
///
/// Presentation only: which days have an entry, which one is selected
/// and what a tap does are the caller's.
library;

import 'package:flutter/material.dart';

/// One month's grid.
final class JournalCalendar extends StatelessWidget {
  /// [month] (any day in it), with [entries] dotted, [today] ringed and
  /// [selected] filled; [onDay] hears a tap, [onMonth] a move to another
  /// month. [cell] is a day's side, in logical pixels.
  const new({
    required this.month,
    required this.entries,
    required this.today,
    required this.onDay,
    required this.onMonth,
    this.selected,
    this.cell = 34,
    super.key,
  });

  /// The month shown.
  final DateTime month;

  /// The days with an entry.
  final Set<DateTime> entries;

  /// The journal's day now.
  final DateTime today;

  /// The day shown selected, or null.
  final DateTime? selected;

  /// Called with the day tapped.
  final ValueChanged<DateTime> onDay;

  /// Called with the first day of the month to show instead.
  final ValueChanged<DateTime> onMonth;

  /// A day's side.
  final double cell;

  @override
  Widget build(BuildContext context) {
    final words = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = DateTime(month.year, month.month);
    final length = DateTime(month.year, month.month + 1, 0).day;
    // Monday is 1 in DateTime, index 1 in the localizations' list.
    final firstWeekday = words.firstDayOfWeekIndex;
    final lead = (first.weekday % 7 - firstWeekday) % 7;
    final headers = [
      for (var i = 0; i < 7; i++) words.narrowWeekdays[(firstWeekday + i) % 7],
    ];
    final days = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= length; d++) DateTime(month.year, month.month, d),
    ];
    while (days.length % 7 != 0) {
      days.add(null);
    }
    Widget day(DateTime? date) {
      if (date == null) return SizedBox(width: cell, height: cell);
      final isSelected = date == selected;
      final isToday = date == today;
      final hasEntry = entries.contains(date);
      final future = date.isAfter(today);
      final ink = isSelected
          ? scheme.onPrimary
          : future
          ? scheme.onSurfaceVariant
          : scheme.onSurface;
      return SizedBox(
        width: cell,
        height: cell,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            key: Key('journal-day-${date.day}'),
            radius: cell / 2,
            onTap: () => onDay(date),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: words.formatFullDate(date),
              excludeSemantics: true,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : null,
                  border: isToday && !isSelected
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ink,
                        fontWeight: isToday ? FontWeight.w700 : null,
                      ),
                    ),
                    if (hasEntry)
                      Positioned(
                        bottom: cell * 0.12,
                        child: Container(
                          key: Key('journal-dot-${date.day}'),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.tertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                words.formatMonthYear(first),
                key: const Key('journal-month'),
                style: theme.textTheme.titleSmall,
              ),
            ),
            IconButton(
              key: const Key('journal-month-previous'),
              tooltip: words.previousMonthTooltip,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
            ),
            IconButton(
              key: const Key('journal-month-next'),
              tooltip: words.nextMonthTooltip,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final header in headers)
              SizedBox(
                width: cell,
                child: Text(
                  header,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        for (var row = 0; row < days.length; row += 7)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final date in days.sublist(row, row + 7)) day(date),
            ],
          ),
      ],
    );
  }
}
