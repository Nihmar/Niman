/// Line diff between two texts (issue #67): Myers' O(ND) algorithm on the
/// lines left after trimming the common head and tail.
///
/// Pure and synchronous; callers with long notes run it in an isolate.
library;

import 'package:meta/meta.dart';

/// What a diff line is.
enum DiffKind {
  /// In both texts.
  same,

  /// Only in the old text.
  removed,

  /// Only in the new text.
  added,
}

/// One line of a diff.
@immutable
final class DiffLine {
  /// A line of [kind] with its [text] and 1-based line numbers in the old
  /// ([oldLine]) and new ([newLine]) texts, null on the side it is absent
  /// from.
  const new(this.kind, this.text, {this.oldLine, this.newLine});

  /// Whether the line is kept, removed or added.
  final DiffKind kind;

  /// The line, without its line break.
  final String text;

  /// Its number in the old text, or null for an added line.
  final int? oldLine;

  /// Its number in the new text, or null for a removed line.
  final int? newLine;

  @override
  bool operator ==(Object other) =>
      other is DiffLine &&
      other.kind == kind &&
      other.text == text &&
      other.oldLine == oldLine &&
      other.newLine == newLine;

  @override
  int get hashCode => Object.hash(kind, text, oldLine, newLine);

  @override
  String toString() =>
      '${switch (kind) {
        DiffKind.same => ' ',
        DiffKind.removed => '-',
        DiffKind.added => '+',
      }}$text';
}

/// The lines of [text], line endings normalized; a trailing line break
/// does not make an extra empty line.
List<String> splitLines(String text) {
  if (text.isEmpty) return const [];
  final lines = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  if (lines.last.isEmpty) lines.removeLast();
  return lines;
}

/// The line diff turning [oldText] into [newText].
///
/// When the texts differ in more than [maxEdits] lines, the differing
/// middle is reported as removed-then-added instead of searched for the
/// shortest edit (the search is quadratic in the worst case).
List<DiffLine> diffLines(
  String oldText,
  String newText, {
  int maxEdits = 4000,
}) {
  final a = splitLines(oldText);
  final b = splitLines(newText);
  var head = 0;
  while (head < a.length && head < b.length && a[head] == b[head]) {
    head++;
  }
  var tail = 0;
  while (tail < a.length - head &&
      tail < b.length - head &&
      a[a.length - 1 - tail] == b[b.length - 1 - tail]) {
    tail++;
  }
  final out = <DiffLine>[
    for (var i = 0; i < head; i++)
      DiffLine(DiffKind.same, a[i], oldLine: i + 1, newLine: i + 1),
  ];
  final midA = a.sublist(head, a.length - tail);
  final midB = b.sublist(head, b.length - tail);
  final script = _myers(midA, midB, maxEdits);
  var i = 0;
  var j = 0;
  for (final kind in script) {
    switch (kind) {
      case DiffKind.same:
        out.add(
          DiffLine(
            DiffKind.same,
            midA[i],
            oldLine: head + i + 1,
            newLine: head + j + 1,
          ),
        );
        i++;
        j++;
      case DiffKind.removed:
        out.add(DiffLine(DiffKind.removed, midA[i], oldLine: head + i + 1));
        i++;
      case DiffKind.added:
        out.add(DiffLine(DiffKind.added, midB[j], newLine: head + j + 1));
        j++;
    }
  }
  final oldTailStart = a.length - tail;
  final newTailStart = b.length - tail;
  for (var k = 0; k < tail; k++) {
    out.add(
      DiffLine(
        DiffKind.same,
        a[oldTailStart + k],
        oldLine: oldTailStart + k + 1,
        newLine: newTailStart + k + 1,
      ),
    );
  }
  return out;
}

/// The edit script from [a] to [b], removals before additions inside a
/// change.
List<DiffKind> _myers(List<String> a, List<String> b, int maxEdits) {
  final n = a.length;
  final m = b.length;
  if (n == 0) return List.filled(m, DiffKind.added);
  if (m == 0) return List.filled(n, DiffKind.removed);
  final max = n + m;
  final limit = maxEdits < max ? maxEdits : max;
  final offset = limit + 1;
  var v = List<int>.filled(2 * limit + 3, 0);
  final trace = <List<int>>[];
  var found = false;
  outer:
  for (var d = 0; d <= limit; d++) {
    trace.add(List<int>.of(v));
    for (var k = -d; k <= d; k += 2) {
      int x;
      if (k == -d || (k != d && v[offset + k - 1] < v[offset + k + 1])) {
        x = v[offset + k + 1];
      } else {
        x = v[offset + k - 1] + 1;
      }
      var y = x - k;
      while (x < n && y < m && a[x] == b[y]) {
        x++;
        y++;
      }
      v[offset + k] = x;
      if (x >= n && y >= m) {
        found = true;
        break outer;
      }
    }
  }
  if (!found) {
    return [
      ...List.filled(n, DiffKind.removed),
      ...List.filled(m, DiffKind.added),
    ];
  }
  // Walk the trace back from (n, m).
  final script = <DiffKind>[];
  var x = n;
  var y = m;
  for (var d = trace.length - 1; d >= 0; d--) {
    v = trace[d];
    final k = x - y;
    final int prevK;
    if (k == -d || (k != d && v[offset + k - 1] < v[offset + k + 1])) {
      prevK = k + 1;
    } else {
      prevK = k - 1;
    }
    final prevX = v[offset + prevK];
    final prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      script.add(DiffKind.same);
      x--;
      y--;
    }
    if (d > 0) {
      script.add(x == prevX ? DiffKind.added : DiffKind.removed);
    }
    x = prevX;
    y = prevY;
  }
  final forward = script.reversed.toList();
  return _removalsFirst(forward);
}

