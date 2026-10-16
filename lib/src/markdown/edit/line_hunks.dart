// What changed between two texts, as hunks of whole lines (#1050).
//
// An edit that replaces a span of the note — Replace All, Tidy, a kind GUI
// handing its text back — records the whole span twice (what was there, what
// is there) although most of its lines are the same on both sides. The undo
// history keeps the *hunks* instead, so what it holds follows what changed.
//
// Not a minimal diff: a greedy walk in lock-step that resynchronises on the
// next few lines the two sides share, which is exactly the shape of a
// find-and-replace (lines changed in place, a few inserted or dropped). When
// no resynchronisation turns up inside the window the rest of the text is one
// hunk, so the answer is always *correct* and, at worst, as large as the
// input. O(n) for a text that changed in place.
import 'dart:math';

/// One run of lines that differ: `removed[removedStart, removedEnd)` became
/// `inserted[insertedStart, insertedEnd)`, offsets into the two texts.
typedef LineHunk = ({
  int removedStart,
  int removedEnd,
  int insertedStart,
  int insertedEnd,
});

/// How many lines either side may differ before the walk gives up and takes
/// the rest of the text as one hunk.
const int _window = 32;

/// How many lines after a candidate must agree for the two sides to be taken
/// as in step again (a single equal line, a blank one say, proves nothing).
const int _agree = 3;

/// The hunks that turn [removed] into [inserted], in order and apart: between
/// two hunks (and before the first, and after the last) the texts are equal.
/// Empty when the two texts are equal.
List<LineHunk> lineHunks(String removed, String inserted) {
  final a = _lineStarts(removed);
  final b = _lineStarts(inserted);
  final na = a.length - 1;
  final nb = b.length - 1;

  bool same(int i, int j) {
    final length = a[i + 1] - a[i];
    if (length != b[j + 1] - b[j]) return false;
    final from = a[i];
    final to = b[j];
    for (var k = 0; k < length; k++) {
      if (removed.codeUnitAt(from + k) != inserted.codeUnitAt(to + k)) {
        return false;
      }
    }
    return true;
  }

  // Whether the lines from `(i, j)` on agree for [_agree] lines, or both texts
  // end together before that.
  bool inStep(int i, int j) {
    for (var t = 0; t < _agree; t++) {
      final ended = i + t >= na;
      final otherEnded = j + t >= nb;
      if (ended || otherEnded) return ended && otherEnded;
      if (!same(i + t, j + t)) return false;
    }
    return true;
  }

  final hunks = <LineHunk>[];
  var i = 0;
  var j = 0;
  while (i < na && j < nb) {
    if (same(i, j)) {
      i++;
      j++;
      continue;
    }
    // The nearest point both sides are in step again, searched by how many
    // lines it skips: (i + x, j + y) for the smallest x + y.
    var skipA = -1;
    var skipB = -1;
    for (var d = 1; d <= 2 * _window && skipA < 0; d++) {
      for (var x = max(0, d - _window); x <= d && x <= _window; x++) {
        final y = d - x;
        if (i + x > na || j + y > nb) continue;
        if (inStep(i + x, j + y)) {
          skipA = x;
          skipB = y;
          break;
        }
      }
    }
    if (skipA < 0) {
      // Not in step inside the window: the rest is one hunk.
      skipA = na - i;
      skipB = nb - j;
    }
    hunks.add((
      removedStart: a[i],
      removedEnd: a[i + skipA],
      insertedStart: b[j],
      insertedEnd: b[j + skipB],
    ));
    i += skipA;
    j += skipB;
  }
  if (i < na || j < nb) {
    hunks.add((
      removedStart: a[i],
      removedEnd: removed.length,
      insertedStart: b[j],
      insertedEnd: inserted.length,
    ));
  }
  return hunks;
}

/// Where each line of [text] starts, and a last entry for its end: line `i`
/// is `[starts[i], starts[i + 1])`, its terminator included. A text that ends
/// in a terminator has no empty last line.
List<int> _lineStarts(String text) {
  final starts = <int>[0];
  var at = text.indexOf('\n');
  while (at >= 0) {
    starts.add(at + 1);
    at = text.indexOf('\n', at + 1);
  }
  if (starts.last != text.length) starts.add(text.length);
  return starts;
}
