/// What the todo list shows, derived from a snapshot (#1003).
///
/// Pure logic, no widgets: the open file is narrowed and sorted by the
/// filter and cut into sections, and `done.txt` is narrowed by the same
/// filter into the Done section. The derivation is the costly part (a pass
/// over every line, a sort); folding a section only changes which rows
/// `items` lists, so the tab derives a model once per snapshot and filter
/// and reads `items` for every fold.
library;

import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/todo/todo_store.dart';

export 'package:niman/src/todo/todo_list_item.dart';

/// The sections of the open list and the entries of the Done section.
final class TodoListModel {
  /// Creates a model from its parts; see `derive`.
  new({
    required this.sections,
    required this._done,
    required this.openTotal,
    required this.doneTotal,
  });

  /// Derives the model of [snapshot] under [filter] as of [today].
  ///
  /// Blank lines are not tasks and are dropped. [hidden] holds entries a
  /// swipe already removed from the screen while their delete is still
  /// being written.
  factory derive(
    TodoSnapshot snapshot,
    TodoFilter filter,
    DateTime today, {
    Set<TodoEntry> hidden = const <TodoEntry>{},
  }) {
    final open = <TodoEntry>[
      for (final entry in snapshot.todo)
        if (entry.task.raw.trim().isNotEmpty) entry,
    ];
    final done = <TodoEntry>[
      for (final entry in snapshot.done)
        if (entry.task.raw.trim().isNotEmpty) entry,
    ];
    final shownOpen = <TodoEntry>[
      for (final entry in applyTodoFilter(open, filter, today))
        if (!hidden.contains(entry)) entry,
    ];
    // Narrowed but not ordered yet: the Done section orders its entries
    // once it is open, and a folded one only needs the count.
    final shownDone = <TodoEntry>[
      for (final entry in done)
        if (filter.matches(entry.task, today) && !hidden.contains(entry)) entry,
    ];
    return TodoListModel(
      sections: todoSections(shownOpen, filter.sort, today),
      done: shownDone,
      openTotal: open.length,
      doneTotal: done.length,
    );
  }

  /// The open list's non-empty sections, in display order.
  final List<TodoSection> sections;

  /// How many open tasks there are, whatever the filter.
  final int openTotal;

  /// How many completed tasks there are, whatever the filter.
  final int doneTotal;

  final List<TodoEntry> _done;
  List<TodoEntry>? _doneSorted;

  /// How many open tasks the filter leaves.
  int get openShown {
    var count = 0;
    for (final section in sections) {
      count += section.count;
    }
    return count;
  }

  /// How many completed tasks the filter leaves (the Done header's count).
  int get doneShown => _done.length;

  /// Whether there is no task at all, in either file.
  bool get hasNoTasks => openTotal == 0 && doneTotal == 0;

  /// Whether the filter leaves nothing to show.
  bool get isEmpty => sections.isEmpty && _done.isEmpty;

  /// The completed entries the filter leaves, newest completion first.
  /// Sorted on the first read, which only an open Done section makes.
  List<TodoEntry> get doneEntries => _doneSorted ??= sortDoneEntries(_done);

  /// The flattened list under the sections [collapsed]: a header per
  /// section (none for the flat list's single section), then its rows
  /// unless it is folded; the Done section last.
  List<TodoListItem> items(Set<String> collapsed) {
    final items = <TodoListItem>[];
    for (final section in sections) {
      final folded = collapsed.contains(section.id);
      if (section.id != todoAllSectionId) {
        items.add(
          TodoHeaderItem(
            section: section.id,
            count: section.count,
            collapsed: folded,
          ),
        );
      }
      if (!folded || section.id == todoAllSectionId) {
        for (final entry in section.entries) {
          items.add(TodoRowItem(entry: entry, done: false));
        }
      }
    }
    if (_done.isNotEmpty) {
      final folded = collapsed.contains(todoDoneSectionId);
      items.add(
        TodoHeaderItem(
          section: todoDoneSectionId,
          count: _done.length,
          collapsed: folded,
        ),
      );
      if (!folded) {
        for (final entry in doneEntries) {
          items.add(TodoRowItem(entry: entry, done: true));
        }
      }
    }
    return items;
  }
}
