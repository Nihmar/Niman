/// Markdown + math-span tokenizer for the source editor and the preview
/// math pipeline.
///
/// Highlighting is a display concern only (design.md): this module turns a
/// plain-text buffer into styled lines; it never models edits, and the edit
/// model stays a plain string.
///
/// Block state carried across lines: fenced code (a run of at least three
/// backticks or tildes; the closer is the same char at least as long, alone
/// on its line), display math (`$$` on a line; a line of exactly `$$…$$` is
/// single-line), and a leading frontmatter block (`---` as the very first
/// line, closed by `---` or `...`). Everything else is per-line syntax.
///
/// [HighlightDocument] keeps the per-line state so a single edit re-tokenizes
/// only the changed lines plus as many following lines as needed until the
/// carried state converges on an unchanged line — typically one or two lines,
/// worst case (an edit before an unclosed fence) the rest of the file.
library;

import 'package:meta/meta.dart';

/// The kind of a styled run within a line.
enum TokenKind {
  /// Plain text. Not emitted as a token: any offset not covered by a token
  /// is plain.
  plain,

  /// The `#` markers of a heading line.
  headingMarker,

  /// Bold (`**…**` or `__…__`).
  bold,

  /// Italic (`*…*` or `_…_`).
  italic,

  /// Strikethrough (`~~…~~`).
  strike,

  /// An inline code span (`` `…` ``).
  codeInline,

  /// A line of a fenced code block (fence lines and content).
  codeFence,

  /// The language info on a fence-opening line.
  codeLanguage,

  /// A link (`[text](url)`).
  link,

  /// An image (`![alt](url)`).
  image,

  /// A wikilink (`[[target]]`, `[[target|alias]]`, `[[target#heading]]`).
  wikilink,

  /// A list marker (`-`, `*`, `+`, `1.`, `1)`).
  listMarker,

  /// A task-list checkbox (`[ ]` or `[x]`).
  taskBox,

  /// A blockquote marker (`>`).
  blockquote,

  /// A horizontal rule line.
  horizontalRule,

  /// Inline math (`$…$`).
  mathInline,

  /// A display-math line (a `$$` block line, or single-line `$$…$$`).
  mathBlock,

  /// An inline tag (`#tag`).
  tag,

  /// A line of the leading frontmatter block.
  frontmatter,
}

/// One styled run of a line; offsets are relative to [StyledLine.text].
///
/// A line's tokens are disjoint and sorted by [start]; the region after a
/// [TokenKind.headingMarker] token up to end-of-line is styled as heading
/// text by the painter.
@immutable
final class Token {
  /// Creates a token of [kind] covering [start]..[end).
  const Token(this.kind, this.start, this.end);

  /// The style of the run.
  final TokenKind kind;

  /// Offset of the first character of the run.
  final int start;

  /// Offset one past the last character of the run.
  final int end;

  /// `kind[start,end)="text"`; for tests and logs.
  String describe(String line) =>
      '$kind[$start,$end)="${line.substring(start, end)}"';

  @override
  bool operator ==(Object other) =>
      other is Token &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}

/// One line of the display text with its tokens; anything not covered by a
/// token is [TokenKind.plain].
final class StyledLine {
  /// Creates a styled line.
  const StyledLine(this.text, this.tokens);

  /// The line text (without newline).
  final String text;

  /// The line's tokens, sorted by [Token.start]; disjoint.
  final List<Token> tokens;
}

/// A math span in absolute text offsets, markers included (`$…$` / `$$…$$`).
final class MathSpan {
  /// Creates a math span covering [start]..[end).
  const MathSpan(this.start, this.end, {required this.block});

  /// Offset of the opening marker.
  final int start;

  /// Offset one past the closing marker.
  final int end;

  /// True for `$$…$$` spans; false for `$…$`.
  final bool block;
}

/// The fence a line is inside.
@immutable
final class _Fence {
  const _Fence(this.char, this.len);

  /// Code unit of the fence char (backtick or tilde).
  final int char;

  /// Length of the opening run.
  final int len;

  @override
  bool operator ==(Object other) =>
      other is _Fence && other.char == char && other.len == len;

