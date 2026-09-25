/// A block of the read view marked where a book was annotated (#285): the
/// whole block tinted as a highlighter marks it, or only the characters
/// annotated (#283), and a tap reported.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';

/// [child], a block, wearing [marks]; [onTap] is called when it is tapped.
final class MarkedBlock extends StatelessWidget {
  /// Marks [child] with [marks], all of them the block's.
  const new({required this.marks, required this.child, this.onTap, super.key});

  /// The block's marks.
  final List<BlockMark> marks;

  /// Called when the block is tapped.
  final VoidCallback? onTap;

  /// The block.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tint = markHighlightFor(
      dark: Theme.of(context).brightness == Brightness.dark,
    );
    final ranges = [for (final mark in marks) ?mark.chars];
    var marked = ranges.isEmpty
        ? child
        : RangeHighlight(ranges: ranges, color: tint, child: child);
    if (ranges.length < marks.length) {
      // A mark of the whole block.
      marked = DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(4),
        ),
        child: marked,
      );
    }
    return GestureDetector(onTap: onTap, child: marked);
  }
}
