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
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show RootIsolateToken;

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger;
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/links/parser.dart';
import 'package:path/path.dart' as p;

/// What a folder or the library is exported as.
enum ExportTreeFormat {
  /// The subtree as it is on disk: the notes and their attachments.
  markdown,

  /// Every Markdown note as an HTML page; every other file copied as it is.
  html,

  /// Every Markdown note as a PDF page, printed by the browser engine.
  pdf,
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
/// gone.
final class ExportCancelled implements Exception {
  /// Creates the cancellation.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'Export cancelled';
}

/// A PDF folder was asked for with no engine to print with.
final class TreeExportNoEngine implements Exception {
  /// Creates the failure.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'No PDF engine was found';
}

/// One tree export, running on its own isolate.
final class TreeExport {
  new _(this._isolate, this._zipPath)
    : progress = ValueNotifier<ExportProgress?>(null);

  final Isolate _isolate;
  final String _zipPath;

  /// How far it has got; null until the first entry is written.
  final ValueNotifier<ExportProgress?> progress;

  final Completer<void> _done = Completer<void>();
  bool _cancelled = false;

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
    final export = TreeExport._(isolate, zipPath)
      .._listen(events, errors, exits);
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

  void _listen(ReceivePort events, ReceivePort errors, ReceivePort exits) {
    final gauge = IsolateGauge.begin('export "${p.basename(_zipPath)}"');
    events.listen((message) {
      if (message is ExportProgress) progress.value = message;
    });
    errors.listen((message) => _settle(gauge, error: _errorOf(message)));
    exits.listen((_) => _settle(gauge));
  }

  void _settle(int gauge, {Object? error}) {
    if (_done.isCompleted) return;
    IsolateGauge.finishJob(gauge, error: error);
    if (_cancelled) {
      _done.completeError(const ExportCancelled());
    } else if (error != null) {
      _done.completeError(error);
    } else {
      _done.complete();
    }
  }

  /// Cancels the export: the isolate is killed and the half-written zip
  /// removed; [done] errors with [ExportCancelled].
  Future<void> cancel() async {
    if (_done.isCompleted) return;
    _cancelled = true;
    _isolate.kill(priority: Isolate.immediate);
    await _done.future.then<void>((_) {}, onError: (Object _) {});
    try {
      await File(_zipPath).delete();
    } on FileSystemException {
      // Never written, or already gone.
    }
  }
}

/// The error an isolate's error port reported: `[error, stackTrace]`.
Object _errorOf(Object? message) {
  if (message is List && message.isNotEmpty) return message.first as Object;
  return message!;
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
  final encoder = ZipFileEncoder()..create(request.zipPath);
  // The PDF format's scratch: one page and one PDF at a time, reused.
  final scratch = request.format == ExportTreeFormat.pdf
      ? Directory.systemTemp.createTempSync('niman-tree-pdf-')
      : null;
  try {
    var done = 0;
    for (final entry in tree.entries) {
      if (entry.isDir) {
        if (request.format == ExportTreeFormat.markdown) {
          encoder.addArchiveFile(ArchiveFile.directory(entry.rel));
        }
      } else if (request.format == ExportTreeFormat.markdown) {
        await encoder.addFile(File(entry.abs), entry.rel);
      } else if (_isNote(entry.rel)) {
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
          // embedded as a `data:` URI, as the single note's page is.
          embedPictures: request.format == ExportTreeFormat.pdf,
        );
        if (request.format == ExportTreeFormat.pdf) {
          await _printInto(
            encoder,
            scratch!,
            request.engine,
            request.runner,
            page,
            _stem(entry.rel),
          );
        } else if (request.format == ExportTreeFormat.html) {
          encoder.addArchiveFile(
            ArchiveFile.string('${_stem(entry.rel)}.html', page),
          );
        } else {
          await encoder.addFile(File(entry.abs), entry.rel);
        }
      } else {
        await encoder.addFile(File(entry.abs), entry.rel);
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
    await encoder.close();
  } on Object {
    // The encoder holds an open file; close it before the error goes on.
    try {
      await encoder.close();
    } on Object {
      // The first failure is the one worth reporting.
    }
    rethrow;
  } finally {
    try {
      scratch?.deleteSync(recursive: true);
    } on FileSystemException {
      // A temp directory left behind is not the export's failure.
    }
  }
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

String _page(
  String text,
  String rel,
  _Tree tree,
  String language,
  String linkExtension, {
  bool embedPictures = false,
}) {
  final noteDir = p.dirname(rel);
  final title =
      parseFrontmatter(text)?.title ?? p.basenameWithoutExtension(rel);
  final source = NoteHtmlSource(
    text: text,
    title: title,
    images: embedPictures
        ? _imageDataUris(text, noteDir, tree)
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

/// The pictures [text] shows, by the target as written, as `data:` URIs.
///
/// A PDF page is printed from the export's scratch directory, where the
/// pictures the zip holds are not: left relative, every one of them is a
/// broken image. The reading happens here, on the export isolate, which is
/// where the tree's files are read anyway.
Map<String, String> _imageDataUris(String text, String noteDir, _Tree tree) {
  final out = <String, String>{};
  for (final target in ExportSources.pictureTargets(text)) {
    final picture = _fileIn(target, noteDir, tree.files);
    if (picture == null) continue;
    final path = p.join(tree.root, picture);
    final mime = ExportSources.imageMime(p.extension(path).toLowerCase());
    if (mime == null) continue;
    try {
      final bytes = File(path).readAsBytesSync();
      out[target] = 'data:$mime;base64,${base64Encode(bytes)}';
    } on FileSystemException {
      // A picture that cannot be read stays as the note wrote it.
    }
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
