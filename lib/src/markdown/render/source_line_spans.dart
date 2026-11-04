/// A source line's text as styled runs (split out of `source_line.dart` for
/// #100): its tokens in their styles, its markers hidden or drawn, what
/// `live` draws in place of its source, and the selection, the composition
/// and the find bar's matches cut into them.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_inline_math.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_line_layout.dart';
import 'package:niman/src/preview/code_highlight.dart';

/// A stretch of a line `live` draws something else in place of: its range,
/// the style that hides it, and whether it has to stay on one row — the room
/// a formula is painted over does.
typedef SourceConcealed = (int, int, TextStyle, {bool whole});

/// The ranges a piece of a table row laid out in fitted columns draws its
/// selection, its composition and the find bar's matches in: the line's own,
/// clipped to the piece's source.
typedef _Ink = ({
  int start,
  int end,
  (int, int)? selected,
  (int, int)? composing,
  List<(int, int, bool)> found,
});

/// The colour a selected run is painted with.
const Color _selectionColor = Color(0x553B82F6);

/// The colours the find bar's matches are painted with: every match, and the
/// one the bar is on.
const Color _matchColor = Color(0x55FFB300);
const Color _currentMatchColor = Color(0xAAFF8F00);

/// The line's runs, as the paragraph draws them.
extension SourceLineSpans on SourceLine {
  /// The span of `[start, end)` of the line's source, for one piece of a
  /// table row laid out in fitted columns: the line's own runs and what is
  /// drawn in place of them, cut to the piece.
  TextSpan pieceSpan(
    int start,
    int end, {
    required List<SourceConcealed> concealed,
    required List<InlineFormula> formulas,
  }) {
    final spans = <InlineSpan>[];
    if (end <= start) return TextSpan(children: spans);
    final marks = <SourceConcealed>[
      for (final hidden in concealed)
        if (hidden.$2 > start && hidden.$1 < end)
          (
            hidden.$1 < start ? start : hidden.$1,
            hidden.$2 > end ? end : hidden.$2,
            hidden.$3,
            whole: hidden.whole,
          ),
    ];
    final ink = (
      start: start,
      end: end,
      selected: _clipTo(selected, start, end),
      composing: _clipTo(composing, start, end),
      found: <(int, int, bool)>[
        for (final match in found)
          if (match.$2 > start && match.$1 < end)
            (
              match.$1 < start ? start : match.$1,
              match.$2 > end ? end : match.$2,
              match.$3,
            ),
      ],
    );
    var at = start;
    for (final token in styled.tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) _add(spans, at, from, null, marks, ink);
      _add(
        spans,
        from,
        to,
        hidden(token, revealed: false) ? liveHiddenMarker : _styleOf(token),
        marks,
        ink,
      );
      at = to;
    }
    if (at < end) _add(spans, at, end, null, marks, ink);
    return TextSpan(children: spans);
  }

  /// [range] clipped to `[start, end)`, or null when it falls outside.
  static (int, int)? _clipTo((int, int)? range, int start, int end) {
    if (range == null || range.$2 <= start || range.$1 >= end) return null;
    return (
      range.$1 < start ? start : range.$1,
      range.$2 > end ? end : range.$2,
    );
  }

  /// The line's tokens as styled runs. A token's override never changes the
  /// size
  /// or the height, so a line keeps the surface's metrics whatever it contains
  /// (`highlight_style.dart`).
  TextSpan lineSpan({
    required bool revealed,
    (int, int)? run,
    List<SourceConcealed> concealed = const <SourceConcealed>[],
  }) {
    if (hideMarkers && shape.code != null && shape.quoteDepth > 0) {
      return _quotedCode(revealed: revealed, concealed: concealed);
    }
    final spans = <InlineSpan>[];
    // A hidden line's prefix is hidden whole, its spaces with its marks: the
    // text then starts at the indent, where its wrapped rows start too.
    final prefix = hideMarkers && !revealed ? prefixEnd : 0;
    if (prefix > 0) _add(spans, 0, prefix, liveHiddenMarker, concealed);
    var at = prefix;
    // The runs are the tokenizer's; the selection cuts them where it starts and
    // ends, so a highlighted range is the same text with a background.
    for (final token in styled.tokens) {
      if (token.end <= prefix) continue;
      if (token.start > at) {
        _add(spans, at, token.start, null, concealed);
      }
      // A token the prefix cuts into — an indented code line's, which is
      // the whole line — is drawn from where the prefix ends.
      final from = token.start < at ? at : token.start;
      // Code, in `live`, is coloured as the read view colours it: by its
      // block's language, or not at all.
      if (hideMarkers && token.kind == TokenKind.codeBlock) {
        final runs = codeRuns;
        if (runs == null) {
          _add(spans, from, token.end, null, concealed);
        } else {
          var cursor = from;
          for (final run in runs) {
            final start = run.start < cursor ? cursor : run.start;
            final end = run.end > token.end ? token.end : run.end;
            if (end <= start) continue;
            if (start > cursor) _add(spans, cursor, start, null, concealed);
            _add(spans, start, end, run.style, concealed);
            cursor = end;
          }
          if (cursor < token.end) {
            _add(spans, cursor, token.end, null, concealed);
          }
        }
        at = token.end;
        continue;
      }
      _add(
        spans,
        from,
        token.end,
        hidden(token, revealed: revealed, run: run)
            ? liveHiddenMarker
            : _styleOf(token),
        concealed,
      );
      at = token.end;
    }
    if (at < styled.text.length) {
      _add(spans, at, styled.text.length, null, concealed);
    }
    return TextSpan(children: spans);
  }

  /// The style [token] is drawn in: its kind's, and the muted colour of a
  /// link that is not there yet when it is part of a dead one (#847).
  TextStyle? _styleOf(Token token) {
    final style = nestedTokenStyle(token, syntax, dark: dark);
    if (deadLinks.isEmpty) return style;
    if (token.kind != TokenKind.wikilink && token.kind != TokenKind.link) {
      return style;
    }
    for (final range in deadLinks) {
      if (token.start >= range.start && token.end <= range.end) {
        return (style ?? const TextStyle()).copyWith(color: syntax.deadLink);
      }
    }
    return style;
  }

  /// A line of a code block inside a quote.
  ///
  /// The styler reads a quote's lines as the quote's prose, so their tokens
  /// say nothing of the code in it: the quote's marks are drawn as its
  /// marks, and the rest as code — a fence hidden as a fence is, the code
  /// in its block's colours ([codeRuns], whose offsets start past the
  /// marks).
  TextSpan _quotedCode({
    required bool revealed,
    required List<SourceConcealed> concealed,
  }) {
    final text = styled.text;
    final spans = <InlineSpan>[];
    final marks = BlockParser.quotePrefixLength(
      text,
      shape.quoteDepth,
      shape.quoteIndent,
    );
    var at = 0;
    if (!revealed) {
      final hidden = shape.codeFence ? text.length : prefixEnd;
      _add(spans, 0, hidden, liveHiddenMarker, concealed);
      at = hidden;
    } else {
      for (final token in styled.tokens) {
        if (token.start >= marks) break;
        if (token.start > at) _add(spans, at, token.start, null, concealed);
        final end = token.end > marks ? marks : token.end;
        _add(
          spans,
          token.start,
          end,
          nestedTokenStyle(token, syntax, dark: dark),
          concealed,
        );
        at = end;
      }
      if (at < marks) _add(spans, at, marks, null, concealed);
      at = marks;
    }
    for (final run in codeRuns ?? const <CodeRun>[]) {
      final start = marks + run.start < at ? at : marks + run.start;
      final end = marks + run.end > text.length ? text.length : marks + run.end;
      if (end <= start) continue;
      if (start > at) _add(spans, at, start, null, concealed);
      _add(spans, start, end, run.style, concealed);
      at = end;
    }
    if (at < text.length) _add(spans, at, text.length, null, concealed);
    return TextSpan(children: spans);
  }

  /// Adds `[start, end)` to [spans], cut at the selection's and the composing
  /// range's edges: the selected part carries the highlight, the composed part
  /// the underline, and the rest keeps the run's own style.
  void _add(
    List<InlineSpan> spans,
    int start,
    int end,
    TextStyle? style, [
    List<SourceConcealed> concealed = const <SourceConcealed>[],
    _Ink? ink,
  ]) {
    // A piece of a table row laid out in fitted columns draws the line's
    // selection, its composition and the find bar's matches clipped to the
    // piece; every other line draws them as they are.
    final chosen = ink == null ? selected : ink.selected;
    final written = ink == null ? composing : ink.composing;
    final matches = ink == null ? found : ink.found;
    final cuts = <int>{start, end};
    for (final range in <(int, int)?>[
      chosen,
      written,
      for (final match in matches) (match.$1, match.$2),
      for (final hidden in concealed) (hidden.$1, hidden.$2),
    ]) {
      if (range == null) continue;
      if (range.$1 > start && range.$1 < end) cuts.add(range.$1);
      if (range.$2 > start && range.$2 < end) cuts.add(range.$2);
    }
    final points = cuts.toList()..sort();
    for (var at = 0; at < points.length - 1; at++) {
      final from = points[at];
      final to = points[at + 1];
      bool inside((int, int)? range) =>
          range != null && from >= range.$1 && to <= range.$2;
      // What `live` draws instead of its source — a picture, a formula — is
      // hidden as a marker is: there, taking no room.
      var piece = style;
      var whole = false;
      for (final hidden in concealed) {
        if (inside((hidden.$1, hidden.$2))) {
          piece = hidden.$3;
          whole = hidden.whole;
        }
      }
      if (inside(chosen)) {
        piece = (piece ?? const TextStyle()).copyWith(
          background: Paint()..color = _selectionColor,
        );
      }
      // A match is drawn over the selection: the current one *is* the
      // selection, and it has to read as the one the bar is on.
      for (final match in matches) {
        if (from >= match.$1 && to <= match.$2) {
          piece = (piece ?? const TextStyle()).copyWith(
            background: Paint()
              ..color = match.$3 ? _currentMatchColor : _matchColor,
          );
        }
      }
      if (inside(written)) {
        piece = (piece ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
        );
      }
      spans.add(
        TextSpan(
          text: whole
              ? unbrokenSource(to - from)
              : styled.text.substring(from, to),
          style: piece,
        ),
      );
    }
  }
}
