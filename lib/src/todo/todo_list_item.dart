import 'package:meta/meta.dart';
import 'package:niman/src/todo/todo_store.dart';

/// One line of the flattened todo list (#1003): a section header or a task
/// row. The list is a single lazy builder over these, so a file of a
/// million lines builds only the rows on screen.
@immutable
sealed class TodoListItem {
  /// Creates an item.
  const new();

  /// A stable identity: what the keyboard's selection is made of. Two items
  /// are the same item across rebuilds when their ids are equal.
  String get id;
}

/// The header of a section: its stable [section] id, the entries it holds
/// after the filter, and whether it is folded.
final class TodoHeaderItem extends TodoListItem {
  /// Creates the header of [section] holding [count] entries.
  const new({
    required this.section,
    required this.count,
    required this.collapsed,
  });

  /// The section id (see `todoSections`).
  final String section;

  /// How many entries the section holds after the filter.
  final int count;

  /// Whether the section is folded: its rows are not among the items.
  final bool collapsed;

  @override
  String get id => 'section:$section';
}

/// A task row, with the file it belongs to.
///
/// A line index means nothing without its file, and a `todo.txt` line that
/// is already marked done (awaiting migration) still lives in `todo.txt`:
/// the row remembers where it was read from rather than guessing from the
/// task.
final class TodoRowItem extends TodoListItem {
  /// Creates the row of [entry] read from `done.txt` when [done], else from
  /// `todo.txt`.
  const new({required this.entry, required this.done});

  /// The task with its line index in its file.
  final TodoEntry entry;

  /// Whether the entry is a line of `done.txt`.
  final bool done;

  /// `done` or `open`: the file, as the rows' keys spell it.
  String get view => done ? 'done' : 'open';

  @override
  String get id => todoRowId(done: done, line: entry.lineIndex);
}

/// The id of the row at [line] of `done.txt` (or `todo.txt`).
String todoRowId({required bool done, required int line}) =>
    '${done ? 'done' : 'open'}:$line';
