/// The task dialog's date pickers, in place (#268): on a window with the
/// room, the due date and the reminder are chosen inside the dialog, under
/// their row, instead of in the system pickers stacked over it (a date
/// dialog, then for a reminder a time dialog over that).
library;

import 'package:flutter/material.dart';

/// Whether the task dialog picks its dates in place: a window wide and
/// tall enough to hold a calendar under the fields. A phone, or a phone
/// on its side, keeps the system pickers, which are made for it.
bool todoPicksInPlace(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= _minWidth && size.height >= _minHeight;
}

const double _minWidth = 600;
const double _minHeight = 600;

/// The first and last day the pickers offer.
final DateTime todoFirstDate = DateTime(2000);

/// See [todoFirstDate].
final DateTime todoLastDate = DateTime(2100);

/// A calendar in place: picking a day is the answer.
final class TodoDatePanel extends StatelessWidget {
  /// A calendar opened on [initial], answering through [onPicked].
  const new({required this.initial, required this.onPicked, super.key});

  /// The day it opens on and shows selected.
  final DateTime initial;

  /// Called with the day picked.
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: CalendarDatePicker(
        initialDate: initial,
        firstDate: todoFirstDate,
        lastDate: todoLastDate,
        onDateChanged: onPicked,
      ),
    );
  }
}

/// A calendar and a time in place, for a reminder: the day and the time
/// are set together, and [onPicked] hears them once the time is set.
final class TodoReminderPanel extends StatefulWidget {
  /// A panel opened on [initial] (day and time), answering through
  /// [onPicked].
  const new({required this.initial, required this.onPicked, super.key});

  /// The day and time it opens on.
  final DateTime initial;

  /// Called with the day and time chosen.
  final ValueChanged<DateTime> onPicked;

  @override
  State<TodoReminderPanel> createState() => _TodoReminderPanelState();
}

final class _TodoReminderPanelState extends State<TodoReminderPanel> {
  late DateTime _day = DateTime(
    widget.initial.year,
    widget.initial.month,
    widget.initial.day,
  );
  late final TextEditingController _time = TextEditingController(
    text: _format(TimeOfDay.fromDateTime(widget.initial)),
  );

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  static String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// The time typed, or null while it is not a valid `H:MM` / `HH:MM`.
  TimeOfDay? get _typed {
    final match = RegExp(r'^\s*([01]?\d|2[0-3])[:.]([0-5]\d)\s*$')
        .firstMatch(_time.text);
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  void _set() {
    final time = _typed;
    if (time == null) return;
    widget.onPicked(
      DateTime(_day.year, _day.month, _day.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = MaterialLocalizations.of(context);
    final valid = _typed != null;
    return _Frame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarDatePicker(
            initialDate: _day,
            firstDate: todoFirstDate,
            lastDate: todoLastDate,
            onDateChanged: (day) => setState(() => _day = day),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(Icons.schedule_outlined, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('todo-reminder-time'),
                    controller: _time,
                    decoration: InputDecoration(
                      labelText: words.timePickerInputHelpText,
                      hintText: '09:00',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _set(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FilledButton.tonal(
                    key: const Key('todo-reminder-set'),
                    onPressed: valid ? _set : null,
                    child: Text(words.okButtonLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The outline a panel sits in, so it reads as part of its row.
final class _Frame extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 28, bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
