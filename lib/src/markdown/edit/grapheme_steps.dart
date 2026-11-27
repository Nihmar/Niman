// Grapheme clusters over text that is only ever read through slices (#1347).
//
// A caret moves by clusters, a word is a run of them, and the text it moves
// through is a note that may be a quarter of a gigabyte: a step must cost the
// size of the cluster it crosses, not of the note. So everything here reads a
// *window* of the text — `slice(from, to)` — and the whole difficulty is
// knowing when a window has told the truth.
//
// A boundary between two clusters is decided by the two code points around it,
// plus the *left* context for two rules: a run of regional indicators pairs up
// from its first one (flags), and an emoji joined by ZWJ continues only when
// an emoji came before the joiner. A window that starts in the middle of a
// cluster knows nothing of what came before it, so its first clusters can be
// wrong; the clusters after them are not. That is what the three-cluster rule
// below rests on — and what the property test (`grapheme_steps_test.dart`)
// holds it to, against the whole text segmented from its start.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A way to read `[start, end)` of some text.
typedef TextSlice = String Function(int start, int end);

/// Cluster boundaries and word runs over [length] units read through [slice].
final class GraphemeSteps {
  /// Steps over the text [slice] reads, [length] code units long.
  const new(this.length, this.slice);

  /// Steps over [text].
  new ofString(String text) : this(text.length, text.substring);

  /// Steps over the text of [buffer].
  new ofBuffer(SourceBuffer buffer) : this(buffer.length, buffer.substring);

  /// How long the text is.
  final int length;

  /// Reads a range of the text.
  final TextSlice slice;

  /// How far either side of an offset a first look reaches. A cluster is a
  /// handful of code units; the look grows when one is not.
  static const int _reach = 64;

  /// How much a word scan reads at a time.
  static const int _chunk = 2048;

  /// The end of the cluster that starts at [at]: the next boundary.
  ///
  /// [at] is taken to be a boundary. A cluster longer than the window — a
  /// zalgo run, a long ZWJ chain — is read again through a window twice as
  /// wide until it ends inside one, so it is one step whatever its length.
  int next(int at) {
    if (at >= length) return length;
    var reach = _reach;
    while (true) {
      final to = math.min(length, at + reach);
      final first = slice(at, to).characters.first.length;
      // Two units to spare, so that a pair cut by the window's end cannot
      // have been what ended (or did not end) the cluster.
      if (to == length || first + 2 <= to - at) return at + first;
      reach *= 2;
    }
  }

  /// The start of the cluster that holds the code unit before [at]: the
  /// boundary before it. For an [at] that is a boundary, the one before the
  /// cluster that ends there.
  int previous(int at) {
    if (at <= 0) return 0;
    // Half a pair is the pair's cluster: asked from its middle, from its end.
    if (at < length && _pairStart(at) != at) return previous(at + 1);
    var reach = _reach;
    while (true) {
      final from = _pairStart(math.max(0, at - reach));
      var count = 0;
      var last = from;
      var position = from;
      for (final cluster in slice(from, at).characters) {
        last = position;
        position += cluster.length;
        count++;
      }
      // From the text's start the answer is exact. From anywhere else the
      // first two clusters may be cut wrong (see the top of the file), so the
      // last one is the answer only when it is the third or later.
      if (from == 0 || count >= 3) return _flagged(last, at);
      reach *= 2;
    }
  }

  /// The start of the cluster ending at [at], given [start] as a window has it.
  ///
  /// A window pairs the regional indicators it sees from its own first one,
  /// and flags are pairs counted from the run's first indicator, which no
  /// window can know: a cluster that starts with an indicator is measured
  /// against the whole run. The cluster is one or two indicators and whatever
  /// marks follow; counting the indicators of the run up to and including the
  /// cluster's last, a pair ends on that last one when the count is even and
  /// a lone indicator does when it is odd.
  int _flagged(int start, int at) {
    if (!_isIndicator(start, at)) return start;
    final here = _isIndicator(start + 2, at) ? 2 : 1;
    var before = start;
    while (_isIndicator(before - 2, at)) {
      before -= 2;
    }
    final run = (start - before) ~/ 2 + here;
    final last = start + 2 * (here - 1);
    return run.isEven ? last - 2 : last;
  }

