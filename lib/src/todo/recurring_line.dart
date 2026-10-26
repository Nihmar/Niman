/// The next copy of a recurring task (#1189).
///
/// A task that carries a readable `rec:` does not end when it is completed:
/// the done line goes to `done.txt` as for any task, and [nextRecurringLine]
/// is the open line that goes back to `todo.txt` with the next due date. The
/// copy is a pure function of the line and the completion day, so two devices
/// that complete the same task the same day write the same line and the
/// record merge keeps it once (`docs/records/recurring-tasks.md`).
///
/// Pure Dart, no I/O.
library;

import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/todo/parser.dart';

/// What the first `rec:` tag of [task] says after the colon, or null when it
/// has none.
String? recurrenceValueOf(TodoTask task) {
  for (final tag in task.keyValues) {
    if (tag.key == 'rec') return tag.value;
  }
  return null;
}

/// The rule a task repeats by: its first `rec:` tag read as a
/// [RecurrenceRule], or null for a task with no `rec:` or one this grammar
/// does not read (which stays an unknown tag, as before).
RecurrenceRule? recurrenceRuleOf(TodoTask task) {
  final value = recurrenceValueOf(task);
  return value == null ? null : RecurrenceRule.parse(value);
}

/// The next copy of the open task on [line], completed on [today], or null
/// when it does not repeat: a completed line, a line with no `rec:` and one
/// whose `rec:` is not readable.
///
/// - `due:` is the rule's next date from the due date (a strict `rec:+`) or
///   from [today]; a task with no `due:` gains one, at the end;
/// - `t:` and `rem:`, when the line has them, move by the same number of
///   calendar days as `due:` did (a task with no `due:` counts from
///   [today]); `rem:` keeps its clock time;
/// - priority, text, links and every other tag stay where they are, so
///   outside the dates the line reads as it did;
/// - the creation date, if the line has one, becomes [today], as Simpletask
///   writes it.
String? nextRecurringLine(String line, DateTime today) {
  final task = parseTodoLine(line);
  if (task.completed) return null;
  final rule = recurrenceRuleOf(task);
  if (rule == null) return null;
  final completed = dateOnly(today);
  final oldDue = task.due;
  final newDue = rule.nextFor(completed: completed, due: oldDue);
  final shift = daysBetween(oldDue ?? completed, newDue);

  var description = task.description;
  if (oldDue == null) {
    description = '$description due:${formatTodoDate(newDue)}';
  } else {
    description = _replaceValue(
      description,
      'due',
      formatTodoDate(oldDue),
      formatTodoDate(newDue),
    );
  }
  final threshold = _threshold(task);
  if (threshold != null) {
    description = _replaceValue(
      description,
      't',
      formatTodoDate(threshold),
      formatTodoDate(addCalendarDays(threshold, shift)),
    );
  }
  final reminder = task.reminder;
  if (reminder != null) {
    description = _replaceValue(
      description,
      'rem',
      formatTodoStamp(reminder),
      formatTodoStamp(
        DateTime(
          reminder.year,
          reminder.month,
          reminder.day + shift,
          reminder.hour,
          reminder.minute,
        ),
      ),
    );
  }
  return formatTodoLine(
    completed: false,
    priority: task.priority,
    creationDate: task.creationDate == null ? null : completed,
    description: description,
  );
}

/// The first valid `t:YYYY-MM-DD` tag (the threshold date other todo.txt
/// tools write), or null.
DateTime? _threshold(TodoTask task) {
  for (final tag in task.keyValues) {
    if (tag.key == 't') {
      final date = parseIsoDate(tag.value);
      if (date != null) return date;
    }
  }
  return null;
}

/// [description] with the value of its first `key:from` tag, outside the
/// wikilinks, changed to [to] in place: whatever surrounds it is untouched.
String _replaceValue(String description, String key, String from, String to) {
  final tag = RegExp(
    '(?:^|\\s)${RegExp.escape(key)}:(${RegExp.escape(from)})'
    r'(?=\s|$)',
  );
  final match = tag.firstMatch(maskWikilinks(description));
  if (match == null) return description;
  return description.replaceRange(match.end - from.length, match.end, to);
}
