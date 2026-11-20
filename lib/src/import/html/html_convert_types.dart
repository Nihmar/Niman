/// What an HTML page's conversion is asked, what it answers and how it reads
/// its file (#1293, #1294): shared by the job that makes a note of a page
/// (`html_convert_job.dart`) and the one that makes notes of a book
/// (`html_book_job.dart`).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:path/path.dart' as p;

/// The most bytes a page may have: what the EPUB conversion allows a text
/// file.
const int htmlMaxBytes = 32 << 20;

/// The words of a book's notes when none are handed in: English.
const BookWords defaultBookWords = (
  chapter: 'Chapter {n}',
  opening: 'Front matter',
  contents: 'Contents',
);

/// How a page that is a book is cut into notes.
enum HtmlBookSplit {
  /// A folder named after the book: a note a chapter, and `index.md`.
  chapters,

  /// One note of the whole book.
  oneNote,
}

/// What a conversion is asked to do.
typedef HtmlConvertRequest = ({
  /// The `.html`, `.htm` or `.xhtml`, absolute.
  String source,

  /// What the page is called when its file is not called that: a share is
  /// copied into the cache under a name of its own. Null for a file named
  /// as it is.
  String? name,

  /// The library, absolute.
  String libraryRoot,

  /// The folder the note goes in, library-relative ('' for the top).
  String parent,

  /// The hidden folder it is written in first, absolute.
  String staging,

  /// The library's attachments folder's name.
  String attachments,

  /// How the library embeds a picture.
  LinkType linkType,

  /// How much of the page becomes the note.
  HtmlExtent extent,

  /// The day written as `imported:`; null for today.
  DateTime? importedOn,

  /// How the page is cut when it is a book; null converts it as one page,
  /// an article of it.
  HtmlBookSplit? book,

  /// The words a book's notes are written with.
  BookWords words,
});

/// What a conversion wrote: the note or the folder (`made`,
/// library-relative), the note to open, and how many notes and pictures.
typedef HtmlConverted = ({String made, String open, int notes, int pictures});

/// Where a conversion has got to: `done` of `total` steps (pictures, then
/// the notes), and the name of the one being written.
typedef HtmlConvertProgress = ({int done, int total, String what});

/// The day [date] is, as `imported:` writes it.
String importedDay(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// What the page at [source] is called to a person: [name] when it is given
/// (a share's own, whatever its copy in the cache is called), else its
/// file's name.
String htmlDisplayName(String source, String? name) =>
    name == null || name.trim().isEmpty ? p.basename(source) : p.basename(name);

/// The bytes of the file at [source]; throws [HtmlRefused] when it is not a
/// file, is too large, or cannot be read.
Future<Uint8List> readHtmlSource(String source) async {
  final file = File(source);
  try {
    if (await FileSystemEntity.type(source) != FileSystemEntityType.file) {
      throw HtmlRefused(HtmlRefusal.notAFile, '"$source" is not a file');
    }
    final length = await file.length();
    if (length > htmlMaxBytes) {
      throw HtmlRefused(
        HtmlRefusal.tooLarge,
        '$length bytes, over $htmlMaxBytes',
      );
    }
    return await file.readAsBytes();
  } on FileSystemException catch (error) {
    throw HtmlRefused(HtmlRefusal.unreadable, error.message);
  }
}
