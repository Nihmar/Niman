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

import 'package:niman/src/editor/block_state.dart';
import 'package:niman/src/editor/code_fence.dart';
import 'package:niman/src/editor/line_tokenizer.dart';
import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/editor/math_span.dart';
import 'package:niman/src/editor/styled_line.dart';
import 'package:niman/src/editor/token.dart';

export 'package:niman/src/editor/math_span.dart';
export 'package:niman/src/editor/styled_line.dart';
export 'package:niman/src/editor/token.dart';
export 'package:niman/src/editor/token_kind.dart';

final class _Line {
  new(this.text);

  final String text;

  /// Carried block state / tokens, null until the line is materialized
  /// (see [HighlightDocument] — tokenization is lazy so opening a 1M-char
  /// note costs only the visible lines, not the whole file).
  BlockState? entering;
  BlockState? exit;
  List<Token>? tokens;

  /// Whether [tokens] were made for the note's first line, which alone can
  /// open a frontmatter: a line moved to or from line 0 is tokenized again.
  bool tokensAtZero = false;
}

/// A walk over a note's lines in order that says which are prose.
///
/// The block state machine of [HighlightDocument] (which
/// [HighlightDocument.forEachHeading] shares) without the inline scan, made a
/// value a caller steps one line at a time: it can pause between two lines —
/// yield to the UI on a long note — which a callback over the whole text
/// cannot.
final class ProseLineWalker {
  /// A walker at the top of a note.
  new();

  BlockState _state = BlockState.initial;

  /// Whether the line [text] at [lineIndex] is prose — not a fence or its
  /// code, display maths or the frontmatter. Lines are given in order from
  /// line 0, each once.
  bool isProse(int lineIndex, String text) =>
      HighlightDocument._walkLine(this, lineIndex, text);
}

/// Incremental highlighter over a plain-text buffer.
///
/// Build once with `fromText`; after every buffer edit call `replace` with
/// the single edit region. Typical cost is one or two lines.
final class HighlightDocument {
  new _();

  /// An empty document, grown through [replaceLines] as lines are loaded
  /// or edited, so a big note costs only the lines it actually touches
  /// instead of one eager whole-file pass at open.
  factory empty() => HighlightDocument._();

  /// Tokenizes [text] fully.
  factory fromText(String text) {
    final doc = HighlightDocument._();
    final raw = text.isEmpty ? <String>[''] : text.split('\n');
    final lines = <_Line>[];
    for (final t in raw) {
      final line = _Line(t);
      _tokenizeAt(lines, lines.length, line);
      lines.add(line);
    }
    doc
      .._lines = lines
      .._materializedUntil = lines.length;
    return doc;
  }

  /// A document over [lines] (each without its terminator), tokenized lazily:
  /// a line is tokenized the first time something asks for it, in order, so
  /// building one over a whole note costs a list and no tokenizing.
  ///
  /// The source surface's constructor: it hands over its buffer's own lines,
  /// which are already split — and split on the note's *own* line endings, so
  /// a CRLF note's lines carry no `\r` that the tokenizer's patterns trip on.
  factory fromLines(List<String> lines) {
    final raw = lines.isEmpty ? const <String>[''] : lines;
    return HighlightDocument._()
      .._lines = <_Line>[for (final text in raw) _Line(text)]
      .._materializedUntil = 0;
  }

  List<_Line> _lines = <_Line>[];

  /// The count of *materialized* leading lines: lines below this index keep
  /// valid tokens/state for the current buffer; at and above it they are
  /// tokenized lazily on the next [lineAt]. Edits (see [replaceLines]) drop
  /// the materialization from the edit point on, so a keystroke re-tokenizes
  /// only what the viewport asks for.
  int _materializedUntil = 0;

  /// The current display text (lines joined with `\n`).
  String get text => _lines.map((l) => l.text).join('\n');

  /// The number of lines (O(1)).
  int get lineCount => _lines.length;

  /// Line [line]'s styled content (O(1) after materialization); [line] in
  /// 0..lineCount-1. This is the per-visible-line accessor the editor view
  /// uses, in place of [lines] (which is O(lineCount) and would break the
  /// "only visible rows" budget).
  StyledLine lineAt(int line) {
    if (line < 0 || line >= _lines.length) {
      throw RangeError.range(line, 0, _lines.length - 1, 'line');
    }
    _materialize(line);
    return StyledLine(_lines[line].text, _tokensOf(line));
  }

  /// Line [index]'s tokens, made the first time they are asked for: the
  /// block state carried into it is already known ([_materialize]).
  List<Token> _tokensOf(int index) {
    final line = _lines[index];
    final tokens = line.tokens;
    if (tokens != null && line.tokensAtZero == (index == 0)) return tokens;
    line.tokensAtZero = index == 0;
    return line.tokens = LineTokenizer.lineTokens(
      line.text,
      line.entering!,
      index,
    );
  }

  /// The styled lines (all of them; O(lineCount) — materializes the whole
  /// document).
  List<StyledLine> get lines {
    if (_lines.isNotEmpty) _materialize(_lines.length - 1);
    return <StyledLine>[
      for (var at = 0; at < _lines.length; at++)
        StyledLine(_lines[at].text, _tokensOf(at)),
    ];
  }

