/// The writing of an HTML book converted to notes (#1294), on the isolate of
/// `html_convert_job.dart` — which hands a request with a [HtmlBookSplit] to
/// [convertHtmlBook].
///
/// Everything is written into a hidden folder beside where the book goes, as
/// the page's is, and moved in at the end with one rename: until then the
/// library holds nothing of the book, and a cancel or a failure deletes the
/// hidden folder and leaves it as it was.
///
/// - **A note a chapter** is a folder named after the book (`Dune`, or
///   `Dune 2` beside one): a note a chapter as planned
///   (`import/book/book_plan.dart`), `index.md`, and the pictures in the
///   book's own attachments folder, each named by its content.
/// - **One note** is that note, beside the other notes of the folder, and its
///   pictures in the library's attachments folder, as a capture keeps them.
library;

import 'dart:io';

import 'package:niman/src/import/book/book_move_in.dart';
import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/book/book_render.dart';
import 'package:niman/src/import/html/book/html_book_reader.dart';
import 'package:niman/src/import/html/book/html_book_render.dart';
import 'package:niman/src/import/html/book/html_book_text.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_convert_types.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:niman/src/import/html/html_picture_pool.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_picture_store.dart';
import 'package:path/path.dart' as p;

/// The notes of [plan] that have text.
List<BookPlannedNote> writtenNotes(BookPlan plan) => [
  for (final note in plan.notes)
    if (noteBody(plan, note).trim().isNotEmpty) note,
];

/// The plan of [book]'s [text]: one note, or a note a chapter.
BookPlan planHtmlBook(
  HtmlBook book,
  HtmlBookText text, {
  required bool oneNote,
  required BookWords words,
}) => oneNote
    ? BookPlan.single(title: book.title, lines: text.lines)
    : BookPlan.split(
        title: book.title,
        lines: text.lines,
        entries: text.entries,
        words: words,
        nameOf: chapterFileTitle,
      );

/// Converts the book [request] names, telling [progress] how far it has got;
/// stopped as `convertHtml` is. [fetch] brings the web pictures.
///
/// Throws [HtmlRefused] for a file that is not a book it can convert.
Future<HtmlConverted> convertHtmlBook(
  HtmlConvertRequest request, {
  PictureFetcher? fetch,
  void Function(HtmlConvertProgress progress)? progress,
  Future<bool> Function()? mayFinish,
  bool Function()? stopped,
}) async {
  final oneNote = request.book == HtmlBookSplit.oneNote;
  final staging = Directory(request.staging);
  Future<void> step() async {
    await Future<void>.delayed(Duration.zero);
    if (stopped?.call() ?? false) throw const HtmlConvertStopped();
  }

  HttpClient? client;
  try {
    await step();
    final bytes = await readHtmlSource(request.source);
    await step();
    final page = readHtmlPage(
      bytes,
      fileName: htmlDisplayName(request.source, request.name),
      extent: HtmlExtent.body,
    );
    final book = readHtmlBook(page);
    if (book == null) {
      throw const HtmlRefused(HtmlRefusal.notABook, 'the page is no book');
    }
    final file = Uri.file(request.source);
    final base = page.baseUrl ?? file;
    final text = convertBookText(
      book,
      base: base,
      oneNote: oneNote,
      words: request.words,
    );
    final plan = planHtmlBook(
      book,
      text,
      oneNote: oneNote,
      words: request.words,
    );
    final written = writtenNotes(plan);

    // Each picture once, whichever `src`s name it.
    final sources = <String, PictureSource>{};
    final addressOf = <String, String>{};
    for (final src in text.pictureSrcs) {
      final source = PictureSource.parse(src, base);
      if (source == null) continue;
      addressOf[src] = source.address;
      sources.putIfAbsent(source.address, () => source);
    }
    staging.createSync(recursive: true);
    final store = HtmlPictureStore(
      staging: request.staging,
      attachments: request.attachments,
      fetch: fetch ?? httpPictureFetcher(client = pictureHttpClient()),
    );
    final total = sources.length + written.length + (oneNote ? 0 : 1);
    final kept = await keepPictures(
      store,
      sources.values.toList(),
      step: step,
      stopped: stopped,
      progress: (done, what) =>
          progress?.call((done: done, total: total, what: what)),
    );
    var done = sources.length;
    final writer = HtmlBookWriter(
      book: book,
      text: text,
      plan: plan,
      day: importedDay(request.importedOn ?? DateTime.now()),
      pictures: (index) {
        if (index >= text.pictureSrcs.length) return null;
        final address = addressOf[text.pictureSrcs[index]];
        return (
          kept: address == null ? null : kept[address],
          web: address != null && sources[address]!.kind == PictureKind.web
              ? address
              : null,
        );
      },
    );

    void write(String path, String content) {
      final target = File(p.joinAll([request.staging, ...path.split('/')]));
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(content);
    }

    if (oneNote) {
      await step();
      progress?.call((done: done++, total: total, what: book.title));
      write(
        plan.notes.single.path,
        writer.single(linkType: request.linkType, folder: request.parent),
      );
    } else {
      for (final note in written) {
        await step();
        progress?.call((done: done++, total: total, what: note.path));
        write(note.path, writer.chapter(note, written));
      }
      await step();
      progress?.call((done: done++, total: total, what: 'index.md'));
      write('index.md', writer.index(written, words: request.words));
    }
    await step();
    if (!(await mayFinish?.call() ?? true)) throw const HtmlConvertStopped();
    if (oneNote) {
      final made = await moveNoteIn(
        libraryRoot: request.libraryRoot,
        parent: request.parent,
        staging: request.staging,
        attachments: request.attachments,
        note: plan.notes.single.path,
      );
      return (made: made, open: made, notes: 1, pictures: store.length);
    }
    final made = moveFolderIn(
      libraryRoot: request.libraryRoot,
      parent: request.parent,
      staging: request.staging,
      title: book.title,
    );
    return (
      made: made,
      open: '$made/index.md',
      notes: written.length,
      pictures: store.length,
    );
  } finally {
    client?.close(force: true);
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}
