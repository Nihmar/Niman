/// Where an export is written (#24): the system's own save dialog on the
/// desktop, SAF on Android, as the theme and the debug log already save.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/saved_file.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_tree_book.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:niman/src/links/resolver.dart';

/// Where an exported file is written; the place it landed, or null when
/// the dialog was dismissed. The tests hand in their own.
typedef SaveExportFile = Future<String?> Function({
  required String name,
  required Uint8List bytes,
  required String mimeType,
  required String dialogTitle,
});

/// Asks where to write [bytes] as [name], and writes them there.
///
/// Answers with the place — a path on the desktop, the picker's own URI
/// where there is no path — or null when the dialog was dismissed.
Future<String?> saveExportFileToDisk({
  required String name,
  required Uint8List bytes,
  required String mimeType,
  required String dialogTitle,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: name,
    bytes: bytes,
    mimeType: mimeType,
    dialogTitle: dialogTitle,
  );
  return uri == null ? null : savedPlace(uri);
}

/// The save seam the shell writes an export through; widget tests override
/// it with a closure that answers a place without a picker.
final saveExportFileProvider = Provider<SaveExportFile>(
  (ref) => saveExportFileToDisk,
);

/// Where the folder an export's zip is written into is asked for; its
/// path, or null when the dialog was dismissed. The tests hand in their
/// own.
typedef PickExportFolder = Future<String?> Function({
  required String dialogTitle,
});

/// Asks for the folder, through the system's own picker: a directory
/// dialog on the desktop, SAF on Android.
Future<String?> pickExportFolderFromDisk({required String dialogTitle}) =>
    FilePicker.getDirectoryPath(dialogTitle: dialogTitle);

/// The folder seam the shell exports a tree through.
final pickExportFolderProvider = Provider<PickExportFolder>(
  (ref) => pickExportFolderFromDisk,
);

/// Why a folder's book has no metadata source before its export starts
/// (#303, E3), or null when it has one. A directory listing and one note
/// read, off the UI isolate. Widget tests answer for their library root,
/// which is not a real folder.
typedef EpubMetadataLookup = Future<EpubMetadataProblem?> Function(
  String folder,
);

/// The metadata pre-flight seam a folder's EPUB export goes through.
final epubMetadataProblemProvider = Provider<EpubMetadataLookup>(
  (ref) => ExportTreeBook.problemOf,
);

/// One note as an EPUB book (#303).
final epubNoteExportProvider = Provider<EpubNoteExport>(
  (ref) => exportNoteEpub,
);

/// Builds one note's EPUB book (#303): the seam the shell exporting a note
/// goes through, so a widget test can answer without the isolate the real
/// builder typesets in.
typedef EpubNoteExport = Future<ExportPayload> Function({
  required String text,
  required String title,
  required String path,
  required String root,
  required String language,
  LinkSource? linkSource,
  bool Function()? isCancelled,
});

/// The printer a note's PDF goes through; tests hand in their own, since
/// no engine can be started under `flutter test`. Android's WebView prints
/// in-process through its channel, so nothing is searched for there.
final pdfPrinterProvider = Provider<PdfPrinter>((ref) {
  if (Platform.isAndroid) return const WebViewPdfPrinter();
  return ProcessPdfPrinter();
});

/// The desktop engine a folder's PDF zip prints with, or null when this
/// machine has none.
///
/// Read lazily, when a folder export first asks ([FutureProvider] caches
/// the answer): a user who never exports pays no `reg.exe` on Windows, and
/// the export can await the answer before offering the format (L4/L5).
final pdfEngineProvider = FutureProvider<String?>((ref) => findPdfEngine());
