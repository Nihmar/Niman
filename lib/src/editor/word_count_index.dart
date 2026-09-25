/// A note's word count, kept up to date by the edits rather than worked out
/// again on a timer.
///
/// Counting the whole note is a pass over every character: 675 ms on the
/// 246 MB note of the 0.0.9 stress test, and the pass had to join the text
/// first — another 190 ms. The statistics did that after every pause in the
/// typing, on an isolate, which is why a note that size waited seconds for
/// its own word count (see `docs/records/huge-notes.md`).
///
/// Here the count is kept per line, in the same chunked storage
/// [PrefixSums] gives the buffer's spans, so an edit pays for the lines it
/// touched and a reader asks for a total that is already there. The value of
/// a line is "the words this line contributes, assuming it ends the line":
/// a line's own words, plus one when a terminator follows it, because the
/// break separates the last word of one line from the first of the next —
/// which is what makes a join come out right.
library;

import 'dart:isolate';

import 'package:meta/meta.dart';

import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/markdown/prefix_sums.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// The words of a note, per line and in total.
final class WordCount {
  /// Counts nothing yet: [words] answers zero until [adopt] or [edited]
  /// fills the count in.
  ///
  /// This is what a note starts as, so that the first frame of a huge one
  /// does not wait for a scan of every character; the caller fills it in
  /// ([countInBackground]) and the count lands a moment later.
  new();

  /// Counts [buffer] here, now: O(characters).
  ///
  /// Notes of a modest size take this at load — a 2 MB one is about 5 ms.
  /// A larger one is started empty and counted in the background instead;
  /// see [countInBackground].
  factory of(SourceBuffer buffer) => WordCount()..adopt(buffer);

  /// The values, chunked like the buffer's spans, or null while the count
  /// has not been built.
  PrefixSums? _sums;

  /// The word count of [buffer], worked out line by line.
  ///
  /// Called on a buffer nothing edits meanwhile: the lines are read once, in
  /// order, and each line's contribution recorded.
  void adopt(SourceBuffer buffer) {
    final values = <double>[
      for (var line = 0; line < buffer.lineCount; line++)
        _lineValue(buffer, line),
    ];
    _sums = PrefixSums(values);
  }

  /// How many words the note holds.
  ///
  /// O(1) once the count is there, and zero until it is — never a pass over
  /// the text.
  int get words => _sums?.total.toInt() ?? 0;

  /// Whether the count has been built: false for a note whose count is still
  /// being worked out elsewhere.
  bool get isCounted => _sums != null;

  /// Drops the count: the note's text was replaced whole, not edited, so no
  /// line of the count is known to still be one of the note's. [words]
  /// answers zero and [edited] waits until the count is built again.
  void forget() => _sums = null;

  /// Takes [counted]'s count as this one's: the count [countInBackground]
  /// worked out elsewhere, so it is not worked out again here.
  void adoptCount(WordCount counted) => _sums = counted._sums;

  /// How many lines this isolate has counted, for a test to see that a count
  /// done in the background was not done again here.
  @visibleForTesting
  static int linesCountedHere = 0;

  /// Follows [edit], already made to [buffer].
  ///
  /// The same shape as the buffer's own index update: one value per line
  /// when the line count did not move, a splice when it did.
  void edited(SourceEdit edit, SourceBuffer buffer) {
    final sums = _sums;
    if (sums == null) return;
    final first = edit.firstLine;
    final removed = edit.removedLines;
    final inserted = edit.insertedLines;
    if (first < 0 || first > buffer.lineCount) return;
    if (inserted == removed) {
      for (var i = 0; i < inserted; i++) {
        final line = first + i;
        if (line >= buffer.lineCount) break;
        sums.setValue(line, _lineValue(buffer, line));
      }
      return;
    }
    sums.splice(first, removed, <double>[
      for (var i = 0; i < inserted; i++) _lineValue(buffer, first + i),
    ]);
  }

  /// What line [line] contributes to the note's word count.
  ///
  /// The words of the line itself. The terminator is not one — counting it
  /// would make the note's count grow with how its text is broken into
  /// lines rather than with what is written on it — and the sum comes out
  /// right through the edit: breaking `ab` into `a` and `b` leaves the count
  /// alone (1 to 1 + 1 counted with the break's separator, see below), and
  /// joining them back takes that one off again.
  ///
  /// A line whose terminator follows it is counted *with* the break —
  /// [countWords] of `line + '\n'` — because a break is a separator: the
  /// join of `a` and `b` into `ab` is 1 + 1 to 1, and it has to lose exactly
  /// one. The last line, with no break under it, is worth its own words
  /// alone.
  static double _lineValue(SourceBuffer buffer, int line) {
    linesCountedHere++;
    final text = buffer.lineAt(line);
    final break_ = buffer.terminatorAt(line).isEmpty ? '' : '\n';
    return countWords('$text$break_').toDouble();
  }
}

/// Counts [buffer]'s words in an isolate and answers a count ready to
/// follow its edits.
///
/// O(characters), off the UI isolate: 675 ms on the 246 MB note. The buffer
/// goes as it is — the Call copies its line list, not its text — and the
/// answer comes back whole.
Future<WordCount> countInBackground(SourceBuffer buffer) =>
    Isolate.run(() => WordCount.of(buffer));
