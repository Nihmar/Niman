import 'package:meta/meta.dart';
import 'package:niman/src/todo/todo_store.dart';

/// One group of the todo list: a stable [id] the UI maps to a heading and
/// remembers as collapsed, and the [entries] under it in list order.
@immutable
final class TodoSection {
  /// Creates a section [id] holding [entries].
  const new({required this.id, required this.entries});

  /// The stable id (`due.overdue`, `priority.A`, `all`, `done`, ...).
  ///
  /// Persisted per device for the collapsed sections, so an id never
  /// changes its spelling once shipped.
  final String id;

  /// The entries of the section, in the order they were received.
  final List<TodoEntry> entries;

  /// The number of entries (what the section header shows).
  int get count => entries.length;
}
