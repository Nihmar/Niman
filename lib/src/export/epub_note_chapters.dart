/// A note's EPUB page cut into chapters at its headings: a novel kept as one
/// note — `# Title`, then `## Chapter 1`, `## Chapter 2`, … — is a book of
/// as many chapters, not one.
///
/// **Where it cuts.** At the page's top-level headings of the chapters' level
/// ([chapterLevelOf]: the shallowest level that occurs at least three times),
/// so a note whose chapters are `#` keeps its `##` as sections inside them,
/// and a note whose one `#` is its title is cut at its `##`. A note with no
/// such level is one chapter, as before.
///
/// **What goes where.** Each chapter holds the page from its heading to the
/// next one's, and is named by the heading's text. What comes before the
/// first — the title, a summary, the author's notes — is a page of its own,
/// named by the note's title, unless it is empty. The footnotes, at the
/// page's end, are at the last chapter's.
///
/// **Links inside the note.** A link to `#id` — a footnote, its way back, a
/// heading of the same note — names an id that may now be in another file:
/// it is rewritten to that file, `note-4.xhtml#fn-1`. An id the link's own
/// chapter carries stays as it is (a drawing's own `<use>` of its defs).
///
/// The page is cut where it already is well-formed XHTML — between two of
/// its top-level elements — so every chapter is too.
library;

import 'package:niman/src/core/chapter_level.dart';
import 'package:xml/xml.dart' show XmlException;
import 'package:xml/xml_events.dart';

/// One chapter of a note's book: its file's name (in the chapters' folder),
/// its title and its body.
typedef EpubNoteChapter = ({String file, String title, String body});

/// The file a note's one chapter is, when it is not cut.
const String epubNoteFile = 'note.xhtml';

/// The file name of chapter [index] of [count].
String _fileOf(int index, int count) =>
    count == 1 ? epubNoteFile : 'note-${index + 1}.xhtml';

/// A heading the page opens a chapter at: where its tag starts, its level,
/// its text.
typedef _Heading = ({int at, int level, String text});

/// A start tag of the page: where it starts and stops.
typedef _Tag = ({int start, int stop});

/// The chapters [body] — a note's XHTML page body — is cut into; [title]
/// names the page before the first one, or the one chapter of a note that is
/// not cut.
List<EpubNoteChapter> splitEpubNoteChapters(
  String body, {
  required String title,
}) {
  final List<_Heading> headings;
  final List<_Tag> tags;
  try {
    (headings, tags) = _scan(body);
  } on XmlException {
    // A page the reader cannot follow stays whole: cutting it blind could
    // split an element.
    return [(file: epubNoteFile, title: title, body: body)];
  }
  final level = chapterLevelOf([for (final h in headings) h.level]);
  if (level == null) return [(file: epubNoteFile, title: title, body: body)];

  final chapters = [
    for (final h in headings)
      if (h.level == level) h,
  ];
  final opening = body.substring(0, chapters.first.at);
  final starts = <int>[if (opening.trim().isNotEmpty) 0];
  final titles = <String>[if (opening.trim().isNotEmpty) title];
  for (final chapter in chapters) {
    starts.add(chapter.at);
    titles.add(chapter.text.isEmpty ? title : chapter.text);
  }
  final count = starts.length;

  // Which chapter each tag is in — the tags are in page order — and which
  // chapter holds each id, the first one when an id repeats.
  final tagChapter = List<int>.filled(tags.length, 0);
  final idChapter = <String, int>{};
  final idsOf = List.generate(count, (_) => <String>{});
  var index = 0;
  for (final (at, tag) in tags.indexed) {
    while (index + 1 < count && starts[index + 1] <= tag.start) {
      index++;
    }
    tagChapter[at] = index;
    final id = _id.firstMatch(body.substring(tag.start, tag.stop))?[2];
    if (id == null) continue;
    idChapter.putIfAbsent(id, () => index);
    idsOf[index].add(id);
  }

  final texts = [for (var i = 0; i < count; i++) StringBuffer()];
  final from = [...starts];
  for (final (at, tag) in tags.indexed) {
    final index = tagChapter[at];
    final source = body.substring(tag.start, tag.stop);
    final rewritten = source.replaceAllMapped(_href, (match) {
      final id = match[3]!;
      final target = idChapter[id];
      if (target == null || idsOf[index].contains(id)) return match[0]!;
      final quote = match[2]!;
      return '${match[1]}$quote${_fileOf(target, count)}#$id$quote';
    });
    if (rewritten == source) continue;
    texts[index]
      ..write(body.substring(from[index], tag.start))
      ..write(rewritten);
    from[index] = tag.stop;
  }
  return [
    for (var i = 0; i < count; i++)
      (
        file: _fileOf(i, count),
        title: titles[i],
        body:
            (texts[i]..write(
                  body.substring(
                    from[i],
                    i + 1 < count ? starts[i + 1] : body.length,
                  ),
                ))
                .toString(),
      ),
  ];
}

/// A `href` naming an id of the page: `\s(href=)(quote)#(id)quote`.
final RegExp _href = RegExp(r'''(\shref=)(["'])#([^"']*)\2''');

/// An `id`: `\sid=(quote)(id)quote`.
final RegExp _id = RegExp(r'''\sid=(["'])([^"']*)\1''');

/// The top-level headings of [body] and every start tag in it.
(List<_Heading>, List<_Tag>) _scan(String body) {
  final headings = <_Heading>[];
  final tags = <_Tag>[];
  var depth = 0;
  int? openAt;
  int? openLevel;
  var openDepth = 0;
  final text = StringBuffer();
  for (final event in parseEvents(
    body,
    withLocation: true,
    validateNesting: true,
  )) {
    switch (event) {
      case XmlStartElementEvent():
        tags.add((start: event.start!, stop: event.stop!));
        final level = depth == 0 ? _levelOf(event.localName) : null;
        if (level != null && !event.isSelfClosing) {
          openAt = event.start;
          openLevel = level;
          openDepth = depth;
          text.clear();
        }
        if (!event.isSelfClosing) depth++;
      case XmlEndElementEvent():
        depth--;
        if (openAt != null && depth == openDepth) {
          headings.add((
            at: openAt,
            level: openLevel!,
            text: text.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
          ));
          openAt = null;
        }
      case XmlTextEvent():
        if (openAt != null) text.write(event.value);
      case XmlCDATAEvent():
        if (openAt != null) text.write(event.value);
      default:
    }
  }
  return (headings, tags);
}

/// The level of a heading element named [name], or null for any other.
int? _levelOf(String name) => switch (name) {
  'h1' => 1,
  'h2' => 2,
  'h3' => 3,
  'h4' => 4,
  'h5' => 5,
  'h6' => 6,
  _ => null,
};
