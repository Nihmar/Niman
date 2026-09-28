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
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';
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
///
/// [text] is the note as the editor holds it — its line endings `\n` — since
/// the offsets here are the ones a caret stands at.
List<AnnotationLink> annotationLinksIn(String text) {
  final headings = _headingsIn(text);
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

/// The headings of [text], each with the offset it starts at, as the note's
/// own outline reads them (`outlineOfBlocks` over the block scan): a `#` line
/// inside a code fence, a formula or the frontmatter is not a heading, and
/// the scan is the answer the outline and the colouring share.
///
/// A regex over the raw text answered a different question — every `#` line
/// where no fence or formula opened one — so a fenced `#` became a mark's
/// heading and its offset, which the outline disagreed with (#374).
List<({int offset, String title})> _headingsIn(String text) {
  final buffer = SourceBuffer.fromText(text);
  return [
    for (final heading in outlineOfBlocks(
      BlockScanner(buffer).index,
      buffer.lineAt,
    ))
      (offset: buffer.offsetOfLine(heading.line), title: heading.text),
  ];
}
