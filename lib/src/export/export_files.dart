/// Where an export is written (#24): the system's own save dialog on the
/// desktop, SAF on Android, as the theme and the debug log already save.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/export/pdf_printer.dart';

/// Where an exported file is written; the place it landed, or null when
/// the dialog was dismissed. The tests hand in their own.
typedef SaveExportFile = Future<String?> Function({
  required String name,
  required Uint8List bytes,
  required String mimeType,
  required String dialogTitle,
});

/// Asks where to write [bytes] as [name], and writes them there.
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
  return uri?.toString();
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

/// The printer a note's PDF goes through; tests hand in their own, since
/// no engine can be started under `flutter test`.
final pdfPrinterProvider = Provider<PdfPrinter>(
  (ref) => const ProcessPdfPrinter(),
);
