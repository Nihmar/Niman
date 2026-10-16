/// The lines the spell check has answered for, kept within bounds (#1052).
///
/// An answer is keyed by the line's *text* and the ranges it was told to
/// skip, not by the line's index: a line pushed down by an Enter above it is
/// still a hit, and nothing is checked twice because the note shifted. The
/// skip is part of the key because a line asked about with nothing to skip —
/// its tokens not known yet — is a different question from the same line
/// asked about with its code, maths and links skipped, and the first answer
/// must not stand for the second (#373).
///
/// Least recently used goes first, within a number of lines and a number of
/// characters: scrolling a large note top to bottom keeps the lines on and
/// near the screen, not a second copy of the note.
library;

import 'dart:collection';

import 'package:flutter/widgets.dart';

/// A bounded memory of line answers.
final class CheckedLines {
  /// Creates a memory of at most [maxLines] lines holding at most [maxChars]
  /// characters of text between them.
  new({this.maxLines = 4096, this.maxChars = 2 * 1024 * 1024});

  /// The most lines kept.
  final int maxLines;

  /// The most characters of line text kept: a few very long lines must not
  /// stand for thousands.
  final int maxChars;

  /// Least recently used first: an entry read is moved to the end.
  final LinkedHashMap<(String, String), List<TextRange>> _entries =
      LinkedHashMap<(String, String), List<TextRange>>();

  int _chars = 0;

  /// How many lines are held.
  int get length => _entries.length;

  /// Whether nothing is held.
  bool get isEmpty => _entries.isEmpty;

  /// The ranges found in [text] when it was checked with [skip], or null when
  /// it was not (or the answer has been evicted since).
  List<TextRange>? lookup(String text, List<TextRange> skip) {
    final key = (text, _signature(skip));
    final ranges = _entries.remove(key);
    if (ranges == null) return null;
    _entries[key] = ranges;
    return ranges;
  }

  /// Remembers that [text], checked with [skip], has [ranges].
  void store(String text, List<TextRange> skip, List<TextRange> ranges) {
    final key = (text, _signature(skip));
    if (_entries.remove(key) != null) _chars -= text.length;
    _entries[key] = ranges;
    _chars += text.length;
    while (_entries.length > 1 &&
        (_entries.length > maxLines || _chars > maxChars)) {
      final oldest = _entries.keys.first;
      _entries.remove(oldest);
      _chars -= oldest.$1.length;
    }
  }

  /// Forgets every line.
  void clear() {
    _entries.clear();
    _chars = 0;
  }

  /// The skip ranges as a string, so they can be part of a key: equal ranges,
  /// equal signature.
  static String _signature(List<TextRange> skip) {
    if (skip.isEmpty) return '';
    final out = StringBuffer();
    for (final range in skip) {
      out
        ..write(range.start)
        ..write('-')
        ..write(range.end)
        ..write(',');
    }
    return '$out';
  }
}
