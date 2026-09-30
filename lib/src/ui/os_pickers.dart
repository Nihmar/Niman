/// Flutter's date and time dialogs, with the soft keyboard kept down (#504).
///
/// A date or a time is chosen, never typed, and on a phone the soft keyboard
/// has no business over the calendar or the dial. Two things used to raise
/// it: the picker opening in its text-entry mode, and the field left focused
/// behind the dialog — the input connection stayed open while the calendar
/// was up and the keyboard came back the moment it closed. Both are closed
/// here: the mode is named, and on the touch platforms the focused field is
/// dropped before the picker opens and again once it returns.
library;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Shows the calendar dialog, over [initialDate] between [firstDate] and
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

/// Shows the clock dialog, over [initialTime], answering the time picked
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

/// Drops whatever held the soft keyboard, on the touch platforms where one
/// can sit over the picker. Called before a dialog opens, so nothing is
/// focused to restore when it closes, and after it returns, so a restored
/// focus does not bring the keyboard back with it (#504). A desktop has no
/// soft keyboard, and unfocusing there would only steal focus from the
/// dialog.
void _dropKeyboard() {
  final touch =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!touch) return;
  FocusManager.instance.primaryFocus?.unfocus();
}
