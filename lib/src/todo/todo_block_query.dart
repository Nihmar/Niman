/// What a `todo` block asks for (#1152): the tasks that match every line
/// of it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/todo/todo_block_due.dart';

/// Whose tasks a block lists.
@immutable
sealed class TodoBlockLink {
  const new();
}

/// `link: this`, the default: the tasks that link the note the block is in.
final class LinkThis extends TodoBlockLink {
  /// The note's own tasks.
  const new();
}

/// `link: any`: every task, linked or not.
final class LinkAny extends TodoBlockLink {
  /// All the tasks.
  const new();
}

/// `link: [[Note]]`: the tasks that link another note.
final class LinkNote extends TodoBlockLink {
  /// The tasks that link the note [target] names, as a wikilink in the
  /// block's note would.
  const new(this.target);

  /// The note, as written between the brackets (heading and alias
  /// dropped).
  final String target;
}

/// Which of the two files a block lists tasks from.
enum TodoBlockDone {
  /// `done: no`, the default: the open tasks of `todo.txt`.
  no,

  /// `done: yes`: the completed tasks of `done.txt`.
  yes,

  /// `done: all`: both.
  all,
}

/// How a block orders its tasks.
enum TodoBlockSort {
  /// `sort: due`, the default: the soonest due first, undated last.
  due,

  /// `sort: priority`: `(A)` first, unprioritised last.
  priority,

  /// `sort: file`: as the file has them.
  file,
}

/// The question a `todo` block puts to the tasks: its [link], the tokens, the
/// [due] dates, the priorities [priorityFrom] to [priorityTo], [done] and
/// [sort], all of which must hold.
@immutable
final class TodoBlockQuery {
  /// A query; the defaults are an empty block's: the open tasks that link
  /// the note, soonest due first.
  const new({
    this.link = const LinkThis(),
    this.projects = const <String>[],
    this.contexts = const <String>[],
    this.tags = const <String>[],
    this.due,
    this.priorityFrom,
    this.priorityTo,
    this.done = TodoBlockDone.no,
    this.sort = TodoBlockSort.due,
  });

  /// Whose tasks.
  final TodoBlockLink link;

  /// The `+project` names a task must all carry, without the sigil.
  final List<String> projects;

  /// The `@context` names, without the sigil.
  final List<String> contexts;

  /// The `#tag` names, without the sigil.
  final List<String> tags;

  /// The due dates listed, or null for any.
  final TodoBlockDue? due;

  /// The first priority letter listed, or null for any (and for none).
  final String? priorityFrom;

  /// The last priority letter listed; equal to [priorityFrom] for one.
  final String? priorityTo;

  /// Which file.
  final TodoBlockDone done;

  /// The order.
  final TodoBlockSort sort;

  /// The tokens as the task filter writes them: `+house`, `@phone`, `#a`.
  Set<String> get tokens => <String>{
    for (final name in projects) '+$name',
    for (final name in contexts) '@$name',
    for (final name in tags) '#$name',
  };

  /// Whether a task of priority [letter] (null for none) is listed.
  bool priorityMatches(String? letter) {
    final from = priorityFrom;
    if (from == null) return true;
    if (letter == null) return false;
    return letter.compareTo(from) >= 0 && letter.compareTo(priorityTo!) <= 0;
  }
}
