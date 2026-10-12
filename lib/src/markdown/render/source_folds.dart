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
///
/// A second kind of range takes rows away the same way: the lines of a
/// side-by-side `columns` block past its opener (#729), **hosted** — drawn
/// inside the opener's row, in their columns. A hosted line answers its
/// host's row, as a folded one its heading's; it is no row of its own, and
/// is not hidden: `isHidden` and `reveal` are the folds' alone.
library;

import 'dart:collection';

import 'package:niman/src/markdown/source_edit.dart';

/// The folded sections, and the rows they leave.
final class SourceFolds {
  /// Each folded heading line, and the end (exclusive) of the lines it hides.
  final SplayTreeMap<int, int> _folded = SplayTreeMap<int, int>();

  /// Each side-by-side `columns` block's opener, and the end (exclusive) of
  /// the lines it hosts.
  final SplayTreeMap<int, int> _hosted = SplayTreeMap<int, int>();

  /// The lines no row draws — folded or hosted — merged: sorted, disjoint
  /// `[start, end)` ranges.
  List<(int, int)> _hidden = const <(int, int)>[];

  /// How many lines the ranges before range *i* hide.
  List<int> _hiddenBefore = const <int>[];

  /// The lines the folds alone hide, merged as [_hidden] is: what
  /// [isHidden] answers from, a hosted line being no hidden one.
  List<(int, int)> _foldedRanges = const <(int, int)>[];

  /// Whether nothing is folded and nothing hosted: every line is a row.
  bool get isEmpty => _folded.isEmpty && _hosted.isEmpty;

  /// These folds and hosts as they stand, to compare with after a change.
  SourceFolds copy() {
    final copy = SourceFolds();
    copy._folded.addAll(_folded);
    copy._hosted.addAll(_hosted);
    copy._merge();
    return copy;
  }

  /// The side-by-side blocks: each opener, and the end of what it hosts.
  Map<int, int> get hosts => _hosted;

  /// Whether [line] is a side-by-side block's opener, whose row draws the
  /// block.
  bool isHost(int line) => _hosted.containsKey(line);

  /// The opener of the side-by-side block hosting [line], or null: the
  /// opener itself is no hosted line.
  int? hostOf(int line) {
    final host = _hosted.lastKeyBefore(line);
    if (host == null) return null;
    return line < _hosted[host]! ? host : null;
  }

  /// Makes [hosts] — each opener and the end of its block — the
  /// side-by-side blocks; true when that changed them.
  bool setHosts(Map<int, int> hosts) {
    if (hosts.length == _hosted.length &&
        hosts.entries.every((entry) => _hosted[entry.key] == entry.value)) {
      return false;
    }
    _hosted
      ..clear()
      ..addAll(hosts);
    _merge();
    return true;
  }

  /// The folded heading lines, in order.
  Iterable<int> get anchors => _folded.keys;

  /// Whether a folded heading stands on a line of `[start, end)`.
  bool foldsWithin(int start, int end) {
    final anchor = _folded.firstKeyAfter(start - 1);
    return anchor != null && anchor < end;
  }

  /// The lines of `[from, to)` no fold hides, as `[start, end)` spans in
  /// order: a hosted line is no hidden one.
  Iterable<(int, int)> unfoldedSpans(int from, int to) sync* {
    var line = from;
    var at = _startingAtOrBefore(_foldedRanges, from);
    if (at < 0) at = 0;
    for (; at < _foldedRanges.length && line < to; at++) {
      final (start, end) = _foldedRanges[at];
      if (end <= line) continue;
      if (start >= to) break;
      if (start > line) yield (line, start);
      if (end > line) line = end;
    }
    if (line < to) yield (line, to);
  }

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

  /// Unfolds everything, and hosts nothing.
  void clear() {
    _folded.clear();
    _hosted.clear();
    _merge();
  }

  /// Whether [line] is folded away.
  bool isHidden(int line) {
    final at = _startingAtOrBefore(_foldedRanges, line);
    return at >= 0 && line < _foldedRanges[at].$2;
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
  ///
  /// A side-by-side block follows the edit too: one after it moves with the
  /// lines, and one it lands inside grows or shrinks by its lines, which
  /// changes no row — its lines are no rows. One whose opener the edit
  /// touched is let go; the view's next layout reads the blocks again.
  bool edited(SourceEdit edit, int lines, int? Function(int line) endOf) {
    _hostsEdited(edit);
    if (_folded.isEmpty) {
      _merge();
      return false;
    }
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

  /// Moves the side-by-side blocks with [edit].
  void _hostsEdited(SourceEdit edit) {
    if (_hosted.isEmpty) return;
    final before = Map<int, int>.of(_hosted);
    _hosted.clear();
    final first = edit.firstLine;
    final untouched = edit.firstUntouchedLine;
    for (final MapEntry(key: host, value: end) in before.entries) {
      if (untouched <= host) {
        // Wholly above the block: it moves with the lines.
        _hosted[host + edit.lineDelta] = end + edit.lineDelta;
        continue;
      }
      if (first >= end) {
        _hosted[host] = end;
        continue;
      }
      // Inside the block, past its opener: it holds the lines it gained.
      // Typing on the opener keeps it too: the layout after the edit says
      // whether it still opens the block.
      if ((first > host || (first == host && edit.removedLines == 1)) &&
          untouched <= end) {
        _hosted[host] = end + edit.lineDelta;
      }
    }
  }

  static int _length((int, int) range) => range.$2 - range.$1;

  /// The index of the last hidden range starting at or before [line], or -1.
  int _rangeAtOrBefore(int line) => _startingAtOrBefore(_hidden, line);

  /// The index of the last of [ranges] — sorted — starting at or before
  /// [line], or -1.
  static int _startingAtOrBefore(List<(int, int)> ranges, int line) {
    var low = 0;
    var high = ranges.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (ranges[mid].$1 <= line) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low - 1;
  }

  /// [ranges] — each an anchor and the end of the lines past it — sorted
  /// by anchor, as the disjoint `[start, end)` ranges of lines they cover.
  static List<(int, int)> _merged(Iterable<(int, int)> ranges) {
    final merged = <(int, int)>[];
    for (final (anchor, end) in ranges) {
      final start = anchor + 1;
      if (merged.isNotEmpty && start <= merged.last.$2) {
        if (end > merged.last.$2) merged.last = (merged.last.$1, end);
      } else {
        merged.add((start, end));
      }
    }
    return merged;
  }

  void _merge() {
    final folded = <(int, int)>[
      for (final MapEntry(key: anchor, value: end) in _folded.entries)
        (anchor, end),
    ];
    _foldedRanges = _merged(folded);
    if (_hosted.isEmpty) {
      _hidden = _foldedRanges;
    } else {
      final ranges = <(int, int)>[
        ...folded,
        for (final MapEntry(key: anchor, value: end) in _hosted.entries)
          (anchor, end),
      ];
      if (folded.isNotEmpty) ranges.sort((a, b) => a.$1.compareTo(b.$1));
      _hidden = _merged(ranges);
    }
    final merged = _hidden;
    final before = <int>[];
    var count = 0;
    for (final range in merged) {
      before.add(count);
      count += _length(range);
    }
    _hiddenBefore = before;
  }
}