  @override
  int get hashCode => Object.hash(char, len);
}

/// The carried block state.
@immutable
final class _State {
  const _State({this.fence, this.inMath = false, this.inFrontmatter = false});

  final _Fence? fence;
  final bool inMath;
  final bool inFrontmatter;

  static const _State initial = _State();

  @override
  bool operator ==(Object other) {
    if (other is! _State) return false;
    final f = fence;
    final o = other.fence;
    return (f == null
            ? o == null
            : o != null && o.char == f.char && o.len == f.len) &&
        inMath == other.inMath &&
        inFrontmatter == other.inFrontmatter;
  }

  @override
  int get hashCode {
    final f = fence;
    return Object.hash(
        f == null ? -1 : f.char, f == null ? -2 : f.len,
        inMath, inFrontmatter);
  }
}

final class _Line {
  _Line(this.text);

  final String text;

  late _State entering;
  late _State exit;
  late List<Token> tokens;
}

/// Incremental highlighter over a plain-text buffer.
///
/// Build once with `fromText`; after every buffer edit call `replace` with
/// the single edit region. Typical cost is one or two lines.
final class HighlightDocument {
  HighlightDocument._();

  /// Tokenizes [text] fully.
  factory HighlightDocument.fromText(String text) {
    final doc = HighlightDocument._();
    final raw = text.isEmpty ? <String>[''] : text.split('\n');
    final lines = <_Line>[];
    for (final t in raw) {
      final line = _Line(t);
      _tokenizeAt(lines, lines.length, line);
      lines.add(line);
    }
    doc._lines = lines;
    return doc;
  }

  List<_Line> _lines = const [];

  /// The current display text (lines joined with `\n`).
  String get text => _lines.map((l) => l.text).join('\n');

  /// The styled lines.
  List<StyledLine> get lines =>
      _lines.map((l) => StyledLine(l.text, l.tokens)).toList();

  /// Math spans over the current buffer; see [mathSpansIn].
  List<MathSpan> mathSpans() => mathSpansIn(text);

  /// Applies the edit: offsets [start]..[end] of [text] are replaced by
  /// [replacement]. Offsets must satisfy `0 <= start <= end <= text.length`.
  void replace(int start, int end, String replacement) {
    if (start < 0 || end > text.length || start > end) {
      throw ArgumentError(
        'edit [$start,$end) out of range for ${text.length} chars',
      );
    }
    final lineStarts = _lineStarts();
    final first = _lineAt(lineStarts, start);
    final firstOffset = start - lineStarts[first];
    final last = end == start ? first : _lineAt(lineStarts, end - 1);
    final lastOffset = end - lineStarts[last];
    // Offsets are positions in the full text; the `\n` after line `last`
    // sits at `lineStarts[last] + length(last)`. When the edit reaches it,
    // the newline is deleted and line `last` merges with line `last + 1`.
    final eatsSeparator = lastOffset > _lines[last].text.length;
    final lastLine = eatsSeparator ? last + 1 : last;

    final replacementLines = replacement.split('\n');
    final region = <String>[
      _lines[first].text.substring(0, firstOffset) + replacementLines.first,
      ...replacementLines.skip(1),
    ];
    final kept = lastOffset > _lines[last].text.length
        ? _lines[last].text.length
        : lastOffset;
    final suffix = _lines[last].text.substring(kept) +
        (eatsSeparator && last + 1 < _lines.length
            ? _lines[last + 1].text
            : '');
    region.last += suffix;

    final tail = <_Line>[
      ..._lines.sublist(0, first),
      for (final t in region) _Line(t),
    ];
    // Tokenize the rebuilt region against the real preceding lines.
    for (var i = first; i < tail.length; i++) {
      _tokenizeAt(tail, i, tail[i]);
    }
    // Extend with unchanged old lines until the carried state converges on
    // a line whose entering state matches the original: that line and every
    // line after it keep their original tokens.
    var state = tail.last.exit;
    var oldIndex = lastLine + 1;
    var nextIndex = tail.length;
    while (oldIndex < _lines.length) {
      final old = _lines[oldIndex];
      if (state == old.entering) {
        tail.addAll(_lines.sublist(oldIndex));
        break;
      }
      tail.add(old);
      _tokenizeAt(tail, nextIndex, old);
      state = old.exit;
      nextIndex++;
      oldIndex++;
    }
    _lines = tail;
  }

