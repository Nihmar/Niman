/// The writing of a book converted to notes (#1138), on its own isolate.
///
/// Everything is written into a hidden folder beside where the book goes —
/// the folder the main isolate names, `.epub.niman-tmp-<micros>` — and moved
/// in at the end with one rename: until then the library holds nothing of
/// the book, and a cancel or a failure deletes the hidden folder and
/// leaves it as it was. A crash leaves the hidden folder to the temp
/// sweep, which takes a stale one whole (`sweepStaleTempFiles`).
///
/// - **A note a chapter** is a folder named after the book (`Dune`, or
///   `Dune 2` beside one), its notes and folders as planned
///   (`epub_convert_plan.dart`), `index.md`, and the pictures in the book's
///   own attachments folder, each named by its content.
/// - **One note** is that note, beside the other notes of the folder, and
///   its pictures in the library's attachments folder, as a capture keeps
///   them.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_convert_failures.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/epub/epub_convert_render.dart';
import 'package:niman/src/library/markdown_import.dart' show freeFolderName;
import 'package:path/path.dart' as p;

/// What a conversion is asked to do.
typedef EpubConvertRequest = ({
  /// The `.epub`, absolute.
  String source,

  /// What the book is called when its file is not called that: a share
  /// is copied into the cache under a name of its own
  /// (`1729512345678-Dune.epub`). Null for a file that is named as it is.
  String? name,

  /// The library, absolute.
  String libraryRoot,

  /// The folder the book goes in, library-relative ('' for the top).
  String parent,

  /// The hidden folder it is written in first, absolute.
  String staging,

  /// One note of the whole book, rather than a note a chapter.
  bool oneNote,

  /// The library's attachments folder's name.
  String attachments,

  /// The words the notes are written with.
  EpubConvertWords words,
});

/// What a conversion wrote: the folder (or the note) it made, the note to
/// open, and how many notes and pictures.
typedef EpubConverted = ({String made, String open, int notes, int pictures});

/// What a book would make, for the dialog to say before anything is
/// written.
typedef EpubConvertPreview = ({
  String title,
  List<String> authors,
  int notes,
  int folders,
  int pictures,
});

/// Where a conversion has got to: `done` of `total` steps (pictures, then
/// notes), and the name of the one being written.
typedef EpubConvertProgress = ({int done, int total, String what});

/// The book at [source] read and planned: what a conversion would write.
///
/// Throws [EpubRefused] when it is not a book that can be converted.
EpubConvertPreview previewEpub(
  String source,
  EpubConvertWords words, {
  String? name,
}) => _withBook(source, (book) {
  final plan = EpubPlan.of(
    book,
    title: _titleOf(book, source, name),
    words: words,
  );
  final written = _written(plan);
  return (
    title: plan.title,
    authors: book.info.authors,
    notes: written.length,
    folders: {
      for (final note in written)
        if (noteFolderOf(note.path).isNotEmpty) noteFolderOf(note.path),
    }.length,
    pictures: _picturesNamed(plan, written).length,
  );
});

