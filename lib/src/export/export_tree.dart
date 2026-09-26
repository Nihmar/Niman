/// Exporting a folder or the whole library as one zip (#24).
///
/// The work runs on a background isolate, one entry at a time, streamed
/// into the zip: a library can be a million notes, and neither the file
/// list nor the pages are held in a list. Progress comes back over a port,
/// and cancelling kills the isolate and removes the half-written zip.
///
/// A PDF export writes one PDF per note, at the note's own relative path —
/// not one combined file — printed by the machine's browser engine, or by
/// Android's WebView ([WebViewPdfPrinter], through the `niman/pdf`
/// channel, which is why the isolate asks for the root token).
///
/// Links and pictures are resolved **inside the exported subtree**: a
/// target that is there becomes a relative link, one that is not stays as
/// the note wrote it (a wikilink becomes highlighted text). Resolving
/// against the tree rather than the link index keeps the whole export on
/// the isolate — the index lives on the UI isolate — and gives the
/// behavior the export wants anyway: what is not in the zip cannot be
/// linked to from it.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show RootIsolateToken;

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger;
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/links/parser.dart';
import 'package:path/path.dart' as p;

const AppLogger _log = AppLogger(name: 'export');

/// What a folder or the library is exported as.
enum ExportTreeFormat {
  /// The subtree as it is on disk: the notes and their attachments.
  markdown,

  /// Every Markdown note as an HTML page; every other file copied as it is.
  html,

  /// Every Markdown note as a PDF page, printed by the browser engine.
  pdf,

  /// Every Markdown note as one chapter of a single EPUB book (#303).
  epub,
}

/// How far a running export has got.
@immutable
final class ExportProgress {
  /// Creates a progress report.
  const new({required this.done, required this.total, required this.current});

  /// Entries written so far.
  final int done;

  /// Entries in the export.
  final int total;

  /// The entry just written, relative to the exported folder.
  final String current;

  /// How much of the work is done, 0..1.
  double get fraction => total <= 0 ? 1 : (done / total).clamp(0.0, 1.0);
}

/// The export was cancelled before it finished; the half-written zip is
/// gone, unless [zipLeftBehind] is true — a handle a killed isolate did
/// not let go, which happens on Windows when a cancel has to fall back to
/// killing.
final class ExportCancelled implements Exception {
  /// Creates the cancellation.
  const new({this.zipLeftBehind = false});

  /// Whether the half-written zip could not be removed.
  final bool zipLeftBehind;

  /// What a log line reads.
  @override
  String toString() => zipLeftBehind
      ? 'Export cancelled; the half-written zip could not be removed'
      : 'Export cancelled';
}

/// A PDF folder was asked for with no engine to print with.
final class TreeExportNoEngine implements Exception {
  /// Creates the failure.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'No PDF engine was found';
}

/// An EPUB was asked for from a folder with no notes in it.
///
/// EPUB 3 wants at least one `itemref` in the spine: a book with no
/// chapters is not a book, and writing the container anyway left a file
/// that no reader opens (E2).
final class TreeExportNoChapters implements Exception {
  /// Creates the failure.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'A folder with no notes has no book to write';
}

/// One tree export, running on its own isolate.
final class TreeExport {
  new _(
    this._isolate,
    this._zipPath,
    this._format,
    this._events,
    this._errors,
    this._exits,
  ) : progress = ValueNotifier<ExportProgress?>(null);

  final Isolate _isolate;
  final String _zipPath;
  final ExportTreeFormat _format;
  final ReceivePort _events;
  final ReceivePort _errors;
  final ReceivePort _exits;

  /// How far it has got; null until the first entry is written.
  final ValueNotifier<ExportProgress?> progress;

  final Completer<void> _done = Completer<void>();
  bool _cancelled = false;
  bool _settling = false;

  /// The isolate's cancellation mailbox, sent over the events port.
  SendPort? _cancelPort;

  /// Completes when the zip is written; errors with the failure, or with
  /// [ExportCancelled].
  Future<void> get done => _done.future;

