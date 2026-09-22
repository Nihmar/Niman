/// The heading sections the source surface has folded (#245, phase 3; the
/// legacy editor's T-M2-07).
///
/// A folded heading hides the lines of its section — up to the next heading
/// of its level or above — and the view draws **rows**, not lines: row *r* is
/// the *r*-th line nobody has hidden. So a folded section of a hundred
/// thousand lines is not a hundred thousand empty children the sliver has to
/// build and walk, it is simply not in the list; and with nothing folded the
/// mapping is the identity, at no cost.
///
/// This class is the arithmetic only — which lines are hidden, and the two
/// directions of the line ↔ row mapping. Where a section ends is the view's
/// question, because only its tokenizer knows what a heading is.
library;

import 'dart:collection';

import 'package:niman/src/markdown/source_edit.dart';

/// The folded sections, and the rows they leave.
final class SourceFolds {
  /// Each folded heading line, and the end (exclusive) of the lines it hides.
  final SplayTreeMap<int, int> _folded = SplayTreeMap<int, int>();

  /// The hidden lines, merged: sorted, disjoint `[start, end)` ranges.
  List<(int, int)> _hidden = const <(int, int)>[];

  /// How many lines the ranges before range *i* hide.
  List<int> _hiddenBefore = const <int>[];

  /// Whether nothing is folded.
  bool get isEmpty => _folded.isEmpty;

  /// These folds as they stand, to compare with after a change.
  SourceFolds copy() {
    final copy = SourceFolds();
    copy._folded.addAll(_folded);
    copy._merge();
    return copy;
  }

  /// The folded heading lines, in order.
  Iterable<int> get anchors => _folded.keys;

  /// The merged hidden ranges.
  List<(int, int)> get hidden => _hidden;

  /// Whether the heading on [line] is folded.
  bool isFolded(int line) => _folded.containsKey(line);

  /// How many lines are hidden in all.
  int get hiddenCount =>
      _hidden.isEmpty ? 0 : _hiddenBefore.last + _length(_hidden.last);

  /// How many rows a note of [lines] lines shows.
  int rowCount(int lines) => lines - hiddenCount;

  /// Folds the heading on [line], hiding `[line + 1, end)`.
  void fold(int line, int end) {
    if (end <= line + 1) return;
    _folded[line] = end;
    _merge();
  }

  /// Unfolds the heading on [line].
  void unfold(int line) {
    if (_folded.remove(line) != null) _merge();
  }

  /// Unfolds everything that hides [line]; true when anything did.
  bool reveal(int line) {
    final covering = <int>[
      for (final MapEntry(key: anchor, value: end) in _folded.entries)
        if (line > anchor && line < end) anchor,
    ];
    if (covering.isEmpty) return false;
    covering.forEach(_folded.remove);
    _merge();
    return true;
  }

  /// Unfolds everything.
  void clear() {
    _folded.clear();
    _merge();
  }

  /// Whether [line] is hidden.
  bool isHidden(int line) {
    final at = _rangeAtOrBefore(line);
    return at >= 0 && line < _hidden[at].$2;
  }

  /// The row [line] is drawn in; a hidden line answers the row of the
  /// heading that hides it, which is where it would be.
  int rowOf(int line) {
    final at = _rangeAtOrBefore(line);
    if (at < 0) return line;
    final (start, end) = _hidden[at];
    if (line < end) return start - 1 - _hiddenBefore[at];
    return line - _hiddenBefore[at] - _length(_hidden[at]);
  }

  /// The line drawn in row [row].
  int lineOf(int row) {
    // The last range whose first row-after is at or before [row]: every range
    // before it hides lines above the row.
    var low = 0;
    var high = _hidden.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      // Rows before range *mid*'s start.
      if (_hidden[mid].$1 - _hiddenBefore[mid] <= row) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low == 0) return row;
    final at = low - 1;
    return row + _hiddenBefore[at] + _length(_hidden[at]);
  }

  /// Follows [edit] to a note of [lines] lines: the headings after it move
  /// with the lines, and a fold whose section — or whose heading's line
  /// count — the edit touched is let go, since what it hid is not what it
  /// hides now. [endOf] says where each remaining heading's section ends
  /// now, or null when the line is no longer a heading.
  ///
  /// Answers whether the rows changed other than by the edit's own lines, so
  /// the view knows whether its row heights can be spliced or must be
  /// measured again.
  bool edited(SourceEdit edit, int lines, int? Function(int line) endOf) {
    if (_folded.isEmpty) return false;
    final before = <int, int>{
      for (final MapEntry(key: anchor, value: end) in _folded.entries)
        anchor: end,
    };
    final first = edit.firstLine;
    final untouched = edit.firstUntouchedLine;
    var reshaped = false;
    _folded.clear();
    for (final MapEntry(key: anchor, value: end) in before.entries) {
      // Typing in a folded heading keeps it folded; anything that adds or
      // takes lines at the heading, or touches what it hides, lets it go.
      final touchesHeading =
          first <= anchor && untouched > anchor && !edit.preservesLineCount;
      final touchesBody = first < end && untouched > anchor + 1;
      if (touchesHeading || touchesBody) {
        reshaped = true;
        continue;
      }
      final moved = anchor >= untouched ? anchor + edit.lineDelta : anchor;
      final shiftedEnd = end >= untouched ? end + edit.lineDelta : end;
      final now = moved < lines ? endOf(moved) : null;
      if (now == null || now <= moved + 1) {
        reshaped = true;
        continue;
      }
      if (now != shiftedEnd) reshaped = true;
      _folded[moved] = now;
    }
    _merge();
    return reshaped;
  }

  static int _length((int, int) range) => range.$2 - range.$1;

  /// The index of the last hidden range starting at or before [line], or -1.
  int _rangeAtOrBefore(int line) {
    var low = 0;
    var high = _hidden.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_hidden[mid].$1 <= line) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low - 1;
  }

  void _merge() {
    final merged = <(int, int)>[];
    for (final MapEntry(key: anchor, value: end) in _folded.entries) {
      final start = anchor + 1;
      if (merged.isNotEmpty && start <= merged.last.$2) {
        if (end > merged.last.$2) merged.last = (merged.last.$1, end);
      } else {
        merged.add((start, end));
      }
    }
    final before = <int>[];
    var count = 0;
    for (final range in merged) {
      before.add(count);
      count += _length(range);
    }
    _hidden = merged;
    _hiddenBefore = before;
  }
}
