/// Moving notes and folders by dragging them in the tree (#567): a row is
/// dragged, and where it is let go is the folder it moves into — the same
/// move as the menu's Move, its destination taken from the drop.
///
/// A folder's row takes a drop into the folder, a note's row into the
/// note's folder, the tree's empty space into the library's root. A folder
/// dropped into itself or under itself, or anything dropped where it
/// already is, does nothing, and the row under it does not light up.
///
/// Dragging one of several marked rows carries them all (#996): the drop
/// moves the marked paths a move would change, and none of the others.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';

/// Moves the items at [paths] into the folder named second, `''` the root.
typedef TreeMove = void Function(List<String> paths, String folder);

/// Whether [path] dropped into [folder] moves anything: not into itself,
/// not under itself, not where it already is.
bool treeDropMoves(String path, String folder) =>
    path != folder && !isUnder(path, folder) && parentOf(path) != folder;

/// The paths of [paths] a drop into [folder] would move, in the order
/// given: what a drop hands to [TreeMove]. A marked folder carries its
/// contents — a path inside one goes with it — so paths inside another of
/// [paths] are still listed and the move skips them.
List<String> treeDropPaths(Iterable<String> paths, String folder) => [
  for (final path in paths)
    if (treeDropMoves(path, folder)) path,
];

/// [child], the row of [note], dragged and dropped on.
///
/// With a mouse the row is dragged as it is pulled; by touch it is held
/// first, so a finger still scrolls the tree — and a hold let go where it
/// started is the long press it always was ([onLongPress], the menu).
final class TreeRowDrag extends StatefulWidget {
  /// Makes [note]'s row, [child], move by [onMove].
  const new({
    required this.note,
    required this.onMove,
    required this.child,
    this.paths,
    this.onLongPress,
    super.key,
  });

  /// The row's note or folder.
  final Note note;

  /// Runs a drop.
  final TreeMove onMove;

  /// The paths the drag carries: the marked rows' when the row is one of
  /// several marked (#996), else [note]'s path alone.
  final List<String>? paths;

  /// The long press a touch hold is when it does not move.
  final VoidCallback? onLongPress;

  /// The row as drawn.
  final Widget child;

  /// The row being dragged, while one is: what a drop outside the tree —
  /// an open note, which takes a link to it (#704) — asks of it, the drag
  /// itself carrying the paths.
  static final ValueNotifier<Note?> dragged = ValueNotifier<Note?>(null);

  /// Whether rows are held before they drag: the touch platforms'.
  static bool get holdToDrag => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };

  @override
  State<TreeRowDrag> createState() => _TreeRowDragState();
}

final class _TreeRowDragState extends State<TreeRowDrag> {
  /// How far a touch drag has gone: kept across the rebuilds the drag
  /// itself causes, as the row under it lights up and goes dark.
  double _travelled = 0;

  Note get note => widget.note;

  /// The paths the drag carries.
  List<String> get paths => widget.paths ?? [note.path];

  /// The folder a drop on this row moves into.
  String get _folder => note.isDir ? note.path : parentOf(note.path);

  @override
  Widget build(BuildContext context) {
    final folder = _folder;
    return DragTarget<List<String>>(
      // The row claims every drop over it, even one it will not run: let
      // through, it would reach the tree's root and move there.
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final movable = treeDropPaths(details.data, folder);
        if (movable.isNotEmpty) widget.onMove(movable, folder);
      },
      builder: (context, candidates, _) {
        final lit =
            candidates.isNotEmpty &&
            candidates.first != null &&
            treeDropPaths(candidates.first!, folder).isNotEmpty;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: lit
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
                : null,
          ),
          child: _draggable(context),
        );
      },
    );
  }

  Widget _draggable(BuildContext context) {
    final feedback = _TreeDragFeedback(note: note, paths: paths);
    final child = widget.child;
    final dimmed = Opacity(opacity: 0.4, child: child);
    if (!TreeRowDrag.holdToDrag) {
      return Draggable<List<String>>(
        data: paths,
        feedback: feedback,
        childWhenDragging: dimmed,
        // The pointer is where the drag is: a note it is let go on puts the
        // link where the pointer stands, which the drop reports only this
        // way (#704).
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => TreeRowDrag.dragged.value = note,
        onDragEnd: (_) => TreeRowDrag.dragged.value = null,
        child: child,
      );
    }
    return LongPressDraggable<List<String>>(
      data: paths,
      feedback: feedback,
      childWhenDragging: dimmed,
      onDragStarted: () => _travelled = 0,
      onDragUpdate: (details) => _travelled += details.delta.distance,
      // Let go where it was held — over its own row, which claims the drop
      // and moves nothing — the hold was a long press.
      onDragEnd: (_) {
        if (_travelled < kTouchSlop) widget.onLongPress?.call();
      },
      child: child,
    );
  }
}

/// The tree's empty space as a place to drop: into the library's root.
final class TreeRootDrop extends StatelessWidget {
  /// Makes [child], the tree, take a drop into the root by [onMove].
  const new({required this.onMove, required this.child, super.key});

  /// Runs a drop.
  final TreeMove onMove;

  /// The tree.
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<List<String>>(
    onWillAcceptWithDetails: (details) =>
        treeDropPaths(details.data, '').isNotEmpty,
    onAcceptWithDetails: (details) {
      final movable = treeDropPaths(details.data, '');
      if (movable.isNotEmpty) onMove(movable, '');
    },
    builder: (context, candidates, _) => child,
  );
}

/// A part of the tree that is no place to drop — the pinned block's heading
/// and divider: it claims a drop over it and runs none, so the drop does not
/// fall through to the root (#574).
final class TreeDropShield extends StatelessWidget {
  /// Makes [child] take no drop.
  const new({required this.child, super.key});

  /// The part shielded.
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<List<String>>(
    onWillAcceptWithDetails: (_) => true,
    builder: (context, candidates, _) => child,
  );
}

/// What follows the pointer: the row's icon and name on a card — several
/// rows dragged together say how many, instead of naming one of them.
final class _TreeDragFeedback extends StatelessWidget {
  const new({required this.note, required this.paths});

  final Note note;

  /// The paths the drag carries.
  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = TreeRowMetrics.of(context);
    final many = paths.length > 1;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: metrics.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                many
                    ? Icons.layers_outlined
                    : (note.isDir
                          ? Icons.folder_outlined
                          : Icons.description_outlined),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                many ? AppStrings.treeMarkedCount(paths.length) : note.name,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