  /// Starts exporting [dir] (absolute) into [zipPath].
  ///
  /// [engine] is the PDF format's browser (Edge, Chromium): the printer a
  /// folder of pages goes through on the desktop. Android needs none — its
  /// WebView prints through the `niman/pdf` channel from the isolate — and
  /// where there is neither an engine nor a WebView there is nothing to
  /// print with: [TreeExportNoEngine], since the raster fallback paints on
  /// the UI isolate and cannot run here.
  ///
  /// [runner] runs the engine's process; null runs the real one, and a test
  /// hands in a top-level function of its own — a closure cannot cross the
  /// isolate boundary.
  static Future<TreeExport> start({
    required String dir,
    required String zipPath,
    required ExportTreeFormat format,
    required String language,
    String? engine,
    ProcessRunner? runner,
  }) async {
    if (format == ExportTreeFormat.pdf &&
        engine == null &&
        !Platform.isAndroid) {
      throw const TreeExportNoEngine();
    }
    final events = ReceivePort();
    final errors = ReceivePort();
    final exits = ReceivePort();
    final isolate = await Isolate.spawn(
      _exportTree,
      (
        dir: dir,
        zipPath: zipPath,
        format: format,
        language: language,
        engine: engine,
        runner: runner,
        // The root isolate's token, so the spawned isolate may open the
        // WebView channel when Android prints.
        token: RootIsolateToken.instance,
        events: events.sendPort,
      ),
      onError: errors.sendPort,
      onExit: exits.sendPort,
    );
    final export = TreeExport._(isolate, zipPath, format, events, errors, exits)
      .._listen();
    return export;
  }

  /// Exports [dir] and answers when it is written: [start] without the
  /// watching, for a caller that does not show progress.
  static Future<void> run({
    required String dir,
    required String zipPath,
    required ExportTreeFormat format,
    required String language,
    String? engine,
    ProcessRunner? runner,
  }) async {
    final export = await start(
      dir: dir,
      zipPath: zipPath,
      format: format,
      language: language,
      engine: engine,
      runner: runner,
    );
    await export.done;
  }

  void _listen() {
    final gauge = IsolateGauge.begin('export "${p.basename(_zipPath)}"');
    _events.listen((message) {
      if (message is ExportProgress) {
        progress.value = message;
      } else if (message is SendPort) {
        // The isolate's cancellation mailbox: what lets a cancel close the
        // zip instead of killing the isolate with a file handle open.
        _cancelPort = message;
      } else if (message is _TreeExportWarning) {
        // Logged here, on the parent: the isolate's buffer goes with it.
        _log.warning(message.message);
      } else if (message is TreeExportNoChapters) {
        // A typed failure the isolate asked to report without throwing:
        // only a message keeps the type across the boundary.
        unawaited(_settle(gauge, error: message));
      }
    });
    _errors.listen(
      (message) => unawaited(_settle(gauge, error: _errorOf(message))),
    );
    _exits.listen((_) => unawaited(_settle(gauge)));
  }

  Future<void> _settle(int gauge, {Object? error}) async {
    if (_settling) return;
    _settling = true;
    IsolateGauge.finishJob(gauge, error: error);
    // The isolate is done (or gone): the ports have nothing left to say,
    // and a cancelled export's zip is removed before `done` answers.
    _events.close();
    _errors.close();
    _exits.close();
    if (_cancelled) {
      final removed = await _removeZip();
      _done.completeError(ExportCancelled(zipLeftBehind: !removed));
    } else if (error != null) {
      _done.completeError(error);
    } else {
      _done.complete();
    }
    progress.dispose();
  }

  /// Removes the half-written zip; false when it is still there.
  Future<bool> _removeZip() async {
    try {
      await File(_zipPath).delete();
      return true;
    } on FileSystemException {
      // Never written, or held open by the isolate Windows has not let go
      // of yet.
      return !File(_zipPath).existsSync();
    }
  }

  /// Cancels the export.
  ///
  /// The isolate is asked to stop and close its zip first — killing it
  /// would leave the file handle open, and Windows refuses to delete a
  /// file that is still held (M4). A run stuck in a print that cannot be
  /// interrupted is killed after a short grace instead; [done] errors with
  /// [ExportCancelled].
  Future<void> cancel() async {
    if (_done.isCompleted) return;
    _cancelled = true;
    if (_format == ExportTreeFormat.pdf && Platform.isAndroid) {
      // The platform print is on the main thread and the isolate waits on
      // it: stopping it is what frees the bridge for the next export (M7).
      unawaited(WebViewPdfPrinter.cancel());
    }
    final mailbox = _cancelPort;
    if (mailbox != null) {
      mailbox.send(null);
      try {
        await _done.future.timeout(const Duration(seconds: 3));
        return;
      } on TimeoutException {
        // A print that will not come back: kill rather than hold the
        // export open.
      } on Object {
        // The export failed on its own: nothing left to stop.
        return;
      }
    }
    _isolate.kill(priority: Isolate.immediate);
    await _done.future.then<void>((_) {}, onError: (Object _) {});
  }
}