  static void _tokenizeAt(List<_Line> lines, int index, _Line line) {
    final entering =
        index == 0 ? _State.initial : lines[index - 1].exit;
    line.entering = entering;
    line.exit = _stateAfter(line.text, entering, index);
    line.tokens = _lineTokens(line.text, entering, index);
  }

  List<int> _lineStarts() {
    final starts = <int>[];
    var at = 0;
    for (final line in _lines) {
      starts.add(at);
      at += line.text.length + 1;
    }
    starts.add(at);
    return starts;
  }

  /// The line containing [offset] (an offset at `text.length` is the last
  /// line). [starts] has [List.length] + 1 entries.
  static int _lineAt(List<int> starts, int offset) {
    var lo = 0;
    var hi = starts.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (starts[mid] <= offset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final index = lo - 1;
    if (index < 0) return 0;
    if (index >= starts.length - 1) return starts.length - 2;
    return index;
  }

  /// The state after [text], given the state entering the line.
  static _State _stateAfter(String text, _State inState, int lineIndex) {
    final fence = inState.fence;
    if (fence != null) {
      return _isFenceClose(text, fence) ? _State.initial : inState;
    }
    if (inState.inMath) {
      return text.trim().startsWith(r'$$') ? _State.initial : inState;
    }
    if (inState.inFrontmatter) {
      final t = text.trim();
      return t == '---' || t == '...' ? _State.initial : inState;
    }
    if (lineIndex == 0 && text.trim() == '---') {
      return const _State(inFrontmatter: true);
    }
    final fenceOpen = _fenceOpen(text);
    if (fenceOpen != null) {
      return _State(fence: fenceOpen);
    }
    final t = text.trim();
    if (t.startsWith(r'$$') && !_isSingleLineMath(t)) {
      return const _State(inMath: true);
    }
    return _State.initial;
  }

  static bool _isSingleLineMath(String trimmed) =>
      _isSingleLineMathPub(trimmed);

  static _Fence? _fenceOpen(String text) {
    final info = _fenceOpenInfo(text);
    return info == null ? null : _Fence(info.$1, info.$2);
  }

  static bool _isFenceClose(String text, _Fence fence) =>
      _isFenceCloseInfo(text, fence.char, fence.len);

  static List<Token> _lineTokens(
    String text,
    _State inState,
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
    final fenceOpen = _fenceOpen(text);
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
          Token(
            TokenKind.codeLanguage,
            infoStart,
            infoStart + info.length,
          ),
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
    var hashes = 0;
    while (hashes < text.length && text.codeUnitAt(hashes) == 0x23) {
      hashes++;
    }
    if (hashes >= 1 &&
        hashes <= 6 &&
        (hashes == text.length || _isSpaceChar(text.codeUnitAt(hashes)))) {
      tokens.add(Token(TokenKind.headingMarker, 0, hashes));
      _InlineScanner.scan(tokens, text, hashes);
      return tokens;
    }

    // Blockquote: up to three spaces, then one or more `>` (whitespace or
    // end of line after).
    var q = 0;
    while (q < 3 && q < text.length && _isSpaceChar(text.codeUnitAt(q))) {
      q++;
    }
    if (q < text.length && text.codeUnitAt(q) == 0x3E) {
      var qEnd = q;
      while (qEnd < text.length && text.codeUnitAt(qEnd) == 0x3E) {
        qEnd++;
      }
      final afterQuote = qEnd < text.length ? text.codeUnitAt(qEnd) : -1;
      if (afterQuote == -1 || _isSpaceChar(afterQuote)) {
        tokens.add(Token(TokenKind.blockquote, q, qEnd));
        _InlineScanner.scan(tokens, text, qEnd);
        return tokens;
      }
    }

    // List item: indent, then a `-`/`*`/`+` or digit(s) plus `.`/`)` marker,
    // with whitespace or end of line after the marker.
    var m = 0;
    while (m < text.length && _isSpaceChar(text.codeUnitAt(m))) {
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
      if (afterMarker == -1 || _isSpaceChar(afterMarker)) {
        tokens.add(Token(TokenKind.listMarker, m, mEnd));
        var from = mEnd;
        while (from < text.length && _isSpaceChar(text.codeUnitAt(from))) {
          from++;
        }
        if (from + 3 <= text.length &&
            text.codeUnitAt(from) == 0x5B &&
            (text.codeUnitAt(from + 1) == 0x20 ||
                text.codeUnitAt(from + 1) == 0x78 ||
                text.codeUnitAt(from + 1) == 0x58) &&
            text.codeUnitAt(from + 2) == 0x5D) {
          final afterBox =
              from + 3 < text.length ? text.codeUnitAt(from + 3) : -1;
          if (afterBox == -1 || _isSpaceChar(afterBox)) {
            tokens.add(Token(TokenKind.taskBox, from, from + 3));
            from += 3;
            if (from < text.length && _isSpaceChar(text.codeUnitAt(from))) {
              from++;
            }
          }
        }
        _InlineScanner.scan(tokens, text, from);
        return tokens;
      }
    }

    _InlineScanner.scan(tokens, text, 0);
    return tokens;
  }

  static final RegExp _hr =
      RegExp(r'^\s{0,3}((?:-{3,})|(?:\*{3,})|(?:_{3,}))\s*$');
}

/// All math spans in [text], absolute offsets, markers included.
///
/// `$$…$$` (single-line or multi-line) spans are [MathSpan.block]; `$…$`
/// spans are inline. Rules: inline math opens at a `$` whose next char is
/// not whitespace or `$`, closes at a `$` whose previous char is not
/// whitespace, is not `\$`, and is not followed by a digit; a display block
/// opens at a line starting with `$$` (unless the line ends with `$$` again)
/// and closes at the next such line; an unterminated block spans to EOF.
List<MathSpan> mathSpansIn(String text) {
  final lines = text.isEmpty ? <String>[''] : text.split('\n');
  final spans = <MathSpan>[];
  var fenceChar = 0;
  var fenceLen = 0;
  var inFence = false;
  var inFm = false;
  var inMath = false;
  var mathStart = 0;
  var offset = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    final lineStart = offset;
    offset = lineStart + line.length + 1;
    final lineEnd = lineStart + line.length;
    if (inFence) {
      if (_isFenceCloseInfo(line, fenceChar, fenceLen)) inFence = false;
      continue;
    }
    final fenceOpen = _fenceOpenInfo(line);
    if (fenceOpen != null) {
      inFence = true;
      fenceChar = fenceOpen.$1;
      fenceLen = fenceOpen.$2;
      continue;
    }
    if (inFm) {
      if (trimmed == '---' || trimmed == '...') inFm = false;
      continue;
    }
    if (i == 0 && trimmed == '---') {
      inFm = true;
      continue;
    }
    if (inMath) {
      if (trimmed.startsWith(r'$$')) {
        final indent = line.length - line.trimLeft().length;
        spans.add(MathSpan(
          mathStart,
          lineStart + indent + 2,
          block: true,
        ));
        inMath = false;
      } else if (i == lines.length - 1) {
        spans.add(MathSpan(mathStart, lineEnd, block: true));
        inMath = false;
      }
      continue;
    }
    if (trimmed.startsWith(r'$$')) {
      if (_isSingleLineMathPub(trimmed)) {
        final indent = line.length - line.trimLeft().length;
        spans.add(MathSpan(
          lineStart + indent,
          lineStart + indent + trimmed.length,
          block: true,
        ));
      } else {
        inMath = true;
        mathStart = lineStart + (line.length - line.trimLeft().length);
      }
      continue;
    }
    for (final (s, e) in _allInlineMath(line)) {
      spans.add(MathSpan(lineStart + s, lineStart + e, block: false));
    }
  }
  spans.sort((a, b) => a.start.compareTo(b.start));
  return spans;
}

