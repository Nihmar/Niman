import 'package:meta/meta.dart';

/// What turning Todo and Calendar off took out of the alarm clock (#1109):
/// how many reminders each had scheduled, for the snackbar that offers to
/// turn it back on.
@immutable
final class ReminderCancellation {
  /// Counts of [todo] and [calendar] reminders cancelled.
  const new({this.todo = 0, this.calendar = 0});

  /// Nothing was cancelled: no switch went off, or none had a reminder.
  static const ReminderCancellation none = ReminderCancellation();

  /// Reminders `todo.txt` had scheduled.
  final int todo;

  /// Reminders `calendar.txt` had scheduled.
  final int calendar;

  /// Both together, the number the snackbar says.
  int get total => todo + calendar;

  @override
  bool operator ==(Object other) =>
      other is ReminderCancellation &&
      other.todo == todo &&
      other.calendar == calendar;

  @override
  int get hashCode => Object.hash(todo, calendar);

  @override
  String toString() => 'ReminderCancellation(todo: $todo, calendar: $calendar)';
}