/// The error an isolate's error port reported: `[error, stackTrace]`.
Object _errorOf(Object? message) {
  if (message is List && message.isNotEmpty) return message.first as Object;
  return message!;
}

/// A warning the isolate saw and the parent is to log (#303, E3): the
/// isolate's own [AppLog] buffer dies with it, so the line would leave no
/// trace.
final class _TreeExportWarning {
  /// Creates the warning.
  const new(this.message);

  /// The line the parent logs.
  final String message;
}

/// One entry of the subtree: its absolute path, its zip name, and whether
/// it is a folder.
typedef _Entry = ({String abs, String rel, bool isDir});

/// The walked tree, its root, and the two lookups links and pictures
/// resolve with.
typedef _Tree = ({
  String root,
  List<_Entry> entries,
  Set<String> files,
  Map<String, String> notes,
  Map<String, List<String>> stems,
});

/// The request the export isolate is spawned with.
typedef TreeExportRequest = ({
  String dir,
  String zipPath,
  ExportTreeFormat format,
  String language,
  String? engine,
  ProcessRunner? runner,
  RootIsolateToken? token,
  SendPort events,
});

Future<void> _exportTree(TreeExportRequest request) async {
  // Android prints through the WebView channel, which a background isolate
  // may only open with the root isolate's token.
  if (request.format == ExportTreeFormat.pdf && Platform.isAndroid) {
    final token = request.token;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }
  }
  final tree = _walk(request.dir);
  // A book needs a chapter: EPUB 3's spine must hold at least one itemref,
  // and a folder of attachments is not a book (E2). Asked before the
  // container is created, so there is no file to sweep afterwards; the
  // failure travels as a message because an exception thrown here would
  // reach the parent as its own text, not as the type a caller can catch.
  if (request.format == ExportTreeFormat.epub && tree.notes.isEmpty) {
    request.events.send(const TreeExportNoChapters());
    return;
  }
  // The cancellation mailbox: the parent asks the export to stop, and the
  // encoder is closed on the way out instead of being torn off by a kill.
  final cancel = ReceivePort();
  var cancelled = false;
  cancel.listen((_) => cancelled = true);
  request.events.send(cancel.sendPort);
  // The EPUB is a zip with a package to end it: the book closes what the
  // encoder would, and the plain formats have no book. Its metadata and
  // cover are the `index.md` note's frontmatter (#303).
  final front = request.format == ExportTreeFormat.epub
      ? _bookFrontmatter(tree, request.events)
      : null;
  final metadata = front?.metadata ?? const EpubMetadata();
  final coverTarget = metadata.cover;
  final cover = coverTarget == null || front == null
      ? null
      : _fileIn(coverTarget, front.dir, tree.files);
  if (coverTarget != null && cover == null) {
    request.events.send(
      _TreeExportWarning(
        'the book\'s cover "$coverTarget" is not in the folder: '
        'the book opens on its first chapter',
      ),
    );
  }
  final book = request.format == ExportTreeFormat.epub
      ? await EpubBook.start(
          path: request.zipPath,
          title: p.basename(request.dir),
          language: request.language,
          metadata: metadata,
          cover: cover == null ? null : p.join(tree.root, cover),
        )
      : null;
  final encoder = book == null
      ? (ZipFileEncoder()..create(request.zipPath))
      : null;
  // The PDF format's scratch: one page and one PDF at a time, reused.
  final scratch = request.format == ExportTreeFormat.pdf
      ? Directory.systemTemp.createTempSync('niman-tree-pdf-')
      : null;
  try {
    var done = 0;
    for (final entry in tree.entries) {
      // Between entries, where the zip is never half-written.
      if (cancelled) break;
      // Every format keeps the tree's folders, empty ones included: a
      // folder in the Markdown zip and not in the HTML one is a support
      // question waiting to happen (L8).
      if (entry.isDir) {
        encoder?.addArchiveFile(ArchiveFile.directory(entry.rel));
      } else if (request.format == ExportTreeFormat.markdown) {
        await encoder!.addFile(File(entry.abs), entry.rel);
      } else if (_isNote(entry.rel)) {
        if (book != null) {
          await _addEpubChapter(book, tree, entry);
        } else {
          final page = _page(
            File(entry.abs).readAsStringSync(),
            entry.rel,
            tree,
            request.language,
            // A PDF zip holds PDFs: its links point at them, not at pages
            // the zip does not have.
            request.format == ExportTreeFormat.pdf ? '.pdf' : '.html',
            // A PDF page is printed from the scratch directory: a picture
            // beside it in the zip has nothing to resolve against, so it is
            // a `file:` URL the engine fetches.
            embedPictures: request.format == ExportTreeFormat.pdf,
          );
          if (request.format == ExportTreeFormat.pdf) {
            await _printInto(
              encoder!,
              scratch!,
              request.engine,
              request.runner,
              page,
              _stem(entry.rel),
            );
          } else {
            encoder!.addArchiveFile(
              ArchiveFile.string('${_stem(entry.rel)}.html', page),
            );
          }
        }
      } else {
        // The EPUB carries the pictures its chapters reference, not the
        // whole tree: an attachment nobody cites would only weigh the
        // book down.
        if (encoder != null) await encoder.addFile(File(entry.abs), entry.rel);
      }
      done++;
      if (done % 8 == 0 || done == tree.entries.length) {
        request.events.send(
          ExportProgress(
            done: done,
            total: tree.entries.length,
            current: entry.rel,
          ),
        );
      }
    }
    if (book != null) {
      await book.close();
    } else {
      await encoder!.close();
    }
  } on Object {
    // The encoder (or the book's) holds an open file; close it before the
    // error goes on.
    try {
      if (book != null) {
        await book.close();
      } else {
        await encoder!.close();
      }
    } on Object {
      // The first failure is the one worth reporting.
    }
    rethrow;
  } finally {
    cancel.close();
    try {
      scratch?.deleteSync(recursive: true);
    } on FileSystemException {
      // A temp directory left behind is not the export's failure.
    }
  }
}

