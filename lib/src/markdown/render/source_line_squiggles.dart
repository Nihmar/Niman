/// The wavy marks over a source line (split out of `source_line.dart` for
/// #100): the spelling's misspelled words and the template checker's
/// problems, painted over the line's paragraph or over each piece of a
/// table row laid out in fitted columns.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/squiggle_painter.dart';

/// The line's wavy marks.
extension SourceLineSquiggles on SourceLine {
  /// The words of [start, end) of the line the spelling flags, as offsets
  /// from the piece's own start: the line's ranges, clipped to the piece.
  List<TextRange> misspelledInPiece(int start, int end) => <TextRange>[
    for (final range in _unjudged())
      if (range.end > start && range.start < end)
        TextRange(
          start: range.start < start ? 0 : range.start - start,
          end: range.end > end ? end - start : range.end - start,
        ),
  ];

  /// The template problems of `[start, end)` of the line, as offsets from the
  /// piece's own start: the line's ranges, clipped to the piece.
  List<TextRange> templateProblemsInPiece(int start, int end) => <TextRange>[
    for (final range in templateProblems)
      if (range.end > start && range.start < end)
        TextRange(
          start: range.start < start ? 0 : range.start - start,
          end: range.end > end ? end - start : range.end - start,
        ),
  ];

  /// The misspelled words to underline: all of them but the one being
  /// composed, which is not judged yet — its underline is the IME's.
  List<TextRange> _unjudged() {
    final typing = composing;
    if (typing == null) return misspelled;
    return <TextRange>[
      for (final word in misspelled)
        if (word.end <= typing.$1 || word.start >= typing.$2) word,
    ];
  }

  /// The paragraph with the wavy marks painted over it rather than written
  /// into its runs: a style has one decoration, and a wavy underline there
  /// took a struck word's strike.
  ///
  /// The template checker's problems and the spelling's words are two layers
  /// of the same shape, so a line that has both shows both — the checker's
  /// mark is not lost under the spelling's, nor the other way round
  /// (T-TPL-09).
  Widget withSquiggles(Widget paragraph) {
    var marked = paragraph;
    if (templateProblems.isNotEmpty) {
      marked = CustomPaint(
        foregroundPainter: SquigglePainter(
          paragraph: paragraphKey,
          ranges: templateProblems,
          color: misspelledColor,
        ),
        child: marked,
      );
    }
    if (misspelled.isNotEmpty) {
      marked = CustomPaint(
        foregroundPainter: SquigglePainter(
          paragraph: paragraphKey,
          ranges: _unjudged(),
          color: misspelledColor,
        ),
        child: marked,
      );
    }
    return marked;
  }
}
