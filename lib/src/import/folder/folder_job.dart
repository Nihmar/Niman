/// The writing of an imported folder (#75, #1295), on its own isolate.
///
/// The notes — the Markdown files copied, the pages converted — and the
/// pages' pictures are written into a hidden folder at the top of the
/// library, `.folder.niman-tmp-<micros>`, and moved in at the end: the
/// pictures into the library's attachments folder, each kept once, and the
/// notes' folder renamed in under a name free there. Until then the library
/// holds nothing of the import, and a cancel or a failure deletes the hidden
/// folder and leaves it as it was. A crash leaves it to the temp sweep.
///
/// In two passes, because a link can point at a file that has not been
/// written yet: the pages first, each with its links under a placeholder
/// (`folder_links.dart`); then the Markdown files, their links to a page
/// rewritten, and the pages' placeholders resolved.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/import/book/book_move_in.dart'
    show moveStagedPictures;
import 'package:niman/src/import/folder/folder_links.dart';
import 'package:niman/src/import/folder/folder_pages.dart';
import 'package:niman/src/import/folder/folder_plan.dart';
import 'package:niman/src/import/folder/folder_types.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_convert_types.dart'
    show HtmlConvertProgress, htmlMaxBytes;
import 'package:niman/src/import/html/html_picture_store.dart';
import 'package:niman/src/import/markdown_links.dart';
import 'package:niman/src/library/markdown_import.dart' show freeFolderName;
import 'package:path/path.dart' as p;

export 'package:niman/src/import/folder/folder_types.dart';

/// The folder the notes are written in, beside the pictures' one, in the
/// staging folder.
const String _tree = 'tree';

/// How often the job gives the event loop a turn, to hear a stop.
const Duration _turn = Duration(milliseconds: 25);

/// A Markdown file that mentions a page by its extension: the only one whose
/// text is read for links.
final RegExp _mentionsPage = RegExp(r'\.x?html?\b', caseSensitive: false);

