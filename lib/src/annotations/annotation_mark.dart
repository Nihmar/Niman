/// Where a PDF or a book was annotated (#285): a place in it, and the
/// annotation of a companion note that points there.
///
/// Marks are read from the companion notes, never stored: every link in a
/// companion that points at a place of its file is one, found by
/// [annotationLinksIn] and resolved by `CompanionNotes.marksOf`. The
/// annotation opens at its section — the heading above the link, as an
/// annotation is written (`Annotation.toMarkdown`) — or at the link's own
/// line when there is none.
///
/// A highlight (#626) is a link whose fragment names a colour,
/// `highlight=green`: its mark is the quote the link closes, start and
/// end, which is what removing it takes away and what its colour is
/// changed in — no heading is its.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/reading/book_location.dart';

/// A place of a file, annotated or highlighted in a note.
@immutable
final class AnnotationMark {
  /// The annotation at [offset] of the note at [note], of [place]; a
  /// highlight's when it has a [highlight] colour.
  const new({
    required this.note,
    required this.offset,
    required this.place,
    this.title,
    this.highlight,
    this.end,
    this.quote = '',
    this.label,
  });

  /// The companion note, library-relative.
  final String note;

  /// Where the annotation starts in the note's text.
  final int offset;

  /// The place of the file it annotates.
  final BookLocation place;

  /// The annotation's heading, when it has one.
  final String? title;

  /// A highlight's colour (#626); null for an annotation.
  final HighlightColour? highlight;

  /// Where a highlight ends in the note's text: its quote, from [offset],
  /// is what removing it takes away. Null for an annotation.
  final int? end;

  /// A highlight's passage, as its quote says it; empty for an annotation.
  final String quote;

  /// What its link shows, `Dune, p. 34`: the place's name, for a heading
  /// or a link to it.
  final String? label;

  /// Whether this is a highlight rather than an annotation.
  bool get isHighlight => highlight != null;

  @override
  bool operator ==(Object other) =>
      other is AnnotationMark &&
      other.note == note &&
      other.offset == offset &&
      other.place == place &&
      other.title == title &&
      other.highlight == highlight &&
      other.end == end &&
      other.quote == quote &&
      other.label == label;

  @override
  int get hashCode =>
      Object.hash(note, offset, place, title, highlight, end, quote, label);

  @override
  String toString() =>
      'AnnotationMark($note@$offset${end == null ? '' : '-$end'}, $place'
      '${highlight == null ? '' : ', ${highlight!.id}'})';
}

/// A link of a note to a place of some file, before it is known to be the
/// file's: its target as written, whether it is a Markdown href (resolved
/// as one), the place, and the annotation it belongs to — or, for a
/// highlight, its colour and the quote it is.
typedef AnnotationLink = ({
  String target,
  bool markdown,
  BookLocation place,
  int offset,
  String? title,
  HighlightColour? highlight,
  int? end,
  String quote,
  String? label,
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
    final String? label;
    switch (link) {
      case WikiLink(:final ref):
        target = ref.target;
        fragment = ref.heading;
        markdown = false;
        label = ref.alias;
      case MarkdownLink(:final href):
        final hash = href.indexOf('#');
        if (hash == -1) continue;
        target = percentDecoded(href.substring(0, hash));
        fragment = href.substring(hash + 1);
        markdown = true;
        label = link.text.isEmpty ? null : link.text;
    }
    if (target.isEmpty || fragment == null) continue;
    final place = BookLocation.fromFragment(fragment);
    if (place == null) continue;
    while (heading < headings.length &&
        headings[heading].offset <= link.start) {
      heading++;
    }
    final highlight = _highlightIn(fragment);
    if (highlight != null) {
      final quote = _quoteAround(text, link.start);
      out.add((
        target: target,
        markdown: markdown,
        place: place,
        offset: quote.start,
        title: null,
        highlight: highlight,
        end: quote.end,
        quote: quote.text,
        label: label,
      ));
      continue;
    }
    final section = heading == 0 ? null : headings[heading - 1];
    final lineStart = text.lastIndexOf('\n', link.start) + 1;
    out.add((
      target: target,
      markdown: markdown,
      place: place,
      offset: section?.offset ?? lineStart,
      title: section?.title,
      highlight: null,
      end: null,
      quote: '',
      label: label,
    ));
  }
  return out;
}

/// The colour a link's [fragment] gives its highlight, `highlight=green`;
/// null when it is an annotation's.
HighlightColour? _highlightIn(String fragment) {
  for (final pair in fragment.split('&')) {
    final equals = pair.indexOf('=');
    if (equals <= 0) continue;
    if (pair.substring(0, equals).trim().toLowerCase() != 'highlight') {
      continue;
    }
    return HighlightColour.fromId(pair.substring(equals + 1));
  }
  return null;
}

/// The quote a highlight's link at [at] closes: the run of `>` lines around
/// it, from the start of its first line to past the end of its last, and
/// the passage they quote — the link's own line left out, the escapes
/// `Annotation.toMarkdown` wrote undone. A link on a line of its own is its
/// own quote.
({int start, int end, String text}) _quoteAround(String text, int at) {
  int lineStartAt(int offset) => text.lastIndexOf('\n', offset - 1) + 1;
  int lineEndAt(int offset) {
    final newline = text.indexOf('\n', offset);
    return newline == -1 ? text.length : newline + 1;
  }

  bool quoted(int start) =>
      _quoteLine.hasMatch(text.substring(start, lineEndAt(start)));

  final linkLine = lineStartAt(at);
  var start = linkLine;
  var end = lineEndAt(linkLine);
  if (quoted(linkLine)) {
    while (start > 0 && quoted(lineStartAt(start - 1))) {
      start = lineStartAt(start - 1);
    }
    while (end < text.length && quoted(end)) {
      end = lineEndAt(end);
    }
  }
  final passage = <String>[];
  for (var line = start; line < end; line = lineEndAt(line)) {
    if (line == linkLine) continue;
    final content = text
        .substring(line, lineEndAt(line))
        .replaceFirst(_quoteLine, '')
        .trim();
    if (content.isNotEmpty) passage.add(content);
  }
  return (
    start: start,
    end: end,
    text: passage.join(' ').replaceAllMapped(_escaped, (m) => m[1]!),
  );
}

/// A block quote's line, and the marker it opens with.
final RegExp _quoteLine = RegExp('^ {0,3}> ?');

/// A Markdown escape: a backslash before a punctuation mark.
final RegExp _escaped = RegExp(r'\\([!-/:-@\[-`{-~])');

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
