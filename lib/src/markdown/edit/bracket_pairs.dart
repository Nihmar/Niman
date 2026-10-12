/// Pairs typed in pairs, in `source` and in `live`: `(` writes `()`, `[`
/// writes `[]`, `{` writes `{}`, `*` writes `**` (the caret between), `"`
/// writes `""`, and so on.
///
/// What every code editor does, and what a Markdown note wants as much: a
/// link is `[text](target)`, a wikilink `[[note]]`, a task `- [ ] `, bold
/// `**bold**`, a quote `"an opening and its close"`. Four rules, each the
/// one a writer expects:
///
/// * an opening character closes itself when what follows is a space, the
///   line's end or a closing bracket — not before a word, where the writer
///   is wrapping something already written, and not after a backslash, where
///   `\(` opens inline math and wants `\)`. A star or a quote counts as
///   closing only when the pair wrote it: one already in the note may as
///   well open what follows, `*emph*` or `"quote"`, and a pair typed in
///   front of it would wrap nothing (#762);
/// * over a selection it wraps it instead, the selection kept inside;
/// * a closing character typed where the one the pair wrote stands steps over
///   it, so typing on through `(a)` does not leave `(a))`;
/// * Backspace between an empty pair takes both — for a symmetric one, `**`
///   or `""`, only when the pair wrote the closer.
///
/// Not every character is closed the same way (#718). The brackets pair
/// whenever there is room; the Markdown punctuation only sometimes does, and
/// each has its own rule:
///
/// * `*` — emphasis — pairs with one star, and the second typed over it
///   steps over, so `**bold**` falls out of the same open-and-step as the
///   brackets: `***bold italic***` too, three and three. A space right
///   after it makes it a literal star, which is what `* ` at the start of
///   a line — a list item — and `a * b` want; a second star right after
///   the first is the bold one, not another pair; and after a word it
///   closes, like `_`: `2*3`, `char *p` or the end of `*this*` (#762);
/// * `_` — emphasis too — opens only when no word stands before it:
///   `snake_case` and a closing `word_` are what they are;
/// * `"` (and `'`, `«`, `“`) open when no word stands before them: after a
///   word the quote closes one already spoken, like the apostrophe in
///   `don't`;
/// * `<`, `>` and `` ` `` do not pair at all: `a < b` is a comparison and
///   `<https://…>` an autolink — a pair would write `< >` in the first —
///   while a fence is three backticks and a code span is typed whole.
///
/// In code and maths — a fenced or indented code block, a code span, a `$$`
/// block or `$…$` — the Markdown punctuation is only itself: `char *p` is a
/// pointer, `$a * b$` a product and `'c'` a character, none of them an
/// emphasis or a quote. The brackets pair there as anywhere: code and
/// formulas are written with them.
library;

import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// An edit a bracket asks for: `[start, end)` replaced with `text`, and the
/// selection after it. An empty `text` over an empty range only moves the
/// caret.
typedef BracketEdit = ({
  int start,
  int end,
  String text,
  int anchor,
  int extent,
});

/// A closing bracket this pair wrote: on `line`, `fromEnd` characters from
/// its end counting itself — which the text typed before it leaves alone.
typedef _Closer = ({int line, int fromEnd, String char});

/// The brackets of one note's surface, and the closing ones it wrote.
final class BracketPairs {
  /// Every character that pairs and the one that closes it (#718): the
  /// brackets, and the punctuation a Markdown note is written with.
  static const Map<String, String> pairs = <String, String>{
    '(': ')',
    '[': ']',
    '{': '}',
    // One star written and one closing it; the second typed over it, so
    // `**bold**` falls out of the open-and-step the brackets use.
    '*': '*',
    '_': '_',
    // The straight quotes, and the two pairs a note is written in.
    '"': '"',
    "'": "'",
    '«': '»',
    '“': '”',
  };

  static final Set<String> _closing = pairs.values.toSet();

  /// The brackets: the pairs that pair in code and maths too. The rest is
  /// the Markdown punctuation, which there is only itself.
  static const Set<String> _brackets = {'(', '[', '{'};

