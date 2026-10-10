/// Flutter's date and time dialogs, with the soft keyboard kept down (#504).
///
/// A date or a time is chosen, never typed, and on a phone the soft keyboard
/// has no business over the calendar or the dial. Two things used to raise
/// it: the picker opening in its text-entry mode, and the field left focused
/// behind the dialog — the input connection stayed open while the calendar
/// was up and the keyboard came back the moment it closed. Both are closed
/// here: the mode is named, and on the touch platforms the focused field is
/// dropped before the picker opens and again once it returns.
///
/// A desktop has no soft keyboard to keep down, and a mouse types a time
/// into fields better than it turns a dial (#712): there the clock opens in
/// its text-entry mode.
library;

import 'package:flutter/material.dart';

/// Shows the calendar dialog, over [initialDate] between [firstDate] and
/// [lastDate], answering the day picked or null when it was dismissed.
Future<DateTime?> showDayPicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final touch = _touch(context);
  _dropKeyboard(touch: touch);
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    // The calendar, never the text entry: the text mode is the one that
    // raises the keyboard (#504). Named even though it matches today's
    // default, so a changed default cannot start opening the keyboard.
    // ignore: avoid_redundant_argument_values
    initialEntryMode: DatePickerEntryMode.calendar,
  );
  _dropKeyboard(touch: touch);
  return picked;
}

/// Shows the clock dialog, over [initialTime], answering the time picked
/// or null when it was dismissed.
Future<TimeOfDay?> showClockPicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) async {
  final touch = _touch(context);
  _dropKeyboard(touch: touch);
  final picked = await showTimePicker(
    context: context,
    initialTime: initialTime,
    // The dial on a phone, where the text mode is the one that raises the
    // keyboard (#504); HH:MM fields where a keyboard is already there
    // (#712). Named even where it matches today's default, so a changed
    // default cannot move it.
    initialEntryMode: touch
        ? TimePickerEntryMode.dial
        : TimePickerEntryMode.input,
  );
  _dropKeyboard(touch: touch);
  return picked;
}

/// Whether [context] is on a touch platform, where a soft keyboard can sit
/// over the picker. Read from the theme, the same answer the task dialog's
/// in-place panel asks (`todoPicksInPlace`), so the two cannot disagree; read
/// before the dialog opens, since the context may be gone once it returns.
bool _touch(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.android || TargetPlatform.iOS => true,
  _ => false,
};

/// Drops whatever held the soft keyboard when [touch]. Called before a dialog
/// opens, so nothing is focused to restore when it closes, and after it
/// returns, so a restored focus does not bring the keyboard back with it
/// (#504). A desktop has no soft keyboard, and unfocusing there would only
/// steal focus from the dialog.
void _dropKeyboard({required bool touch}) {
  if (!touch) return;
  FocusManager.instance.primaryFocus?.unfocus();
}
