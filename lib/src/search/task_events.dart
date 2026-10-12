/// A lone `+project` or `@context` in the search box, and the rows it
/// answers with (#730): the tasks and events already in memory.
///
/// The index holds the notes' words and nothing else, and `todo.txt` /
/// `calendar.txt` are no exception — a lone token reads the snapshots the
/// task list and the journal already hold (`TodoController.snapshot`,
/// `CalendarController.snapshot`), so the group costs one walk of the two
/// files in memory and nothing on disk.
///
/// Pure Dart: the models in, the rows out, no widget and no notifier (the
/// screen's seam is `ui/search_task_events.dart`).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';

/// The lone `+project`/`@context` token [userText] is, or null.
///
/// Exactly one whitespace-separated token that opens with `+` or `@` and
/// carries something after the sigil: `+thesis`, `@phone`. `#tag` is the
/// Tags screen's own mode, and anything else — a second token, a
/// `key = value` filter, a bare `+` — stays a word search.
String? taskEventQuery(String userText) {
  final text = userText.trim();
  if (text.length < 2) return null;
  final sigil = text[0];
  if (sigil != '+' && sigil != '@') return null;
  if (text.contains(RegExp(r'\s'))) return null;
  return text;
}

/// What one row of the Tasks and events group is.
enum TaskEventKind {
  /// An event of a `calendar.txt` day line.
  event,

  /// A week, month or year goal of `calendar.txt`.
  goal,

  /// An open task of `todo.txt`.
  task,
}

/// One row of the group: a task, an event or a goal, with the line it
/// sits on.
@immutable
final class TaskEventHit {
  /// Creates a row.
  const new({
    required this.kind,
    required this.lineIndex,
    this.event,
    this.goal,
    this.task,
  });

  /// What the row is.
  final TaskEventKind kind;

  /// The 0-based line in the row's own file: `calendar.txt` for an event
  /// or a goal, `todo.txt` for a task (what a tap opens at).
  final int lineIndex;

  /// The event, when [kind] is [TaskEventKind.event].
  final CalendarEntryEvent? event;

  /// The goal's line, when [kind] is [TaskEventKind.goal].
  final CalendarLine? goal;

  /// The task, when [kind] is [TaskEventKind.task].
  final TodoTask? task;

  /// The day the row is about: an event's day, the day a goal's head
  /// names, a task's due date — null for a task with none.
  DateTime? get day => switch (kind) {
    TaskEventKind.event => event?.line.date,
    TaskEventKind.goal => goal?.date,
    TaskEventKind.task => task?.due,
  };

  @override
  String toString() =>
      'TaskEventHit(${kind.name}, line $lineIndex, ${task?.description})';
}

/// The rows the lone [token] answers with, from the two files already in
/// memory.
///
/// The events of [calendar] that carry it, in file order; then its goals,
/// a week's before a month's before a year's, as the journal shows a
/// day's; then the open tasks of [tasks], in file order.
///
/// A line is here because it carries exactly [token]: `+Thesis` is not
/// `+thesis`, the way the task list's own token chips read them.
List<TaskEventHit> taskEventHits(
  String token, {
  required List<TodoEntry> tasks,
  required List<CalendarEntry> calendar,
}) {
  if (token.length < 2) return const [];
  final sigil = token[0];
  final value = token.substring(1);
  final kind = switch (sigil) {
    '+' => CalendarTokenKind.project,
    '@' => CalendarTokenKind.context,
    _ => null,
  };
  if (kind == null || value.isEmpty) return const [];
  final hits = <TaskEventHit>[];

  for (final entry in calendar) {
    if (entry.line.kind != CalendarLineKind.day) continue;
    for (final event in entry.line.events) {
      if (!_carries(event.tokens, kind, value)) continue;
      hits.add(
        TaskEventHit(
          kind: TaskEventKind.event,
          lineIndex: entry.lineIndex,
          event: CalendarEntryEvent(
            lineIndex: entry.lineIndex,
            line: entry.line,
            event: event,
          ),
        ),
      );
    }
  }
  for (final goal in const [
    CalendarLineKind.weekGoal,
    CalendarLineKind.monthGoal,
    CalendarLineKind.yearGoal,
  ]) {
    for (final entry in calendar) {
      if (entry.line.kind != goal) continue;
      if (!_carries(entry.line.tokens, kind, value)) continue;
      hits.add(
        TaskEventHit(
          kind: TaskEventKind.goal,
          lineIndex: entry.lineIndex,
          goal: entry.line,
        ),
      );
    }
  }
  for (final entry in tasks) {
    final task = entry.task;
    if (task.completed) continue;
    final carries = kind == CalendarTokenKind.project
        ? task.projects.contains(value)
        : task.contexts.contains(value);
    if (!carries) continue;
    hits.add(
      TaskEventHit(
        kind: TaskEventKind.task,
        lineIndex: entry.lineIndex,
        task: task,
      ),
    );
  }
  return hits;
}

/// Whether [tokens] holds one of [kind] whose value is exactly [value].
bool _carries(
  List<CalendarToken> tokens,
  CalendarTokenKind kind,
  String value,
) {
  for (final token in tokens) {
    if (token.kind == kind && token.value == value) return true;
  }
  return false;
}