bool _isSingleLineMathPub(String trimmed) =>
    trimmed.length >= 4 &&
    trimmed.startsWith(r'$$') &&
    trimmed.endsWith(r'$$');

bool _isSpaceChar(int c) =>
    c == 0x20 ||
    c == 0x09 ||
    c == 0x0A ||
    c == 0x0B ||
    c == 0x0C ||
    c == 0x0D;

/// `$…$` at/after [from] under the inline-math rules.
(int, int)? _findMath(String line, int from) {
  for (var i = from; i < line.length; i++) {
    if (line.codeUnitAt(i) != 0x24) continue;
    final after = i + 1;
    if (after >= line.length) continue;
    final a = line.codeUnitAt(after);
    if (a == 0x24 || _isSpaceChar(a)) continue;
    for (var j = after; j < line.length; j++) {
      if (line.codeUnitAt(j) != 0x24) continue;
      final before = line.codeUnitAt(j - 1);
      if (before == 0x5C || _isSpaceChar(before)) continue;
      final nextCh = j + 1 < line.length ? line.codeUnitAt(j + 1) : -1;
      if (nextCh >= 0x30 && nextCh <= 0x39) continue;
      return (i, j + 1);
    }
  }
  return null;
}

/// All `$…$` spans in [line].
Iterable<(int, int)> _allInlineMath(String line) sync* {
  var pos = 0;
  while (pos < line.length) {
    final m = _findMath(line, pos);
    if (m == null) return;
    yield m;
    pos = m.$2;
  }
}

