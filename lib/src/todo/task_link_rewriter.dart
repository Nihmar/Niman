/// The rewrite of the links in the tasks after a rename or a move (#1152).
library;

import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/rewrite.dart';
import 'package:niman/src/todo/task_line_edit.dart';
import 'package:niman/src/todo/task_link_rewrites.dart';
import 'package:niman/src/todo/task_links.dart';

/// Plans the rewrite from the task link map and writes it through the todo
/// store (`TodoController.replaceLines`).
///
/// The map answers which tasks have a link that resolved to a moved file
/// ([TaskLinkMap.movedBy]); each such task's line goes through
/// `rewriteMovedLinks`, the notes' own rewrite, with the links the map
/// resolved. A line is replaced by its text, so what the plan holds stays
/// right whatever happened to the file meanwhile.
final class TaskLinkRewriter implements TaskLinkRewrites {
  /// Plans over [map] and writes through [write].
  const new({required this.map, required this.write});

  /// The links of the tasks, resolved.
  final TaskLinkMap map;

  /// Writes the planned edits, one write for each file.
  final Future<void> Function(List<TaskLineEdit> edits) write;

  @override
  Future<PendingTaskRewrite?> plan({
    required Iterable<String> oldPaths,
    required LinkMoves moves,
    String? renamedFrom,
    String? renamedTo,
  }) async {
    // A build may be running for the tasks as they are: its answer is the
    // one to ask.
    await map.settled;
    final edits = <TaskLineEdit>[];
    for (final hit in map.movedBy(oldPaths)) {
      final raw = hit.entry.task.raw;
      final next = rewriteMovedLinks(
        raw,
        from: hit.file.path,
        moves: moves,
        renamedFrom: renamedFrom,
        renamedTo: renamedTo,
        resolved: hit.links,
      );
      if (next == raw) continue;
      edits.add(
        TaskLineEdit(
          file: hit.file,
          lineIndex: hit.entry.lineIndex,
          from: raw,
          to: next,
        ),
      );
    }
    if (edits.isEmpty) return null;
    return PendingTaskRewrite(
      count: {for (final edit in edits) edit.file}.length,
      apply: () => write(edits),
    );
  }
}
