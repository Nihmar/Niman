/// A printed `todo` block as HTML (#1152).
library;

import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/printed_todo_block.dart';

/// The box ahead of an open task.
const String _open = '☐';

/// The box ahead of a done one.
const String _done = '☑';

/// [block] as a box: its head, then the tasks with their ☐ and ☑ as text
/// (a page has no checkbox to tick), the lines that could not be read, or the
/// line that says there is nothing.
String todoBlockHtml(PrintedTodoBlock block) {
  final failed = block.problems.isNotEmpty;
  final parts = block.head.split(' · ');
  final rest = parts.skip(1).map((part) => ' · ${escapeHtml(part)}');
  final out = StringBuffer()
    ..write('<div class="todo-block${failed ? ' todo-failed' : ''}">')
    ..write('<p class="todo-head"><strong>${escapeHtml(parts.first)}</strong>')
    ..write('${rest.join()}</p>');
  if (failed) {
    out.write('<ul class="todo-problems">');
    for (final problem in block.problems) {
      out.write('<li>${escapeHtml(problem)}</li>');
    }
    out.write('</ul>');
  } else if (block.tasks.isNotEmpty) {
    out.write('<ul class="todo-tasks">');
    for (final (:done, :text) in block.tasks) {
      out.write(
        '<li class="todo-task${done ? ' todo-done' : ''}">'
        '${done ? _done : _open} ${escapeHtml(text)}</li>',
      );
    }
    out.write('</ul>');
  } else if (block.empty case final empty?) {
    out.write('<p class="todo-empty">${escapeHtml(empty)}</p>');
  }
  out.write('</div>');
  return out.toString();
}
