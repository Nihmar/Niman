/// Where a source line's own text begins.
///
/// A line may carry syntax before its text: indentation, quote marks, a
/// heading's hashes, a list item's marker and its task box. The caret's
/// arithmetic needs that boundary for one thing only — a `Ctrl+←` at the head
/// of a line is the line's motion, not the note's (#528) — but the rule is the
/// scanner's, so it lives here rather than inside `caret_motion.dart`.
///
/// The rule mirrors `BlockScanner`: a quote mark is `>` up to three spaces in,
/// a heading is one to six `#` then a space, a list marker is a bullet (`-`,
/// `+`, `*`) or one to nine digits and a `.` or `)`, then at least one space.
/// The marker's own indent is not asked about, exactly as
/// `BlockScanner.listMarkerOf` does not.
library;

import 'package:niman/src/markdown/source_buffer.dart';

/// The offset where [line]'s own text begins, past the syntax before it.
///
/// Deliberately not the caret's `lineTextStart` motion, which is Home's answer
/// and stops at the indentation: this is where the *content* starts, so a caret
/// anywhere among the marker — `  - [ ] |La` — counts as the head of the line.
/// An empty or marker-only line answers its own end.
int lineBodyStart(SourceBuffer buffer, int line) {
  final text = buffer.lineAt(line);
  var at = 0;
  // Quote marks, each up to three spaces in, so `> > x` nests like `>> x`.
  while (true) {
    final mark = _quoteMark(text, at);
    if (mark < 0) break;
    at = mark;
  }
  // The indentation before the text.
  while (at < text.length && _isLineSpace(text.codeUnitAt(at))) {
    at++;
  }
  final start = at;
  // A heading's hashes, or a list marker and its task box.
  final hashes = _headingHashes(text, start);
  if (hashes > 0) {
    at = hashes;
  } else {
    final marker = _itemMarker(text, start);
    if (marker != null) at = marker;
  }
  // The spaces a marker, a box or a heading's hashes are written with are not
  // the text either.
  while (at < text.length && _isLineSpace(text.codeUnitAt(at))) {
    at++;
  }
  return buffer.offsetOfLine(line) + at;
}

/// The column past the quote mark at [from], or -1 when there is none.
///
/// A mark takes up to three spaces before its `>`, and one space after it.
int _quoteMark(String text, int from) {
  var probe = from;
  while (probe < text.length &&
      probe - from < 3 &&
      _isLineSpace(text.codeUnitAt(probe))) {
    probe++;
  }
  if (probe >= text.length || text.codeUnitAt(probe) != 0x3E) return -1;
  probe++;
  if (probe < text.length && _isLineSpace(text.codeUnitAt(probe))) probe++;
  return probe;
}

/// The column past the hashes of the heading at [from], or 0 when there is
/// none.
int _headingHashes(String text, int from) {
  var hashes = from;
  while (hashes < text.length && text.codeUnitAt(hashes) == 0x23) {
    hashes++;
  }
  final count = hashes - from;
  if (count >= 1 &&
      count <= 6 &&
      (hashes == text.length || _isLineSpace(text.codeUnitAt(hashes)))) {
    return hashes;
  }
  return 0;
}

/// The column past the list marker, its padding and its task box at [from], or
/// null.
int? _itemMarker(String text, int from) {
  if (from >= text.length) return null;
  final char = text.codeUnitAt(from);
  var width = 0;
  if (char == 0x2D || char == 0x2B || char == 0x2A) {
    width = 1;
  } else if (char >= 0x30 && char <= 0x39) {
    var digits = 0;
    while (from + digits < text.length &&
        digits < 9 &&
        text.codeUnitAt(from + digits) >= 0x30 &&
        text.codeUnitAt(from + digits) <= 0x39) {
      digits++;
    }
    if (from + digits >= text.length) return null;
    final delimiter = text.codeUnitAt(from + digits);
    if (delimiter != 0x2E && delimiter != 0x29) return null;
    width = digits + 1;
  } else {
    return null;
  }
  final after = from + width;
  if (after >= text.length) return after;
  if (!_isLineSpace(text.codeUnitAt(after))) return null;
  var padding = 0;
  while (after + padding < text.length &&
      padding < 4 &&
      _isLineSpace(text.codeUnitAt(after + padding))) {
    padding++;
  }
  if (padding == 0) padding = 1;
  var body = after + padding;
  final boxEnd = body + 3;
  if (boxEnd <= text.length &&
      text.codeUnitAt(body) == 0x5B &&
      _isTaskMark(text.codeUnitAt(body + 1)) &&
      text.codeUnitAt(body + 2) == 0x5D &&
      (boxEnd == text.length || _isLineSpace(text.codeUnitAt(boxEnd)))) {
    body = boxEnd;
  }
  return body;
}

/// Whether [char] is a space or tab the line's syntax is laid out with.
bool _isLineSpace(int char) => char == 0x20 || char == 0x09;

/// Whether [char] is the box of a task item: empty, `x` or `X`.
bool _isTaskMark(int char) => char == 0x20 || char == 0x78 || char == 0x58;
