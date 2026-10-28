/// The event form's Repeat and Ends rows (#1191).
///
/// Repeat is the task dialog's own row — Never, the presets, Custom — with
/// the presets an event has; Ends says when the rule stops, never or on a
/// date (`until:`). Both stay where they are when they do not apply (an
/// edit of one occurrence only, which becomes a plain event, or no rule yet
/// to end): disabled, not hidden, so nothing moves under a thumb already on
/// the form.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/todo/parser.dart' show formatTodoDate;
import 'package:niman/src/ui/event_repeat_presets.dart';
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/repeat_custom.dart';
import 'package:niman/src/ui/repeat_row.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_date_panel.dart';

/// The two rows, and the custom editor under Repeat when it is open in
/// place.
final class CalendarEventRepeat extends StatelessWidget {
  /// Rows for an event on [day] repeating by [rule] until [until].
  const new({
    required this.day,
    required this.rule,
    required this.until,
    required this.enabled,
    required this.customOpen,
    required this.onRule,
    required this.onUntil,
    required this.onToggleCustom,
    super.key,
  });

  /// The event's own day: what the presets and the end are taken from.
  final DateTime day;

  /// The rule, or null for an event that happens once.
  final RecurrenceRule? rule;

  /// The last day of the rule, or null for never.
  final DateTime? until;

  /// Whether the rule can be changed at all.
  final bool enabled;

  /// Whether the custom editor is open under the Repeat row.
  final bool customOpen;

  /// Called with the rule picked, or null for Never.
  final ValueChanged<RecurrenceRule?> onRule;

  /// Called with the end picked, or null for never.
  final ValueChanged<DateTime?> onUntil;

  /// Called when Custom is picked and the editor opens, or closes, in place.
  final VoidCallback onToggleCustom;

  @override
  Widget build(BuildContext context) {
    final current = rule;
    final end = until;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepeatRow(
          rule: current,
          unreadable: null,
          anchor: day,
          presets: eventRepeatPresets(day),
          keyPrefix: 'calendar-event',
          countsFrom: false,
          enabled: enabled,
          onChanged: onRule,
          onCustomInPlace: onToggleCustom,
        ),
        if (customOpen && enabled)
          TodoPanelFrame(
            child: RepeatCustom(
              initial: current,
              anchor: day,
              keyPrefix: 'calendar-event',
              countsFrom: false,
              onChanged: onRule,
            ),
          ),
        Row(
          children: [
            const Icon(Icons.event_busy_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                key: const Key('calendar-event-ends'),
                onPressed: enabled && current != null
                    ? () => _pick(context)
                    : null,
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                child: Text(
                  end == null
                      ? AppStrings.calendarEndsNever
                      : AppStrings.calendarEndsOn(formatTodoDate(end)),
                ),
              ),
            ),
            if (end != null && enabled)
              IconButton(
                key: const Key('calendar-event-ends-clear'),
                tooltip: AppStrings.calendarEndsNever,
                icon: const Icon(Icons.clear),
                onPressed: () => onUntil(null),
              ),
          ],
        ),
      ],
    );
  }

  /// The calendar over the end, from the event's own day on: a rule cannot
  /// end before it starts.
  Future<void> _pick(BuildContext context) async {
    final first = dateOnly(day);
    final current = until;
    final initial = current == null || current.isBefore(first)
        ? first
        : dateOnly(current);
    final picked = await showDayPicker(
      context,
      initialDate: initial,
      firstDate: first,
      lastDate: todoLastDate.isAfter(initial) ? todoLastDate : initial,
    );
    // The form may be gone while the picker was up (#1222).
    if (picked == null || !context.mounted) return;
    onUntil(dateOnly(picked));
  }
}
