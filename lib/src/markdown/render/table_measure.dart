/// Measuring a table's cell for the fit (#1108): the one measure the read
/// view and `live` share, so a column is as wide in one as in the other.
library;

import 'package:flutter/widgets.dart';

/// What a cell asks of its column.
///
/// `natural` is the width of its text on one line. `least` is the narrowest
/// it can be drawn without breaking a word: the widest unbreakable run of its
/// text, styles included, where the text may break by the rules the text
/// engine breaks it by. `widget` says the cell holds a widget (inline math,
/// an image, an embed), which the measure leaves out — the table asks the
/// widget itself for its width (`FittedColumnWidth`).
typedef TableCellWidths = ({double natural, double least, bool widget});

/// The widths [text] asks for, drawn at [scaler].
///
/// One layout answers both: the engine works out the widest unbreakable run
/// while it lays the line out, so the floor costs no layout of its own — and
/// no word is measured one by one.
TableCellWidths measureTableCell(InlineSpan text, TextScaler scaler) {
  var widget = false;
  text.visitChildren((span) {
    if (span is WidgetSpan) widget = true;
    return !widget;
  });
  final painter = TextPainter(
    // A widget has no widget tree under it here: it is left out, and the
    // column asks it for its width when the table is laid out.
    text: widget ? _withoutWidgets(text) : text,
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final widths = (
    natural: painter.width,
    least: painter.minIntrinsicWidth,
    widget: widget,
  );
  painter.dispose();
  return widths;
}

/// [span] with every widget in it replaced by nothing.
InlineSpan _withoutWidgets(InlineSpan span) {
  if (span is! TextSpan) return const TextSpan();
  return TextSpan(
    text: span.text,
    style: span.style,
    children: [
      for (final child in span.children ?? const <InlineSpan>[])
        _withoutWidgets(child),
    ],
  );
}
