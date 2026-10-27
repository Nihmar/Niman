/// The event form's two clocks (#730): a start and an optional end, each a
/// button that opens the clock picker and, once set, a way to take it back.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/strings.dart';

/// The start and the end of an event, as minutes from midnight.
final class CalendarEventTimes extends StatelessWidget {
  /// Two clocks showing [start] and [end]; a time picked, or taken back
  /// (null), is answered through [onStart] and [onEnd].
  const new({
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
    super.key,
  });

  /// The start, or null for an event with no time.
  final int? start;

  /// The end, or null.
  final int? end;

  /// Called with the start picked, or null when it is taken back.
  final ValueChanged<int?> onStart;

  /// Called with the end picked, or null when it is taken back.
  final ValueChanged<int?> onEnd;

  @override
  Widget build(BuildContext context) {
    // Wrapped, not stretched: the dock's island and a phone's sheet are both
    // narrow, and the two clocks are the row.
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TimeButton(
          name: 'start',
          // A time nobody set reads as an empty clock, and nothing else:
          // there is no string in an `--:--`.
          label: start == null ? '--:--' : _clockText(start!),
          onPressed: () => _pick(context, start, onStart),
          onClear: start == null ? null : () => onStart(null),
        ),
        _TimeButton(
          name: 'end',
          label: end == null
              ? AppStrings.calendarEndOptional
              : _clockText(end!),
          onPressed: () => _pick(context, end ?? start, onEnd),
          onClear: end == null ? null : () => onEnd(null),
        ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    int? from,
    ValueChanged<int?> answer,
  ) async {
    final time = await showClockPicker(
      context,
      initialTime: from == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: from ~/ 60, minute: from % 60),
    );
    if (time == null || !context.mounted) return;
    answer(time.hour * 60 + time.minute);
  }
}

/// One of the two time fields: the time, and a way to take it back.
final class _TimeButton extends StatelessWidget {
  const new({
    required this.name,
    required this.label,
    required this.onPressed,
    required this.onClear,
  });

  final String name;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: Key('calendar-event-$name'),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 16),
          const SizedBox(width: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (onClear != null)
            IconButton(
              key: Key('calendar-event-$name-clear'),
              icon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

/// A clock time as a field shows it: `15:00`, `9:30`.
String _clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';
