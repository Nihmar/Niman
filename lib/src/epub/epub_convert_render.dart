/// What the notes of a converted book say (#1138): each note's lines with
/// the book's pictures and links pointing at the library's files, and
/// `index.md`, the book's metadata and contents.
///
/// - **Pictures** point at their copy in the book's folder, relative to the
///   note: the folder moves whole, and a folder exported as a book takes the
///   pictures inside it along. In one note they are the library's own, and
///   are written from the folder the note goes in (`../assets/…`), as any
///   Markdown link is (#1282, #1315).
/// - **A link into the book** points at the note it lands in, relative to
///   the note it is written in, and at its heading when it lands on one
///   (`02%20Part/01%20Arrival.md#The%20Storm`). A link out of the book is
///   left as written. The destinations are `import/book/book_render.dart`'s,
///   shared with the HTML book.
/// - **`index.md`** carries the keys a folder's book export reads back
///   (`epubMetadataOf`): a converted book exported again keeps its title,
///   authors, series, identifier and cover.
library;

import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/epub/epub_info.dart';
import 'package:niman/src/import/book/book_render.dart';
import 'package:niman/src/links/rewrite.dart' show hrefFrom;

export 'package:niman/src/import/book/book_render.dart' show noteBody;

/// The text of [note], one of [written] — the notes of [plan] that have
/// text. [pictureAt] answers where picture `n` was written, relative to
/// the folder the notes' paths are relative to; null when it was not.
///
/// A book that is one note has its pictures in the library, not beside
/// it: [libraryFolder] is the library-relative folder the note goes in
/// ('' for the top), and [pictureAt] answers library-relative paths, which
/// are written from that folder. Left null, the pictures are the book
/// folder's, written from the note's own folder in it.
String renderNote(
  EpubPlan plan,
  EpubPlannedNote note,
  List<EpubPlannedNote> written, {
  required String? Function(int picture) pictureAt,
  String? libraryFolder,
}) {
  final body = noteBody(plan, note);
  final titled = body.startsWith('#') ? body : '# ${note.title}\n\n$body';
  final from = noteFolderOf(note.path);
  String href(String at) => libraryFolder == null
      ? bookHref(at, from: from)
      : hrefFrom(
          at,
          note: libraryFolder.isEmpty ? 'note.md' : '$libraryFolder/note.md',
        );
  final count = plan.book.pictures.length;
  return titled
      .replaceAllMapped(_picture, (match) {
        final index = int.parse(match.group(2)!);
        // A number the book has no picture for is words of the book.
        if (index >= count) return match.group(0)!;
        final at = pictureAt(index);
        return '![${match.group(1)}](${at == null ? '' : href(at)})';
      })
      .replaceAllMapped(_link, (match) {
        final index = int.parse(match.group(1)!);
        if (index >= plan.book.links.length) return match.group(0)!;
        return '](<${_linkTarget(plan, note, written, index) ?? '#'}>)';
      });
}

/// Where link [index] of the book goes, written in [note].
String? _linkTarget(
  EpubPlan plan,
  EpubPlannedNote note,
  List<EpubPlannedNote> written,
  int index,
) {
  final line = plan.lineOfTarget(plan.book.links[index]);
  if (line == null) return null;
  return bookLinkTo(plan, note, written, line);
}

/// `index.md` of [plan]: the book's metadata as frontmatter, then its title,
/// its authors, its cover and its contents as links to the notes. [cover]
/// is where the cover picture was written, relative to the book's folder.
String renderIndex(
  EpubPlan plan,
  List<EpubPlannedNote> written, {
  required EpubConvertWords words,
  String? cover,
}) {
  final info = plan.book.info;
  final out = StringBuffer('---\n')
    ..write(_frontmatter(info, title: plan.title, cover: cover))
    ..write('---\n\n# ${plan.title}\n');
  if (info.authors.isNotEmpty) out.write('\n*${info.authors.join(', ')}*\n');
  if (cover != null) out.write('\n![${plan.title}](${bookHref(cover)})\n');
  out
    ..write('\n## ${words.contents}\n\n')
    ..write(bookContents(plan, written));
  return out.toString();
}

String _frontmatter(EpubInfo info, {required String title, String? cover}) =>
    bookFrontmatter([
      ('title', title),
      ('author', info.authors),
      ('language', info.language),
      ('publisher', info.publisher),
      ('published', info.published),
      ('isbn', info.isbn),
      ('identifier', info.identifier),
      ('series', info.series),
      ('series_index', info.seriesIndex),
      ('rights', info.rights),
      ('description', info.description),
      ('tags', info.subjects),
      ('cover', cover),
    ]);

final RegExp _picture = bookPictureRef(epubPictureScheme);
final RegExp _link = bookLinkRef(epubLinkScheme);

/// The numbers of the book's pictures [markdown] shows, in order, each
/// once: the destination of an image the converter wrote, a number the book
/// has a picture for. Words that say `epub-picture:0` show none (#1313).
Iterable<int> picturesShown(EpubPlan plan, String markdown) sync* {
  final seen = <int>{};
  for (final match in _picture.allMatches(markdown)) {
    final index = int.parse(match.group(2)!);
    if (index < plan.book.pictures.length && seen.add(index)) yield index;
  }
}
