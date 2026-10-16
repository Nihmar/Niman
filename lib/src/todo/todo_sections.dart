/// Grouping of the todo list into sections that follow the sort key
/// (#1003).
///
/// Pure logic, no widgets and no I/O: the tab narrows and sorts the open
/// file with `applyTodoFilter`, then [todoSections] groups the sorted list.
/// Grouping is one pass that collects each section's entries in the order
/// they arrive, followed by a sort of the (few) sections by rank: it does
/// not lean on the entries of a section lying side by side, so the section
/// order is the rank's and never the sort's by accident. An empty section
/// is never produced.
library;

import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_section.dart';
import 'package:niman/src/todo/todo_store.dart';

export 'package:niman/src/todo/todo_section.dart';

/// The id of the Done section: the entries of `done.txt`, shown last.
const String todoDoneSectionId = 'done';

/// The id of the single section of a flat list (sorted by creation date).
///
/// The UI draws no header for it.
const String todoAllSectionId = 'all';

/// Due before today.
const String todoDueOverdueSectionId = 'due.overdue';

/// Due today.
const String todoDueTodaySectionId = 'due.today';

/// Due tomorrow through seven days out (inclusive).
const String todoDueNext7SectionId = 'due.next7';

/// Due after the next-7 window.
const String todoDueLaterSectionId = 'due.later';

/// No due date.
const String todoDueNoneSectionId = 'due.none';

/// The id prefix of a priority section; the letter follows (`priority.A`).
const String todoPrioritySectionPrefix = 'priority.';

/// The id of the section of tasks without a priority.
const String todoPriorityNoneSectionId = 'priority.none';

/// The due sections in the order they are shown.
const List<String> _dueOrder = <String>[
  todoDueOverdueSectionId,
  todoDueTodaySectionId,
  todoDueNext7SectionId,
  todoDueLaterSectionId,
  todoDueNoneSectionId,
];

/// Cuts [sorted] (already filtered and sorted by `applyTodoFilter` under
/// [sort]) into sections against [today].
///
/// - [TodoSort.due]: overdue, today, next 7 days (tomorrow through today
///   plus seven calendar days), later, no date.
/// - [TodoSort.priority]: one section per letter present, `A` first, then
///   the tasks without a priority.
/// - [TodoSort.creation]: a single [todoAllSectionId] section.
///
/// Entries keep the order they arrive in inside a section; sections that
/// would be empty are dropped.
List<TodoSection> todoSections(
  List<TodoEntry> sorted,
  TodoSort sort,
  DateTime today,
) {
  if (sorted.isEmpty) {
    return const <TodoSection>[];
  }
  switch (sort) {
    case TodoSort.creation:
      return <TodoSection>[
        TodoSection(id: todoAllSectionId, entries: List.of(sorted)),
      ];
    case TodoSort.due:
      final start = DateTime(today.year, today.month, today.day);
      final tomorrow = addCalendarDays(start, 1);
      final weekEnd = addCalendarDays(start, 7);
      return _bucket(
        sorted,
        (entry) => _dueSectionId(entry.task.due, start, tomorrow, weekEnd),
        _dueOrder.indexOf,
      );
    case TodoSort.priority:
      return _bucket(
        sorted,
        (entry) => _prioritySectionId(entry.task.priority),
        _priorityRank,
      );
  }
}

/// Orders the completed entries of `done.txt` for the Done section:
/// newest completion date first, those without one last, and between equal
/// dates the later file line first (the file is appended to, so a later
/// line is the newer completion).
List<TodoEntry> sortDoneEntries(List<TodoEntry> done) {
  return List<TodoEntry>.of(done)..sort((a, b) {
    final left = a.task.completionDate;
    final right = b.task.completionDate;
    if (left == null || right == null) {
      if (left != null) {
        return -1;
      }
      if (right != null) {
        return 1;
      }
    } else {
      final byDay = _dayKey(right).compareTo(_dayKey(left));
      if (byDay != 0) {
        return byDay;
      }
    }
    return b.lineIndex.compareTo(a.lineIndex);
  });
}

/// The section id of a task due on [due], against the day boundaries.
String _dueSectionId(
  DateTime? due,
  DateTime today,
  DateTime tomorrow,
  DateTime weekEnd,
) {
  if (due == null) {
    return todoDueNoneSectionId;
  }
  final day = DateTime(due.year, due.month, due.day);
  if (day.isBefore(today)) {
    return todoDueOverdueSectionId;
  }
  if (day.isBefore(tomorrow)) {
    return todoDueTodaySectionId;
  }
  if (!day.isAfter(weekEnd)) {
    return todoDueNext7SectionId;
  }
  return todoDueLaterSectionId;
}

/// The section id of a task with [priority] (`A`…`Z` or null).
String _prioritySectionId(String? priority) {
  return priority == null
      ? todoPriorityNoneSectionId
      : '$todoPrioritySectionPrefix$priority';
}

/// Sort rank of a priority section id: letters in order, none last.
int _priorityRank(String id) {
  return id == todoPriorityNoneSectionId
      ? 1 << 30
      : id.codeUnitAt(todoPrioritySectionPrefix.length);
}

/// Groups [sorted] by [idOf], keeping the incoming order inside a group,
/// and returns the groups ordered by [rankOf] of their id.
List<TodoSection> _bucket(
  List<TodoEntry> sorted,
  String Function(TodoEntry) idOf,
  int Function(String) rankOf,
) {
  final groups = <String, List<TodoEntry>>{};
  for (final entry in sorted) {
    (groups[idOf(entry)] ??= <TodoEntry>[]).add(entry);
  }
  final ids = groups.keys.toList()
    ..sort((a, b) => rankOf(a).compareTo(rankOf(b)));
  return <TodoSection>[
    for (final id in ids) TodoSection(id: id, entries: groups[id]!),
  ];
}

/// A day-precision sortable key, so a completion stamp's time of day (or a
/// DST offset) never decides between two dates.
int _dayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