/// The fence-opening run at the start of [text] (at least three backticks
/// or tildes, nothing but whitespace/language after) or null.
(int, int)? _fenceOpenInfo(String text) {
  final t = text.trimLeft();
  if (t.length < 3) return null;
  final c0 = t.codeUnitAt(0);
  if (c0 != 0x60 && c0 != 0x7E) return null;
  var len = 0;
  while (len < t.length && t.codeUnitAt(len) == c0) {
    len++;
  }
  if (len < 3) return null;
  final rest = t.substring(len);
  if (rest.startsWith('`') || rest.startsWith('~')) return null;
  return (c0, len);
}

/// Whether [text] closes a fence opened with [fenceChar]/[fenceLen]: the
/// line is exactly a run of the same char, at least as long.
bool _isFenceCloseInfo(String text, int fenceChar, int fenceLen) {
  final t = text.trim();
  if (t.isEmpty) return false;
  var len = 0;
  while (len < t.length && t.codeUnitAt(len) == fenceChar) {
    len++;
  }
  return len >= fenceLen && t.length == len;
}

final class _InlineScanner {
  static final RegExp _image = RegExp(r'!\[[^\]\n]*\]\([^()\n]*\)');
  static final RegExp _link = RegExp(r'\[[^\[\]\n]*\]\([^()\n]*\)');
  static final RegExp _wiki = RegExp(r'\[\[[^\[\]\n]*\]\]');
  static final RegExp _boldStar = RegExp(r'\*\*[^*\n]+\*\*');
  static final RegExp _boldUnder = RegExp('__(?:[^_]|_(?:[^_]))+__');
  static final RegExp _strike = RegExp(r'~~[^~\n]+~~');
  static final RegExp _italicStar = RegExp(r'\*[^*\n]+\*');
  static final RegExp _italicUnder = RegExp('_(?:[^_]|_(?:[^_]))+_');
  static final RegExp _tag = RegExp(r'#([\w/-]+)');

  /// The first match of [re] in [line] at/after [pos] (or null).
  static RegExpMatch? _first(RegExp re, String line, int pos) {
    final it = re.allMatches(line, pos).iterator;
    return it.moveNext() ? it.current : null;
  }