  /// Carries the block state through lines up to [upTo] (inclusive) — only
  /// the gap since the last materialized line, walking forward so the state
  /// is exact.
  ///
  /// The state, not the tokens. What a line's colours depend on from the
  /// lines above it is the block it is in — a fence, display maths, the
  /// frontmatter — and that is a few comparisons a line; its inline tokens
  /// are the costly part and depend on nothing above it but that state. A
  /// note reopened at its end asked for line 2.7 million and inline-scanned
  /// every line before it: 163 s and 2.8 GB of tokens nobody drew (0.0.9
  /// stress test). Now the walk carries the state, and a line's tokens are
  /// made when it is drawn ([_tokensOf]) — kept while the state entering it
  /// stays what it was.
  void _materialize(int upTo) {
    // Already tokenized: asking for a line above the watermark must not pull
    // the watermark *down*, or every line below it is tokenized again on the
    // next ask — which is what a viewport rebuilt from its top line did.
    if (upTo < _materializedUntil) return;
    var i = _materializedUntil;
    while (i <= upTo) {
      final line = _lines[i];
      final entering = i == 0 ? BlockState.initial : _lines[i - 1].exit!;
      if (line.entering != entering) line.tokens = null;
      line
        ..entering = entering
        ..exit = _stateAfter(line.text, entering, i);
      i++;
    }
    _materializedUntil = upTo + 1;
  }

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
    // The offset edit is the eager path (its convergence math needs the
    // old states): materialize everything first.
    if (_lines.isNotEmpty) _materialize(_lines.length - 1);
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
    final suffix =
        _lines[last].text.substring(kept) +
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

  /// Applies a line-granularity edit: [removed] lines starting at line
  /// [first] are replaced by [replacement] (each a line without a newline).
  ///
  /// The model is always edited line-based: offsets are hard to recover
  /// across edits. Only the replaced lines (plus the following ones
  /// until the carried state converges) are re-tokenized; the unchanged
  /// tail is shared.
  void replaceLines(int first, int removed, List<String> replacement) {
    if (first < 0 || first > _lines.length) {
      throw ArgumentError('first $first out of range 0..${_lines.length}');
    }
    if (removed < 0) {
      throw ArgumentError('removed $removed < 0');
    }
    final end = first + removed > _lines.length
        ? _lines.length
        : first + removed;
    // In place: a keystroke replaces one line, and copying the whole list to
    // do it was O(lineCount) on every one. (Every list this document holds is
    // one it built, so it is growable.)
    _lines.replaceRange(first, end, <_Line>[
      for (final text in replacement) _Line(text),
    ]);
    // The materialized prefix ends at `first`: everything at/above it is
    // (re)tokenized lazily on the next lineAt, in order, so stale tokens
    // are overwritten before they are ever read — no eager invalidation
    // walk (which would be O(remaining lines) per keystroke).
    if (_materializedUntil > first) _materializedUntil = first;
  }

  static void _tokenizeAt(List<_Line> lines, int index, _Line line) {
    final entering = index == 0 ? BlockState.initial : lines[index - 1].exit!;
    line.entering = entering;
    line.exit = _stateAfter(line.text, entering, index);
    line.tokens = LineTokenizer.lineTokens(line.text, entering, index);
    line.tokensAtZero = index == 0;
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
  static BlockState _stateAfter(
    String text,
    BlockState inState,
    int lineIndex,
  ) {
    final fence = inState.fence;
    if (fence != null) {
      return CodeFence.closes(text, fence) ? BlockState.initial : inState;
    }
    if (inState.inMath) {
      return text.trim().startsWith(r'$$') ? BlockState.initial : inState;
    }
    if (inState.inFrontmatter) {
      final t = text.trim();
      return t == '---' || t == '...' ? BlockState.initial : inState;
    }
    if (lineIndex == 0 && text.trim() == '---') {
      return const BlockState(inFrontmatter: true);
    }
    final fenceOpen = CodeFence.openedBy(text);
    if (fenceOpen != null) {
      return BlockState(fence: fenceOpen);
    }
    final t = text.trim();
    if (t.startsWith(r'$$') && !_isSingleLineMath(t)) {
      return const BlockState(inMath: true);
    }
    return BlockState.initial;
  }

  static bool _isSingleLineMath(String trimmed) => isSingleLineDisplay(trimmed);

  /// Calls [onHeading] for each heading line of [text], in line order, with
  /// the line index, the level, and the heading's text (markers stripped).
  ///
  /// Walks the block state machine ([_stateAfter]) and nothing else: no
  /// inline scanning, which is where a maths-heavy note spends its time.
  /// Collecting the 84 headings of a 931K note by tokenizing it whole cost
  /// ~1 s on device; this way it is a few ms. `outline_test` holds the two
  /// to the same answer over the cases the block context decides.
  static void forEachHeading(
    String text,
    void Function(int line, int level, String heading) onHeading,
  ) {
    final raw = text.isEmpty ? const <String>[''] : text.split('\n');
    var state = BlockState.initial;
    for (var i = 0; i < raw.length; i++) {
      final line = raw[i];
      final heading = LineTokenizer.headingIn(line, state, i);
      if (heading != null) {
        final (start, level) = heading;
        onHeading(i, level, line.substring(start + level).trim());
      }
      state = _stateAfter(line, state, i);
    }
  }

  /// Whether the line [text] at [lineIndex], entered in [walker]'s state, is
  /// prose — not a fence, a fence's code, display maths, the frontmatter —
  /// and moves the walker on to the next line. A caller that visits every
  /// line in order (and may pause between two, which [forEachHeading]'s
  /// loop cannot) asks this of each.
  static bool _walkLine(ProseLineWalker walker, int lineIndex, String text) {
    final state = walker._state;
    final prose =
        state.fence == null &&
        !state.inMath &&
        !state.inFrontmatter &&
        CodeFence.openedBy(text) == null &&
        !text.trim().startsWith(r'$$') &&
        !(lineIndex == 0 && text.trim() == '---');
    walker._state = _stateAfter(text, state, lineIndex);
    return prose;
  }
}