/// Reorders each run of changes so its removals come before its
/// additions, the way a reader expects a replaced block to read.
List<DiffKind> _removalsFirst(List<DiffKind> script) {
  final out = <DiffKind>[];
  var removed = 0;
  var added = 0;
  void flush() {
    out
      ..addAll(List.filled(removed, DiffKind.removed))
      ..addAll(List.filled(added, DiffKind.added));
    removed = 0;
    added = 0;
  }

  for (final kind in script) {
    switch (kind) {
      case DiffKind.removed:
        removed++;
      case DiffKind.added:
        added++;
      case DiffKind.same:
        flush();
        out.add(kind);
    }
  }
  flush();
  return out;
}

/// A block of changes with the unchanged lines around it.
@immutable
final class DiffHunk {
  /// A hunk made of [lines].
  const new(this.lines);

  /// The lines, context included.
  final List<DiffLine> lines;

  /// The first old-text line the hunk covers (1-based), or the line it
  /// sits after when it only adds.
  int get oldStart {
    for (final l in lines) {
      if (l.oldLine != null) return l.oldLine!;
    }
    return 0;
  }

  /// The last old-text line the hunk covers.
  int get oldEnd {
    for (final l in lines.reversed) {
      if (l.oldLine != null) return l.oldLine!;
    }
    return 0;
  }

  /// The first new-text line the hunk covers.
  int get newStart {
    for (final l in lines) {
      if (l.newLine != null) return l.newLine!;
    }
    return 0;
  }

  /// The last new-text line the hunk covers.
  int get newEnd {
    for (final l in lines.reversed) {
      if (l.newLine != null) return l.newLine!;
    }
    return 0;
  }
}

/// A diff cut into hunks (changes with a few unchanged lines on each
/// side) and the unchanged runs between them.
@immutable
final class DiffSummary {
  const new _(this.hunks, this.gaps, this.added, this.removed);

  /// Groups [lines] into hunks; unchanged runs longer than twice
  /// [context] between hunks are folded into gaps.
  factory of(List<DiffLine> lines, {int context = 3}) {
    final changed = [
      for (var i = 0; i < lines.length; i++)
        if (lines[i].kind != DiffKind.same) i,
    ];
    var added = 0;
    var removed = 0;
    for (final l in lines) {
      if (l.kind == DiffKind.added) added++;
      if (l.kind == DiffKind.removed) removed++;
    }
    if (changed.isEmpty) return const DiffSummary._([], [], 0, 0);
    final ranges = <(int, int)>[];
    var start = (changed.first - context).clamp(0, lines.length);
    var end = (changed.first + context + 1).clamp(0, lines.length);
    for (final i in changed.skip(1)) {
      final s = (i - context).clamp(0, lines.length);
      final e = (i + context + 1).clamp(0, lines.length);
      if (s <= end) {
        end = e;
      } else {
        ranges.add((start, end));
        start = s;
        end = e;
      }
    }
    ranges.add((start, end));
    final hunks = [for (final (s, e) in ranges) DiffHunk(lines.sublist(s, e))];
    final gaps = <int>[
      ranges.first.$1,
      for (var r = 1; r < ranges.length; r++) ranges[r].$1 - ranges[r - 1].$2,
      lines.length - ranges.last.$2,
    ];
    return DiffSummary._(hunks, gaps, added, removed);
  }

  /// The hunks, in order.
  final List<DiffHunk> hunks;

  /// Unchanged lines folded away: before the first hunk, between each
  /// pair, and after the last (`hunks.length + 1` entries; empty when
  /// nothing changed).
  final List<int> gaps;

  /// Lines only in the new text.
  final int added;

  /// Lines only in the old text.
  final int removed;

  /// Whether the texts are the same.
  bool get identical => hunks.isEmpty;
}
