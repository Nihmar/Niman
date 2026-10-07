/// Moving notes and folders by dragging them in the tree (#567): a row is
/// dragged, and where it is let go is the folder it moves into — the same
/// move as the menu's Move, its destination taken from the drop.
///
/// A folder's row takes a drop into the folder, a note's row into the
/// note's folder, the tree's empty space into the library's root. A folder
/// dropped into itself or under itself, or anything dropped where it
/// already is, does nothing, and the row under it does not light up.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';

/// Moves the item at path into the folder named second, `''` the root.
typedef TreeMove = void Function(String path, String folder);

/// A row on the move: its path, and how far a hold has carried it.
///
/// A touch hold let go within the slop is the long press, never a drop —
/// even over the next row, a few pixels away (#576) — so every target asks
/// [moved] before it runs anything.
final class TreeDrag {
  /// [path] dragged; [held] when a hold started it.
  new(this.path, {required this.held});

  /// The row's note or folder.
  final String path;

  /// Whether a touch hold started it.
  final bool held;

  /// How far it has gone since.
  double travelled = 0;

  /// Whether a drop of it runs: a mouse's always, a hold's once it moved.
  bool get moved => !held || travelled >= kTouchSlop;
}

/// Whether [path] dropped into [folder] moves anything: not into itself,
/// not under itself, not where it already is.
bool treeDropMoves(String path, String folder) =>
    path != folder && !isUnder(path, folder) && parentOf(path) != folder;

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
    this.onLongPress,
    super.key,
  });

  /// The row's note or folder.
  final Note note;

  /// Runs a drop.
  final TreeMove onMove;

  /// The long press a touch hold is when it does not move.
  final VoidCallback? onLongPress;

  /// The row as drawn.
  final Widget child;

  @override
  State<TreeRowDrag> createState() => _TreeRowDragState();
}

final class _TreeRowDragState extends State<TreeRowDrag> {
  /// The drag this row starts: kept across the rebuilds the drag itself
  /// causes, as the row under it lights up and goes dark.
  TreeDrag? _drag;

  Note get note => widget.note;

  TreeDrag get _data => _drag?.path == note.path
      ? _drag!
      : _drag = TreeDrag(note.path, held: true);

  /// The folder a drop on this row moves into.
  String get _folder => note.isDir ? note.path : parentOf(note.path);

  @override
  Widget build(BuildContext context) {
    final folder = _folder;
    return DragTarget<TreeDrag>(
      // The row claims every drop over it, even one it will not run: let
      // through, it would reach the tree's root and move there.
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final drag = details.data;
        if (drag.moved && treeDropMoves(drag.path, folder)) {
          widget.onMove(drag.path, folder);
        }
      },
      builder: (context, candidates, _) {
        final lit =
            candidates.isNotEmpty &&
            candidates.first != null &&
            treeDropMoves(candidates.first!.path, folder);
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
    final feedback = _TreeDragFeedback(note: note);
    final child = widget.child;
    final dimmed = Opacity(opacity: 0.4, child: child);
    final drag = _data;
    // The pointer chooses, not the platform (#575): a mouse drags the row
    // as it is pulled, anything else holds it first — a finger on a
    // desktop's touchscreen still scrolls the tree.
    final hold = _HoldDraggable(
      data: drag,
      feedback: feedback,
      childWhenDragging: dimmed,
      onDragUpdate: (details) => drag.travelled += details.delta.distance,
      // Let go where it was held — no target ran it — the hold was a long
      // press. The next hold starts from nothing.
      onDragEnd: (_) {
        _drag = null;
        if (!drag.moved) widget.onLongPress?.call();
      },
      child: child,
    );
    return _MouseDraggable(
      data: TreeDrag(note.path, held: false),
      feedback: feedback,
      childWhenDragging: dimmed,
      child: hold,
    );
  }
}

/// A row dragged by the mouse, as soon as it is pulled; no other pointer.
final class _MouseDraggable extends Draggable<TreeDrag> {
  const new({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => ImmediateMultiDragGestureRecognizer(
    supportedDevices: const {PointerDeviceKind.mouse},
  )..onStart = onStart;
}

/// A row held, then dragged: by every pointer but the mouse.
final class _HoldDraggable extends LongPressDraggable<TreeDrag> {
  const new({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.onDragUpdate,
    required super.onDragEnd,
    required super.child,
  });

  @override
  DelayedMultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) =>
      DelayedMultiDragGestureRecognizer(
          delay: delay,
          supportedDevices: {
            for (final kind in PointerDeviceKind.values)
              if (kind != PointerDeviceKind.mouse) kind,
          },
        )
        ..onStart = (position) {
          final drag = onStart(position);
          if (drag != null) unawaited(HapticFeedback.selectionClick());
          return drag;
        };
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
  Widget build(BuildContext context) => DragTarget<TreeDrag>(
    onWillAcceptWithDetails: (details) => treeDropMoves(details.data.path, ''),
    onAcceptWithDetails: (details) {
      if (details.data.moved) onMove(details.data.path, '');
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
  Widget build(BuildContext context) => DragTarget<TreeDrag>(
    onWillAcceptWithDetails: (_) => true,
    builder: (context, candidates, _) => child,
  );
}

/// What follows the pointer: the row's icon and name on a card.
final class _TreeDragFeedback extends StatelessWidget {
  const new({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = TreeRowMetrics.of(context);
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
                note.isDir ? Icons.folder_outlined : Icons.description_outlined,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(note.name, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