  static void scan(List<Token> out, String line, int from) {
    var pos = from;
    while (pos < line.length) {
      var bestKind = TokenKind.plain;
      var bestStart = -1;
      var bestEnd = -1;
      void consider(TokenKind kind, int start, int end) {
        if (start < pos || end <= start) return;
        if (bestStart == -1 || start < bestStart) {
          bestKind = kind;
          bestStart = start;
          bestEnd = end;
        }
      }

      final code = _findCode(line, pos);
      if (code != null) {
        consider(TokenKind.codeInline, code.$1, code.$2);
      }
      final math = _findMath(line, pos);
      if (math != null) {
        consider(TokenKind.mathInline, math.$1, math.$2);
      }
      final image = _first(_image, line, pos);
      if (image != null) {
        consider(TokenKind.image, image.start, image.end);
      }
      final wiki = _first(_wiki, line, pos);
      if (wiki != null) {
        consider(TokenKind.wikilink, wiki.start, wiki.end);
      }
      final link = _first(_link, line, pos);
      if (link != null) {
        consider(TokenKind.link, link.start, link.end);
      }
      final boldStar = _first(_boldStar, line, pos);
      if (boldStar != null) {
        consider(TokenKind.bold, boldStar.start, boldStar.end);
      }
      final boldUnder = _first(_boldUnder, line, pos);
      if (boldUnder != null) {
        consider(TokenKind.bold, boldUnder.start, boldUnder.end);
      }
      final strike = _first(_strike, line, pos);
      if (strike != null) {
        consider(TokenKind.strike, strike.start, strike.end);
      }
      final italicStar = _findItalicStar(line, pos);
      if (italicStar != null) {
        consider(TokenKind.italic, italicStar.$1, italicStar.$2);
      }
      final italicUnder = _findItalicUnder(line, pos);
      if (italicUnder != null) {
        consider(TokenKind.italic, italicUnder.$1, italicUnder.$2);
      }
      final tag = _first(_tag, line, pos);
      if (tag != null) {
        final precededBySpace =
            tag.start == 0 || _isSpaceChar(line.codeUnitAt(tag.start - 1));
        if (precededBySpace) {
          consider(TokenKind.tag, tag.start, tag.end);
        }
      }

      if (bestStart == -1) break;
      out.add(Token(bestKind, bestStart, bestEnd));
      pos = bestEnd;
    }
  }

  /// `` `code` `` at/after [from]: the backtick run must close with a run of
  /// the same length (a maximal run). Returns (start, end) or null.
  static (int, int)? _findCode(String line, int from) {
    var i = from;
    while (i < line.length && line.codeUnitAt(i) != 0x60) {
      i++;
    }
    if (i >= line.length) return null;
    final runStart = i;
    var run = 0;
    while (i < line.length && line.codeUnitAt(i) == 0x60) {
      run++;
      i++;
    }
    var k = i;
    while (k < line.length) {
      final next = line.indexOf('`', k);
      if (next == -1) return null;
      var len2 = 0;
      var m = next;
      while (m < line.length && line.codeUnitAt(m) == 0x60) {
        len2++;
        m++;
      }
      if (len2 == run) {
        return (runStart, m);
      }
      k = m;
    }
    return null;
  }

  /// `*…*` not part of `**`; validated because Dart regex has no lookbehind.
  static (int, int)? _findItalicStar(String line, int from) {
    var pos = from;
    while (pos < line.length) {
      final m = _first(_italicStar, line, pos);
      if (m == null) return null;
      final okBefore = m.start == 0 || line.codeUnitAt(m.start - 1) != 0x2A;
      final okAfter = m.end >= line.length || line.codeUnitAt(m.end) != 0x2A;
      if (okBefore && okAfter) return (m.start, m.end);
      pos = m.start + 1;
    }
    return null;
  }

  /// `_…_` not intra-word.
  static (int, int)? _findItalicUnder(String line, int from) {
    var pos = from;
    while (pos < line.length) {
      final m = _first(_italicUnder, line, pos);
      if (m == null) return null;
      final okBefore = m.start == 0 ||
          !(_isWord(line.codeUnitAt(m.start - 1)) ||
              line.codeUnitAt(m.start - 1) == 0x5F);
      final afterCh = m.end < line.length ? line.codeUnitAt(m.end) : -1;
      final okAfter = afterCh == -1 || (!_isWord(afterCh) && afterCh != 0x5F);
      if (okBefore && okAfter) return (m.start, m.end);
      pos = m.start + 1;
    }
    return null;
  }

  static bool _isWord(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0x30 && c <= 0x39);
}
