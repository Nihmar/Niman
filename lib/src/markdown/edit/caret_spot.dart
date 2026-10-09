import 'package:flutter/foundation.dart';

/// Where the caret is, for the lines that draw it and the reveal that follows
/// it: its line, and the run of non-whitespace it sits in on that line.
///
/// One value rather than a line and a word kept apart, because the property
/// that matters is *equality*: a caret that moves inside a run produces an
/// equal [CaretSpot], so no line rebuilds, and one that crosses a run boundary
/// produces a different one, so exactly the two lines involved do
/// (`docs/records/unified-surface.md` §8.6.2's budget).
@immutable
final class CaretSpot {
  /// The caret's line and its run on it.
  const new(this.line, this.runStart, this.runEnd);

  /// The line the caret is on, or -1 for a caret the note cannot hold.
  final int line;

  /// Where the run of non-whitespace the caret is in starts.
  final int runStart;

  /// Where that run ends, exclusive.
  final int runEnd;

  @override
  bool operator ==(Object other) =>
      other is CaretSpot &&
      other.line == line &&
      other.runStart == runStart &&
      other.runEnd == runEnd;

  @override
  int get hashCode => Object.hash(line, runStart, runEnd);

  @override
  String toString() => 'CaretSpot($line, $runStart..$runEnd)';
}
