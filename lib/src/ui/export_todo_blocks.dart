import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link_label.dart';
import 'package:niman/src/todo/todo_block_parser.dart';
import 'package:niman/src/todo/todo_block_query.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_block_shown.dart';
import 'package:niman/src/ui/todo_block_text.dart';

/// The lists a note's `todo` fences are at the moment of an export (#1152).
///
/// An export builds its page without reading anything: the tasks are asked
/// here, once, before it starts, and what they answer is plain data that goes
/// to wherever the page is built. The page is the list as it is then — not the
/// fence's source, and not the list as it was when the note was opened.
final class ExportTodoBlocks {
  /// The fences of notes over the tasks of [host].
  const new(this.host);

  /// The tasks, and the resolver for a note a block names.
  final NoteTasksHost host;

  /// The lists the closed `todo` fences of [text] are, by the key of their
  /// source, [text] being the note at library-relative [notePath].
  Future<PrintedTodoBlocks> of({
    required String text,
    required String notePath,
  }) async {
    final sources = ExportSources.todoBlockSources(text);
    if (sources.isEmpty) return const <String, PrintedTodoBlock>{};
    // A tick a moment ago is in the files; the list is told by the map the
    // tasks have been read into.
    await host.map.settled;
    final snapshot = host.snapshot ?? const TodoSnapshot(todo: [], done: []);
    final today = host.today;
    final blocks = <String, PrintedTodoBlock>{};
    for (final source in sources) {
      final key = todoBlockKey(source);
      if (blocks.containsKey(key)) continue;
      final block = TodoBlock.parse(source);
      final link = block.query.link;
      final named = link is LinkNote
          ? await host.resolveNote(link.target, from: notePath)
          : null;
      blocks[key] = printedTodoBlock(
        TodoBlockShown.of(
          block,
          snapshot: snapshot,
          tasksFor: host.map.tasksFor,
          notePath: notePath,
          today: today,
          named: named,
        ),
      );
    }
    return blocks;
  }
}

/// [shown] as words: the head the screen has, and the tasks with the links in
/// them as their labels, `(A)` and the due date after the words that carry
/// them.
PrintedTodoBlock printedTodoBlock(TodoBlockShown shown) {
  final problems = <String>[
    for (final error in shown.block.errors)
      '${todoBlockErrorText(error)} — ${AppStrings.todoBlockLine(error.line)}',
    if (shown.problem case final problem?)
      '$problem — ${AppStrings.todoBlockLine(shown.block.linkLine)}',
  ];
  final failed = problems.isNotEmpty;
  final tasks = <PrintedTodoTask>[
    if (!failed) ...[
      for (final entry in shown.tasks.open) (done: false, text: _words(entry)),
      for (final entry in shown.tasks.done) (done: true, text: _words(entry)),
    ],
  ];
  return PrintedTodoBlock(
    head: todoBlockHead(
      shown.block.query,
      count: failed ? null : shown.tasks.count,
    ),
    tasks: tasks,
    problems: problems,
    empty: !failed && tasks.isEmpty ? AppStrings.todoEmptyFiltered : null,
  );
}

/// One task as a line of a printed list: its priority, its words with their
/// links by label, its projects and contexts, and when it is due.
String _words(TodoEntry entry) {
  final task = entry.task;
  final due = task.due;
  return <String>[
    if (task.priority case final priority?) '($priority)',
    taskPlainText(task.description, markers: true),
    if (due != null) '— ${AppStrings.todoRowDue} ${formatTodoDate(due)}',
  ].join(' ');
}
