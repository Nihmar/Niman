/// The places of a book on screen, as a link (#282) and an annotation
/// (#284) name them: a line of a chapter, labelled with the book's name and
/// the contents entry being read there.
library;

import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/read_selection.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/place_link_button.dart';
import 'package:path/path.dart' as p;

/// The places of the book at [path], as [document] reads and [view] shows
/// it.
final class EpubPlaces {
  /// The places of the book at [path], an absolute path, in the library
  /// [positions] keeps.
  const new({
    required this.path,
    required this.positions,
    required this.document,
    required this.view,
  });

  /// The book's absolute path.
  final String path;

  /// The library's reading positions, which know its root; null for a book
  /// outside a library, which has no place to link to.
  final ReadingPositions? positions;

  /// The book, once read.
  final EpubDocument? document;

  /// Its read view, once drawn.
  final MarkdownReadViewState? view;

  /// The line being read: the one at the top of the view, or the next one
  /// when the view is mostly past it.
  int? topLine() => switch (view?.topAnchor) {
    final anchor? => anchor.line + (anchor.fraction > 0.5 ? 1 : 0),
    null => null,
  };

  /// [line] of the book as a place to link to.
  PlaceToLink? at(int line) {
    final document = this.document;
    final key = positions?.keyOf(path);
    final place = document?.locationAt(line, 0);
    if (document == null || key == null || place == null) return null;
    final name = p.basenameWithoutExtension(path);
    final entry = document.entryAt(line);
    return (
      path: key,
      place: place,
      label: entry == -1 ? name : '$name, ${document.contents[entry].title}',
    );
  }

  /// The place being read.
  PlaceToLink? here() => switch (topLine()) {
    final line? => at(line),
    null => null,
  };

  /// The paragraph opening at [line], [text] its words, as an annotation.
  Annotation? annotation(int line, String text) => switch (at(line)) {
    final at? => Annotation(
      path: at.path,
      place: at.place,
      label: at.label,
      quote: text,
    ),
    null => null,
  };

  /// The passage [selection] holds, as a place to link to: the paragraph
  /// it starts in, and its characters there when it ends there too (#283).
  PlaceToLink? selected(ReadSelection selection) {
    final paragraph = at(selection.line);
    if (paragraph == null) return null;
    final place = paragraph.place as EpubLocation;
    final end = selection.end;
    return (
      path: paragraph.path,
      place: end == null
          ? place
          : EpubLocation(
              chapter: place.chapter,
              line: place.line,
              chars: (start: selection.start, end: end),
            ),
      label: paragraph.label,
    );
  }

  /// The passage [selection] holds, as an annotation quoting it.
  Annotation? selectionAnnotation(ReadSelection selection) =>
      switch (selected(selection)) {
        final at? => Annotation(
          path: at.path,
          place: at.place,
          label: at.label,
          quote: selection.text,
        ),
        null => null,
      };

  /// The passage selected, else the paragraph being read, as an
  /// annotation.
  Annotation? annotationHere() {
    if (view?.selection case final selection?) {
      return selectionAnnotation(selection);
    }
    final top = topLine();
    final block = top == null ? null : view?.blockTextAt(top);
    return block == null ? null : annotation(block.line, block.text);
  }
}
