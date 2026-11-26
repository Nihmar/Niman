/// A note's EPUB container, written on a background isolate (#1305).
///
/// Writing the zip is the slow part of a note's export: every picture is
/// opened and read, the page is typeset, and the whole `.epub` is read back
/// for the save. On a phone with fifty photos that is seconds, and none of it
/// belongs on the UI isolate (AGENTS.md: no disk I/O there). What the UI
/// isolate keeps is what only it can do — resolving the pictures' paths,
/// where the link index is — and it hands the writer plain strings and maps.
///
/// The writer is cooperative about a stop, as the folder export is: the
/// parent asks, the isolate looks between its stages — before the book,
/// between the pictures, after the page is built — and answers with
/// [EpubExportCancelled] rather than a book.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/epub_note_chapters.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/export/printed_todo_block.dart';

/// The folder the book's chapters sit in, in the container.
const String _chapterDir = 'OEBPS/text';

/// The user stopped a note's EPUB export: no file is written.
final class EpubExportCancelled implements Exception {
  /// Creates the cancellation.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'EPUB export cancelled';
}

/// The writer failed: what an isolate can say of an error, which is its
/// text.
final class EpubExportFailed implements Exception {
  /// Creates the failure with [message], the isolate's own error text.
  const new(this.message);

  /// What went wrong, as the isolate saw it.
  final String message;

  /// What a log line reads.
  @override
  String toString() => 'EPUB export failed: $message';
}

/// What the writer is asked: everything resolved already, plain strings,
/// lists and records.
///
/// `file` is where the container is written (a scratch file); `pictures` are
/// the absolute paths of the pictures the note shows, by the target as the
/// note writes it; `cover` the cover's path, or null. `libraryPath` names
/// the book (`EpubBook.start`).
typedef NoteEpubJob = ({
  String file,
  String text,
  String title,
  String libraryPath,
  String language,
  String? cover,
  Map<String, String> pictures,
  PrintedTodoBlocks todoBlocks,
  bool kanban,
});

/// The job and the ports it is answered on: `events` carries the answer
/// back, `probe` is a port the writer tells which isolate it runs on, for a
/// test.
typedef NoteEpubRequest = ({NoteEpubJob job, SendPort events, SendPort? probe});

/// The book the writer wrote: its bytes (handed over, not copied), and what
/// its page did with the formulas — an ad-hoc diagnostic (#303).
final class NoteEpubWritten {
  /// The written book.
  const new(this.bytes, {required this.formulas, required this.sources});

  /// The container's bytes.
  final TransferableTypedData bytes;

  /// How many formulas the chapter drew as SVG.
  final int formulas;

  /// How many it left as source.
  final int sources;
}

/// Writes [job]'s container on a background isolate, and answers the book.
///
/// [isCancelled] is asked every tenth of a second while the writer works;
/// when it answers true the writer stops at its next stage and this throws
/// [EpubExportCancelled]. [probe] is the test's way to see which isolate the
/// container is written on.
Future<NoteEpubWritten> writeNoteEpubInBackground(
  NoteEpubJob job, {
  bool Function()? isCancelled,
  SendPort? probe,
}) async {
  final events = ReceivePort();
  final errors = ReceivePort();
  final exits = ReceivePort();
  final answer = Completer<NoteEpubWritten>();
  SendPort? mailbox;
  events.listen((message) {
    if (message is SendPort) {
      mailbox = message;
    } else if (message is NoteEpubWritten) {
      if (!answer.isCompleted) answer.complete(message);
    } else if (message is EpubExportCancelled) {
      if (!answer.isCompleted) answer.completeError(message);
    } else if (message is EpubExportFailed) {
      if (!answer.isCompleted) answer.completeError(message);
    }
  });
  void died(Object? message) {
    if (answer.isCompleted) return;
    final text = message is List && message.isNotEmpty
        ? '${message.first}'
        : 'the writer ended without a book';
    answer.completeError(EpubExportFailed(text));
  }

  errors.listen(died);
  exits.listen(died);
  final stop = Timer.periodic(const Duration(milliseconds: 100), (_) {
    if (isCancelled?.call() ?? false) mailbox?.send(null);
  });
  final isolate = await Isolate.spawn(
    writeNoteEpub,
    (job: job, events: events.sendPort, probe: probe),
    onError: errors.sendPort,
    onExit: exits.sendPort,
  );
  try {
    return await answer.future;
  } finally {
    stop.cancel();
    isolate.kill();
    events.close();
    errors.close();
    exits.close();
  }
}

/// The isolate's entry: the container of [request], answered on its
/// `events`.
@visibleForTesting
Future<void> writeNoteEpub(NoteEpubRequest request) async {
  request.probe?.send(Isolate.current.controlPort);
  final cancel = ReceivePort();
  var cancelled = false;
  cancel.listen((_) => cancelled = true);
  request.events.send(cancel.sendPort);
  try {
    request.events.send(await _write(request.job, () => cancelled));
  } on EpubExportCancelled {
    request.events.send(const EpubExportCancelled());
  } on Object catch (error) {
    request.events.send(EpubExportFailed('$error'));
  } finally {
    cancel.close();
  }
}

Future<NoteEpubWritten> _write(
  NoteEpubJob job,
  bool Function() isCancelled,
) async {
  void check() {
    if (isCancelled()) throw const EpubExportCancelled();
  }

  check();
  final book = await EpubBook.start(
    path: job.file,
    title: job.title,
    language: job.language,
    libraryPath: job.libraryPath,
    metadata: epubMetadataOf(job.text),
    cover: job.cover,
  );
  var formulas = 0;
  var sources = 0;
  try {
    final images = <String, String>{};
    for (final entry in job.pictures.entries) {
      // The picture copies are asynchronous: a stop that arrived while one
      // was being written is seen here.
      check();
      final href = await book.imageHref(_chapterDir, entry.value);
      if (href != null) images[entry.key] = href;
    }
    final html = NoteHtml(
      NoteHtmlSource(
        text: job.text,
        title: job.title,
        images: images,
        todoBlocks: job.todoBlocks,
        kanban: job.kanban,
        epub: true,
      ),
    );
    final body = html.body();
    check();
    formulas = _count(body, '<svg');
    sources = _count(body, 'class="math-source"');
    for (final part in splitEpubNoteChapters(body, title: job.title)) {
      book.addChapter(
        href: '$_chapterDir/${part.file}',
        title: part.title,
        body: part.body,
        fontFaces: html.fontFaces,
        hasSvg: html.usesSvg && part.body.contains('<svg'),
        hasBoard: html.boardSheet != null,
      );
    }
  } finally {
    await book.close();
  }
  check();
  final bytes = await File(job.file).readAsBytes();
  return NoteEpubWritten(
    TransferableTypedData.fromList(<Uint8List>[bytes]),
    formulas: formulas,
    sources: sources,
  );
}

/// How many times [needle] appears in [text]; a diagnostic count, not a
/// parser.
int _count(String text, String needle) {
  var count = 0;
  var at = 0;
  while (true) {
    final found = text.indexOf(needle, at);
    if (found < 0) return count;
    count++;
    at = found + needle.length;
  }
}
