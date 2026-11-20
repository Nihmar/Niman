/// Whether an HTML page is a book (#1294), and the book it is.
///
/// A profile that knows the page's shape reads it first — an AO3 download
/// (`html_book_ao3.dart`), whose metadata and chapters are in its markup —
/// and any other page is a book by the rule of `html_book_headings.dart`.
library;

import 'package:niman/src/import/html/book/html_book.dart';
import 'package:niman/src/import/html/book/html_book_ao3.dart';
import 'package:niman/src/import/html/book/html_book_headings.dart';
import 'package:niman/src/import/html/html_page.dart';

export 'package:niman/src/import/html/book/html_book.dart';

/// [page] — read with the whole body, not an article — as a book, or null
/// when it is not one.
HtmlBook? readHtmlBook(HtmlPage page) =>
    readAo3Book(page) ?? readHeadingsBook(page);
