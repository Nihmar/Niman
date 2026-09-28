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
///
/// The walk and the copy run on a background isolate (#382): on Android
/// every `listSync` is a FUSE round trip, and a vault of a few thousand
/// notes costs seconds on the UI isolate (AGENTS.md:72). The caller's
/// isolate only awaits the answer.
library;

import 'dart:io';

import 'package:niman/src/core/isolate_gauge.dart';
import 'package:path/path.dart' as p;

/// The extensions a Markdown file is known by.
const Set<String> _markdown = {'.md', '.markdown'};

/// The Markdown files under [folder] (an absolute path), relative to it, in
/// a stable order. Hidden folders are not entered.
///
/// Top-level and fully synchronous so it can be handed to `Isolate.run`:
/// the `listSync` behind it cannot run on the UI isolate.
List<String> _markdownFilesUnder(String folder) {
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
        found.add(p.relative(entry.path, from: folder));
      }
    }
  }

  walk(Directory(folder));
  return found;
}

/// [_markdownFilesUnder] off the caller's isolate: what the shell counts a
/// dropped folder's notes with, before it offers the import.
Future<List<String>> markdownFilesIn(String folder) =>
    IsolateGauge.run(() => _markdownFilesUnder(folder), 'scan "$folder"');

/// Copies the Markdown files of [source] into a new folder of
/// [libraryRoot] named after it — `Name`, or `Name 2`, `Name 3`… when
/// that is taken — and answers the new folder, relative to the library,
/// with the number of notes it holds. Nothing is created for a folder
/// with no Markdown in it: the answer is then null.
///
/// The walk and the copy run on a background isolate, and the caller is
/// answered when they are done; the library's watcher indexes what landed
/// (#382).
Future<({String folder, int notes})?> importMarkdownFolder({
  required String source,
  required String libraryRoot,
}) => IsolateGauge.run(
  () => _importMarkdownBelow(source: source, libraryRoot: libraryRoot),
  'import folder "${p.basename(p.normalize(source))}"',
);

/// [importMarkdownFolder]'s work, off the UI isolate. Top-level so
/// `Isolate.run` can take it: its closure carries two paths.
({String folder, int notes})? _importMarkdownBelow({
  required String source,
  required String libraryRoot,
}) {
  final files = _markdownFilesUnder(source);
  if (files.isEmpty) return null;
  final name = freeFolderName(libraryRoot, p.basename(p.normalize(source)));
  final target = p.join(libraryRoot, name);
  for (final relative in files) {
    final to = File(p.join(target, relative));
    to.parent.createSync(recursive: true);
    File(p.join(source, relative)).copySync(to.path);
  }
  return (folder: name, notes: files.length);
}

/// A folder name free in [root]: [wanted], or `wanted 2`, `wanted 3`…
/// while each is taken, so an import never lands on top of the library's
/// own folders.
String freeFolderName(String root, String wanted) {
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
