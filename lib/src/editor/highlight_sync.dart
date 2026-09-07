import 'package:copist/src/editor/highlight_style.dart';
import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

/// The bridge between the re_editor buffer ([CodeLineEditingController]) and
/// the incremental Markdown tokenizer ([HighlightDocument]).
///
/// re_editor's built-in highlight engine highlights the *whole buffer in one
/// pass* per change in an isolate — multi-second on a 931K note and
/// restarted per keystroke, which is why big files appeared uncolored. This
/// class replaces it: on each text change it re-tokenizes **only the
/// changed lines** (the unchanged tail is shared by state convergence), and
/// builds styled spans per line on demand — exactly the M2a budget
/// "O(visible), never O(file)". Colors appear instantly at any file size and
/// cost a per-keystroke O(changed lines).
///
/// The edit anchor is recovered from the two [CodeLines] versions by line
/// identity (re_editor reuses untouched line objects), so no offsets are
/// needed: [onBufferChanged] gets the current [CodeLines] (the previous
/// value is the class's own copy), finds the first changed line, and calls
/// [HighlightDocument.replaceLines].
///
/// [spanFor] builds a line's [TextSpan] (cached per line and theme, so the
/// editor's paragraph cache keeps hitting: the same instance is returned
/// until the line's tokens or the palette change).
final class EditorHighlightSync {
  final HighlightDocument _doc = HighlightDocument.empty();

  /// The buffer version the document mirrors; `null` until the first text.
  CodeLines? _lastCodeLines;

  /// Cached spans, keyed by line index; entries at or after an edit's first
  /// changed line are dropped (they are re-requested on the next layout).
  final Map<int, TextSpan> _spans = <int, TextSpan>{};

  bool _dark = false;

  /// Syncs the document with the buffer after a text change (call with the
  /// controller's current [CodeLines]; selection-only values reuse the same
  /// instance and are a no-op).
  void onBufferChanged(CodeLines current) {
    if (identical(current, _lastCodeLines)) return;
    final previous = _lastCodeLines;
    final int first;
    final int removed;
    final List<String> replacement;
    if (previous == null || previous.length == 0 && current.length != 0) {
      first = 0;
      removed = 0;
      replacement = _texts(current);
    } else {
      first = _firstChangedLine(previous, current);
      final suffix = _commonSuffix(previous, current, first);
      removed = previous.length - suffix - first;
      final count = current.length - suffix - first;
      replacement = <String>[
        for (var i = first; i < first + count; i++) current[i].text,
      ];
    }
    if (removed > 0 || replacement.isNotEmpty) {
      _doc.replaceLines(first, removed, replacement);
    }
    _lastCodeLines = current;
    _spans.removeWhere((index, _) => index >= first);
  }

  /// The tokens of buffer line [index] (T-M3-07: the editor Ctrl+click
  /// looks the caret's token range up here). Materializes the line if the
  /// viewport has not asked for it yet.
  List<Token> tokensOf(int index) =>
      index < _doc.lineCount ? _doc.lineAt(index).tokens : const <Token>[];

  /// The styled span for buffer line [index] (the [CodeLineSpanBuilder]
  /// implementation): [text] is the line's text, [base] the editor's base
  /// style, [dark] the palette selection, [accent] the theme's primary
  /// (wikilinks, T-UI-09).
  TextSpan spanFor({
    required int index,
    required String text,
    required TextStyle base,
    required bool dark,
    required Color accent,
  }) {
    if (dark != _dark) {
      _dark = dark;
      _spans.clear();
    }
    final cached = _spans[index];
    if (cached != null) return cached;
    final styled = index < _doc.lineCount
        ? _doc.lineAt(index)
        : StyledLine(text, const <Token>[]);
    final span = _buildSpan(styled, base, accent);
    _spans[index] = span;
    return span;
  }

  /// The document's heading outline (T-M2-07), from the incremental
  /// document's tokens — materializes the whole document, so call it from a
  /// debounced path.
  List<OutlineEntry> outline() => outlineOf(_doc.lines);

