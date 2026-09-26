/// One note exported as a PDF (#63): the page printed by the machine's
/// browser engine, or drawn here when it has none.
///
/// The engine wants a file to read (`file:///…`) and writes a file, so
/// the page and the PDF live in a scratch directory for the run and are
/// removed afterwards. When no engine answers, the note is drawn by
/// [rasterPdf] — a picture of the pages, which is the price of a machine
/// without a browser — and the caller says so.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_raster.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:path/path.dart' as p;

const AppLogger _log = AppLogger(name: 'export');

/// No engine is on this machine, and the note could not be drawn either.
final class NoPdfEngine implements Exception {
  /// Creates the failure.
  const new();

  @override
  String toString() => 'No PDF engine was found';
}

/// A note's printed PDF: the file, and whether its text can be selected
/// (a browser printed it) or it is a picture of the pages.
typedef PdfExport = ({ExportPayload payload, bool selectable});

/// Hears what a running [exportNotePdf] is doing.
typedef PdfProgressListener = void Function(PdfExportProgress progress);

/// Prints the note at [path] (relative to [root]) into a PDF.
///
/// [printer] defaults to the desktop engine search; [theme] and
/// [mathCache] are what the raster fallback draws with — without them a
/// machine with no engine has no PDF at all.
///
/// [onProgress] reports the engine print and, when the engine will not
/// answer, the pages the fallback draws; [isCancelled] is asked at stage
/// boundaries and between drawn pages, and answers with
/// [PdfExportCancelled] rather than a file.
Future<PdfExport> exportNotePdf({
  required String text,
  required String title,
  required String path,
  required String root,
  required String language,
  LinkSource? linkSource,
  PdfPrinter? printer,
  MarkdownTheme? theme,
  MathCache? mathCache,
  Directory? scratch,
  PdfProgressListener? onProgress,
  bool Function()? isCancelled,
}) async {
  final chosen = printer ?? ProcessPdfPrinter();
  // Nothing to print with: the note is drawn, and its page — the reads,
  // the parse, the highlighting — is never built.
  if (!await chosen.canPrint) {
    return await _draw(
      path: path,
      text: text,
      root: root,
      linkSource: linkSource,
      theme: theme,
      mathCache: mathCache,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }
  final source = await ExportSources.forPrint(
    text: text,
    title: title,
    notePath: p.join(root, path),
    root: root,
    linkSource: linkSource,
  );
  final page = await ExportSources.page(source, language: language);
  final dir = scratch ?? await Directory.systemTemp.createTemp('niman-pdf-');
  try {
    final htmlPath = p.join(dir.path, 'page.html');
    final pdfPath = p.join(dir.path, 'page.pdf');
    await File(htmlPath).writeAsString(page);
    onProgress?.call(const PdfExportProgress(stage: PdfExportStage.printing));
    final outcome = await chosen.print(htmlPath, pdfPath);
    // A cancel during the print cannot stop a running engine, but its
    // answer is not the user's: nothing is written.
    if (isCancelled?.call() ?? false) throw const PdfExportCancelled();
    switch (outcome) {
      case PdfPrinted():
        return (
          payload: _payload(path, await File(pdfPath).readAsBytes()),
          selectable: true,
        );
      case PdfNoEngine():
        _log.warning('no PDF engine: drawing the note instead');
        return await _draw(
          path: path,
          text: text,
          root: root,
          linkSource: linkSource,
          theme: theme,
          mathCache: mathCache,
          onProgress: onProgress,
          isCancelled: isCancelled,
        );
      case PdfFailed(:final message):
        _log.warning('the PDF engine failed ($message): drawing the note');
        return await _draw(
          path: path,
          text: text,
          root: root,
          linkSource: linkSource,
          theme: theme,
          mathCache: mathCache,
          // As on the no-engine branch: the note is drawn page by page,
          // and the dialog's cancel must be heard (P2).
          onProgress: onProgress,
          isCancelled: isCancelled,
        );
    }
  } finally {
    if (scratch == null) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // The scratch is a temp directory: a failed sweep is not the
        // export's failure.
      }
    }
  }
}

/// The raster fallback: the note drawn as page pictures, or the failure of
/// a machine that has neither an engine nor a theme to draw with.
Future<PdfExport> _draw({
  required String path,
  required String text,
  required String root,
  required LinkSource? linkSource,
  required MarkdownTheme? theme,
  required MathCache? mathCache,
  PdfProgressListener? onProgress,
  bool Function()? isCancelled,
}) async {
  if (theme == null || mathCache == null) throw const NoPdfEngine();
  // The pictures are read here, off the UI isolate, and drawn by the
  // raster pass: there is no browser to embed them, and without them the
  // note would print with its pictures silently missing (H3).
  final images = await ExportSources.imageBytes(
    text: text,
    notePath: p.join(root, path),
    root: root,
    linkSource: linkSource,
  );
  final drawn = await rasterPdf(
    text: text,
    theme: theme,
    mathCache: mathCache,
    images: images,
    onProgress: onProgress == null
        ? null
        : (done, total) => onProgress(
            PdfExportProgress(
              stage: PdfExportStage.drawing,
              done: done,
              total: total,
            ),
          ),
    isCancelled: isCancelled,
  );
  return (payload: _payload(path, drawn), selectable: false);
}

ExportPayload _payload(String path, Uint8List bytes) => (
  name: '${p.basenameWithoutExtension(path)}.pdf',
  bytes: bytes,
  mimeType: 'application/pdf',
);
