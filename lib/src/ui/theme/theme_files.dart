// The file a theme travels in (issue #269): exported where the user says,
// imported where the user says, through the system's own pickers — the
// same ones the debug log export uses.
//
// The read happens off the UI isolate: on Android every read is a round
// trip through the storage layer, and a theme file is small enough that
// nothing else needs doing with it.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:niman/src/core/saved_file.dart';
import 'package:niman/src/core/theme_transfer.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// Where an exported theme is written; the place it landed, or null when
/// the dialog was dismissed. The tests hand in their own.
typedef SaveThemeFile = Future<String?> Function({
  required String name,
  required String json,
});

/// Where an imported theme is read from; its text, or null when nothing
/// was picked.
typedef PickThemeFile = Future<String?> Function();

/// Asks where to write the exported theme, and writes it there.
///
/// Answers with the place, for the message that says it landed, or null
/// when the dialog was dismissed.
Future<String?> saveThemeFileToDisk({
  required String name,
  required String json,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: '${themeFileName(name)}$themeFileExtension',
    bytes: Uint8List.fromList(utf8.encode(json)),
    mimeType: 'application/json',
    dialogTitle: AppStrings.themeExport,
  );
  return uri == null ? null : savedPlace(uri);
}

/// Asks for a theme file, and reads it.
///
/// Answers with the text, or null when nothing was picked.
Future<String?> pickThemeFileFromDisk() async {
  final file = await FilePicker.pickFile(
    dialogTitle: AppStrings.themeImport,
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  final path = file?.path;
  if (path == null) return null;
  return await Isolate.run(() => File(path).readAsStringSync());
}

/// [name] as a file name: the characters a file name cannot hold become
/// dashes, and an empty answer reads as "theme".
String themeFileName(String name) {
  final wanted = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
  return wanted.isEmpty ? 'theme' : p.basename(wanted);
}