  /// The first line whose content differs between [old] and [current].
  ///
  /// Segment-aware: whole segments whose line list is shared between the
  /// two versions are skipped in O(1), so the scan is O(segments + 256)
  /// for a single-line edit at any file size. Only the segment(s) that
  /// actually changed get a line-by-line pass (re_editor reuses untouched
  /// `CodeLine` objects across values; a full-buffer replace — e.g. a
  /// load — rebuilds them all, and the walk then text-compares every line,
  /// which only happens on that rare path).
  static int _firstChangedLine(CodeLines old, CodeLines current) {
    final oldSegments = old.segments;
    final currentSegments = current.segments;
    var offset = 0;
    final pairs = oldSegments.length < currentSegments.length
        ? oldSegments.length
        : currentSegments.length;
    for (var s = 0; s < pairs; s++) {
      final oldLines = oldSegments[s].codeLines;
      final currentLines = currentSegments[s].codeLines;
      if (identical(oldLines, currentLines)) {
        offset += oldLines.length;
        continue;
      }
      final n = oldLines.length < currentLines.length
          ? oldLines.length
          : currentLines.length;
      for (var i = 0; i < n; i++) {
        final a = oldLines[i];
        final b = currentLines[i];
        if (!identical(a, b) && a.text != b.text) return offset + i;
      }
      if (oldLines.length != currentLines.length) {
        // Same content up to the shorter list: the change is at the
        // boundary (aligned segments end/shift here).
        return offset + n;
      }
      // Same length and content, different instances: keep scanning (the
      // changed line may be in a later segment, e.g. a full rebuild).
      offset += n;
    }
    if (oldSegments.length != currentSegments.length) return offset;
    return 0;
  }

  /// The number of *unchanged* trailing lines shared by [old] and
  /// [current] after the change at [first].
  ///
  /// Segment-aware like [_firstChangedLine]: identical trailing segments
  /// are counted in O(1); only the first differing pair (from the end) is
  /// walked, ≤256 lines with the end-comparison alignment (insertions and
  /// deletions shift the tail uniformly, so comparing k lines from the end
  /// stays aligned).
  static int _commonSuffix(CodeLines old, CodeLines current, int first) {
    var suffix = 0;
    var p = 0;
    final pairs = old.segments.length < current.segments.length
        ? old.segments.length
        : current.segments.length;
    while (p < pairs) {
      final oldLines = old.segments[old.segments.length - 1 - p].codeLines;
      final currentLines =
          current.segments[current.segments.length - 1 - p].codeLines;
      if (identical(oldLines, currentLines)) {
        suffix += oldLines.length;
        p++;
        continue;
      }
      final bound = oldLines.length < currentLines.length
          ? oldLines.length
          : currentLines.length;
      var k = 0;
      while (k < bound) {
        final a = oldLines[oldLines.length - 1 - k];
        final b = currentLines[currentLines.length - 1 - k];
        if (!identical(a, b) && a.text != b.text) break;
        k++;
      }
      suffix += k;
      break;
    }
    final maxSuffix = (old.length - first) < (current.length - first)
        ? old.length - first
        : current.length - first;
    return suffix > maxSuffix ? maxSuffix : suffix;
  }

  static List<String> _texts(CodeLines lines) => <String>[
    for (var i = 0; i < lines.length; i++) lines[i].text,
  ];

  /// Splits one line into non-overlapping styled spans: every maximal run
  /// between token boundaries gets the covering token's style; the unmarked
  /// region after a heading marker gets the heading style; the rest is
  /// plain (the base style shows).
  TextSpan _buildSpan(StyledLine styled, TextStyle base, Color accent) {
    final textLength = styled.text.length;
    if (textLength == 0) {
      return TextSpan(text: '', style: base);
    }
    var headingStart = -1;
    for (final token in styled.tokens) {
      if (token.kind == TokenKind.headingMarker) {
        headingStart = token.end;
        break;
      }
    }
    final bounds = <int>{0, textLength};
    for (final token in styled.tokens) {
      if (token.start >= textLength) break;
      final end = token.end > textLength ? textLength : token.end;
      bounds
        ..add(token.start)
        ..add(end);
    }
    if (headingStart >= 0 && headingStart < textLength) {
      bounds.add(headingStart);
    }
    final sorted = bounds.toList()..sort();
    final children = <TextSpan>[];
    for (var i = 0; i + 1 < sorted.length; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (start >= end) continue;
      children.add(
        TextSpan(
          text: styled.text.substring(start, end),
          style: _styleAt(styled.tokens, start, headingStart, accent),
        ),
      );
    }
    return TextSpan(children: children, style: base);
  }

  /// The style for the region starting at [pos]: the covering token's
  /// override, the heading style for the unmarked heading text, null (base)
  /// otherwise. [headingStart] is the first unmarked heading position (-1 =
  /// no heading).
  TextStyle? _styleAt(
    List<Token> tokens,
    int pos,
    int headingStart,
    Color accent,
  ) {
    for (final token in tokens) {
      if (token.start > pos) break;
      if (pos < token.end) {
        return _palette.styleFor(token.kind, accent: accent);
      }
    }
    if (headingStart >= 0 && pos >= headingStart) return _palette.headingStyle;
    return null;
  }

  HighlightPalette get _palette =>
      _dark ? HighlightPalette.dark : HighlightPalette.light;
}
