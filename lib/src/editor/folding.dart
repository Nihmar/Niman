/// Fold state for the editor (M2a E6 / T-M2-07): which heading sections are
/// collapsed, and therefore which logical lines the layout skips.
///
/// Per the plan, folding is "layout skips these line ranges" — a set of
/// folded `(startLine, endLine)`; the view omits those lines. A folded heading
/// on line `L` (level `k`) hides the lines after it up to the next heading of
/// level `k` or shallower (or end of document): the range `[L+1, terminus)`.
/// The heading line itself stays visible (it is the fold anchor); sub-headings
/// inside the range are hidden along with the content.
library;

import 'package:copist/src/editor/outline.dart';

/// The folded-section state over a document's heading outline.
final class FoldState {
  /// Creates a fold state over [outline] (the document's headings) and
  /// [lineCount] logical lines, with the heading lines in [folded] folded.
  FoldState(
    this._outline,
    int lineCount, {
    Iterable<int> folded = const <int>{},
  }) : _lineCount = lineCount,
       _indexByLine = <int, int>{},
       _folded = Set<int>.of(folded) {
    for (var i = 0; i < _outline.length; i++) {
      _indexByLine[_outline[i].line] = i;
    }
    _recompute();
  }

  final List<OutlineEntry> _outline;
  final int _lineCount;
  final Map<int, int> _indexByLine; // heading line -> outline index
  final Set<int> _folded; // folded heading lines

  /// The merged, sorted hidden intervals `[start, end)`.
  List<(int, int)> _hidden = const [];

  /// The document's headings.
  List<OutlineEntry> get outline => List.unmodifiable(_outline);

  /// The logical lines currently folded.
  Set<int> get foldedLines => Set.unmodifiable(_folded);

  /// The number of logical lines (the document length at construction).
  int get lineCount => _lineCount;

  /// The merged hidden line ranges `[start, end)` (layout skips them).
  List<(int, int)> get hiddenRanges => List.unmodifiable(_hidden);

  /// Whether the heading on [line] is folded.
  bool isFolded(int line) => _folded.contains(line);

  /// Toggles folding on the heading on [line]. Non-heading lines are ignored.
  void toggle(int line) {
    if (_indexByLine[line] == null) return;
    if (!_folded.remove(line)) _folded.add(line);
    _recompute();
  }

  /// Whether logical line [line] is visible (outside every folded range).
  bool isLineVisible(int line) {
    final hidden = _hidden;
    var lo = 0;
    var hi = hidden.length;
    while (hi - lo > 0) {
      final mid = (lo + hi) >> 1;
      if (hidden[mid].$1 <= line) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final idx = lo - 1;
    if (idx < 0) return true;
    return line >= hidden[idx].$2;
  }

  /// The visible logical lines in order (folded ranges omitted) — the line
  /// set the row model wraps.
  List<int> visibleLines() {
    final out = <int>[];
    var from = 0;
    for (final (start, end) in _hidden) {
      for (var l = from; l < start; l++) {
        out.add(l);
      }
      from = end;
    }
    for (var l = from; l < _lineCount; l++) {
      out.add(l);
    }
    return out;
  }

  /// The fold state after a line edit (M2a E8c): the folded set remapped
  /// through a replace of [start, end) by [inserted] lines, over the
  /// recomputed [newOutline] and [newLineCount].
  ///
  /// Folds are transient view state, not buffer state: a fold is indexed by
  /// heading line number, so an edit above it shifts it, and an edit that
  /// removes its heading line — or turns that line into a non-heading — drops
  /// it. The line-number remap is exact; the "no longer a heading" case is
  /// caught by checking the remapped line against [newOutline], which the
  /// caller recomputes from the edited buffer before this call.
  FoldState applyEdit({
    required int start,
    required int end,
    required int inserted,
    required List<OutlineEntry> newOutline,
    required int newLineCount,
  }) {
    final headingLines = <int>{for (final e in newOutline) e.line};
    final newFolded = <int>{};
    for (final f in _folded) {
      final fPrime = _remapLine(f, start, end, inserted);
      if (fPrime == null) continue;
      if (!headingLines.contains(fPrime)) continue;
      newFolded.add(fPrime);
    }
    return FoldState(newOutline, newLineCount, folded: newFolded);
  }

  void _recompute() {
    final h = _outline.length;
    // terminus[i] = line of the next heading with level <= outline[i].level
    // (a same-or-higher heading ends the section), or lineCount. O(h) via a
    // monotonic stack scanned right-to-left.
    final terminus = List<int>.filled(h, _lineCount);
    final stack = <int>[];
    for (var i = h - 1; i >= 0; i--) {
      final level = _outline[i].level;
      while (stack.isNotEmpty && _outline[stack.last].level > level) {
        stack.removeLast();
      }
      if (stack.isNotEmpty) terminus[i] = _outline[stack.last].line;
      stack.add(i);
    }
    final intervals = <(int, int)>[];
    for (final line in _folded) {
      final i = _indexByLine[line];
      if (i == null) continue;
      final start = _outline[i].line + 1;
      final end = terminus[i];
      if (start < end) intervals.add((start, end));
    }
    intervals.sort((a, b) => a.$1.compareTo(b.$1));
    _hidden = _merge(intervals);
  }

  /// Remaps logical line [f] through a replace of [start, end) by
  /// [inserted] lines, or `null` if the edit removes the line.
  ///
  /// Lines before [start] are untouched; lines from [end] on shift by the net
  /// delta `inserted - (end - start)`. A line inside `[start, end)` survives
  /// (at the same number) only while a new line still occupies its position,
  /// i.e. `f < start + inserted` — a one-for-one content edit keeps the line
  /// number, a net deletion past `start + inserted` drops it.
  static int? _remapLine(int f, int start, int end, int inserted) {
    final delta = inserted - (end - start);
    if (f < start) return f;
    if (f >= end) return f + delta;
    return f < start + inserted ? f : null;
  }

  static List<(int, int)> _merge(List<(int, int)> in_) {
    if (in_.isEmpty) return const [];
    final out = <(int, int)>[in_.first];
    for (var i = 1; i < in_.length; i++) {
      final (s, e) = in_[i];
      final (ls, le) = out.last;
      if (s <= le) {
        // Overlapping (or touching): extend the last interval.
        out[out.length - 1] = (ls, e > le ? e : le);
      } else {
        out.add((s, e));
      }
    }
    return out;
  }
}
