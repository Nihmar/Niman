/// How far into a book the reader is (#1275): into the chapter, into the
/// book, and the reading time left to the end of each.
///
/// Measured in characters, never in lines or laid-out pixels: a book's
/// paragraphs vary too much in length for its lines to be a fair measure,
/// and the pixels are known only for the part of it built so far. The time
/// comes from the words left, at an average reading pace. The book is
/// counted once, as it is read ([EpubCounts], on the isolate that reads
/// it); a scroll only looks the figures up.
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The views the progress line cycles through, a tap moving to the next.
enum EpubProgressView {
  /// How far into the chapter.
  chapter,

  /// How far into the whole book, and which chapter of how many.
  book,

  /// The reading time left to the chapter's end and to the book's.
  time;

  /// The view a tap moves to.
  EpubProgressView get next => values[(index + 1) % values.length];

  /// The view with this [name]; anything unknown is [chapter].
  static EpubProgressView fromName(Object? name) {
    for (final view in values) {
      if (view.name == name) return view;
    }
    return chapter;
  }
}

/// A book's text counted a line at a time: its characters (whitespace
/// left out) and its words before each line.
@immutable
final class EpubCounts {
  const new _(this._chars, this._words);

  /// Counts [text], the book's Markdown.
  ///
  /// Words are kept in halves: a run of letters between spaces is a word,
  /// and so is every two characters of a script written without spaces
  /// (Chinese, Japanese), which reads at about twice the characters a
  /// minute an alphabet's words do.
  factory of(String text) {
    final chars = <int>[0];
    final halves = <int>[0];
    var c = 0;
    var h = 0;
    var inWord = false;
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (unit == 0x0A) {
        inWord = false;
        chars.add(c);
        halves.add(h);
      } else if (unit == 0x20 || unit == 0x09 || unit == 0x0D) {
        inWord = false;
      } else if (unit & 0xFC00 != 0xDC00) {
        // The second half of a surrogate pair is the same character.
        c++;
        if (_unspaced(unit)) {
          inWord = false;
          h++;
        } else if (!inWord) {
          inWord = true;
          h += 2;
        }
      }
    }
    chars.add(c);
    halves.add(h);
    return EpubCounts._(Int32List.fromList(chars), Int32List.fromList(halves));
  }

  /// Kana and the common ideographs: scripts written without spaces.
  static bool _unspaced(int unit) =>
      (unit >= 0x3040 && unit <= 0x30FF) || (unit >= 0x3400 && unit <= 0x9FFF);

  final Int32List _chars;
  final Int32List _words;

  /// How many lines were counted.
  int get lines => _chars.length - 1;

  /// The characters of the whole book.
  int get chars => _chars[lines];

  /// The characters before [line], [fraction] of the way into it.
  double charsAt(int line, [double fraction = 0]) =>
      _at(_chars, line, fraction);

  /// The words before [line], [fraction] of the way into it.
  double wordsAt(int line, [double fraction = 0]) =>
      _at(_words, line, fraction) / 2;

  double _at(Int32List counts, int line, double fraction) {
    if (line < 0) return 0;
    if (line >= lines) return counts[lines].toDouble();
    final before = counts[line];
    return before + (counts[line + 1] - before) * fraction.clamp(0.0, 1.0);
  }
}

/// Where a reader is in a book, as the progress line shows it.
///
/// The chapter is counted from 1, of `chapters`; how far
/// into it and into the book run from 0 to 1; the minutes are the reading
/// time left to the chapter's end and to the book's.
typedef EpubProgressAt = ({
  int chapter,
  int chapters,
  double inChapter,
  double inBook,
  int chapterMinutes,
  int bookMinutes,
});

/// The progress through one book.
final class EpubProgress {
  /// The progress through a book counted as [counts], whose chapters open
  /// on [chapterLines], in order.
  new(this.counts, List<int> chapterLines)
    : _starts = chapterLines.isEmpty ? const [0] : chapterLines;

  /// The book's counts.
  final EpubCounts counts;

  final List<int> _starts;

  /// The reading pace the time left is reckoned at, in words a minute.
  static const int wordsPerMinute = 250;

  /// Whether the book has no text to measure: no progress line for it.
  bool get isEmpty => counts.chars == 0;

  /// How far into the book each chapter after the first opens, from 0 to
  /// 1: the ticks on the book's track.
  List<double> get chapterTicks => [
    if (!isEmpty)
      for (final line in _starts.skip(1)) counts.charsAt(line) / counts.chars,
  ];

  /// The progress with the top of the view at [line], [fraction] of the
  /// way into it. A line past the book's last is its end.
  EpubProgressAt at(int line, [double fraction = 0]) {
    final index = _chapterAt(line);
    final startLine = _starts[index];
    final endLine = index + 1 < _starts.length
        ? _starts[index + 1]
        : counts.lines;
    final start = counts.charsAt(startLine);
    final end = counts.charsAt(endLine);
    final here = counts.charsAt(line, fraction).clamp(start, end);
    final words = counts.wordsAt(line, fraction);
    return (
      chapter: index + 1,
      chapters: _starts.length,
      inChapter: end == start ? 1 : (here - start) / (end - start),
      inBook: isEmpty ? 0 : here / counts.chars,
      chapterMinutes: _minutes(counts.wordsAt(endLine) - words),
      bookMinutes: _minutes(counts.wordsAt(counts.lines) - words),
    );
  }

  /// The chapter [line] is in: the last opening at or above it, the first
  /// for a line above them all.
  int _chapterAt(int line) {
    var low = 0;
    var high = _starts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_starts[mid] <= line) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  static int _minutes(double words) =>
      words <= 0 ? 0 : (words / wordsPerMinute).ceil();
}
