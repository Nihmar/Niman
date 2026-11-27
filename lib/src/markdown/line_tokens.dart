/// What source mode colours on a line, built from what is known of it: a
/// fence's, a div's and a heading's marks, and the pieces of a line made
/// disjoint tokens. Static and pure; `SourceStyler` decides which block a
/// line is in and what its inline parse says, and puts them here.
library;

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/live_inlines.dart';

/// The tokens of a line, from its block and its pieces.
abstract final class LineTokens {
  /// A fenced div's fence line (#729): its colons as a fence's, and its
  /// attributes as a fence's language.
  static List<Token> div(String text) {
    final start = text.indexOf(':');
    if (start < 0) return const <Token>[];
    var end = start;
    while (end < text.length && text.codeUnitAt(end) == 0x3A) {
      end++;
    }
    final rest = text.substring(end);
    final attributes = rest.trim().replaceFirst(RegExp(r'[:\s]*$'), '');
    if (attributes.isEmpty) {
      return <Token>[Token(TokenKind.codeFence, start, end)];
    }
    final at = end + rest.indexOf(attributes);
    final after = at + attributes.length;
    final closing = text.trimRight().length;
    return <Token>[
      Token(TokenKind.codeFence, start, end),
      Token(TokenKind.codeLanguage, at, after),
      if (closing > after) Token(TokenKind.codeFence, after, closing),
    ];
  }

  /// A fence's line: all of it code, and the opening line's language.
  ///
  /// Disjoint, as every line's tokens are: the language cuts the fence line
  /// in three rather than lying on top of it.
  static List<Token> fence(Block block, int line, String text) {
    final whole = <Token>[Token(TokenKind.codeFence, 0, text.length)];
    // A fence opened on an item's marker line (`- ```js`) was open when the
    // block's first line came: that line is already code, and the opener is
    // the item's ([fenceOpening]).
    if (line != block.startLine || block.entering?.fence != null) {
      // The code itself, unless this is the fence that closes the block.
      final closing =
          line == block.endLine - 1 && _closesFence(text.trimLeft());
      return closing
          ? whole
          : <Token>[Token(TokenKind.codeBlock, 0, text.length)];
    }
    final info = block.fenceInfo;
    if (info == null) return whole;
    final at = text.indexOf(info);
    if (at < 0) return whole;
    final end = at + info.length;
    return <Token>[
      Token(TokenKind.codeFence, 0, at),
      Token(TokenKind.codeLanguage, at, end),
      if (end < text.length) Token(TokenKind.codeFence, end, text.length),
    ];
  }

  /// The fence [text] opens past the marks that end at [from] — an item's
  /// marker — if it opens one, added to [out] as a fence's line is: the
  /// fence and what follows its language, and the language. The scanner
  /// puts that line in the item, and the fence's block starts under it.
  static void fenceOpening(String text, int from, List<InlinePiece> out) {
    final rest = from == 0 ? text : text.substring(from);
    final marker = LineSyntax.fenceOpen(rest);
    if (marker == null) return;
    final info = rest
        .substring(marker.indent + marker.length)
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    final at = info.isEmpty
        ? text.length
        : text.indexOf(info, from + marker.indent + marker.length);
    final end = at + info.length;
    InlinePiece piece(TokenKind kind, int start, int to) =>
        InlinePiece(kind, start, to, structural);
    out.add(piece(TokenKind.codeFence, from, at));
    if (info.isEmpty) return;
    out.add(piece(TokenKind.codeLanguage, at, end));
    if (end < text.length) {
      out.add(piece(TokenKind.codeFence, end, text.length));
    }
  }

  /// Whether [text], a code block's last line trimmed, is its closing fence
  /// rather than code: a block the note did not close ends on its code.
  static bool _closesFence(String text) =>
      text.startsWith('```') || text.startsWith('~~~');

  /// A quote depth no line reaches: how far a line's own quote marks go.
  static const int _anyDepth = 1 << 16;

  /// The structural marks at the start of [text] — quote marks, a list
  /// marker and its task box, a heading's hashes — added to [out]; answers
  /// where they end, before which no inline token is put.

  static int structure(
    Block block,
    int line,
    String text,
    int prefix,
    List<InlinePiece> out,
  ) {
    // Every quote mark the line has, not only the block's: a quote that
    // opens at one level and goes a level deeper — `> a` then `> > b` — is one
    // block at the first level, and the second `>` is as much syntax as the
    // first (`live` drew it as text).
    final own = BlockParser.quotePrefixLength(text, _anyDepth);
    final marks = own > prefix ? own : prefix;
    for (var at = 0; at < marks; at++) {
      if (text.codeUnitAt(at) == 0x3E) {
        out.add(InlinePiece(TokenKind.blockquote, at, at + 1, structural));
      }
    }
    final opensItem =
        (block.kind == BlockKind.listItem && line == block.startLine) ||
        block.kind == BlockKind.quote;
    var from = opensItem ? listMarker(text, marks, out) : marks;
    // A heading block is one the scanner decided; a quote's inside is not,
    // and a `#` four spaces into it is code, not a heading.
    final heading = LineSyntax.headingMarkerOf(
      from == 0 ? text : text.substring(from),
      block.kind == BlockKind.quote ? 3 : null,
    );
    if (heading != null &&
        (block.kind == BlockKind.heading || block.kind == BlockKind.quote)) {
      // The `#`s where they stand: a heading may be indented, in an item or
      // up to three spaces from the margin, and the spaces are not marker.
      final (start, hashes) = heading;
      out.add(
        InlinePiece(
          TokenKind.headingMarker,
          from + start,
          from + start + hashes,
          structural,
        ),
      );
      from += start + hashes;
      if (block.kind == BlockKind.heading) headingClose(text, from, out);
    }
    return from;
  }

