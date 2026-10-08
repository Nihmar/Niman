/// A block of the read view marked where a book was annotated (#285) or
/// highlighted (#626): the whole block tinted as a highlighter marks it, or
/// only the characters marked (#283), and a tap reported.
///
/// A highlight wears its colour; an annotation the highlighter's yellow and
/// a dotted underline, drawn over any highlight on the same words, as the
/// note behind it is the more to say.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color tintOf(HighlightColour? highlight) =>
        highlight?.tint(dark: dark) ?? markHighlightFor(dark: dark);

    // The annotations innermost: a layer paints its ranges before the
    // layers inside it, so theirs end on top.
    var marked = child;
    final annotated = [
      for (final mark in marks)
        if (mark.highlight == null) ?mark.chars,
    ];
    if (annotated.isNotEmpty) {
      marked = RangeHighlight(
        ranges: annotated,
        color: tintOf(null),
        underline: annotationUnderlineFor(dark: dark),
        child: marked,
      );
    }
    for (final colour in HighlightColour.values.reversed) {
      final ranges = [
        for (final mark in marks)
          if (mark.highlight == colour) ?mark.chars,
      ];
      if (ranges.isEmpty) continue;
      marked = RangeHighlight(
        ranges: ranges,
        color: tintOf(colour),
        child: marked,
      );
    }
    // A mark of the whole block: an annotation's tint before a
    // highlight's.
    final whole = [
      for (final mark in marks)
        if (mark.chars == null) mark,
    ];
    if (whole.isNotEmpty) {
      final annotation = whole.any((mark) => mark.highlight == null);
      marked = DecoratedBox(
        decoration: BoxDecoration(
          color: tintOf(annotation ? null : whole.first.highlight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: marked,
      );
    }
    return GestureDetector(onTap: onTap, child: marked);
  }
}
