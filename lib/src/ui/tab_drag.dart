/// Dragging tabs (#204): what travels with a dragged tab, and where it
/// can be dropped.
///
/// A tab is dragged along its own row to reorder it, onto the other
/// pane's row or body to move it there, and — with the window not split
/// — onto a pane's right or bottom edge to split with it, the gesture
/// every editor with tabs uses.
///
/// The move keeps the tab as the right-click menu's *Move to the other
/// pane* does, editor and undo included: it is the same workspace
/// operation, so the note is never reloaded.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/workspace/workspace.dart';

/// A tab being dragged: where it is now, so the drop knows what to move.
@immutable
final class TabDrag {
  /// The tab at [index] of [pane], showing [label].
  const new({required this.pane, required this.index, required this.label});

  /// The pane the tab is in.
  final int pane;

  /// Its place in that pane's row.
  final int index;

  /// The note's name, for the thing under the pointer.
  final String label;
}

/// What a drop on a pane means: the pane it landed on, and the edge it
/// landed near.
enum TabDropKind {
  /// Into the pane: the tab moves there.
  move,

  /// On the right edge of an unsplit window: split right with the tab.
  splitRight,

  /// On the bottom edge of an unsplit window: split down with it.
  splitDown,
}

/// The thing under the pointer while a tab is dragged.
final class TabDragFeedback extends StatelessWidget {
  /// A chip reading [label].
  const new(this.label, {super.key});

  /// The note's name.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.9,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }
}

/// A pane's body as a place to drop a tab (#204).
///
/// Near the right or bottom edge of an unsplit window the drop splits
/// with the tab; anywhere else it moves the tab into this pane. The zone
/// paints what is about to happen — the whole pane, or the half the new
/// pane would take — and does nothing at all for a tab already here,
/// where a move would be a no-op.
final class TabDropZone extends StatefulWidget {
  /// Wraps [child], the body of [pane].
  const new({
    required this.pane,
    required this.isSplit,
    required this.onDrop,
    required this.child,
    super.key,
  });

  /// Which pane this is.
  final int pane;

  /// Whether the window is split already: then there is no edge to split
  /// on, only the move.
  final bool isSplit;

  /// Runs the drop.
  final void Function(TabDrag drag, TabDropKind kind) onDrop;

  /// The pane's body.
  final Widget child;

  /// How much of the pane's width or height counts as its edge.
  static const double edge = 0.25;

  @override
  State<TabDropZone> createState() => _TabDropZoneState();
}

final class _TabDropZoneState extends State<TabDropZone> {
  TabDropKind? _over;

  /// What a drop at [at] of a [size] pane would do.
  TabDropKind _kindAt(Offset at, Size size) {
    if (widget.isSplit) return TabDropKind.move;
    if (at.dx > size.width * (1 - TabDropZone.edge)) {
      return TabDropKind.splitRight;
    }
    if (at.dy > size.height * (1 - TabDropZone.edge)) {
      return TabDropKind.splitDown;
    }
    return TabDropKind.move;
  }

  /// Whether a tab from [drag] can be dropped here at all: a tab already
  /// in this pane can only be reordered, which its own row does.
  bool _takes(TabDrag drag) => !widget.isSplit || drag.pane != widget.pane;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TabDrag>(
      onWillAcceptWithDetails: (details) {
        if (!_takes(details.data)) return false;
        _highlight(details.offset, context);
        return true;
      },
      onMove: (details) => _highlight(details.offset, context),
      onLeave: (_) => _clear(),
      onAcceptWithDetails: (details) {
        final kind = _over ?? TabDropKind.move;
        _clear();
        widget.onDrop(details.data, kind);
      },
      builder: (context, candidate, _) => Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_over case final kind?) _hint(context, kind),
        ],
      ),
    );
  }

  void _highlight(Offset globalOffset, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final kind = _kindAt(box.globalToLocal(globalOffset), box.size);
    if (kind != _over) setState(() => _over = kind);
  }

  void _clear() {
    if (_over != null) setState(() => _over = null);
  }

  /// The half (or the whole) the tab would land in.
  Widget _hint(BuildContext context, TabDropKind kind) {
    final colour = Theme.of(context).colorScheme.primary;
    final fill = ColoredBox(color: colour.withValues(alpha: 0.12));
    return Positioned.fill(
      key: const Key('tab-drop-hint'),
      child: IgnorePointer(
        child: switch (kind) {
          TabDropKind.move => fill,
          TabDropKind.splitRight => FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: TabDropZone.edge * 2,
            child: fill,
          ),
          TabDropKind.splitDown => FractionallySizedBox(
            alignment: Alignment.bottomCenter,
            heightFactor: TabDropZone.edge * 2,
            child: fill,
          ),
        },
      ),
    );
  }
}

/// The axis [kind] splits on, or null when it is a move.
SplitAxis? tabDropAxis(TabDropKind kind) => switch (kind) {
  TabDropKind.move => null,
  TabDropKind.splitRight => SplitAxis.right,
  TabDropKind.splitDown => SplitAxis.down,
};
