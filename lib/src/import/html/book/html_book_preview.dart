/// What a web page would make if it is a book (#1294), for the dialog to say
/// before anything is written: whether it is one, how many notes a note a
/// chapter makes, and in how many folders.
library;

import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/html/book/html_book_job.dart';
import 'package:niman/src/import/html/book/html_book_reader.dart';
import 'package:niman/src/import/html/book/html_book_text.dart';
import 'package:niman/src/import/html/html_convert_types.dart';
import 'package:niman/src/import/html/html_page.dart';

/// What a page that is a book would make.
typedef HtmlBookPreview = ({
  String title,
  List<String> authors,
  int notes,
  int folders,
});

/// The page at [source] read and planned: what a note a chapter would write,
/// or null when it is not a book. [name] is what the page is called when its
/// file is not.
///
/// Throws `HtmlRefused` for a page it cannot read.
Future<HtmlBookPreview?> previewHtmlBook(
  String source,
  BookWords words, {
  String? name,
}) async {
  final bytes = await readHtmlSource(source);
  final page = readHtmlPage(
    bytes,
    fileName: htmlDisplayName(source, name),
    extent: HtmlExtent.body,
  );
  final book = readHtmlBook(page);
  if (book == null) return null;
  final text = convertBookText(
    book,
    base: page.baseUrl ?? Uri.file(source),
    oneNote: false,
    words: words,
  );
  final written = writtenNotes(
    planHtmlBook(book, text, oneNote: false, words: words),
  );
  return (
    title: book.title,
    authors: book.authors,
    notes: written.length,
    folders: {
      for (final note in written)
        if (noteFolderOf(note.path).isNotEmpty) noteFolderOf(note.path),
    }.length,
  );
}
