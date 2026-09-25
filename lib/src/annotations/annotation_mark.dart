/// Where a PDF or a book was annotated (#285): a place in it, and the
/// annotation of a companion note that points there.
///
/// Marks are read from the companion notes, never stored: every link in a
/// companion that points at a place of its file is one, found by
/// [annotationLinksIn] and resolved by `CompanionNotes.marksOf`. The
/// annotation opens at its section — the heading above the link, as an
/// annotation is written (`Annotation.toMarkdown`) — or at the link's own
/// line when there is none.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/reading/book_location.dart';

/// A place of a file, annotated in a note.
@immutable
final class AnnotationMark {
  /// The annotation at [offset] of the note at [note], of [place].
  const new({
    required this.note,
    required this.offset,
    required this.place,
    this.title,
  });

  /// The companion note, library-relative.
  final String note;

  /// Where the annotation starts in the note's text.
  final int offset;

  /// The place of the file it annotates.
  final BookLocation place;

  /// The annotation's heading, when it has one.
  final String? title;

  @override
  bool operator ==(Object other) =>
      other is AnnotationMark &&
      other.note == note &&
      other.offset == offset &&
      other.place == place &&
      other.title == title;

  @override
  int get hashCode => Object.hash(note, offset, place, title);

  @override
  String toString() => 'AnnotationMark($note@$offset, $place)';
}

/// A link of a note to a place of some file, before it is known to be the
/// file's: its target as written, whether it is a Markdown href (resolved
/// as one), the place, and the annotation it belongs to.
typedef AnnotationLink = ({
  String target,
  bool markdown,
  BookLocation place,
  int offset,
  String? title,
});

/// The links of [text], a note, that point at a place of a file, each with
/// the annotation it belongs to. Pure, for an isolate: a companion may be
/// long.
List<AnnotationLink> annotationLinksIn(String text) {
  final headings = [
    for (final match in _heading.allMatches(text))
      (offset: match.start, title: match[1]!.trim()),
  ];
  final out = <AnnotationLink>[];
  var heading = 0;
  for (final link in parseLinks(text)) {
    final String target;
    final String? fragment;
    final bool markdown;
    switch (link) {
      case WikiLink(:final ref):
        target = ref.target;
        fragment = ref.heading;
        markdown = false;
      case MarkdownLink(href: final written):
        // `<Books/My Book.pdf#page=3>`, the form that allows spaces.
        final href = written.startsWith('<') && written.endsWith('>')
            ? written.substring(1, written.length - 1)
            : written;
        final hash = href.indexOf('#');
        if (hash == -1) continue;
        target = percentDecoded(href.substring(0, hash));
        fragment = href.substring(hash + 1);
        markdown = true;
    }
    if (target.isEmpty || fragment == null) continue;
    final place = BookLocation.fromFragment(fragment);
    if (place == null) continue;
    while (heading < headings.length &&
        headings[heading].offset <= link.start) {
      heading++;
    }
    final section = heading == 0 ? null : headings[heading - 1];
    final lineStart = text.lastIndexOf('\n', link.start) + 1;
    out.add((
      target: target,
      markdown: markdown,
      place: place,
      offset: section?.offset ?? lineStart,
      title: section?.title,
    ));
  }
  return out;
}

/// A heading line, its text captured.
final RegExp _heading = RegExp(r'^#{1,6}[ \t]+(.*)$', multiLine: true);