  /// Whether a regional indicator (U+1F1E6..U+1F1FF) stands at [offset],
  /// inside the text and before [limit].
  bool _isIndicator(int offset, int limit) {
    if (offset < 0 || offset + 2 > limit) return false;
    final pair = slice(offset, offset + 2);
    return pair.codeUnitAt(0) == 0xD83C &&
        pair.codeUnitAt(1) >= 0xDDE6 &&
        pair.codeUnitAt(1) <= 0xDDFF;
  }

  /// [offset], moved back off the middle of a surrogate pair: a window that
  /// begins on a lone low surrogate segments what follows wrongly.
  int _pairStart(int offset) {
    if (offset <= 0 || offset >= length) return offset;
    final unit = slice(offset, offset + 1).codeUnitAt(0);
    return unit >= 0xDC00 && unit <= 0xDFFF ? offset - 1 : offset;
  }

  /// The end of the run of clusters from [from] whose being a word character
  /// ([isWordChar]) is [word].
  int runForward(int from, {required bool word}) {
    var index = from;
    var reach = _chunk;
    while (index < length) {
      final to = math.min(length, index + reach);
      var position = index;
      for (final cluster in slice(index, to).characters) {
        // The last cluster of a window short of the text's end may be cut by
        // it; the next window starts there.
        if (to < length && position + cluster.length + 2 > to) break;
        if (isWordChar(cluster) != word) return position;
        position += cluster.length;
      }
      if (position == index) {
        reach *= 2;
      } else {
        index = position;
      }
    }
    return length;
  }

  /// The start of the run of clusters before [from] whose being a word
  /// character is [word].
  int runBackward(int from, {required bool word}) {
    var index = from;
    var reach = _chunk;
    while (index > 0) {
      final start = _pairStart(math.max(0, index - reach));
      final clusters = slice(start, index).characters.toList();
      // The first two clusters of a window cut out of the middle of the text
      // are not to be trusted ([previous]).
      final trusted = start == 0 ? 0 : 2;
      if (clusters.length <= trusted) {
        reach *= 2;
        continue;
      }
      var end = index;
      for (var at = clusters.length - 1; at >= trusted; at--) {
        if (isWordChar(clusters[at]) != word) return end;
        end -= clusters[at].length;
      }
      index = end;
    }
    return 0;
  }
}

/// Whether [cluster] is part of a word: it starts with a letter, a digit or an
/// underscore — what follows (a combining accent, a joiner, a variation
/// selector) belongs to it, and a cluster that starts with one of those is
/// not a letter's.
///
/// The rule editors share, and the one a writer expects: `snake_case_name`
/// moves as one word, `due parole` as two, and punctuation belongs to neither
/// side. The bracket pairs read it too, for the characters that only sometimes
/// pair (#718).
bool isWordChar(String cluster) {
  if (cluster.isEmpty) return false;
  final unit = cluster.codeUnitAt(0);
  if (unit < 0x80) {
    return (unit >= 0x61 && unit <= 0x7A) ||
        (unit >= 0x41 && unit <= 0x5A) ||
        (unit >= 0x30 && unit <= 0x39) ||
        unit == 0x5F;
  }
  // A letter outside the BMP is a surrogate pair: the code point is read
  // whole.
  final long =
      unit >= 0xD800 &&
      unit <= 0xDBFF &&
      cluster.length > 1 &&
      cluster.codeUnitAt(1) >= 0xDC00 &&
      cluster.codeUnitAt(1) <= 0xDFFF;
  return _wordPattern.hasMatch(
    long ? cluster.substring(0, 2) : String.fromCharCode(unit),
  );
}

/// Compiled once: a keystroke-rate caller compiling it per character was the
/// most expensive part of a word motion.
final RegExp _wordPattern = RegExp(r'^[\p{L}\p{N}_]$', unicode: true);
