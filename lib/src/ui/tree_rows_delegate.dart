import 'package:flutter/widgets.dart';

/// The delegate of the tree's rows, which tells what range it laid out
/// (#1200).
///
/// The tree keeps the pages the list can draw, and what the list can draw is
/// what it built: its viewport and its own cache extent, whatever the row
/// height. Taking the range from the list itself, rather than working it out
/// again from the scroll position, keeps the pages held and the rows drawn
/// from ever disagreeing.
final class TreeRowsDelegate extends SliverChildBuilderDelegate {
  /// Builds the rows `builder` makes, [childCount] of them, and tells
  /// [onLaidOut] which were built after each layout.
  new(super.builder, {required int super.childCount, required this.onLaidOut});

  /// Called after a layout with the first and the last index built.
  final void Function(int first, int last) onLaidOut;

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    super.didFinishLayout(firstIndex, lastIndex);
    onLaidOut(firstIndex, lastIndex);
  }
}
