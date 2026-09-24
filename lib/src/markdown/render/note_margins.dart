/// Where a note's text is set across its pane, one rule for every mode.
///
/// `live` and the read view are one page, one of them editable: a glyph
/// that moves when the pane flips is the page changing under the reader.
/// The read view set its text 16 px in from each side; the editor, with no
/// note column, 5 px — past its line numbers when they were on — and 5 px
/// from the right, so the text moved and wrapped elsewhere at every flip.
/// Both now ask here.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/editor/note_column.dart';

/// The gap between the line numbers and the text: the room the legacy
/// gutter kept for the fold arrows, which is why its text never touched
/// its numbers.
const double lineNumbersGap = 14;

/// How far in from its pane's left edge a note's field starts: the legacy
/// editor's own number, under the numbers as under the text.
const double noteFieldInset = 5;

/// How wide [lineCount]'s line numbers are, set in [style] at [scaler], with
/// the gap after them.
///
/// **Measured**, not estimated: "0.6 em per digit" is only nearly true of a
/// monospace face — DejaVu Sans Mono, Linux's usual one, is 0.602 em, so two
/// digits did not fit the room for two and every number from 10 on wrapped
/// onto a second row, making each of its lines two rows tall.
double lineNumbersWidth(int lineCount, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: '0' * lineCount.toString().length, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  // A pixel of slack: a width that is exactly the text's can still wrap on
  // rounding.
  final width = painter.width.ceilToDouble() + 1;
  painter.dispose();
  return width + lineNumbersGap;
}

/// How far in from its pane's edges a note's text is set, with [side] the
/// note column's side space and [numbers] the line numbers' width
/// ([lineNumbersWidth]), or 0 when they are not drawn.
///
/// The column's edge, [NoteColumn.textInset] in, on both sides — or past the
/// numbers on the left, when they reach further. The read view keeps the
/// numbers' room without drawing them, so its text stands where the
/// editor's does.
({double left, double right}) noteTextInsets({
  required double side,
  required double numbers,
}) => (
  left: math.max(side + NoteColumn.textInset, noteFieldInset + numbers),
  right: side + NoteColumn.textInset,
);
