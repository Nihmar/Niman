/// The shapes of a block diagram (#530) that are its own: a block arrow's
/// outline and the box its text fits in, and where a straight edge between
/// two outlines leaves the one and reaches the other.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/block_model.dart';

/// How much of an arrow's thickness its shaft takes.
const double _shaft = 0.6;

/// How long a head is, against the arrow's thickness: a right angle at
/// its point.
const double _head = 0.5;

/// The number of heads [direction] has.
int _heads(BlockArrowDirection direction) =>
    direction == BlockArrowDirection.x || direction == BlockArrowDirection.y
    ? 2
    : 1;

/// The size of an arrow whose text, padding included, is [text]: a shaft
/// thick enough to hold it and the heads past its ends.
Size blockArrowSize(Size text, BlockArrowDirection direction) {
  final heads = _heads(direction);
  if (direction.isVertical) {
    final width = text.width / _shaft;
    return Size(width, text.height + heads * width * _head);
  }
  final height = text.height / _shaft;
  return Size(text.width + heads * height * _head, height);
}

/// The outline of an arrow pointing [direction] and filling [rect].
List<Offset> blockArrowOutline(Rect rect, BlockArrowDirection direction) {
  // Drawn pointing right (or both ways across) in a frame where x runs
  // along the arrow, then turned into [rect].
  final vertical = direction.isVertical;
  final length = vertical ? rect.height : rect.width;
  final thick = vertical ? rect.width : rect.height;
  final head = math.min(thick * _head, length * 0.4);
  final inset = thick * (1 - _shaft) / 2;
  final forward =
      direction != BlockArrowDirection.left &&
      direction != BlockArrowDirection.up;
  final both = _heads(direction) == 2;
  final half = thick / 2;
  final tip = <Offset>[
    Offset(length - head, inset),
    Offset(length - head, 0),
    Offset(length, half),
    Offset(length - head, thick),
    Offset(length - head, thick - inset),
  ];
  final tail = both
      ? [
          Offset(head, thick - inset),
          Offset(head, thick),
          Offset(0, half),
          Offset(head, 0),
          Offset(head, inset),
        ]
      : [Offset(0, thick - inset), Offset(0, inset)];
  final points = [...tip, ...tail];
  Offset place(Offset p) {
    final along = forward ? p.dx : length - p.dx;
    return vertical
        ? Offset(rect.left + p.dy, rect.top + along)
        : Offset(rect.left + along, rect.top + p.dy);
  }

  return [for (final p in points) place(p)];
}

/// The box an arrow's text sits in: its shaft between the heads.
Rect blockArrowTextBox(Rect rect, BlockArrowDirection direction) {
  final vertical = direction.isVertical;
  final length = vertical ? rect.height : rect.width;
  final thick = vertical ? rect.width : rect.height;
  final head = math.min(thick * _head, length * 0.4);
  final both = _heads(direction) == 2;
  final forward =
      direction != BlockArrowDirection.left &&
      direction != BlockArrowDirection.up;
  final from = both || !forward ? head : 0.0;
  final to = both || forward ? length - head : length;
  return vertical
      ? Rect.fromLTRB(rect.left, rect.top + from, rect.right, rect.top + to)
      : Rect.fromLTRB(rect.left + from, rect.top, rect.left + to, rect.bottom);
}

/// Where the straight line from [from] to [to] last crosses [outline]
/// ([from] inside it), as a fraction of the way; 0 when it does not.
double lastCrossing(List<Offset> outline, Offset from, Offset to) {
  var best = 0.0;
  final d = to - from;
  for (var i = 0; i < outline.length; i++) {
    final a = outline[i];
    final b = outline[(i + 1) % outline.length];
    final e = b - a;
    final denominator = d.dx * e.dy - d.dy * e.dx;
    if (denominator.abs() < 1e-9) continue;
    final w = a - from;
    final t = (w.dx * e.dy - w.dy * e.dx) / denominator;
    final s = (w.dx * d.dy - w.dy * d.dx) / denominator;
    if (t >= 0 && t <= 1 && s >= 0 && s <= 1) best = math.max(best, t);
  }
  return best;
}
