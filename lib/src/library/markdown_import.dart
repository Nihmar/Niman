/// A folder of Markdown files brought into the library (#75).
///
/// The files are copied, never moved: the folder they came from is left
/// as it was. They land in a new folder of the library root named after
/// the one dropped, with its layout kept, and the library's watcher
/// indexes them like any file that appears there.
///
/// Only Markdown comes along. Anything else in the folder, and any
/// folder hidden by a leading dot (`.git`, `.niman`, `.obsidian`), stays
/// behind: bringing in other kinds of file is an import of its own.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The extensions a Markdown file is known by.
const Set<String> _markdown = {'.md', '.markdown'};

/// The Markdown files under [folder], relative to it, in a stable order.
/// Hidden folders are not entered.
List<String> markdownFilesIn(Directory folder) {
  final found = <String>[];
  void walk(Directory dir) {
    final entries = dir.listSync(followLinks: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final entry in entries) {
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      if (entry is Directory) {
        walk(entry);
      } else if (entry is File &&
          _markdown.contains(p.extension(name).toLowerCase())) {
        found.add(p.relative(entry.path, from: folder.path));
      }
    }
  }

  walk(folder);
  return found;
}

/// Copies the Markdown files of [source] into a new folder of
/// [libraryRoot] named after it — `Name`, or `Name 2`, `Name 3`… when
/// that is taken — and answers the new folder, relative to the library,
/// with the number of notes it holds. Nothing is created for a folder
/// with no Markdown in it: the answer is then null.
Future<({String folder, int notes})?> importMarkdownFolder({
  required String source,
  required String libraryRoot,
}) async {
  final files = markdownFilesIn(Directory(source));
  if (files.isEmpty) return null;
  final name = _freeName(libraryRoot, p.basename(p.normalize(source)));
  final target = p.join(libraryRoot, name);
  for (final relative in files) {
    final to = File(p.join(target, relative));
    await to.parent.create(recursive: true);
    await File(p.join(source, relative)).copy(to.path);
  }
  return (folder: name, notes: files.length);
}

String _freeName(String root, String wanted) {
  var name = wanted;
  for (
    var n = 2;
    FileSystemEntity.typeSync(p.join(root, name)) !=
        FileSystemEntityType.notFound;
    n++
  ) {
    name = '$wanted $n';
  }
  return name;
}
