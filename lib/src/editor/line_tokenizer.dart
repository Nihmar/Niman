import 'package:niman/src/editor/block_state.dart';
import 'package:niman/src/editor/code_fence.dart';
import 'package:niman/src/editor/inline_token_scanner.dart';
import 'package:niman/src/editor/token.dart';
import 'package:niman/src/editor/token_kind.dart';

/// One line's tokens, given the block state entering it: the per-line half
/// of the highlighter, which `HighlightDocument` carries the state for.
abstract final class LineTokenizer {
  /// The number of `#` opening a heading on [text], or 0: one to six of
  /// them at offset zero, followed by whitespace or the end of the line.
  ///
  /// Block context is the caller's to rule out first. [lineTokens] and
  /// [headingIn] share this, so the highlight and the outline cannot
  /// disagree about what counts as a heading.
  /// Where the `#`s of an ATX heading on [text] start and how many there
  /// are, or null: up to three spaces in, as CommonMark and the block
  /// scanner read it (`LineSyntax.headingMarkerOf`).
  static (int, int)? _headingHashes(String text) {
    var at = 0;
    while (at < 3 && at < text.length && isSpaceChar(text.codeUnitAt(at))) {
      at++;
    }
    var hashes = 0;
    while (at + hashes < text.length && text.codeUnitAt(at + hashes) == 0x23) {
      hashes++;
    }
    if (hashes >= 1 &&
        hashes <= 6 &&
        (at + hashes == text.length ||
            isSpaceChar(text.codeUnitAt(at + hashes)))) {
      return (at, hashes);
    }
    return null;
  }

  /// The heading on [text] entered in [inState] — where its `#`s start and
  /// how many — or null.
  ///
  /// Mirrors the order of [lineTokens]'s early returns — fence content, a
  /// fence line, math, frontmatter, a horizontal rule — because a line that
  /// stops there never reaches the heading branch there either.
  static (int, int)? headingIn(String text, BlockState inState, int lineIndex) {
    if (inState.fence != null) return null;
    if (CodeFence.openedBy(text) != null) return null;
    final trimmed = text.trim();
    if (inState.inMath || trimmed.startsWith(r'$$')) return null;
    if (inState.inFrontmatter || (lineIndex == 0 && trimmed == '---')) {
      return null;
    }
    if (_hr.hasMatch(text)) return null;
    return _headingHashes(text);
  }

  /// The tokens of [text], the line at [lineIndex], entered in [inState].
  static List<Token> lineTokens(
    String text,
    BlockState inState,
    int lineIndex,
  ) {
    final tokens = <Token>[];
    final fence = inState.fence;
    final trimmed = text.trim();
    if (fence != null) {
      // Fence content or the closing fence line.
      tokens.add(Token(TokenKind.codeFence, 0, text.length));
      return tokens;
    }
    final fenceOpen = CodeFence.openedBy(text);
    if (fenceOpen != null) {
      tokens.add(Token(TokenKind.codeFence, 0, text.length));
      final indent = text.length - text.trimLeft().length;
      var run = 0;
      while (indent + run < text.length &&
          text.codeUnitAt(indent + run) == fenceOpen.char) {
        run++;
      }
      var infoStart = indent + run;
      while (infoStart < text.length &&
          (text.codeUnitAt(infoStart) == 0x20 ||
              text.codeUnitAt(infoStart) == 0x09)) {
        infoStart++;
      }
      final info = text.substring(infoStart).trim();
      if (info.isNotEmpty) {
        tokens.add(
          Token(TokenKind.codeLanguage, infoStart, infoStart + info.length),
        );
      }
      return tokens;
    }
    if (inState.inMath || trimmed.startsWith(r'$$')) {
      // Math block content, a closing line, or single-line `$$…$$`.
      tokens.add(Token(TokenKind.mathBlock, 0, text.length));
      return tokens;
    }
    if (inState.inFrontmatter || (lineIndex == 0 && trimmed == '---')) {
      tokens.add(Token(TokenKind.frontmatter, 0, text.length));
      return tokens;
    }
    if (_hr.hasMatch(text)) {
      return <Token>[Token(TokenKind.horizontalRule, 0, text.length)];
    }

    // Heading: `#`..`######` followed by whitespace or end of line.
    final heading = _headingHashes(text);
    if (heading != null) {
      final (start, hashes) = heading;
      tokens.add(Token(TokenKind.headingMarker, start, start + hashes));
      InlineTokenScanner.scan(tokens, text, start + hashes);
      return tokens;
    }

    // Blockquote: up to three spaces, then one or more `>` (whitespace or
    // end of line after).
    var q = 0;
    while (q < 3 && q < text.length && isSpaceChar(text.codeUnitAt(q))) {
      q++;
    }
    if (q < text.length && text.codeUnitAt(q) == 0x3E) {
      var qEnd = q;
      while (qEnd < text.length && text.codeUnitAt(qEnd) == 0x3E) {
        qEnd++;
      }
      final afterQuote = qEnd < text.length ? text.codeUnitAt(qEnd) : -1;
      if (afterQuote == -1 || isSpaceChar(afterQuote)) {
        tokens.add(Token(TokenKind.blockquote, q, qEnd));
        InlineTokenScanner.scan(tokens, text, qEnd);
        return tokens;
      }
    }

    // List item: indent, then a `-`/`*`/`+` or digit(s) plus `.`/`)` marker,
    // with whitespace or end of line after the marker.
    var m = 0;
    while (m < text.length && isSpaceChar(text.codeUnitAt(m))) {
      m++;
    }
    var mEnd = -1;
    if (m < text.length) {
      final c = text.codeUnitAt(m);
      if (c == 0x2D || c == 0x2A || c == 0x2B) {
        mEnd = m + 1;
      } else if (c >= 0x30 && c <= 0x39) {
        var d = m;
        while (d < text.length &&
            d - m < 9 &&
            text.codeUnitAt(d) >= 0x30 &&
            text.codeUnitAt(d) <= 0x39) {
          d++;
        }
        if (d < text.length &&
            (text.codeUnitAt(d) == 0x2E || text.codeUnitAt(d) == 0x29)) {
          mEnd = d + 1;
        }
      }
    }
    if (mEnd > 0) {
      final afterMarker = mEnd < text.length ? text.codeUnitAt(mEnd) : -1;
      if (afterMarker == -1 || isSpaceChar(afterMarker)) {
        tokens.add(Token(TokenKind.listMarker, m, mEnd));
        var from = mEnd;
        while (from < text.length && isSpaceChar(text.codeUnitAt(from))) {
          from++;
        }
        if (from + 3 <= text.length &&
            text.codeUnitAt(from) == 0x5B &&
            (text.codeUnitAt(from + 1) == 0x20 ||
                text.codeUnitAt(from + 1) == 0x78 ||
                text.codeUnitAt(from + 1) == 0x58) &&
            text.codeUnitAt(from + 2) == 0x5D) {
          final afterBox = from + 3 < text.length
              ? text.codeUnitAt(from + 3)
              : -1;
          if (afterBox == -1 || isSpaceChar(afterBox)) {
            tokens.add(Token(TokenKind.taskBox, from, from + 3));
            from += 3;
            if (from < text.length && isSpaceChar(text.codeUnitAt(from))) {
              from++;
            }
          }
        }
        InlineTokenScanner.scan(tokens, text, from);
        return tokens;
      }
    }

    InlineTokenScanner.scan(tokens, text, 0);
    return tokens;
  }

  static final RegExp _hr = RegExp(
    r'^\s{0,3}((?:-{3,})|(?:\*{3,})|(?:_{3,}))\s*$',
  );
}
