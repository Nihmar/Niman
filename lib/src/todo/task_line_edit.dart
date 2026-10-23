/// A planned change of one task line, applied by text (#1152).
///
/// The rename rewrite plans its edits from a snapshot, and the file may have
/// moved on by the time they are written: another tool added a line above,
/// or edited the task. An edit therefore names the line by its old text, and
/// the index it had is only a hint of where to look first.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/todo/task_link.dart' show TaskFile;

/// One line of `todo.txt` or `done.txt` to be replaced by another.
@immutable
final class TaskLineEdit {
  /// Replaces [from], which stood at [lineIndex] of [file], with [to].
  const new({
    required this.file,
    required this.lineIndex,
    required this.from,
    required this.to,
  });

  /// The file the line is in.
  final TaskFile file;

  /// The 0-based index the line had when the edit was planned.
  final int lineIndex;

  /// The line as planned against, without its line ending.
  final String from;

  /// The line to write in its place.
  final String to;
}

/// Replaces in [lines] each line the [edits] name, in place, and tells how
/// many were replaced. Every other line is left as it is.
///
/// An edit finds its line at its planned index when that still holds the old
/// text, and otherwise at the first line that does and that no earlier edit
/// has replaced; a line that is no longer there (edited or removed by
/// another tool) is skipped, never replaced by guesswork.
int applyLineEdits(List<String> lines, Iterable<TaskLineEdit> edits) {
  final replaced = <int>{};
  for (final edit in edits) {
    var at = -1;
    final planned = edit.lineIndex;
    if (planned >= 0 &&
        planned < lines.length &&
        lines[planned] == edit.from &&
        !replaced.contains(planned)) {
      at = planned;
    } else {
      for (var i = 0; i < lines.length; i++) {
        if (lines[i] == edit.from && !replaced.contains(i)) {
          at = i;
          break;
        }
      }
    }
    if (at < 0) continue;
    lines[at] = edit.to;
    replaced.add(at);
  }
  return replaced.length;
}

/// Removes from [lines] the last line equal to each of [wanted], in place,
/// and tells how many were removed (Undo of a move to tasks, #1152). A line
/// that is not there -- changed or removed by another tool since -- is
/// skipped, and every other line is left as it is.
int removeLastEqual(List<String> lines, Iterable<String> wanted) {
  var removed = 0;
  for (final line in wanted) {
    final at = lines.lastIndexOf(line);
    if (at < 0) continue;
    lines.removeAt(at);
    removed++;
  }
  return removed;
}
