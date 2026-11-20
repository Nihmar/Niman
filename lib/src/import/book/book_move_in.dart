/// The last step of a book's conversion (#1138, #1294): what was written in
/// a hidden folder is moved into the library in one go, so the library holds
/// nothing of the book until then.
///
/// - **A note a chapter** is the staged folder renamed in under a name free
///   in its parent ([moveFolderIn]): `Dune`, or `Dune 2` beside one.
/// - **One note** is that note moved in beside the folder's others, its
///   pictures into the library's attachments folder, each kept once
///   ([moveNoteIn]).
/// - **Pictures** staged for a note or for a folder of them go into the
///   attachments folder alike ([moveStagedPictures]).
library;

import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/markdown_import.dart' show freeFolderName;
import 'package:path/path.dart' as p;

/// The staged folder [staging] renamed into the folder [parent]
/// (library-relative, '' for the top) of [libraryRoot], named after [title]
/// when that name is free; answers its library-relative path.
String moveFolderIn({
  required String libraryRoot,
  required String parent,
  required String staging,
  required String title,
}) {
  final parentAbs = p.joinAll([libraryRoot, ...parent.split('/')]);
  Directory(parentAbs).createSync(recursive: true);
  final name = freeFolderName(
    parentAbs,
    sanitizeName(title, fallback: defaultFolderName),
  );
  Directory(staging).renameSync(p.join(parentAbs, name));
  return parent.isEmpty ? name : '$parent/$name';
}

/// The note staged at [note] (relative to [staging]) moved into the folder
/// [parent] of [libraryRoot] under a name free there, and the pictures staged
/// in [attachments] into the library's own; answers the note's
/// library-relative path.
Future<String> moveNoteIn({
  required String libraryRoot,
  required String parent,
  required String staging,
  required String attachments,
  required String note,
}) async {
  moveStagedPictures(
    libraryRoot: libraryRoot,
    staging: staging,
    attachments: attachments,
  );
  final folder = Directory(p.joinAll([libraryRoot, ...parent.split('/')]))
    ..createSync(recursive: true);
  final stem = p.posix.basenameWithoutExtension(note);
  final name = await uniqueFileName(folder, stem, '.md');
  File(p.join(staging, note)).renameSync(p.join(folder.path, name));
  return parent.isEmpty ? name : '$parent/$name';
}

/// The pictures staged in [attachments] under [staging] moved into the
/// library's own attachments folder, each kept once: they are named by their
/// content, so one already there is the same one.
void moveStagedPictures({
  required String libraryRoot,
  required String staging,
  required String attachments,
}) {
  final assets = Directory(p.join(staging, attachments));
  if (!assets.existsSync()) return;
  final into = Directory(p.join(libraryRoot, attachments))
    ..createSync(recursive: true);
  for (final picture in assets.listSync().whereType<File>()) {
    final target = File(p.join(into.path, p.basename(picture.path)));
    if (!target.existsSync()) picture.renameSync(target.path);
  }
}
