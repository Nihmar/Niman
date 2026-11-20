/// What a folder brought in from outside holds that becomes notes (#75,
/// #1295): its Markdown files, and its web pages.
///
/// Only those two come along. Anything else in the folder — pictures, PDFs,
/// stylesheets, scripts — stays behind, and so does what a person does not
/// see in it: a folder hidden by a leading dot (`.git`, `.niman`,
/// `.obsidian`), and the `<Page>_files` folder a browser saves beside
/// `<Page>.html`, whose frames and ads are not notes. A page's pictures are
/// read from there all the same, by their paths, when the page is
/// converted.
///
/// The walk is refused when the folder is far beyond what a notes app
/// should hold — more files, more bytes or more entries to look at than
/// [folderImportLimits] — before anything is converted, as the Notion
/// import's is (`notion.dart`). It runs off the UI isolate: on Android every
/// `listSync` is a FUSE round trip.
library;

import 'dart:io';

import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/import/html/html_file.dart' show isHtmlFile;
import 'package:path/path.dart' as p;

/// What a folder import may hold: the most files it converts or copies, the
/// most bytes of them, and the most entries — of any kind — the walk looks at
/// before it gives up on a folder that is not a place for notes (a drive, a
/// home folder).
typedef FolderLimits = ({int files, int bytes, int visited});

/// What the app takes: as many files as the Notion import's, the bytes it
/// expands to, and a million entries to look at.
const FolderLimits folderImportLimits = (
  files: 100000,
  bytes: 1 << 30,
  visited: 1000000,
);

/// Why a folder is refused.
enum FolderRefusal {
  /// More files, or more entries to look at, than the limits allow.
  tooManyFiles,

  /// More bytes of notes and pages than the limits allow.
  tooManyBytes,
}

/// A folder that is too large to import, refused before anything is made.
final class FolderImportRefused implements Exception {
  /// Refused for [reason]; [detail] is for the log.
  const new(this.reason, this.detail);

  /// Why.
  final FolderRefusal reason;

  /// What exactly.
  final String detail;

  @override
  String toString() => 'FolderImportRefused(${reason.name}): $detail';
}

/// What a folder holds that is imported: the Markdown files and the web
/// pages, relative to it, `/`-separated, in a stable order; and their bytes.
typedef FolderScan = ({List<String> markdown, List<String> pages, int bytes});

/// The extensions a Markdown file is known by.
const Set<String> _markdown = {'.md', '.markdown'};

/// Whether [name] is a Markdown file by its extension, in any case.
bool isMarkdownName(String name) =>
    _markdown.contains(p.extension(name).toLowerCase());

/// [scanImportFolder] off the caller's isolate: what the shell counts a
/// folder's notes with before it offers the import. Throws
/// [FolderImportRefused] for a folder past [limits].
Future<FolderScan> scanFolder(
  String folder, {
  FolderLimits limits = folderImportLimits,
}) => IsolateGauge.run(
  () => scanImportFolder(folder, limits: limits),
  'scan "$folder"',
);

/// The Markdown files and web pages under [folder] (an absolute path).
///
/// Top-level and fully synchronous so it can be handed to `Isolate.run`: the
/// `listSync` behind it cannot run on the UI isolate. Throws
/// [FolderImportRefused] for a folder past [limits].
FolderScan scanImportFolder(
  String folder, {
  FolderLimits limits = folderImportLimits,
}) {
  final markdown = <String>[];
  final pages = <String>[];
  var bytes = 0;
  var visited = 0;

  void walk(Directory dir, String within) {
    final entries = dir.listSync(followLinks: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    final lower = {
      for (final entry in entries) p.basename(entry.path).toLowerCase(),
    };
    for (final entry in entries) {
      if (++visited > limits.visited) {
        throw FolderImportRefused(
          FolderRefusal.tooManyFiles,
          'more than ${limits.visited} entries to look at',
        );
      }
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      final relative = within.isEmpty ? name : '$within/$name';
      if (entry is Directory) {
        if (!_isSavedFilesFolder(name, lower)) walk(entry, relative);
      } else if (entry is File) {
        final isMarkdown = isMarkdownName(name);
        if (!isMarkdown && !isHtmlFile(name)) continue;
        if (markdown.length + pages.length >= limits.files) {
          throw FolderImportRefused(
            FolderRefusal.tooManyFiles,
            'more than ${limits.files} files',
          );
        }
        bytes += entry.lengthSync();
        if (bytes > limits.bytes) {
          throw FolderImportRefused(
            FolderRefusal.tooManyBytes,
            'more than ${limits.bytes} bytes',
          );
        }
        (isMarkdown ? markdown : pages).add(relative);
      }
    }
  }

  walk(Directory(folder), '');
  return (markdown: markdown, pages: pages, bytes: bytes);
}

/// Whether the folder [name] is what a browser saves a page's own files in:
/// `<Page>_files` beside `<Page>.html` (or `.htm`, `.xhtml`). [siblings] are
/// the names beside it, in lower case.
bool _isSavedFilesFolder(String name, Set<String> siblings) {
  const suffix = '_files';
  if (!name.toLowerCase().endsWith(suffix) || name.length == suffix.length) {
    return false;
  }
  final stem = name.substring(0, name.length - suffix.length).toLowerCase();
  return [
    for (final extension in const ['.html', '.htm', '.xhtml'])
      '$stem$extension',
  ].any(siblings.contains);
}
