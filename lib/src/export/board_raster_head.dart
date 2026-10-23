/// A rastered column's head and box (#1170).
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/export/board_raster_context.dart';

/// The padding inside a column's box, in logical pixels.
const EdgeInsets boardLanePadding = EdgeInsets.symmetric(
  horizontal: 9,
  vertical: 8,
);

/// What a column's box adds to what it holds, top and bottom: its padding
/// and its line.
final double boardLaneChrome = boardLanePadding.vertical + 2;

/// The space under a column's head, in logical pixels.
const double _headGap = 6;

/// The space the count takes at the head's right: its gap and its digits.
const double _countRoom = 34;

/// The style column names are drawn in on a board whose columns are
/// [width] wide inside: the heading the read view gives an h2, when every
/// name of [names] fits it on one line beside the count; otherwise a
/// heading of the body's type, a little larger, which is what a narrow
/// column of a four-column sheet can hold.
TextStyle boardHeadStyle(
  BoardRasterContext context,
  Iterable<String> names,
  double width,
) {
  final theme = context.theme;
  final h2 = theme.heading2.copyWith(height: 1.3);
  final room = width - _countRoom;
  for (final name in names) {
    final painter = TextPainter(
      text: TextSpan(text: name, style: h2),
      textDirection: TextDirection.ltr,
    )..layout();
    final fits = painter.width <= room;
    painter.dispose();
    if (!fits) {
      return h2.copyWith(fontSize: (theme.body.fontSize ?? 14) * 1.1);
    }
  }
  return h2;
}

/// A column's line, rounded, and its padding.
final class BoardLaneBox extends StatelessWidget {
  /// A box with a line of [color] round [child].
  const new({required this.color, required this.child, super.key});

  /// The line's colour.
  final Color color;

  /// What the column holds.
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(padding: boardLanePadding, child: child),
  );
}

/// A column's head: its name and how many cards it holds.
final class BoardLaneHead extends StatelessWidget {
  /// The head of a column called [name] with [count] cards, [width] wide,
  /// the name drawn in [style].
  const new({
    required this.name,
    required this.count,
    required this.width,
    required this.style,
    required this.context,
    super.key,
  });

  /// The column's name, as inline Markdown.
  final String name;

  /// How many cards the column holds.
  final int count;

  /// The head's width.
  final double width;

  /// The name's style.
  final TextStyle style;

  /// What the board is drawn with.
  final BoardRasterContext context;

  @override
  Widget build(BuildContext buildContext) {
    final theme = context.theme;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(bottom: _headGap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text.rich(context.inline(name, base: style))),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: theme.body.copyWith(
                fontSize: (theme.body.fontSize ?? 14) * 0.85,
                color: theme.markerDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