/// The frontmatter a folder's book takes: `index.md`'s, when the exported
/// folder has one at its root (#303).
///
/// A folder has no frontmatter of its own, and a book's metadata belongs to
/// the book, not to whichever note sorts first: `index.md` is the note the
/// author writes it in.
///
/// A book without one — or with one that says nothing — is not a failure,
/// but it is silent: the package carries the folder's name and nothing
/// else, so why is said over [events] for the parent to log (E3).
({EpubMetadata metadata, String dir})? _bookFrontmatter(
  _Tree tree,
  SendPort events,
) {
  final rel = tree.notes['index.md'];
  if (rel == null || p.dirname(rel) != '.') {
    events.send(
      const _TreeExportWarning(
        'the exported folder has no index.md at its root: the book carries '
        "the folder's name and no metadata",
      ),
    );
    return null;
  }
  final text = File(p.join(tree.root, rel)).readAsStringSync();
  if (parseFrontmatter(text) == null) {
    events.send(
      const _TreeExportWarning(
        "the book's index.md has no frontmatter: the package carries the "
        "folder's name and no metadata",
      ),
    );
  }
  return (metadata: epubMetadataOf(text), dir: '.');
}

/// Adds one note of the tree to [book] as a chapter (#303).
Future<void> _addEpubChapter(EpubBook book, _Tree tree, _Entry entry) async {
  final rel = entry.rel;
  final noteDir = p.dirname(rel);
  final href = 'OEBPS/text/${_stem(rel)}.xhtml';
  final text = File(entry.abs).readAsStringSync();
  final images = <String, String>{};
  for (final target in ExportSources.pictureTargets(text)) {
    final picture = _fileIn(target, noteDir, tree.files);
    if (picture == null) continue;
    final url = await book.imageHref(
      p.posix.dirname(href),
      p.join(tree.root, picture),
    );
    if (url != null) images[target] = url;
  }
  final title = _pageTitle(text, rel);
  final source = NoteHtmlSource(
    text: text,
    title: title,
    images: images,
    // A book's chapters link to each other, as the HTML zip's pages do.
    links: _linkUrls(text, noteDir, tree, '.xhtml'),
  );
  final html = NoteHtml(source);
  book.addChapter(
    href: href,
    title: title,
    body: html.body(),
    fontFaces: html.fontFaces,
  );
}

