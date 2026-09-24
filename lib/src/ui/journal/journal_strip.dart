/// The journal strip (#7, mockup A): above any note that is a journal
/// entry, on every platform — the entry before, the day, the entry after.
///
/// It says which note this is in the journal's terms and moves through
/// it without the calendar: the neighbours are the entries that exist,
/// skipping the days without one. With none earlier, the previous side
/// offers the day before; the next side stops at today.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/journal/journal_days.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/strings.dart';

/// The strip over one entry.
final class JournalStrip extends StatefulWidget {
  /// The strip for [day]'s entry, with [today] the journal's day now.
  ///
  /// [entryDays] reads the days that have an entry; it is read again
  /// when [day] or [revision] (the library's) changes. [onPrevious] and
  /// [onNext] move; [onDay], when given, is the day's own tap (the
  /// calendar). [compact] is the phone's shorter date.
  const new({
    required this.day,
    required this.today,
    required this.entryDays,
    required this.onPrevious,
    required this.onNext,
    this.onDay,
    this.revision = 0,
    this.compact = false,
    super.key,
  });

  /// The entry's day.
  final DateTime day;

  /// The journal's day now.
  final DateTime today;

  /// The days with an entry, oldest first.
  final Future<List<DateTime>?> Function() entryDays;

  /// Goes to the entry before.
  final VoidCallback onPrevious;

  /// Goes to the entry after.
  final VoidCallback onNext;

  /// The day's own tap, or null for none.
  final VoidCallback? onDay;

  /// The library's revision: a change reads the entries again.
  final int revision;

  /// Whether to write the day short (the phone's width).
  final bool compact;

  @override
  State<JournalStrip> createState() => _JournalStripState();
}

final class _JournalStripState extends State<JournalStrip> {
  List<DateTime> _days = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant JournalStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day || oldWidget.revision != widget.revision) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final days = await widget.entryDays();
    if (mounted && days != null) setState(() => _days = days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = widget.day;
    final before =
        journalDayBefore(_days, day) ??
        DateTime(day.year, day.month, day.day - 1);
    final after =
        journalDayAfter(_days, day) ??
        (day.isBefore(widget.today)
            ? DateTime(day.year, day.month, day.day + 1)
            : null);
    // A neighbour with no entry is one that would be made: said softer.
    Color side(DateTime? other) => other != null && _days.contains(other)
        ? scheme.onSurfaceVariant
        : scheme.outline;
    final isToday = day == widget.today;
    final small = theme.textTheme.bodySmall;
    return Container(
      key: const Key('journal-strip'),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: AppStrings.journalPrevious,
            child: TextButton.icon(
              key: const Key('journal-previous'),
              onPressed: widget.onPrevious,
              style: TextButton.styleFrom(foregroundColor: side(before)),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: Text(formatDateTime(before, 'ddd D'), style: small),
            ),
          ),
          Expanded(
            child: InkWell(
              key: const Key('journal-day'),
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onDay,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.compact
                          ? formatDateTime(day, 'ddd D MMM YYYY')
                          : journalDayLabel(day),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      key: const Key('journal-today-badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.primary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        MaterialLocalizations.of(context).currentDateLabel,
                        style: small?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // The same place whether or not there is somewhere to go, so
          // nothing moves under a pointer already on it.
          Tooltip(
            message: AppStrings.journalNext,
            child: TextButton(
              key: const Key('journal-next'),
              onPressed: after == null ? null : widget.onNext,
              style: TextButton.styleFrom(foregroundColor: side(after)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    after == null ? '' : formatDateTime(after, 'ddd D'),
                    style: small,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
