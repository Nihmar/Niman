/// The look a Mermaid `style` statement gives one node or subgraph.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/css_color.dart';

/// What a `style` statement sets: each property the theme's own where it
/// is null.
final class FlowNodeStyle {
  /// Creates a style.
  const new({this.fill, this.stroke, this.strokeWidth, this.color});

  /// Reads Mermaid's CSS-like list, `fill:#f9f,stroke:#333,stroke-width:4px,
  /// color:#fff`. A property it does not draw, or a value it cannot read,
  /// is left to the theme: a style is a note's own touch, not something to
  /// refuse the whole diagram over.
  factory parse(String text) {
    Color? fill;
    Color? stroke;
    double? strokeWidth;
    Color? color;
    for (final property in _properties(text)) {
      final colon = property.indexOf(':');
      if (colon < 0) continue;
      final name = property.substring(0, colon).trim().toLowerCase();
      final value = property.substring(colon + 1).trim();
      switch (name) {
        case 'fill':
          fill = parseCssColor(value) ?? fill;
        case 'stroke':
          stroke = parseCssColor(value) ?? stroke;
        case 'stroke-width':
          final width = double.tryParse(value.replaceFirst('px', '').trim());
          if (width != null && width >= 0) strokeWidth = width;
        case 'color':
          color = parseCssColor(value) ?? color;
      }
    }
    return FlowNodeStyle(
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
      color: color,
    );
  }

  /// What it is filled with.
  final Color? fill;

  /// What it is outlined with.
  final Color? stroke;

  /// How wide its outline is drawn.
  final double? strokeWidth;

  /// What its text is written in.
  final Color? color;

  /// This style with what [later] sets put over it: a second `style`
  /// statement for the same id adds to the first.
  FlowNodeStyle overlaid(FlowNodeStyle later) => FlowNodeStyle(
    fill: later.fill ?? fill,
    stroke: later.stroke ?? stroke,
    strokeWidth: later.strokeWidth ?? strokeWidth,
    color: later.color ?? color,
  );

  /// The colour text reads in on this style's fill: its own [color], or
  /// black or white, whichever stands out on the fill — a pale fill in a
  /// dark theme kept the theme's pale text and could not be read. Null
  /// when neither is set, or the fill is too faint to read text against.
  Color? get textColor {
    if (color != null) return color;
    final fill = this.fill;
    if (fill == null || fill.a < 0.5) return null;
    return fill.computeLuminance() > 0.4
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFFFFFFF);
  }

  /// The properties of [text], split at the commas between them, not at
  /// those inside a value (`rgb(1, 2, 3)`).
  static Iterable<String> _properties(String text) sync* {
    var start = 0;
    var depth = 0;
    for (var i = 0; i < text.length; i++) {
      switch (text[i]) {
        case '(':
          depth++;
        case ')' when depth > 0:
          depth--;
        case ',' || ';' when depth == 0:
          yield text.substring(start, i);
          start = i + 1;
      }
    }
    yield text.substring(start);
  }
}