/// Prints [page] with the machine's printer and adds the PDF to [encoder]
/// as `<stem>.pdf`.
Future<void> _printInto(
  ZipFileEncoder encoder,
  Directory scratch,
  String? engine,
  ProcessRunner? runner,
  String page,
  String stem,
) async {
  final htmlPath = p.join(scratch.path, 'page.html');
  final pdfPath = p.join(scratch.path, 'page.pdf');
  File(htmlPath).writeAsStringSync(page);
  // The scratch is reused for every note: a PDF left by the last one must
  // not pass for this one's, should the printer answer without writing.
  try {
    File(pdfPath).deleteSync();
  } on FileSystemException {
    // Never written, or already gone.
  }
  final printer = Platform.isAndroid
      ? const WebViewPdfPrinter()
      : ProcessPdfPrinter(engine: engine, run: runner ?? runProcess);
  final outcome = await printer.print(htmlPath, pdfPath);
  switch (outcome) {
    case PdfPrinted():
      await encoder.addFile(File(pdfPath), '$stem.pdf');
    case PdfNoEngine():
      throw const TreeExportNoEngine();
    case PdfFailed(:final message):
      throw StateError('printing "$stem": $message');
  }
}

/// Whether [rel] becomes a page: a Markdown note.
bool _isNote(String rel) => p.extension(rel).toLowerCase() == '.md';

/// The subtree of [dir] in path order: every file and folder whose name
/// does not start with a dot (settings, trash and history are not part of
/// an export).
_Tree _walk(String dir) {
  final entries = <_Entry>[];
  void visit(Directory current, String rel) {
    final children = current.listSync()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final child in children) {
      final name = p.basename(child.path);
      if (name.startsWith('.')) continue;
      final childRel = rel.isEmpty ? name : '$rel/$name';
      if (child is Directory) {
        entries.add((abs: child.path, rel: childRel, isDir: true));
        visit(child, childRel);
      } else if (child is File) {
        entries.add((abs: child.path, rel: childRel, isDir: false));
      }
    }
  }

  visit(Directory(dir), '');
  final files = <String>{
    for (final entry in entries)
      if (!entry.isDir) entry.rel,
  };
  final notes = <String, String>{
    for (final file in files)
      if (p.extension(file).toLowerCase() == '.md') file.toLowerCase(): file,
  };
  final stems = <String, List<String>>{};
  for (final file in notes.values) {
    final stem = _stem(file).toLowerCase();
    (stems[stem] ??= <String>[]).add(file);
  }
  return (
    root: dir,
    entries: entries,
    files: files,
    notes: notes,
    stems: stems,
  );
}

/// [rel] without its Markdown extension: the page beside the note.
String _stem(String rel) => p.withoutExtension(rel);

/// The title a page or a chapter carries: the note's frontmatter title, or
/// its file's own name.
String _pageTitle(String text, String rel) =>
    parseFrontmatter(text)?.title ?? p.basenameWithoutExtension(rel);

String _page(
  String text,
  String rel,
  _Tree tree,
  String language,
  String linkExtension, {
  bool embedPictures = false,
}) {
  final noteDir = p.dirname(rel);
  final title = _pageTitle(text, rel);
  final source = NoteHtmlSource(
    text: text,
    title: title,
    images: embedPictures
        ? _imageFileUrls(text, noteDir, tree)
        : _imageUrls(text, noteDir, tree),
    links: _linkUrls(text, noteDir, tree, linkExtension),
  );
  final html = NoteHtml(source);
  return htmlPage(
    title: title,
    body: html.body(),
    fontFaces: html.fontFaces,
    language: language,
  );
}

/// The pictures [text] shows, by the target as written, as URLs relative to
/// the page.
Map<String, String> _imageUrls(String text, String noteDir, _Tree tree) {
  final out = <String, String>{};
  for (final target in ExportSources.pictureTargets(text)) {
    final picture = _fileIn(target, noteDir, tree.files);
    if (picture != null) out[target] = _url(noteDir, picture);
  }
  return out;
}

