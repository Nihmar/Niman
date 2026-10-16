/// Ordering for the home-screen todo widget (issue 6).
///
/// The widget shows the same rows as the Todo tab's open view with its
/// default filter: every non-blank `todo.txt` line (frontmatter never
/// reaches the snapshot — the store skips it keeping indices), ordered
/// due-soonest first (overdue on top, undated last), ties broken by
/// priority (`(A)` first, unprioritized last), then creation date, then
/// file order. The single sort lives in `todo_filter.dart`; this file only
/// fixes the widget's input set (open file, no token/range narrowing) and
/// its row cap, so tab and widget can never disagree on ordering.
///
/// Pure Dart, no I/O: callers load the snapshot off the UI isolate per the
/// Android FUSE rule and pass it in.
library;

import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/todo/todo_store.dart';

/// Max rows pushed to one widget instance.
///
/// The widget rows are a scrollable `RemoteCollection`, so the cap is a
/// payload-size guard, not a visibility one: a home-screen glance rarely
/// scrolls past this, and the count text still names the true total via
/// the payload's `total` field. The widget links back to the tab for the
/// full list.
const int widgetTodoLimit = 100;

/// Open todos of [snapshot] in widget order, capped to [limit] rows.
///
/// Blank lines are dropped (the tab hides them too); everything else —
/// including `x`-completed lines an external tool may have left in
/// `todo.txt` — mirrors the tab's open view exactly.
List<TodoEntry> sortTodosForWidget(
  TodoSnapshot snapshot, {
  int limit = widgetTodoLimit,
}) {
  final sorted = _sortedOpen(snapshot);
  if (sorted.length <= limit) {
    return sorted;
  }
  return sorted.sublist(0, limit);
}

/// The open todos of [snapshot] in widget order, uncapped.
List<TodoEntry> _sortedOpen(TodoSnapshot snapshot) {
  final open = <TodoEntry>[
    for (final entry in snapshot.todo)
      if (entry.task.raw.trim().isNotEmpty) entry,
  ];
  // The range is always `all`, so the `today` argument never narrows: it
  // only feeds due-range comparisons the default filter does not use.
  return applyTodoFilter(open, const TodoFilter(), DateTime.now());
}

/// One section of the widget: the Todo tab's due-date section `id`, its
/// localized `label`, its true `count` and the `entries` it shows under
/// the row cap.
typedef WidgetTodoSection = ({
  String id,
  String label,
  int count,
  List<TodoEntry> entries,
});

/// The open todos of [snapshot] grouped like the Todo tab sorted by due
/// date (#1003): overdue, today, next 7 days, later, no date. Empty
/// sections are not produced.
///
/// [labelOf] names a section id (the caller owns the localization, so
/// this stays free of the UI layer); [today] defaults to now. The row cap
/// [limit] counts entries across all sections, in order: a section's
/// `count` stays its true count, and a section the cap leaves with no
/// entry is dropped, so the widget never draws a header over nothing.
List<WidgetTodoSection> widgetTodoSections(
  TodoSnapshot snapshot, {
  required String Function(String id) labelOf,
  DateTime? today,
  int limit = widgetTodoLimit,
}) {
  final sections = todoSections(
    _sortedOpen(snapshot),
    TodoSort.due,
    today ?? DateTime.now(),
  );
  final result = <WidgetTodoSection>[];
  var room = limit;
  for (final section in sections) {
    if (room <= 0) break;
    final shown = section.entries.length <= room
        ? section.entries
        : section.entries.sublist(0, room);
    room -= shown.length;
    result.add((
      id: section.id,
      label: labelOf(section.id),
      count: section.count,
      entries: shown,
    ));
  }
  return result;
}

/// The open (non-blank) todo count of [snapshot]: the widget's count
/// text, independent of the row cap.
int widgetTodoTotal(TodoSnapshot snapshot) {
  return snapshot.todo
      .where((entry) => entry.task.raw.trim().isNotEmpty)
      .length;
}
