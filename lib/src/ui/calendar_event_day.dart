/// The event form's Day row (#1191): the day the event is written on, and the
/// way to change it.
///
/// It uses the task dialog's due-date pattern: a window with the room opens
/// the calendar in place under the row, a touch screen the system's date
/// picker. A row that cannot move the event — a series moves by changing its
/// rule — stays where it is, disabled.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/journal/journal_flow.dart' show journalDayLabel;
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_date_panel.dart';

/// The row, and the calendar under it when it is open in place.
final class CalendarEventDay extends StatelessWidget {
  /// A row showing [day]; a day picked is answered through [onPicked].
  const new({
    required this.day,
    required this.enabled,
    required this.open,
    required this.onToggle,
    required this.onPicked,
    super.key,
  });

  /// The day the event is written on.
  final DateTime day;

  /// Whether the day can be changed at all.
  final bool enabled;

  /// Whether the calendar is open under the row.
  final bool open;

  /// Called to open the calendar in place, or close it.
  final VoidCallback onToggle;

  /// Called with the day picked.
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.event_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: AppStrings.calendarEventDay,
                child: TextButton(
                  key: const Key('calendar-event-day'),
                  onPressed: enabled ? () => _tap(context) : null,
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  child: Text(
                    journalDayLabel(day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (open && enabled)
          TodoDatePanel(
            key: const Key('calendar-event-day-panel'),
            initial: day,
            onPicked: onPicked,
          ),
      ],
    );
  }

  Future<void> _tap(BuildContext context) async {
    if (todoPicksInPlace(context)) return onToggle();
    final picked = await showDayPicker(
      context,
      initialDate: day,
      firstDate: todoFirstDate,
      lastDate: todoLastDate,
    );
    if (picked == null) return;
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }
}
