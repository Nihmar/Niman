/// An open note as a place to drop a row of the tree (#704): the caret
/// follows the pointer while the row is over the note, as it does under a
/// text dragged in, and letting go there writes a link to the row's file.
///
/// Only a file is taken: a folder dragged over the note passes over it.
/// The tree's own drops are untouched — a row let go on a folder still
/// moves into it.
library;

import 'package:flutter/widgets.dart';
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
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (details) {
      final row = TreeRowDrag.dragged.value;
      return row != null && !row.isDir && row.path == details.data;
    },
    // The tree's rows drag by the pointer, so the drag's offset is where
    // the pointer stands.
    onMove: (details) => _follow(details.offset),
    onAcceptWithDetails: (details) {
      _follow(details.offset);
      onDrop(details.data);
    },
    builder: (context, _, _) => child,
  );
}
