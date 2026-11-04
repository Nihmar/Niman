/// A table cell's text as `live` draws it: the spans it is drawn in, its
/// hidden marks left out, and how wide that is.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/live_table_counts.dart';
import 'package:niman/src/markdown/render/live_table_row_work.dart';
import 'package:niman/src/markdown/render/table_measure.dart';

/// Measures a cell's text and cuts it into the spans it is drawn in.
abstract final class LiveTableSpans {
  /// How wide `[start, end)` of [text] is drawn, its marks left out, the
  /// rest in its tokens' styles over [style]; and how many characters of
  /// marks it has, and how many of them come before its first glyph.
  static LiveTableMeasured measure(
    String text,
    List<Token> tokens,
    int start,
    int end,
    TextStyle style,
    TextScaler scaler,
    bool Function(Token token) hiddenAtRest,
    TextStyle? Function(Token token) styleOf,
  ) {
    if (end <= start) return (visible: 0, least: 0, hidden: 0, lead: 0);
    final spans = LiveTableSpans.spans(
      text,
      tokens,
      start,
      end,
      hiddenAtRest,
      styleOf,
    );
    var hidden = 0;
    int? lead;
    var at = start;
    for (final token in tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) lead ??= hidden;
      if (hiddenAtRest(token)) {
        hidden += to - from;
      } else {
        lead ??= hidden;
      }
      at = to;
    }
    if (at < end) lead ??= hidden;
    LiveTableCounts.measurements++;
    final widths = measureTableCell(
      TextSpan(children: spans, style: style),
      scaler,
    );
    return (
      visible: widths.natural,
      least: widths.least,
      hidden: hidden,
      lead: lead ?? hidden,
    );
  }

  /// The spans `[start, end)` of [text] is drawn in: its tokens' styles, and
  /// the ones [hiddenAtRest] says are marks left out — the same spans
  /// [measure] measures, so a cell's measured width and its wrapped pieces
  /// are the same text.
  static List<InlineSpan> spans(
    String text,
    List<Token> tokens,
    int start,
    int end,
    bool Function(Token token) hiddenAtRest,
    TextStyle? Function(Token token) styleOf,
  ) {
    return <InlineSpan>[
      for (final (from, to, token) in _segments(tokens, start, end))
        if (token == null)
          TextSpan(text: text.substring(from, to))
        else if (!hiddenAtRest(token))
          TextSpan(text: text.substring(from, to), style: styleOf(token)),
    ];
  }

  /// The stretches of source `[start, end)` is drawn from, in order: what
  /// [spans] draws of it, its hidden marks left out.
  static List<(int, int)> shownOf(
    List<Token> tokens,
    int start,
    int end,
    bool Function(Token token) hiddenAtRest,
  ) => <(int, int)>[
    for (final (from, to, token) in _segments(tokens, start, end))
      if (token == null || !hiddenAtRest(token)) (from, to),
  ];

  /// The source offset the drawn text's offset [drawn] stands for, [shown]
  /// being the stretches of source that text is made of, from [start]: the
  /// [drawn]-th character of them laid end to end. An offset between two
  /// stretches, where hidden marks sit, is the earlier one's end — a line
  /// broken there ends on its text, and the marks open the next line, with
  /// the word they belong to.
  static int sourceOf(List<(int, int)> shown, int start, int drawn) {
    var left = drawn;
    for (final (from, to) in shown) {
      if (left <= to - from) return from + left;
      left -= to - from;
    }
    return shown.isEmpty ? start : shown.last.$2;
  }

  /// `[start, end)` cut at [tokens]' edges: each token's stretch, clipped to
  /// it, and the stretches between them, which have no token.
  static List<(int, int, Token?)> _segments(
    List<Token> tokens,
    int start,
    int end,
  ) {
    if (end <= start) return const <(int, int, Token?)>[];
    final segments = <(int, int, Token?)>[];
    var at = start;
    for (final token in tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) segments.add((at, from, null));
      segments.add((from, to, token));
      at = to;
    }
    if (at < end) segments.add((at, end, null));
    return segments;
  }
}
