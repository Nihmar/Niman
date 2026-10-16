/// An open note as a place to drop a row of the tree (#704): the caret
/// follows the pointer while the row is over the note, as it does under a
/// text dragged in, and letting go there writes a link to the row's file.
///
/// Only a file is taken: a folder dragged over the note passes over it.
/// Several rows dragged together are refused, and say so (#1027): while
/// they are over the note it is tinted and ringed and the pointer shows
/// the "no" cursor, so the drop that does nothing is not taken for one the
/// app did not notice. The tree's own drops are untouched — a row let go
/// on a folder still moves into it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/tree_drag.dart';

/// [child], the note's editor behind [viewKey], taking a tree row's drop.
final class TreeLinkDrop extends StatelessWidget {
  /// Makes [child] take a dropped file's path through [onDrop], the caret
  /// already where the pointer let it go.
  const new({
    required this.viewKey,
    required this.onDrop,
    required this.child,
    super.key,
  });

  /// The key of the tint a refused drag is drawn over the note with.
  static const refusedKey = Key('link-drop-refused');

  /// The editor the caret moves in.
  final GlobalKey<MarkdownSourceViewState> viewKey;

  /// Writes the link to the file at the dropped library-relative path.
  final void Function(String path) onDrop;

  /// The editor as drawn.
  final Widget child;

  /// Puts the caret under the pointer at [global], when it is over a line.
  void _follow(Offset global) {
    final view = viewKey.currentState;
    final at = view?.offsetAt(global);
    if (view == null || at == null) return;
    final selection = view.selection;
    if (selection.isCollapsed && selection.extent == at) return;
    view.placeCaret(at);
  }

  @override
  Widget build(BuildContext context) => DragTarget<List<String>>(
    onWillAcceptWithDetails: (details) {
      final row = TreeRowDrag.dragged.value;
      // Several marked rows dragged together are a move (#996): a link is
      // one file's drag.
      return row != null &&
          !row.isDir &&
          details.data.length == 1 &&
          row.path == details.data.single;
    },
    // The tree's rows drag by the pointer, so the drag's offset is where
    // the pointer stands.
    onMove: (details) => _follow(details.offset),
    onAcceptWithDetails: (details) {
      _follow(details.offset);
      onDrop(details.data.single);
    },
    builder: (context, _, rejected) {
      // The drag over the note that the note will not take, by the rule
      // above: several rows. (A folder passes over, as it always did.)
      final refused = rejected.any(
        (paths) => paths is List<String> && paths.length > 1,
      );
      final error = Theme.of(context).colorScheme.error;
      // The stack is always there, the tint only in it while refused, so
      // the editor under it keeps its place — and its state. The cursor is
      // the tint's own: the editor's text cursor sits below it.
      return Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          if (refused)
            Positioned.fill(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: DecoratedBox(
                  key: refusedKey,
                  decoration: BoxDecoration(
                    color: error.withValues(alpha: 0.08),
                    border: Border.all(
                      color: error.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.block,
                      size: 56,
                      color: error.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