/// Writes the import [request] names, telling [progress] how far it has got;
/// null when there was nothing to write. [fetch] brings the web pictures;
/// null downloads them as a capture does.
///
/// A stop is cooperative, as the page's is (`convertHtml`): between its
/// steps it gives the event loop a turn, and [stopped] true ends it there with
/// [HtmlConvertStopped], its hidden folder deleted. Before it moves anything
/// into the library it asks [mayFinish]: an import cancelled by then answers
/// false and stops with nothing moved in; one that goes on cannot be
/// cancelled any more.
Future<FolderImported?> importFolder(
  FolderImportRequest request, {
  PictureFetcher? fetch,
  void Function(HtmlConvertProgress progress)? progress,
  Future<bool> Function()? mayFinish,
  bool Function()? stopped,
}) async {
  final plan = FolderPlan((
    markdown: request.markdown,
    pages: request.pages,
    bytes: 0,
  ));
  final total = plan.entries.length;
  if (total == 0) return null;
  final staging = Directory(request.staging);
  // A turn of the event loop costs a timer, which is some milliseconds on
  // Windows: a folder of a hundred thousand files cannot pay one each. The
  // loop is given a turn about every [_turn], enough for a stop to be heard.
  final clock = Stopwatch()..start();
  var lastTurn = -1 << 20;
  Future<void> step() async {
    if (clock.elapsedMilliseconds - lastTurn >= _turn.inMilliseconds) {
      await Future<void>.delayed(Duration.zero);
      lastTurn = clock.elapsedMilliseconds;
    }
    if (stopped?.call() ?? false) throw const HtmlConvertStopped();
  }

  HttpClient? client;
  try {
    await step();
    final name = freeFolderName(request.libraryRoot, request.name);
    staging.createSync(recursive: true);
    var done = 0;
    void report(String what) =>
        progress?.call((done: done, total: total, what: what));
    final pages = FolderPages(
      source: request.source,
      plan: plan,
      store: HtmlPictureStore(
        staging: request.staging,
        attachments: request.attachments,
        fetch: fetch ?? httpPictureFetcher(client = pictureHttpClient()),
        maxDownloads: folderImportMaxDownloads,
      ),
      step: step,
      stopped: stopped,
      progress: report,
      linkType: request.linkType,
      folderName: name,
      imported: request.importedOn ?? DateTime.now(),
    );
    File staged(FolderEntry entry) {
      final target = File(
        p.joinAll([request.staging, _tree, ...entry.target.split('/')]),
      );
      target.parent.createSync(recursive: true);
      return target;
    }

    // The first pass: the pages.
    final headings = PageHeadings.filled(total, null);
    final linked = <FolderEntry>[];
    var skipped = 0;
    var written = 0;
    for (final entry in plan.pages) {
      await step();
      report(entry.source);
      final note = await pages.convert(entry);
      if (note == null) {
        skipped++;
      } else {
        headings[entry.index] = note.headings;
        if (note.linked) linked.add(entry);
        staged(entry).writeAsStringSync(note.text);
        written++;
      }
      done++;
    }

    // The second: the Markdown, and the links of the pages.
    var copied = 0;
    for (final entry in plan.markdown) {
      await step();
      report(entry.source);
      final from = File(
        p.joinAll([request.source, ...entry.source.split('/')]),
      );
      try {
        final target = staged(entry);
        if (from.lengthSync() > htmlMaxBytes) {
          // Too large to read whole: copied as it is.
          from.copySync(target.path);
        } else {
          target.writeAsBytesSync(
            _markdownBytes(from, markdownLinkRewriter(plan, entry, headings)),
          );
        }
        copied++;
      } on FileSystemException {
        skipped++;
      }
      done++;
    }
    for (final entry in linked) {
      await step();
      final note = File(
        p.joinAll([request.staging, _tree, ...entry.target.split('/')]),
      );
      note.writeAsStringSync(
        resolvePageLinks(
          note.readAsStringSync(),
          plan: plan,
          here: entry,
          headings: headings,
        ),
      );
    }

    await step();
    final notes = written + copied;
    if (notes == 0) return null;
    if (!(await mayFinish?.call() ?? true)) throw const HtmlConvertStopped();
    moveStagedPictures(
      libraryRoot: request.libraryRoot,
      staging: request.staging,
      attachments: request.attachments,
    );
    // Free now: another import may have taken the name since it was chosen.
    final folder = freeFolderName(request.libraryRoot, name);
    Directory(p.join(request.staging, _tree))
        .renameSync(p.join(request.libraryRoot, folder));
    return (
      folder: folder,
      notes: notes,
      pages: written,
      pictures: pages.pictures,
      skipped: skipped,
    );
  } finally {
    client?.close(force: true);
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}

/// The bytes the Markdown file [from] lands as: its own, or — when its text
/// mentions a page — its text with the links to a page rewritten by
/// [rewrite]. A file that is not UTF-8 is copied unchanged.
List<int> _markdownBytes(File from, String? Function(String href) rewrite) {
  final bytes = from.readAsBytesSync();
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    return bytes;
  }
  if (!_mentionsPage.hasMatch(text)) return bytes;
  return utf8.encode(rewriteLinkDestinations(text, rewrite));
}

/// The entry of the import's isolate: [importFolder], its progress and its
/// end sent to the port it is handed, as plain messages.
///
/// Its first message hands the main isolate a port to stop it by: a `'stop'`
/// sent there is seen at the next step boundary of [importFolder].
Future<void> importFolderEntry(
  (FolderImportRequest request, SendPort events) message,
) async {
  final (request, events) = message;
  var stop = false;
  final control = ReceivePort()
    ..listen((message) {
      if (message == 'stop') stop = true;
    });
  events.send(('ready', control.sendPort));
  try {
    final imported = await importFolder(
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
      imported?.folder ?? '',
      imported?.notes ?? 0,
      imported?.pages ?? 0,
      imported?.pictures ?? 0,
      imported?.skipped ?? 0,
    ));
  } on HtmlConvertStopped {
    events.send(('stopped',));
  } on Object catch (error) {
    events.send(('failed', '$error'));
  } finally {
    control.close();
  }
}
