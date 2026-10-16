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
/// a line is the words of its text ([wordsOfLine]): not the syntax it is
/// written in — `## Title` is one word, `---` none — and nothing at all for
/// the lines of the frontmatter (#1051). The line break separates one line's
/// last word from the next one's, so a join comes out right when the edit
/// recounts the line it made.
///
/// A line's value depends on the line alone, except in the frontmatter: a
/// leading `---` … `---` block, whose extent the count keeps (`_front`) and
/// re-reads when an edit touches it.
library;

import 'dart:isolate';
import 'dart:math';

import 'package:meta/meta.dart';

import 'package:niman/src/editor/line_words.dart';
import 'package:niman/src/markdown/line_syntax.dart';
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

  /// How many lines the frontmatter takes at the top of the note, the closing
  /// mark included; zero for a note without one. Its lines count no words.
  int _front = 0;

  /// How many lines are searched for the mark that closes the frontmatter. A
  /// note that opens with `---` and does not close it that soon has a rule on
  /// its first line, not a frontmatter: the search is a bounded read, so the
  /// edit that asks it stays O(change).
  static const int frontmatterWindow = 1024;

  /// How many lines at the top of [buffer] are its frontmatter.
  static int _frontLines(SourceBuffer buffer) {
    if (buffer.lineCount == 0) return 0;
    if (!LineSyntax.opensFrontmatter(0, buffer.lineAt(0))) return 0;
    final last = min(buffer.lineCount, frontmatterWindow);
    for (var line = 1; line < last; line++) {
      if (LineSyntax.closesFrontmatter(buffer.lineAt(line))) return line + 1;
    }
    return 0;
  }

  /// The word count of [buffer], worked out line by line.
  ///
  /// Called on a buffer nothing edits meanwhile: the lines are read once, in
  /// order, and each line's contribution recorded.
  void adopt(SourceBuffer buffer) {
    _front = _frontLines(buffer);
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
  void adoptCount(WordCount counted) {
    _sums = counted._sums;
    _front = counted._front;
  }

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
    // The frontmatter is the one thing a line's value reads beyond the line:
    // an edit inside it (or on the first line, which may open one) says where
    // it ends now, and the lines between the old end and the new one change
    // value without having been touched.
    // A note that opens with `---` and has not closed it yet is waiting for
    // the mark: an edit within the window may be the one that closes it.
    final before = _front;
    final touchesFront = before > 0
        ? first < before
        : first == 0 ||
              (first < frontmatterWindow &&
                  LineSyntax.opensFrontmatter(0, buffer.lineAt(0)));
    if (touchesFront) _front = _frontLines(buffer);
    if (inserted == removed) {
      for (var i = 0; i < inserted; i++) {
        final line = first + i;
        if (line >= buffer.lineCount) break;
        sums.setValue(line, _lineValue(buffer, line));
      }
    } else {
      sums.splice(first, removed, <double>[
        for (var i = 0; i < inserted; i++) _lineValue(buffer, first + i),
      ]);
    }
    if (touchesFront && (before > 0 || _front > 0)) {
      final through = min(
        buffer.lineCount,
        max(_front, before + edit.lineDelta),
      );
      for (var line = 0; line < through; line++) {
        sums.setValue(line, _lineValue(buffer, line));
      }
    }
  }

  /// What line [line] contributes to the note's word count: the words of its
  /// text ([wordsOfLine]), none for a line of the frontmatter.
  ///
  /// The terminator is not a word, and the sum comes out right through an
  /// edit all the same: breaking `ab` into `a` and `b` makes two lines of
  /// one word each, and joining them back recounts the one line it made.
  double _lineValue(SourceBuffer buffer, int line) {
    linesCountedHere++;
    if (line < _front) return 0;
    return wordsOfLine(buffer.lineAt(line)).toDouble();
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
