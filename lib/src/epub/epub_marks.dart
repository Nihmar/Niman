/// Where a book's annotations fall in its text (#285): the lines of the
/// book its marks point at.
library;

import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/reading/book_location.dart';

/// The lines of [document] that [marks] point at, ascending; a mark in a
/// chapter the book no longer has points at none.
List<int> epubMarkedLines(EpubDocument document, List<AnnotationMark> marks) =>
    [for (final (:line, mark: _) in _placed(document, marks)) line]..sort();

/// The [marks] of [document] that point at its lines [start]..[end], the
/// end excluded: a paragraph's annotations.
List<AnnotationMark> epubMarksBetween(
  EpubDocument document,
  List<AnnotationMark> marks,
  int start,
  int end,
) => [
  for (final (:line, :mark) in _placed(document, marks))
    if (line >= start && line < end) mark,
];

Iterable<({int line, AnnotationMark mark})> _placed(
  EpubDocument document,
  List<AnnotationMark> marks,
) sync* {
  for (final mark in marks) {
    if (mark.place case final EpubLocation place) {
      final line = document.lineOfLocation(place);
      if (line != null) yield (line: line, mark: mark);
    }
  }
}
