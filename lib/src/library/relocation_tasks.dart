/// The part of a relocation that concerns the tasks' links (#1152).
library;

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/todo/task_link_rewrites.dart';
import 'package:path/path.dart' as p;

/// The old and new base names of what a move from [from] to [to] renamed:
/// the one case a bare-name wikilink follows. Both are null for a folder,
/// whose members keep their names, and for a move that keeps the name.
({String? from, String? to}) renamedBaseNames(
  String from,
  String to, {
  required bool isDir,
}) {
  if (isDir) return (from: null, to: null);
  final oldName = p.basename(from);
  final newName = p.basename(to);
  return oldName == newName
      ? (from: null, to: null)
      : (from: oldName, to: newName);
}

/// What the tasks' links would have rewritten after the move of [from] to
/// [to] that carries [oldPaths] along as [moves] says, asked of [seam]
/// before the move. Null when there is no seam, no task names a moved file,
/// or the question failed: the notes' rewrite goes on without it.
Future<PendingTaskRewrite?> planTaskRewrite(
  TaskLinkRewrites? seam, {
  required List<String> oldPaths,
  required LinkMoves moves,
  required String from,
  required String to,
  required bool isDir,
}) async {
  if (seam == null) return null;
  final names = renamedBaseNames(from, to, isDir: isDir);
  try {
    return await seam.plan(
      oldPaths: oldPaths,
      moves: moves,
      renamedFrom: names.from,
      renamedTo: names.to,
    );
  } on Object catch (error) {
    const AppLogger(name: 'links')
        .warning('could not read the links in the tasks: $error');
    return null;
  }
}

/// Writes [tasks]. The move and the rewrite of the notes are done: a
/// failure here is logged and undoes nothing.
Future<void> applyTaskRewrite(PendingTaskRewrite? tasks) async {
  if (tasks == null) return;
  try {
    await tasks.apply();
  } on Object catch (error) {
    const AppLogger(name: 'links')
        .warning('could not rewrite the links in the tasks: $error');
  }
}
