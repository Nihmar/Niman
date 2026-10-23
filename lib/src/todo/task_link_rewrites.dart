/// The seam through which a rename or a move reaches the links in the tasks
/// (#1152).
///
/// The relocation flow lives in the library layer and knows nothing of the
// TODOfiles or their link map; the shell hands it one of these, built on
/// the map and the controller, and the flow asks it the question it asks the
/// index about the notes: what in the tasks named what is about to move.
library;

import 'package:niman/src/links/link_moves.dart';

/// What the tasks would have rewritten after a move, planned before it.
final class PendingTaskRewrite {
  /// A rewrite that changes tasks in [count] files, done by [apply].
  const new({required this.count, required this.apply});

  /// How many of the task files (`todo.txt`, `done.txt`) it would change.
  final int count;

  /// Writes the rewrite. It reads the files again as it goes, so an edit made
  /// since it was planned is kept, and a failure is the caller's to log.
  final Future<void> Function() apply;
}

/// Plans the rewrite of the links in the tasks that a move leaves behind.
abstract interface class TaskLinkRewrites {
  /// The rewrite for a move that carries [oldPaths] (library-relative, as
  /// the index has them) to where [moves] says, or null when no task link
  /// names any of them. Called before the move, while the index still says
  /// what each link named; [renamedFrom] and [renamedTo] are the old and new
  /// base names of a renamed file, as `rewriteMovedLinks` takes them.
  Future<PendingTaskRewrite?> plan({
    required Iterable<String> oldPaths,
    required LinkMoves moves,
    String? renamedFrom,
    String? renamedTo,
  });
}
