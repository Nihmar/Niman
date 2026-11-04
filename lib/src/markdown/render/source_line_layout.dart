/// How a source line is set (split out of `source_line.dart` for #100):
/// the style its text is drawn in, and in `live` where its prefix ends and
/// how far its text is indented past it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/source_line.dart';

/// The line's style, its prefix and its indent.
extension SourceLineLayout on SourceLine {
  /// The style the line is set in.
  ///
  /// In live mode a heading is drawn at its own size, which is the difference
  /// between hiding a hash and *being* a heading; a source view shows the note
  /// as
  /// written and keeps one size for everything, so the markers keep their own
  /// advance there.
  TextStyle lineStyle({required bool revealed}) {
    // The line's own size is the *hiding*'s, not the reveal's: a heading is
    // drawn as a heading whether its hashes are shown or not, because what the
    // mode is about is reading the note with the syntax out of the way — and
    // revealing a marker is not a reason to restyle the line under the caret
    // (`docs/records/unified-surface.md` §8.6.2, and the test that holds it).
    if (!hideMarkers) return theme.body;
    // A table's cells are set as the read view sets them.
    if (tableRow != null) {
      return tableHeader ? theme.tableHeader : theme.tableCell;
    }
    // Code reads as the read view draws it: in monospace, fences and all.
    if (shape.code != null) return theme.code;
    // A callout's title, as the read view sets it (#279) — the caret on it
    // or not: revealing the mark is no reason to restyle the line.
    final callout = shape.callout;
    if (callout != null && callout.title) {
      return theme.body.copyWith(
        color: callout.style.color,
        fontWeight: FontWeight.w600,
      );
    }
    // A heading inside a quote is set at its size, as the read view sets it.
    if (shape.heading > 0) return theme.heading(shape.heading);
    // Quoted prose reads as the read view draws it: in the quote's own style.
    if (shape.quoteDepth > 0) return theme.body.merge(theme.quote);
    final text = styled.text;
    var level = 0;
    while (level < text.length && level < 6 && text[level] == '#') {
      level++;
    }
    if (level == 0 || (level < text.length && text[level] != ' ')) {
      return theme.body;
    }
    return switch (level) {
      1 => theme.heading1,
      2 => theme.heading2,
      3 => theme.heading3,
      4 => theme.heading4,
      5 => theme.heading5,
      _ => theme.heading6,
    };
  }

  /// How far the line is indented, in live mode.
  ///
  /// A list item's text is set one column in per level, as the read view
  /// sets it, and a quote's a step in past each bar. The line's prefix —
  /// the written indent, the quote marks, the marker, the box and the
  /// spaces between them — is hidden whole (`_span`), so the text lands on
  /// the column and a wrapped item's next row starts under it, where it
  /// hung out to the left by the prefix's width. Live nested by the spaces
  /// the note was written with before: a sublist sat a few pixels in. A
  /// code block's rows are set a padding into its box, as the read view
  /// sets its code.
  ///
  /// It is pure layout: no offset moves, because the text underneath is
  /// still the note's own text, character for character.
  ///
  /// On the caret's line ([revealed]) the prefix is drawn as written, and
  /// it is set *into* the indent rather than before it: otherwise the text
  /// jumped right by the marks' width each time the caret came onto the
  /// line, and back when it left (device screenshot 2026-09-23, a list
  /// being typed). Marks wider than the column — a task's `- [ ] `, a
  /// `10. `, a heading's `# ` over its zero column — move the line right by
  /// what is left over; they start at the note's left margin, never hung
  /// out into the field left of the text (#288).
  double textIndent(BuildContext context, {bool revealed = false}) {
    if (!hideMarkers) return 0;
    final listed = shape.listed
        ? (shape.listDepth + 1) * theme.listIndentPerLevel
        : 0.0;
    final base = math.max<double>(
      0,
      listed +
          shape.quoteDepth * theme.quoteIndentPerLevel +
          (shape.code == null ? 0 : theme.codePadding) -
          outerIndent,
    );
    if (base == 0 && prefixEnd == 0) return 0;
    final marks =
        _textStart(context, revealed: revealed) -
        _glyphLeft(context, const <InlineSpan>[]);
    return math.max<double>(0, base - marks);
  }

  /// Whether the line is a heading's: its hashes and the spaces after them
  /// are its prefix, hidden whole, where the space was left behind and set
  /// the title a space's width in.
  bool get _heading =>
      styled.tokens.any((token) => token.kind == TokenKind.headingMarker);

