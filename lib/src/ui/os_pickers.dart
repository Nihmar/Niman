/// The platform's own date and time pickers, with the keyboard kept down
/// (#504).
///
/// A date or a time is chosen, never typed, and on a phone the soft keyboard
/// has no business over the calendar or the dial. Two things used to raise
/// it: the picker opening in its text-entry mode, and the field left focused
/// behind the dialog — the input connection stayed open while the calendar
/// was up and the keyboard came back the moment it closed. Both are closed
/// here: the mode is named, and the focused field is dropped before the
/// picker opens and again once it returns.
library;

import 'package:flutter/material.dart';

/// Shows the platform's calendar, over [initialDate] between [firstDate] and
/// [lastDate], answering the day picked or null when it was dismissed.
Future<DateTime?> showDayPicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  _dropKeyboard();
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
  _dropKeyboard();
  return picked;
}

/// Shows the platform's clock, over [initialTime], answering the time picked
/// or null when it was dismissed.
Future<TimeOfDay?> showClockPicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) async {
  _dropKeyboard();
  final picked = await showTimePicker(
    context: context,
    initialTime: initialTime,
    // The dial, never the text entry (#504). Named even though it matches
    // today's default, so a changed default cannot start opening the keyboard.
    // ignore: avoid_redundant_argument_values
    initialEntryMode: TimePickerEntryMode.dial,
  );
  _dropKeyboard();
  return picked;
}

/// Drops whatever held the keyboard. Called before a picker opens, so nothing
/// is focused to restore when it closes, and after it returns, so a restored
/// focus does not bring the keyboard back with it (#504).
void _dropKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
