/// The PDF glue of a folder export (#63), split from the isolate's
/// orchestration: one page printed by the machine's engine and added to the
/// zip.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:niman/src/core/process_run.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:path/path.dart' as p;

/// A page the export's isolate asks the UI isolate to print with the
/// system WebView, and where the [PdfOutcome] goes.
///
/// The isolate does not open the WebView's channel itself: on a Mac a
/// background isolate's answer waited for the next event to wake the main
/// thread, so an export stood still until something was clicked. The UI
/// isolate's call is the one a single note's export makes.
final class TreeExportPrint {
  /// Asks for [htmlPath] printed into [pdfPath] on [paper], answered on
  /// [reply].
  const new(
    this.htmlPath,
    this.pdfPath,
    this.reply, {
    this.paper = PdfPaper.a4,
  });

  /// The page.
  final String htmlPath;

  /// Where the PDF goes.
  final String pdfPath;

  /// The sheet it is printed on: a board's is not a note's (#1170).
  final PdfPaper paper;

  /// Where the outcome goes back to.
  final SendPort reply;
}

/// Prints by asking the UI isolate to, over [_parent] ([TreeExportPrint]).
final class _RelayPdfPrinter implements PdfPrinter {
  const new(this._parent);

  final SendPort _parent;

  @override
  Future<bool> get canPrint async => true;

  @override
  Future<PdfOutcome> print(
    String htmlPath,
    String pdfPath, {
    PdfPaper paper = PdfPaper.a4,
  }) async {
    final reply = ReceivePort();
    try {
      _parent.send(
        TreeExportPrint(htmlPath, pdfPath, reply.sendPort, paper: paper),
      );
      return await reply.first as PdfOutcome;
    } finally {
      reply.close();
    }
  }
}

/// A PDF folder was asked for with no engine to print with.
final class TreeExportNoEngine implements Exception {
  /// Creates the failure.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'No PDF engine was found';
}

/// One page at a time, through the machine's printer.
abstract final class ExportTreePrinter {
  /// Prints [page] on [paper] with the machine's printer and adds the PDF
  /// to [encoder] as `<stem>.pdf`.
  ///
  /// [engine] is the desktop browser (Edge, Chromium); null where the
  /// system WebView prints (Android, a Mac's WebKit). It is the caller's
  /// decision, made on the UI isolate: this runs on another, which sees
  /// none of that one's state, and asks the UI isolate to print over
  /// [parent] ([TreeExportPrint]). [runner] runs the engine's
  /// process: null runs the real one, and a test hands in a top-level
  /// function of its own — a closure cannot cross the isolate boundary.
  static Future<void> printInto(
    ZipFileEncoder encoder,
    Directory scratch,
    String? engine,
    ProcessRunner? runner,
    String page,
    String stem, {
    required SendPort parent,
    PdfPaper paper = PdfPaper.a4,
  }) async {
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
    final printer = engine == null
        ? _RelayPdfPrinter(parent)
        : ProcessPdfPrinter(engine: engine, run: runner ?? runEngine);
    final outcome = await printer.print(htmlPath, pdfPath, paper: paper);
    switch (outcome) {
      case PdfPrinted():
        await encoder.addFile(File(pdfPath), '$stem.pdf');
      case PdfNoEngine():
        throw const TreeExportNoEngine();
      case PdfFailed(:final message):
        throw StateError('printing "$stem": $message');
    }
  }
}
