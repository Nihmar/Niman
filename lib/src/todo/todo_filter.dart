/// Filtering + sorting for the todo list (plan/todo-tab.md T-TD-05).
///
/// Pure logic, no widgets: the tab holds one [TodoFilter] (due range +
/// AND-ed token selection + sort key), narrows the visible file with
/// [applyTodoFilter], and feeds the chip bar with [tokenCountsFor] —
/// counts over the due-range-narrowed pool with the token selection
/// ignored, so chips show the pool they narrow and combos stay sane.
library;

import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:meta/meta.dart';

/// The due-date filter: one range (or all / no date).
enum TodoDueRange {
  /// Every task regardless of due date.
  all,

  /// Due before today.
  overdue,

  /// Due today.
  today,

  /// Due today through seven days out (inclusive).
  next7,

  /// No due date.
  noDate,
}

/// The sort key, each with its natural fixed direction.
enum TodoSort {
  /// Due soonest first (overdue on top), tasks without a due date last.
  due,

  /// Priority `(A)` first, tasks without a priority last.
  priority,

  /// Creation date newest first, tasks without one last.
  creation,
}

/// One token filter chip: the sigil disambiguates (`+p` vs `@p`).
///
/// Values come from the parser (`+`/`@`/`#` + `\S+`), so they never hold
/// whitespace and the first char is always the kind.
typedef TodoTokenRef = String;

/// The tab's list filter: due range, AND-ed token chips, sort key.
@immutable
final class TodoFilter {
  /// Creates a filter (defaults: everything, due-soonest first).
  const TodoFilter({
    this.dueRange = TodoDueRange.all,
    this.tokens = const <String>{},
    this.sort = TodoSort.due,
  });

  /// The selected due range.
  final TodoDueRange dueRange;

  /// The selected token chips (`+project` / `@context` / `#tag`).
  final Set<String> tokens;

  /// The sort key.
  final TodoSort sort;

  /// Copies the filter with replaced fields.
  TodoFilter copyWith({
    TodoDueRange? dueRange,
    Set<String>? tokens,
    TodoSort? sort,
  }) {
    return TodoFilter(
      dueRange: dueRange ?? this.dueRange,
      tokens: tokens ?? this.tokens,
      sort: sort ?? this.sort,
    );
  }

  /// Drops selected tokens absent from [available] (used when the
  /// visible file changes, so a stale chip never dead-ends the list).
  TodoFilter pruneTokens(Set<String> available) {
    if (tokens.every(available.contains)) {
      return this;
    }
    return copyWith(
      tokens: <String>{
        for (final token in tokens)
          if (available.contains(token)) token,
      },
    );
  }

  /// Whether [task] passes the due range and every selected token.
  bool matches(TodoTask task, DateTime today) {
    if (!_dueInRange(task.due, today, dueRange)) {
      return false;
    }
    for (final token in tokens) {
      if (token.length < 2 || !_matchesToken(task, token)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is TodoFilter &&
        other.dueRange == dueRange &&
        other.sort == sort &&
        other.tokens.length == tokens.length &&
        other.tokens.containsAll(tokens);
  }

  @override
  int get hashCode => Object.hash(dueRange, sort, Object.hashAll(tokens));
}

/// Narrows [entries] by [filter] against [today] and sorts the survivors.
List<TodoEntry> applyTodoFilter(
  List<TodoEntry> entries,
  TodoFilter filter,
  DateTime today,
) {
  final kept = <TodoEntry>[
    for (final entry in entries)
      if (filter.matches(entry.task, today)) entry,
  ]..sort((a, b) => _compareEntries(a, b, filter.sort));
  return kept;
}

/// Token chips for [entries] narrowed by [range] only (the token
/// selection ignored): `(token, task count)` ranked by count desc, then
/// token asc. Each task counts once per token it carries.
List<({String token, int count})> tokenCountsFor(
  List<TodoEntry> entries,
  TodoDueRange range,
  DateTime today,
) {
  final probe = TodoFilter(dueRange: range);
  final counts = <String, int>{};
  for (final entry in entries) {
    final task = entry.task;
    if (!probe.matches(task, today)) {
      continue;
    }
    for (final token in _taskTokens(task)) {
      counts[token] = (counts[token] ?? 0) + 1;
    }
  }
  final ranked = <({String token, int count})>[
    for (final e in counts.entries) (token: e.key, count: e.value),
  ]..sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : a.token.compareTo(b.token);
  });
  return ranked;
}

/// All token refs of [task] (deduped per task for counting).
Set<String> _taskTokens(TodoTask task) {
  return <String>{
    for (final value in task.projects) '+$value',
    for (final value in task.contexts) '@$value',
    for (final value in task.hashtags) '#$value',
  };
}

/// Whether [task] carries the selected [token] (`+`/`@`/`#` + value).
bool _matchesToken(TodoTask task, String token) {
  final value = token.substring(1);
  return switch (token[0]) {
    '+' => task.projects.contains(value),
    '@' => task.contexts.contains(value),
    '#' => task.hashtags.contains(value),
    _ => false,
  };
}

/// Whether [due] falls in [range] against [today] (day precision).
bool _dueInRange(DateTime? due, DateTime today, TodoDueRange range) {
  switch (range) {
    case TodoDueRange.all:
      return true;
    case TodoDueRange.noDate:
      return due == null;
    case TodoDueRange.overdue:
      return due != null && _day(due).isBefore(_day(today));
    case TodoDueRange.today:
      return due != null && _day(due) == _day(today);
    case TodoDueRange.next7:
      if (due == null) {
        return false;
      }
      final day = _day(due);
      final start = _day(today);
      final end = start.add(const Duration(days: 7));
      return !day.isBefore(start) && !day.isAfter(end);
  }
}

/// Truncates [date] to day precision for due comparisons.
DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

/// Compares two entries by [sort], deterministically (line index breaks
/// every tie, since list sort is not stable).
int _compareEntries(TodoEntry a, TodoEntry b, TodoSort sort) {
  int result;
  switch (sort) {
    case TodoSort.due:
      result = _compareDue(a.task.due, b.task.due);
      if (result == 0) {
        result = _comparePriority(a.task.priority, b.task.priority);
      }
      if (result == 0) {
        result = _compareCreation(a.task.creationDate, b.task.creationDate);
      }
    case TodoSort.priority:
      result = _comparePriority(a.task.priority, b.task.priority);
      if (result == 0) {
        result = _compareDue(a.task.due, b.task.due);
      }
      if (result == 0) {
        result = _compareCreation(a.task.creationDate, b.task.creationDate);
      }
    case TodoSort.creation:
      result = _compareCreation(a.task.creationDate, b.task.creationDate);
      if (result == 0) {
        result = _comparePriority(a.task.priority, b.task.priority);
      }
      if (result == 0) {
        result = _compareDue(a.task.due, b.task.due);
      }
  }
  return result != 0
      ? result
      : a.lineIndex.compareTo(b.lineIndex);
}

/// Due soonest first, tasks without a due date last.
int _compareDue(DateTime? a, DateTime? b) {
  if (a == null) {
    return b == null ? 0 : 1;
  }
  if (b == null) {
    return -1;
  }
  return _day(a).compareTo(_day(b));
}

/// Priority `(A)` first, tasks without a priority last.
int _comparePriority(String? a, String? b) {
  if (a == null) {
    return b == null ? 0 : 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

/// Creation newest first, tasks without one last.
int _compareCreation(DateTime? a, DateTime? b) {
  if (a == null) {
    return b == null ? 0 : 1;
  }
  if (b == null) {
    return -1;
  }
  return b.compareTo(a);
}
