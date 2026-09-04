import 'package:copist/src/editor/highlight_style.dart';
import 'package:copist/src/editor/highlighting.dart';
import 'package:flutter/widgets.dart';

/// The styled runs of one visual row: the slice [rowStart)..[rowEnd) of
/// [line]'s text, split at token boundaries, each run carrying the style of
/// the token covering it (a plain gap is a null override — the base row style
/// shows; the heading text, after a `#…` marker, is [headingStyle]).
///
/// This is the per-visible-row work of the editor view (M2a E7): it touches
/// only the tokens intersecting the slice, never the rest of the file.
/// Offsets are relative to the line's text.
List<TextSpan> styledRuns(StyledLine line, int rowStart, int rowEnd) {
  final text = line.text;
  final end = rowEnd > text.length ? text.length : rowEnd;
  if (rowStart >= end) return const [];

  // The heading-text region starts after the `#…` marker token (the tokenizer
  // leaves it unmarked; the painter styles it as heading).
  var headingStart = -1;
  for (final t in line.tokens) {
    if (t.kind == TokenKind.headingMarker) {
      headingStart = t.end;
      break;
    }
  }

  // Boundaries: the slice ends plus every token edge and the heading boundary
  // that falls strictly inside the slice. Each maximal run between two
  // boundaries is either inside one token or plain, so one style per run.
  final bounds = <int>{rowStart, end};
  for (final t in line.tokens) {
    if (t.end <= rowStart || t.start >= end) continue;
    if (t.start > rowStart) bounds.add(t.start);
    if (t.end < end) bounds.add(t.end);
  }
  if (headingStart >= rowStart && headingStart < end) bounds.add(headingStart);

  final sorted = bounds.toList()..sort();
  final spans = <TextSpan>[];
  for (var i = 0; i + 1 < sorted.length; i++) {
    final s = sorted[i];
    final e = sorted[i + 1];
    if (s >= e) continue;
    final kind = _kindAt(line.tokens, s);
    TextStyle? style;
    if (kind != null) {
      style = tokenStyle(kind);
    } else if (headingStart >= 0 && s >= headingStart) {
      style = headingStyle;
    }
    spans.add(TextSpan(text: text.substring(s, e), style: style));
  }
  return spans;
}

/// The token kind covering position [pos] ([Token.start] <= pos < [Token.end]),
/// or null (plain). [tokens] are sorted by start and disjoint.
TokenKind? _kindAt(List<Token> tokens, int pos) {
  for (final t in tokens) {
    if (t.start > pos) break;
    if (pos < t.end) return t.kind;
  }
  return null;
}