  /// The closing characters that close only: the brackets' and the
  /// language's own quotes'. A star, an underscore or a straight quote
  /// opens as often as it closes (#762).
  static final Set<String> _closingOnly = {
    for (final MapEntry(:key, :value) in pairs.entries)
      if (key != value) value,
  };

  final List<_Closer> _closers = <_Closer>[];

  /// What typing [typed] over `[start, end)` of [buffer] does instead of
  /// inserting it; null when it is only typed.
  ///
  /// [verbatimAt] answers whether a caret at an offset stands in code or
  /// maths, where the Markdown punctuation neither opens a pair nor wraps a
  /// selection: asked only for that punctuation, once a keystroke.
  BracketEdit? typed(
    SourceBuffer buffer,
    int start,
    int end,
    String typed, {
    bool Function(int offset)? verbatimAt,
  }) {
    // A space between a `*` pair the pair wrote: a literal star with a
    // space after it — `* ` at the start of a line is a list item, and
    // `a * b` is a multiplication — so the closer is replaced by the
    // space (#718).
    if (start == end && typed == ' ') {
      final star = _spaceAfterStarPair(buffer, start);
      if (star != null) return star;
    }
    // A closing character this pair wrote, standing where the caret is:
    // stepped over, whichever character it is — the one that closes an
    // emphasis written open and stepped, the brackets as ever.
    if (start == end && _closing.contains(typed)) {
      final closer = _closerAt(buffer, start, typed);
      if (closer != null) {
        _closers.remove(closer);
        return (
          start: start,
          end: start,
          text: '',
          anchor: start + 1,
          extent: start + 1,
        );
      }
    }
    final close = pairs[typed];
    if (close == null) return null;
    if (!_brackets.contains(typed) && (verbatimAt?.call(start) ?? false)) {
      return null;
    }
    if (start != end) {
      final inside = buffer.substring(start, end);
      return (
        start: start,
        end: end,
        text: '$typed$inside$close',
        anchor: start + 1,
        extent: end + 1,
      );
    }
    if (!_opensAt(buffer, start, typed)) return null;
    final line = buffer.lineOf(start);
    final column = start - buffer.offsetOfLine(line);
    _closers.add((
      line: line,
      fromEnd: buffer.lineLengthAt(line) - column + 1,
      char: close,
    ));
    return (
      start: start,
      end: start,
      text: '$typed$close',
      anchor: start + 1,
      extent: start + 1,
    );
  }

  /// A space typed between a `*` pair the pair wrote: the closer goes and
  /// the space takes its place, a literal star — `* ` a list item, `a * b`
  /// a multiplication (#718).
  BracketEdit? _spaceAfterStarPair(SourceBuffer buffer, int caret) {
    if (caret <= 0 || caret >= buffer.length) return null;
    if (buffer.substring(caret - 1, caret) != '*' ||
        buffer.substring(caret, caret + 1) != '*') {
      return null;
    }
    final closer = _closerAt(buffer, caret, '*');
    if (closer == null) return null;
    _closers.remove(closer);
    return (
      start: caret,
      end: caret + 1,
      text: ' ',
      anchor: caret + 1,
      extent: caret + 1,
    );
  }

  /// What Backspace at [caret] does instead of taking one character; null
  /// when it takes one. Between an empty pair it takes both.
  ///
  /// A bracket and its closer side by side are an empty pair whoever wrote
  /// them: `()` holds nothing. A symmetric delimiter is not (#761): the two
  /// stars around the caret in `**bold*|*` close one bold, and `''`, `***`
  /// or `___` are a run of one character — so both go only when the closer
  /// is the one this pair wrote.
  BracketEdit? backspace(SourceBuffer buffer, int caret) {
    if (caret <= 0 || caret >= buffer.length) return null;
    final open = buffer.substring(caret - 1, caret);
    final close = pairs[open];
    if (close == null || buffer.substring(caret, caret + 1) != close) {
      return null;
    }
    if (open == close && _closerAt(buffer, caret, close) == null) return null;
    final line = buffer.lineOf(caret);
    final column = caret - buffer.offsetOfLine(line);
    _closers.removeWhere(
      (c) =>
          c.line == line &&
          c.fromEnd == buffer.lineLengthAt(line) - column &&
          c.char == close,
    );
    return (
      start: caret - 1,
      end: caret + 1,
      text: '',
      anchor: caret - 1,
      extent: caret - 1,
    );
  }