/// The pictures [text] shows, by the target as written, as `file:` URLs.
///
/// A PDF page is printed from the export's scratch directory, where the
/// pictures the zip holds are not: left relative, every one of them is a
/// broken image. A `file:` URL points at the tree itself, and the engine
/// fetches it — the page stays the note's size, where embedding a
/// library's photos as base64 built one no phone could hold.
Map<String, String> _imageFileUrls(String text, String noteDir, _Tree tree) {
  final out = <String, String>{};
  for (final target in ExportSources.pictureTargets(text)) {
    final picture = _fileIn(target, noteDir, tree.files);
    if (picture == null) continue;
    out[target] = Uri.file(p.join(tree.root, picture)).toString();
  }
  return out;
}

/// The note links [text] writes, by the target as written, as URLs
/// relative to the page. A target outside the subtree is left out: it
/// becomes highlighted text on the page. [extension] is what a note link
/// points at — the page the zip holds, `.html` or `.pdf`.
Map<String, String> _linkUrls(
  String text,
  String noteDir,
  _Tree tree,
  String extension,
) {
  final out = <String, String>{};
  for (final link in parseLinks(text)) {
    switch (link) {
      case WikiLink(:final ref):
        final note = _noteIn(ref.target, noteDir, tree);
        if (note != null) {
          out[ref.target] = _url(noteDir, '${_stem(note)}$extension');
        }
      case MarkdownLink(:final href):
        if (!href.toLowerCase().endsWith('.md')) continue;
        final note = _noteIn(href, noteDir, tree);
        if (note != null) out[href] = _url(noteDir, '${_stem(note)}$extension');
    }
  }
  return out;
}

/// The file [target] names inside the tree, from [noteDir]: the subtree
/// root first, then the note's own folder, then a unique file name — the
/// read view's own order, over the tree instead of the index.
String? _fileIn(String target, String noteDir, Set<String> files) {
  var clean = target.trim().replaceAll(r'\', '/');
  while (clean.startsWith('./')) {
    clean = clean.substring(2);
  }
  if (clean.isEmpty) return null;
  if (files.contains(clean)) return clean;
  final beside = p.posix.normalize(p.posix.join(noteDir, clean));
  if (files.contains(beside)) return beside;
  if (clean.contains('%')) {
    try {
      final decoded = Uri.decodeFull(clean);
      if (decoded != clean) return _fileIn(decoded, noteDir, files);
    } on FormatException {
      // A stray `%` is taken as written.
    }
  }
  final base = p.posix.basename(clean);
  final matches = [
    for (final file in files)
      if (p.posix.basename(file) == base) file,
  ];
  return matches.length == 1 ? matches.single : null;
}

/// The note [target] names inside the tree: an exact path first (with
/// `.md`), then the note's own folder, then a unique stem, then the stem
/// under the target's own folder — the index's own order.
String? _noteIn(String target, String noteDir, _Tree tree) {
  var clean = target.trim().replaceAll(r'\', '/');
  while (clean.startsWith('./')) {
    clean = clean.substring(2);
  }
  if (clean.isEmpty) return null;
  var lower = clean.toLowerCase();
  if (!lower.endsWith('.md')) lower = '$lower.md';
  final atRoot = tree.notes[lower];
  if (atRoot != null) return atRoot;
  final beside = tree.notes[p.posix.join(noteDir, lower)];
  if (beside != null) return beside;
  final stem = p.withoutExtension(p.posix.basename(lower));
  final candidates = tree.stems[stem] ?? const <String>[];
  if (candidates.length == 1) return candidates.single;
  final prefix = p.posix.dirname(lower);
  if (candidates.isEmpty || prefix == '.') return null;
  final filtered = [
    for (final candidate in candidates)
      if (p.posix.dirname(candidate.toLowerCase()) == prefix) candidate,
  ];
  return filtered.length == 1 ? filtered.single : null;
}

/// Where [target] sits, from the page in [fromDir] (both tree-relative):
/// a URL a browser reads, one path segment at a time.
///
/// `Uri.encodeFull` would leave `#` and `?` alone — they are URI delimiters,
/// not path characters — so a picture named `a#b.png` would export as a
/// fragment of a path that does not exist.
String _url(String fromDir, String target) {
  final relative = fromDir.isEmpty || fromDir == '.'
      ? target
      : p.posix.relative(target, from: fromDir);
  return relative.split('/').map(Uri.encodeComponent).join('/');
}
