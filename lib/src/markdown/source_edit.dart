/// What one edit did, in the units the parser works in.
///
/// A buffer edit is an offset range, but everything above the buffer — the
/// block scanner, the inline cache, the height map — thinks in lines. Handing
/// them the offset range would make each of them recompute the same two line
/// numbers, and get the *removed* extent wrong in the same way: a replacement
/// of three lines by one has a net line delta of -2, which is not enough to
/// know which blocks survived. So the buffer reports what it did, once, in the
/// shape its callers need.
library;

import 'package:meta/meta.dart';

/// One edit: where it started, how many lines it took out, how many it put in.
@immutable
final class SourceEdit {
  /// Creates an edit record.
  const new({
    required this.firstLine,
    required this.removedLines,
    required this.insertedLines,
    required this.revision,
  });

  /// The line the edit began on, in the coordinates *before* it was applied.
  final int firstLine;

  /// How many lines the replaced range covered, the first one included.
  ///
  /// At least one: an edit always touches the line it starts on.
  final int removedLines;

  /// How many lines the replacement introduced.
  final int insertedLines;

  /// The buffer revision the edit produced.
  final int revision;

  /// How many lines the document gained: negative when it lost some.
  int get lineDelta => insertedLines - removedLines;

  /// The first old line that survived untouched: everything from here moved by
  /// [lineDelta].
  int get firstUntouchedLine => firstLine + removedLines;

  /// Whether the edit left the line count alone.
  bool get preservesLineCount => lineDelta == 0;

  @override
  String toString() =>
      'SourceEdit(line $firstLine, -$removedLines +$insertedLines '
      '@$revision)';
}
