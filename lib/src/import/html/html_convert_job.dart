/// The writing of an HTML page converted to a note (#1293), on its own
/// isolate.
///
/// The page's pictures and its note are written into a hidden folder beside
/// where the note goes — the folder the main isolate names,
/// `.html.niman-tmp-<micros>` — and moved in at the end: the pictures into
/// the library's attachments folder, each named by its content (one already
/// there is the same one), then the note, under a name free in its folder.
/// Until then the library holds nothing of the page, and a cancel or a
/// failure deletes the hidden folder and leaves it as it was. A crash leaves
/// the hidden folder to the temp sweep (`sweepStaleTempFiles`).
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_note.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_picture_store.dart';
import 'package:niman/src/library/note_writer.dart' show swapFileIn;
import 'package:path/path.dart' as p;

/// The most bytes a page may have: what the EPUB conversion allows a text
/// file.
const int htmlMaxBytes = 32 << 20;

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
});

/// What a conversion wrote: the note (`made`, library-relative), the note
/// to open (the same one), and how many notes (one) and pictures.
typedef HtmlConverted = ({String made, String open, int notes, int pictures});

/// Where a conversion has got to: `done` of `total` steps (pictures, then
/// the note), and the name of the one being written.
typedef HtmlConvertProgress = ({int done, int total, String what});

/// Converts the page [request] names, telling [progress] how far it has
/// got. [fetch] brings the web pictures; null downloads them as a capture
/// does.
///
/// A stop is cooperative, as the book's is (`convertEpub`): between its
/// steps — the file's reading, each picture, the note, the moving in — it
/// gives the event loop a turn, and [stopped] true ends it there with
/// [HtmlConvertStopped], its hidden folder deleted. Before it moves
/// anything into the library it asks [mayFinish]: a conversion cancelled by
/// then answers false and stops with nothing moved in; one that goes on
/// cannot be cancelled any more.
///
/// Throws [HtmlRefused] for a file it cannot convert.
Future<HtmlConverted> convertHtml(
  HtmlConvertRequest request, {
  PictureFetcher? fetch,
  void Function(HtmlConvertProgress progress)? progress,
  Future<bool> Function()? mayFinish,
  bool Function()? stopped,
}) async {
  final staging = Directory(request.staging);
  Future<void> step() async {
    await Future<void>.delayed(Duration.zero);
    if (stopped?.call() ?? false) throw const HtmlConvertStopped();
  }

  HttpClient? client;
  try {
    await step();
    final bytes = await _read(request.source);
    await step();
    final page = readHtmlPage(
      bytes,
      fileName: htmlDisplayName(request.source, request.name),
      extent: request.extent,
    );
    final file = Uri.file(request.source);
    final base = page.baseUrl ?? file;
    // Each picture once, whichever `src`s name it.
    final sources = <String, PictureSource>{};
    final addressOf = <String, String>{};
    for (final src in htmlPictureSrcs(page)) {
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
    final total = sources.length + 1;
    var done = 0;
    final kept = <String, String>{};
    for (final source in sources.values) {
      await step();
      progress?.call((done: done++, total: total, what: source.label));
      final path = await store.keep(source);
      if (path != null) kept[source.address] = path;
    }
    await step();
    progress?.call((done: done, total: total, what: page.title));
    final text = htmlNote(
      page,
      imported: request.importedOn ?? DateTime.now(),
      file: file,
      pictures: {
        for (final entry in addressOf.entries) entry.key: ?kept[entry.value],
      },
      linkType: request.linkType,
      folder: request.parent,
    );
    final stem = sanitizeName(page.title, fallback: defaultNoteName);
    final note = File(p.join(request.staging, '$stem.md'))
      ..writeAsStringSync(text);
    await step();
    if (!(await mayFinish?.call() ?? true)) throw const HtmlConvertStopped();
    return await _moveIn(request, note, stem, store.length);
  } finally {
    client?.close(force: true);
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}

/// What the page at [source] is called to a person: [name] when it is given
/// (a share's own, whatever its copy in the cache is called), else its
/// file's name.
String htmlDisplayName(String source, String? name) =>
    name == null || name.trim().isEmpty ? p.basename(source) : p.basename(name);

/// The bytes of the file at [source]; throws [HtmlRefused] when it is not a
/// file, is too large, or cannot be read.
Future<Uint8List> _read(String source) async {
  final file = File(source);
  try {
    if (FileSystemEntity.typeSync(source) != FileSystemEntityType.file) {
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

/// The staged pictures moved into the library's attachments folder, then
/// [note] into its folder under a name free there; answers what was made.
Future<HtmlConverted> _moveIn(
  HtmlConvertRequest request,
  File note,
  String stem,
  int pictures,
) async {
  final assets = Directory(p.join(request.staging, request.attachments));
  if (assets.existsSync()) {
    final into = Directory(p.join(request.libraryRoot, request.attachments))
      ..createSync(recursive: true);
    for (final picture in assets.listSync().whereType<File>()) {
      final target = File(p.join(into.path, p.basename(picture.path)));
      // Named by its content: one already there is this one.
      if (!target.existsSync()) {
        await swapFileIn(target.path, picture.path);
      }
    }
  }
  final parent = Directory(
    p.joinAll([request.libraryRoot, ...request.parent.split('/')]),
  )..createSync(recursive: true);
  final name = await uniqueFileName(parent, stem, '.md');
  await swapFileIn(p.join(parent.path, name), note.path);
  final made = request.parent.isEmpty ? name : '${request.parent}/$name';
  return (made: made, open: made, notes: 1, pictures: pictures);
}

/// The entry of the conversion's isolate: [convertHtml], its progress and
/// its end sent to the port it is handed, as plain messages.
///
/// Its first message hands the main isolate a port to stop it by: a `'stop'`
/// sent there is seen at the next step boundary of [convertHtml].
Future<void> convertHtmlEntry(
  (HtmlConvertRequest request, SendPort events) message,
) async {
  final (request, events) = message;
  var stop = false;
  final control = ReceivePort()
    ..listen((message) {
      if (message == 'stop') stop = true;
    });
  events.send(('ready', control.sendPort));
  try {
    final converted = await convertHtml(
      request,
      stopped: () => stop,
      progress: (progress) => events.send((
        'progress',
        progress.done,
        progress.total,
        progress.what,
      )),
      // The main isolate says whether the moving in may start: a cancel it
      // took first says no, and one after the answer is refused there.
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
  } on HtmlConvertStopped {
    events.send(('stopped',));
  } on HtmlRefused catch (refused) {
    events.send(('refused', refused.reason.name, refused.detail));
  } on Object catch (error) {
    events.send(('failed', '$error'));
  } finally {
    control.close();
  }
}