  /// The caret is on [line]: the closing characters written on other lines
  /// are forgotten, and one typed later is typed, not stepped over.
  void caretOnLine(int line) {
    if (_closers.isEmpty) return;
    _closers.removeWhere((closer) => closer.line != line);
  }

  /// Forgets every closing character written: another note.
  void clear() => _closers.clear();

  /// Whether [typed] opens a pair at [offset]: per character, because half
  /// of these are ordinary punctuation most of the time (#718).
  bool _opensAt(SourceBuffer buffer, int offset, String typed) {
    switch (typed) {
      case '*':
        // A second star right after the first is the bold one being
        // written, not another pair (#718); after a word the star closes
        // an emphasis — `*this*` — or is a product, `2*3` (#762).
        if (_charBefore(buffer, offset) == '*') return false;
        if (_wordBefore(buffer, offset)) return false;
        return _closesBefore(buffer, offset);
      case '_':
      // `snake_case` and a closing `word_` are what they are.
      case '"':
      case "'":
      case '«':
      case '“':
        // After a word the quote closes one already spoken — `don't`,
        // `word"` — and is only itself.
        if (_wordBefore(buffer, offset)) return false;
        return _closesBefore(buffer, offset);
      default:
        return _closesBefore(buffer, offset);
    }
  }

  /// Whether an opening character at [offset] closes itself: at the line's
  /// end, before a space, a closing bracket or a closer this pair wrote,
  /// and not after a backslash.
  ///
  /// A star or a quote already in the note is no closing character (#762):
  /// `*` typed before `"quote"`, or `(` before `*emph*`, wraps what
  /// follows, and a pair there would write `**"quote"` and `()*emph*`.
  /// One the pair wrote is: `*(|)*` inside an emphasis being written.
  bool _closesBefore(SourceBuffer buffer, int offset) {
    if (offset > 0 && buffer.substring(offset - 1, offset) == r'\') {
      return false;
    }
    if (offset >= buffer.length) return true;
    final next = buffer.substring(offset, offset + 1);
    return next == '\n' ||
        next == ' ' ||
        next == '\t' ||
        _closingOnly.contains(next) ||
        _closerAt(buffer, offset, next) != null;
  }

  /// The character before [offset], or null at the start of the note.
  static String? _charBefore(SourceBuffer buffer, int offset) =>
      offset <= 0 ? null : buffer.substring(offset - 1, offset);

  /// Whether a word stands right before [offset]. The combining marks of a
  /// decomposed accent — `café` written `cafe` + U+0301 — belong to the
  /// letter before them, so they are stepped back over to it (#762).
  static bool _wordBefore(SourceBuffer buffer, int offset) {
    var index = offset;
    while (index > 0 &&
        _combiningMark.hasMatch(buffer.substring(index - 1, index))) {
      index -= 1;
    }
    final before = _charBefore(buffer, index);
    return before != null && isWordChar(before);
  }

  static final RegExp _combiningMark = RegExp(r'^\p{M}$', unicode: true);

  /// The closing character [char] this pair wrote, standing at [offset].
  _Closer? _closerAt(SourceBuffer buffer, int offset, String char) {
    if (offset >= buffer.length ||
        buffer.substring(offset, offset + 1) != char) {
      return null;
    }
    final line = buffer.lineOf(offset);
    final fromEnd =
        buffer.lineLengthAt(line) - (offset - buffer.offsetOfLine(line));
    for (final closer in _closers.reversed) {
      if (closer.line == line &&
          closer.fromEnd == fromEnd &&
          closer.char == char) {
        return closer;
      }
    }
    return null;
  }
}
