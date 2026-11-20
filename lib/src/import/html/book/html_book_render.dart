/// What the notes of an HTML book say (#1294): each chapter's lines with its
/// pictures and links pointing at the library's files, `index.md`, and the
/// one note of the whole book.
///
/// - **Pictures** are kept first, then written: a kept one points at its copy
///   in the book's folder, relative to the note (the folder moves whole, as
///   an EPUB's does), or — in the one note — at the library's attachments as
///   a capture embeds them; a web picture that was not kept keeps its
///   address; any other that was not is left out.
/// - **A link into the book** points at the note it lands in and at the
///   nearest heading above where it lands, as an EPUB's do
///   (`import/book/book_render.dart`); in the one note, at that heading. A
///   web link stays; an `id` the book does not have stays as written.
/// - **`index.md`** has the book's metadata as frontmatter, its title, its
///   authors, its intro (an AO3 work's summary and notes) and its contents as
///   links. Its keys are the ones a folder's book export reads back
///   (`epubMetadataOf`).
library;

import 'package:niman/src/core/percent.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/book/book_render.dart';
import 'package:niman/src/import/html/book/html_book.dart';
import 'package:niman/src/import/html/book/html_book_text.dart';
import 'package:niman/src/import/html/html_anchor_links.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// Where a picture of the text went: the path it was kept at, relative to
/// the folder the conversion is staged in, and the web address it came from
/// when it came from one. Both null for a picture that is left out.
typedef BookPicture = ({String? kept, String? web});

/// The picture the placeholder numbered [index] stands for.
typedef BookPictures = BookPicture Function(int index);

/// A picture's placeholder in the text: `![alt](niman-picture:3)`.
final RegExp _picture = RegExp(
  '!\\[((?:[^\\]\\\\]|\\\\.)*)\\]\\($pictureScheme:(\\d+)\\)',
);

/// The notes of one HTML book, written.
final class HtmlBookWriter {
  /// Writes [book]'s [text], planned as [plan], [pictures] kept, on [day]
  /// (`2026-11-20`).
  new({
    required this.book,
    required this.text,
    required this.plan,
    required this.pictures,
    required this.day,
  }) : _headings = markdownHeadings(text.lines);

  /// The book.
  final HtmlBook book;

  /// Its text.
  final HtmlBookText text;

  /// Where it goes.
  final BookPlan plan;

  /// Where its pictures went.
  final BookPictures pictures;

  /// The day it is imported, for `imported:`.
  final String day;

  final List<MarkdownHeading> _headings;

  /// The text of [note], one of [written] — the notes of the plan that have
  /// text: a note a chapter.
  String chapter(BookPlannedNote note, List<BookPlannedNote> written) {
    final body = noteBody(plan, note);
    final titled = _startsWithHeading.hasMatch(body)
        ? body
        : '# ${escapeMarkdownText(note.title)}\n\n$body';
    final from = noteFolderOf(note.path);
    final linked = _links(
      _withPictures(
        titled,
        (kept, alt) => '![$alt](${bookHref(kept, from: from)})',
      ),
      note,
      written,
    );
    // A picture left out leaves its paragraph blank.
    return '${linked.trim()}\n';
  }

  /// `index.md`: the book's metadata, its title, authors and intro, and its
  /// contents as links to the notes of [written].
  String index(List<BookPlannedNote> written, {required BookWords words}) {
    final out = StringBuffer('---\n')
      ..write(bookFrontmatter(book.fieldsImportedOn(day)))
      ..write('---\n\n# ${escapeMarkdownText(book.title)}\n');
    if (book.authors.isNotEmpty) {
      out.write('\n*${book.authors.map(escapeMarkdownText).join(', ')}*\n');
    }
    if (text.intro.isNotEmpty) {
      final intro = _withPictures(
        text.intro,
        (kept, alt) => '![$alt](${bookHref(kept)})',
      );
      out.write('\n$intro\n');
    }
    out
      ..write('\n## ${words.contents}\n\n')
      ..write(bookContents(plan, written));
    return out.toString();
  }

  /// The one note of the whole book, written in the library folder [folder]
  /// (library-relative): the metadata, the title, the intro, the text. The
  /// kept pictures are embedded as the library's [linkType] embeds them.
  String single({required LinkType linkType, String folder = ''}) {
    // The note's own name is not known to the line, but its folder is.
    final from = folder.isEmpty ? 'note.md' : '$folder/note.md';
    final body = _withPictures(
      resolveAnchorLinks(
        text.lines.join('\n'),
        text.anchors,
        title: escapeMarkdownText(book.title),
      ),
      (kept, alt) => attachmentEmbed(
        relativePath: kept,
        label: alt,
        linkType: linkType,
        note: from,
      ),
    ).trim();
    final out = StringBuffer('---\n')
      ..write(bookFrontmatter(book.fieldsImportedOn(day)))
      ..write('---\n\n# ${escapeMarkdownText(book.title)}\n');
    if (text.intro.isNotEmpty) {
      final intro = _withPictures(
        text.intro,
        (kept, alt) => attachmentEmbed(
          relativePath: kept,
          label: alt,
          linkType: linkType,
          note: from,
        ),
      );
      out.write('\n$intro\n');
    }
    if (body.isNotEmpty) out.write('\n$body\n');
    return out.toString();
  }

  /// [markdown] with each picture placeholder written by [embed] — the kept
  /// path and the alt text — or as its web address, or left out.
  String _withPictures(
    String markdown,
    String Function(String kept, String alt) embed,
  ) {
    var dropped = false;
    final written = markdown.replaceAllMapped(_picture, (match) {
      final picture = pictures(int.parse(match[2]!));
      final kept = picture.kept;
      if (kept != null) return embed(kept, match[1]!);
      final web = picture.web;
      if (web != null) return '![${match[1]}]($web)';
      dropped = true;
      return '';
    });
    return dropped ? _withoutBlankRuns(written) : written;
  }

  /// [markdown], a chapter's text, with each link into the book pointing at
  /// the note and the heading it lands in.
  String _links(
    String markdown,
    BookPlannedNote note,
    List<BookPlannedNote> written,
  ) => markdown.replaceAllMapped(anchorPlaceholder, (match) {
    final id = percentDecoded(match[1]!);
    final line = text.anchors[id];
    final target = line == null ? null : plan.noteAt(line, written);
    if (line == null || target == null) return '(#${bookEncoded(id)})';
    // The nearest heading above, and within, the note it lands in.
    final heading = headingBefore(_headings, line);
    final link = bookLinkTo(
      plan,
      note,
      written,
      line,
      headingAt: (_) =>
          heading != null && heading.line > target.start ? heading.text : null,
    );
    return '(${link ?? '#${bookEncoded(id)}'})';
  });
}

final RegExp _startsWithHeading = RegExp(r'^#{1,6}[ \t]');

/// [markdown] with each run of blank lines one blank line, as a picture left
/// out makes of its paragraph; the lines of a code fence are left as they
/// are.
String _withoutBlankRuns(String markdown) {
  final out = <String>[];
  var fenced = false;
  for (final line in markdown.split('\n')) {
    if (_fence.hasMatch(line)) fenced = !fenced;
    if (!fenced &&
        line.trim().isEmpty &&
        out.isNotEmpty &&
        out.last.trim().isEmpty) {
      continue;
    }
    out.add(line);
  }
  return out.join('\n');
}

final RegExp _fence = RegExp(r'^\s*(```|~~~)');
