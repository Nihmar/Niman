/// What a `todo` block shows at one moment (#1152): its lines read, and the
/// tasks they list.
library;

import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/task_link_hits.dart';
import 'package:niman/src/todo/todo_block_parser.dart';
import 'package:niman/src/todo/todo_block_query.dart';
import 'package:niman/src/todo/todo_block_run.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/strings.dart';

/// A block's [block] and the [tasks] it lists, for the screen and for an
/// export to draw alike.
///
/// A block with an error lists no tasks: a half-read filter would show a
/// list that looks right. A `link: [[Note]]` that names no note, or several,
/// is the same kind of fault — a row that says so, [problem], and no tasks.
final class TodoBlockShown {
  /// The tasks a [block] lists, with the note they are about and the trouble
  /// with the note it names, if any.
  const new({
    required this.block,
    required this.tasks,
    this.subject,
    this.problem,
  });

  /// Runs [block] against [snapshot].
  ///
  /// [tasksFor] is the task link map's question, [notePath] the note the block
  /// is in, and [named] what `link: [[Note]]` resolved to (asked of the
  /// resolver by whoever draws, as it is asked of the index).
  factory of(
    TodoBlock block, {
    required TodoSnapshot snapshot,
    required NoteTasks Function(String path) tasksFor,
    required String notePath,
    required DateTime today,
    ResolveResult? named,
  }) {
    final link = block.query.link;
    String? namedPath;
    String? problem;
    if (link is LinkNote) {
      switch (named) {
        case ResolvedNote(:final note):
          namedPath = note.path;
        case AmbiguousNote():
          problem = AppStrings.todoBlockSeveralNotes('[[${link.target}]]');
        case _:
          problem = AppStrings.todoBlockNoNote('[[${link.target}]]');
      }
    }
    final subject = switch (link) {
      LinkThis() => notePath,
      LinkNote() => namedPath,
      LinkAny() => null,
    };
    if (block.hasErrors || problem != null) {
      return TodoBlockShown(
        block: block,
        tasks: NoteTasks.none,
        subject: subject,
        problem: problem,
      );
    }
    return TodoBlockShown(
      block: block,
      tasks: runTodoBlock(
        block.query,
        snapshot: snapshot,
        tasksFor: tasksFor,
        notePath: notePath,
        namedPath: namedPath,
        today: today,
      ),
      subject: subject,
    );
  }

  /// The block, read.
  final TodoBlock block;

  /// The tasks it lists: none when it has an error or a [problem].
  final NoteTasks tasks;

  /// The note the list is about — the one that links these tasks — as a
  /// library-relative path; null for `link: any`, or a note not found. The
  /// link to it is not drawn on a row, and Add task links it.
  final String? subject;

  /// What is wrong with the note `link:` names, in words; null when nothing.
  final String? problem;
}