  /// Where the line's prefix ends: past its leading spaces, its quote
  /// marks, its list marker, its task box, a heading's hashes and the spaces
  /// between them. Zero for a line that is none of these, whose leading
  /// spaces are its own.
  int get prefixEnd {
    if (shape.code != null) {
      // A code line's prefix is its quote's marks and, in an indented
      // block, the block's indent: the spaces past them are the code's.
      final text = styled.text;
      final marks = shape.quoteDepth > 0
          ? BlockParser.quotePrefixLength(
              text,
              shape.quoteDepth,
              shape.quoteIndent,
            )
          : 0;
      return shape.codeIndented
          ? marks + _codeIndentEnd(text.substring(marks))
          : marks;
    }
    if (!shape.listed && shape.quoteDepth == 0 && !_heading) {
      // A line of a column drawn at its list items' indent already (#729):
      // the spaces that put it in the items are that indent, hidden.
      return outerIndent > 0 ? LineSyntax.indentOf(styled.text) : 0;
    }
    final text = styled.text;
    var at = 0;
    var tokens = 0;
    while (true) {
      while (at < text.length &&
          (text.codeUnitAt(at) == 0x20 || text.codeUnitAt(at) == 0x09)) {
        at++;
      }
      while (tokens < styled.tokens.length &&
          styled.tokens[tokens].start < at) {
        tokens++;
      }
      if (tokens == styled.tokens.length) return at;
      final token = styled.tokens[tokens];
      if (token.start != at ||
          (token.kind != TokenKind.blockquote &&
              token.kind != TokenKind.listMarker &&
              token.kind != TokenKind.taskBox &&
              token.kind != TokenKind.headingMarker)) {
        return at;
      }
      at = token.end;
    }
  }

  /// Where an indented code line's indent ends: four columns in, a tab
  /// being all four, and no further — the spaces past them are the code's.
  static int _codeIndentEnd(String text) {
    var at = 0;
    var columns = 0;
    while (at < text.length && columns < 4) {
      final unit = text.codeUnitAt(at);
      if (unit == 0x09) {
        columns = 4;
      } else if (unit == 0x20) {
        columns++;
      } else {
        break;
      }
      at++;
    }
    return at;
  }

  /// Where the line's text is drawn from, past its prefix — hidden whole,
  /// or on the caret's line as written — in the paragraph's own shaping.
  ///
  /// Measured to the first glyph of the text, not to the end of the
  /// prefix: under an ambient letter spacing a paragraph's first glyph is
  /// drawn half a spacing in, and one after a hidden mark (which has none)
  /// is not, so a lazy line's text stood an eighth of a pixel right of its
  /// item's.
  double _textStart(BuildContext context, {required bool revealed}) {
    final end = prefixEnd;
    final text = styled.text;
    final spans = <InlineSpan>[];
    if (!revealed) {
      if (end > 0) {
        spans.add(
          TextSpan(text: text.substring(0, end), style: liveHiddenMarker),
        );
      }
      return _glyphLeft(context, spans);
    }
    var at = 0;
    for (final token in styled.tokens) {
      if (token.start >= end) break;
      if (token.start > at) {
        spans.add(TextSpan(text: text.substring(at, token.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(token.start, token.end),
          style: nestedTokenStyle(token, syntax, dark: dark),
        ),
      );
      at = token.end;
    }
    if (at < end) spans.add(TextSpan(text: text.substring(at, end)));
    return _glyphLeft(context, spans);
  }

  /// Where a glyph set after [spans] is drawn, as the line's paragraph sets
  /// them: the paragraph's style is the line's over the ambient one, whose
  /// letter spacing moves a glyph as the paragraph moves it. The glyph is a
  /// probe — where it starts is the spacing's, not its own shape's.
  double _glyphLeft(BuildContext context, List<InlineSpan> spans) {
    final style = DefaultTextStyle.of(context).style
        .merge(lineStyle(revealed: false));
    var length = 0;
    for (final span in spans) {
      length += (span as TextSpan).text?.length ?? 0;
    }
    final painter = TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          ...spans,
          const TextSpan(text: 'x'),
        ],
        style: style,
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: length, extentOffset: length + 1),
    );
    painter.dispose();
    return boxes.isEmpty ? 0 : boxes.first.left;
  }
}