  /// The closing `#`s of the ATX heading on [text] whose opening marker ends
  /// at [from], if it has any, added to [out] as a marker as the opening
  /// ones are.
  static void headingClose(String text, int from, List<InlinePiece> out) {
    final close = LineSyntax.headingCloseOf(text, from);
    if (close == null) return;
    out.add(
      InlinePiece(TokenKind.headingMarker, close.$1, close.$2, structural),
    );
  }

  /// The list marker at [at] of [text], if one stands there, and its task
  /// box, added to [out]; answers where they end: [at] when there is none.
  static int listMarker(String text, int at, List<InlinePiece> out) {
    final marker = LineSyntax.listMarkerOf(at == 0 ? text : text.substring(at));
    if (marker == null) return at;
    final (start, width, content) = marker;
    out.add(
      InlinePiece(
        TokenKind.listMarker,
        at + start,
        at + start + width,
        structural,
      ),
    );
    var from = at + content;
    if (from + 3 <= text.length &&
        text.codeUnitAt(from) == 0x5B &&
        _isBoxMark(text.codeUnitAt(from + 1)) &&
        text.codeUnitAt(from + 2) == 0x5D &&
        (from + 3 == text.length || _isSpace(text.codeUnitAt(from + 3)))) {
      out.add(InlinePiece(TokenKind.taskBox, from, from + 3, structural));
      from += 3;
    }
    return from;
  }

  static bool _isBoxMark(int char) =>
      char == 0x20 || char == 0x78 || char == 0x58;

  static bool _isSpace(int char) => char == 0x20 || char == 0x09;

  /// The depth a structural mark wins at: nothing inline overlaps one.
  static const int structural = 1 << 20;

  /// [pieces], which may nest, as disjoint tokens: each stretch of the line
  /// takes the deepest piece over it. Inline pieces before [marksEnd] are
  /// dropped — the parse sees no marks there.
  static List<Token> flatten(List<InlinePiece> pieces, int marksEnd) {
    if (pieces.isEmpty) return const <Token>[];
    final cuts = <int>{};
    for (final piece in pieces) {
      cuts
        ..add(piece.start)
        ..add(piece.end);
    }
    final points = cuts.toList()..sort();
    final tokens = <Token>[];
    for (var at = 0; at + 1 < points.length; at++) {
      final from = points[at];
      final to = points[at + 1];
      InlinePiece? best;
      for (final piece in pieces) {
        if (piece.start > from || piece.end < to) continue;
        if (piece.depth < structural && from < marksEnd) continue;
        if (best == null || piece.depth >= best.depth) best = piece;
      }
      if (best == null) continue;
      final outer = best.depth < structural
          ? _outerOf(pieces, best, from, to)
          : const <TokenKind>[];
      final last = tokens.isEmpty ? null : tokens.last;
      if (last != null &&
          last.end == from &&
          last.kind == best.kind &&
          last.marker == best.marker &&
          _sameKinds(last.outer, outer) &&
          best.depth < structural) {
        tokens[tokens.length - 1] = Token(
          last.kind,
          last.start,
          to,
          marker: last.marker,
          outer: last.outer,
        );
      } else {
        tokens.add(
          Token(best.kind, from, to, marker: best.marker, outer: outer),
        );
      }
    }
    return tokens;
  }

  /// The inline constructs around [inner] over `[from, to)`, outermost
  /// first: the text of the pieces shallower than it that cover the stretch,
  /// each kind once. A construct's markers are its own syntax and style
  /// nothing inside it, so a marker piece is none of them.
  static List<TokenKind> _outerOf(
    List<InlinePiece> pieces,
    InlinePiece inner,
    int from,
    int to,
  ) {
    final around = <InlinePiece>[
      for (final piece in pieces)
        if (!identical(piece, inner) &&
            !piece.marker &&
            piece.depth < inner.depth &&
            piece.start <= from &&
            piece.end >= to)
          piece,
    ];
    if (around.isEmpty) return const <TokenKind>[];
    around.sort((a, b) => a.depth.compareTo(b.depth));
    final kinds = <TokenKind>[];
    for (final piece in around) {
      if (piece.kind != inner.kind && !kinds.contains(piece.kind)) {
        kinds.add(piece.kind);
      }
    }
    return kinds.isEmpty ? const <TokenKind>[] : List.unmodifiable(kinds);
  }

  static bool _sameKinds(List<TokenKind> a, List<TokenKind> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }
}
