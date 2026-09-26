/// The PDF glue of a folder export (#63), split from the isolate's
/// orchestration: one page printed by the machine's engine and added to the
/// zip.
library;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:path/path.dart' as p;

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
  /// Prints [page] with the machine's printer and adds the PDF to [encoder]
  /// as `<stem>.pdf`.
  ///
  /// [engine] is the desktop browser (Edge, Chromium); Android prints
  /// through its WebView and needs none. [runner] runs the engine's
  /// process: null runs the real one, and a test hands in a top-level
  /// function of its own — a closure cannot cross the isolate boundary.
  static Future<void> printInto(
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
}