/// Converts the book [request] names, telling [progress] how far it has
/// got.
///
/// A stop is cooperative. Between its steps — before each chapter the book
/// is read by, each picture, each note, the index, and the moving in — it
/// gives the event loop a turn, so a stop message can be delivered, and asks
/// [stopped]: true ends it there
/// with [EpubConvertStopped], its `finally` blocks run — the book closed,
/// the hidden folder deleted. A killed isolate runs none of them: it leaves
/// the book open (on Windows, a file that cannot be moved or deleted) and
/// may still be writing into the folder its canceller is deleting.
///
/// Before it moves anything into the library it asks [mayFinish]: a
/// conversion cancelled by then answers false, and stops with nothing
/// moved in; one that goes on cannot be cancelled any more.
Future<EpubConverted> convertEpub(
  EpubConvertRequest request, {
  void Function(EpubConvertProgress progress)? progress,
  Future<bool> Function()? mayFinish,
  bool Function()? stopped,
}) async {
  final staging = Directory(request.staging);
  // The turn the event loop is given, and the stop it may have delivered.
  Future<void> step() async {
    await Future<void>.delayed(Duration.zero);
    if (stopped?.call() ?? false) throw const EpubConvertStopped();
  }

  try {
    final result = await _withBookAsync(request.source, step, (book) async {
      staging.createSync(recursive: true);
      final title = _titleOf(book, request.source, request.name);
      final plan = EpubPlan.of(
        book,
        title: title,
        words: request.words,
        oneNote: request.oneNote,
      );
      final written = _written(plan);
      final pictures = _picturesNamed(plan, written);
      final cover = _coverIndex(book);
      if (!request.oneNote && cover != null && !pictures.contains(cover)) {
        pictures.add(cover);
      }
      final total = pictures.length + written.length + 1;
      var done = 0;
      // Pictures first: the notes are written knowing where each one went.
      final at = <int, String>{};
      for (final index in pictures) {
        await step();
        progress?.call((
          done: done++,
          total: total,
          what: book.pictures[index],
        ));
        final bytes = book.pictureBytes(index);
        if (bytes == null) continue;
        at[index] = _keepPicture(
          staging.path,
          request.attachments,
          book.pictures[index],
          bytes,
        );
      }
      for (final note in written) {
        await step();
        progress?.call((done: done++, total: total, what: note.path));
        final file = File(p.joinAll([staging.path, ...note.path.split('/')]));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(
          renderNote(plan, note, written, pictureAt: (index) => at[index]),
        );
      }
      if (!request.oneNote) {
        await step();
        progress?.call((done: done++, total: total, what: 'index.md'));
        File(p.join(staging.path, 'index.md')).writeAsStringSync(
          renderIndex(
            plan,
            written,
            words: request.words,
            cover: cover == null ? null : at[cover],
          ),
        );
      }
      return (plan: plan, written: written, pictures: at.length);
    });
    await step();
    if (!(await mayFinish?.call() ?? true)) throw const EpubConvertStopped();
    return request.oneNote
        ? await _moveNoteIn(request, result.written.single, result.pictures)
        : _moveFolderIn(
            request,
            result.plan.title,
            result.written.length,
            result.pictures,
          );
  } finally {
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}

/// The book's folder renamed in under a name free in its parent.
EpubConverted _moveFolderIn(
  EpubConvertRequest request,
  String title,
  int notes,
  int pictures,
) {
  final parent = p.joinAll([request.libraryRoot, ...request.parent.split('/')]);
  Directory(parent).createSync(recursive: true);
  final name = freeFolderName(
    parent,
    sanitizeName(title, fallback: defaultFolderName),
  );
  Directory(request.staging).renameSync(p.join(parent, name));
  final made = request.parent.isEmpty ? name : '${request.parent}/$name';
  return (made: made, open: '$made/index.md', notes: notes, pictures: pictures);
}

/// The one note moved in beside the folder's others, and its pictures into
/// the library's attachments folder, each kept once.
Future<EpubConverted> _moveNoteIn(
  EpubConvertRequest request,
  EpubPlannedNote note,
  int pictures,
) async {
  final assets = Directory(p.join(request.staging, request.attachments));
  if (assets.existsSync()) {
    final into = Directory(p.join(request.libraryRoot, request.attachments))
      ..createSync(recursive: true);
    for (final picture in assets.listSync().whereType<File>()) {
      final target = File(p.join(into.path, p.basename(picture.path)));
      // Named by its content: one already there is this one.
      if (!target.existsSync()) picture.renameSync(target.path);
    }
  }
  final parent = Directory(
    p.joinAll([request.libraryRoot, ...request.parent.split('/')]),
  )..createSync(recursive: true);
  final stem = p.posix.basenameWithoutExtension(note.path);
  final name = await uniqueFileName(parent, stem, '.md');
  File(p.join(request.staging, note.path))
      .renameSync(p.join(parent.path, name));
  final made = request.parent.isEmpty ? name : '${request.parent}/$name';
  return (made: made, open: made, notes: 1, pictures: pictures);
}

/// Opens the book at [source] and hands it to [work], closing the file
/// after.
T _withBook<T>(String source, T Function(EpubBook book) work) {
  final input = InputFileStream(source);
  try {
    return work(parseEpub(EpubArchive.open(input)));
  } finally {
    input.closeSync();
  }
}

/// [_withBook] for a [work] that yields: the file is held open across its
/// awaits and closed when it ends, however it ends. [between] runs before
/// each chapter of the book's reading, which it may end by throwing.
Future<T> _withBookAsync<T>(
  String source,
  Future<void> Function() between,
  Future<T> Function(EpubBook book) work,
) async {
  final input = InputFileStream(source);
  try {
    final archive = EpubArchive.open(input);
    return await work(await parseEpubStepped(archive, between: between));
  } finally {
    input.closeSync();
  }
}

/// The book's title, or — when it has none — the name of its file.
String _titleOf(EpubBook book, String source, String? name) =>
    book.info.title ??
    p.basenameWithoutExtension(epubDisplayName(source, name));

/// What the book at [source] is called to a person: [name] when it is given
/// (a share's own, whatever its copy in the cache is called), else its
/// file's name.
String epubDisplayName(String source, String? name) =>
    name == null || name.trim().isEmpty ? p.basename(source) : p.basename(name);

/// The notes of [plan] that have text.
List<EpubPlannedNote> _written(EpubPlan plan) => [
  for (final note in plan.notes)
    if (noteBody(plan, note).trim().isNotEmpty) note,
];

/// The pictures [written] show, by their numbers, in order.
List<int> _picturesNamed(EpubPlan plan, List<EpubPlannedNote> written) {
  final out = <int>{};
  for (final note in written) {
    for (final match in _picture.allMatches(noteBody(plan, note))) {
      out.add(int.parse(match.group(1)!));
    }
  }
  return out.toList();
}

/// The number of the cover picture among the book's pictures — added to
/// them when no chapter shows it — or null when the book names none.
int? _coverIndex(EpubBook book) {
  final cover = book.info.cover;
  if (cover == null) return null;
  final known = book.pictures.indexOf(cover);
  if (known >= 0) return known;
  book.pictures.add(cover);
  return book.pictures.length - 1;
}

/// Writes [bytes], the picture at [path] in the book, into [attachments]
/// under [staging], named by its content; answers where, relative to
/// [staging].
String _keepPicture(
  String staging,
  String attachments,
  String path,
  Uint8List bytes,
) {
  final name =
      '${sha256.convert(bytes)}${p.posix.extension(path).toLowerCase()}';
  final file = File(p.join(staging, attachments, name));
  if (!file.existsSync()) {
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }
  return '$attachments/$name';
}

final RegExp _picture = RegExp('$epubPictureScheme:(\\d+)');

/// The entry of the conversion's isolate: [convertEpub], its progress and
/// its end sent to the port it is handed, as plain messages.
///
/// Its first message hands the main isolate a port to stop it by: a `'stop'`
/// sent there is seen at the next step boundary of [convertEpub].
Future<void> convertEpubEntry(
  (EpubConvertRequest request, SendPort events) message,
) async {
  final (request, events) = message;
  var stop = false;
  final control = ReceivePort()
    ..listen((message) {
      if (message == 'stop') stop = true;
    });
  events.send(('ready', control.sendPort));
  try {
    final converted = await convertEpub(
      request,
      stopped: () => stop,
      progress: (progress) => events.send((
        'progress',
        progress.done,
        progress.total,
        progress.what,
      )),
      // The main isolate says whether the moving in may start: a cancel
      // it took first says no, and one after the answer is refused there.
      mayFinish: () async {
        final reply = ReceivePort();
        events.send(('finishing', reply.sendPort));
        final go = await reply.first;
        reply.close();
        return go == true;
      },
    );
    events.send((
      'done',
      converted.made,
      converted.open,
      converted.notes,
      converted.pictures,
    ));
  } on EpubConvertStopped {
    events.send(('stopped',));
  } on EpubRefused catch (refused) {
    events.send(('refused', refused.reason.name, refused.detail));
  } on Object catch (error) {
    events.send(('failed', '$error'));
  } finally {
    // The isolate ends when its last port closes; its exit is what a cancel
    // waits for.
    control.close();
  }
}
