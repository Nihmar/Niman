/// Bringing a Notion export into the library (#25).
///
/// Notion exports "Markdown & CSV": a zip whose pages are `.md` files
/// named after the page plus its 32-hex id (`Roadmap 1f2e4c…md`), each
/// page with children in a folder of its own name, assets beside the page
/// that uses them, and one `.csv` per database view. Opened as it comes
/// out, the result is a browsable library of unreadable names — and the
/// links between pages point at names that stop existing the moment the
/// ids are stripped.
///
/// This copies the export into a new folder of the library, strips the
/// page ids from every name, rewrites the Markdown links that pointed at
/// the old ones (pages and assets alike, relative or absolute), keeps
/// what the export holds — images, PDFs — and drops what Notion exports
/// for itself: the `.csv` of a database view, `__MACOSX`, dotfiles.
///
/// A page id is 32 hex digits (dashes allowed) after a space, on the file
/// name and on `basenameWithoutExtension` only: `Roadmap 1f2e….md` is
/// `Roadmap.md`, a folder `Meeting notes 4a1b…` is `Meeting notes`. Two
/// pages that clean to one name are kept apart with `_2`, `_3`, the way
/// a new note's name is uniquified.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/library/markdown_import.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

/// What an import brought in: the folder it landed in (library-relative),
/// and what that folder holds.
typedef NotionImport = ({String folder, int notes, int assets});

/// A page or folder id Notion appends to a name: a space, then 32 hex
/// digits, dashes optional (`1f2e4c…`, `1f2e4c…-4a1b-…`).
final RegExp _pageId = RegExp(
  r'\s+[0-9a-fA-F]{32}$'
  r'|\s+[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
);

/// Imports the Notion export at [source] (a `.zip`) into [libraryRoot] as
/// a new folder named after the export, and answers it with what it
/// holds. Null when the zip holds nothing to import — a library can hold
/// an archive that is not an export, and a folder of nothing is not worth
/// creating for it.
///
/// Throws [FileSystemException] when [source] cannot be read, and
/// [ArchiveException] when it is not a zip; the caller says so.
Future<NotionImport?> importNotionZip({
  required String source,
  required String libraryRoot,
}) {
  return IsolateGauge.run(
    () => _importNotionZip(source: source, libraryRoot: libraryRoot),
    'import Notion export "${p.basename(source)}"',
  );
}

Future<NotionImport?> _importNotionZip({
  required String source,
  required String libraryRoot,
}) async {
  final archive = ZipDecoder().decodeBytes(await File(source).readAsBytes());
  final entries = _keptEntries(archive);
  if (entries.isEmpty) return null;
  final strip = _commonRoot(entries);
  final wanted = _exportName(strip, source);
  final folder = freeFolderName(libraryRoot, wanted);
  final target = Directory(p.join(libraryRoot, folder));
  await target.create(recursive: true);
  final plan = _planNames(entries, strip);
  final written = await _writeAll(entries, plan, target: target);
  if (written.notes == 0) {
    await target.delete(recursive: true);
    return null;
  }
  return (folder: folder, notes: written.notes, assets: written.assets);
}

/// The file entries worth importing, in archive order: every file whose
/// path is not hidden, not inside `__MACOSX`, and not a `.csv`.
List<({String path, ArchiveFile file})> _keptEntries(Archive archive) {
  final kept = <({String path, ArchiveFile file})>[];
  for (final file in archive) {
    if (!file.isFile) continue;
    final path = _normalized(file.name);
    if (path.isEmpty || _hidden(path)) continue;
    if (p.posix.extension(path).toLowerCase() == '.csv') continue;
    kept.add((path: path, file: file));
  }
  return kept;
}

String _normalized(String name) =>
    p.posix.normalize(name.replaceAll(r'\', '/'));

bool _hidden(String path) => path
    .split('/')
    .any((segment) => segment.startsWith('.') || segment == '__MACOSX');

/// The one top-level folder everything sits in, or null when the archive
/// has files at its root or more than one top-level folder.
String? _commonRoot(List<({String path, ArchiveFile file})> entries) {
  String? root;
  for (final entry in entries) {
    final parts = entry.path.split('/');
    if (parts.length < 2) return null;
    root ??= parts.first;
    if (root != parts.first) return null;
  }
  return root;
}

/// What the import folder is called: the export's own root, or the zip's
/// name when it has none.
String _exportName(String? strip, String source) {
  final fromArchive = strip == null ? null : _cleanSegment(strip, isDir: true);
  final wanted =
      fromArchive ??
      sanitizeName(
        p.basenameWithoutExtension(source),
        fallback: defaultFolderName,
      );
  return wanted;
}

/// The name every kept file lands under, keyed by its path in the archive:
/// the ids stripped, the segments cleaned, and no two names in a folder
/// the same.
Map<String, String> _planNames(
  List<({String path, ArchiveFile file})> entries,
  String? strip,
) {
  final plan = <String, String>{};
  // New directories by their old path ('' for the import root), so the
  // cleaned names are computed once and reused by every file inside.
  final dirs = <String, String>{'': ''};
  final used = <String, Set<String>>{'': <String>{}};
  for (final entry in entries) {
    final old = strip == null
        ? entry.path
        : entry.path.substring('$strip/'.length);
    final segments = old.split('/');
    var oldDir = '';
    var newDir = '';
    for (final segment in segments.take(segments.length - 1)) {
      oldDir = oldDir.isEmpty ? segment : '$oldDir/$segment';
      final known = dirs[oldDir];
      if (known != null) {
        newDir = known;
        continue;
      }
      final clean = _cleanSegment(segment, isDir: true);
      final unique = _unique(clean, used.putIfAbsent(newDir, () => {}));
      final rel = newDir.isEmpty ? unique : '$newDir/$unique';
      dirs[oldDir] = rel;
      newDir = rel;
    }
    final name = _unique(
      _cleanSegment(segments.last, isDir: false),
      used.putIfAbsent(newDir, () => <String>{}),
    );
    plan[entry.path] = newDir.isEmpty ? name : '$newDir/$name';
  }
  return plan;
}

/// [candidate] made unique inside its folder with `_2`, `_3`… — [used]
/// holds the folder's lowercase names, and the candidate is added to it.
String _unique(String candidate, Set<String> used) {
  final base = p.posix.basenameWithoutExtension(candidate);
  final ext = p.posix.extension(candidate);
  var name = candidate;
  for (var n = 2; !used.add(name.toLowerCase()); n++) {
    name = '${base}_$n$ext';
  }
  return name;
}

/// One archive segment as it lands in the library: the id gone, the name
/// sanitized, the extension kept for a file.
String _cleanSegment(String segment, {required bool isDir}) {
  if (isDir) {
    return sanitizeName(
      segment.replaceAll(_pageId, ''),
      fallback: defaultFolderName,
    );
  }
  final extension = p.posix.extension(segment);
  final base = p.posix
      .basenameWithoutExtension(segment)
      .replaceAll(_pageId, '');
  return '${sanitizeName(base, fallback: defaultNoteName)}$extension';
}

/// Copies every planned file into [target], rewriting the Markdown links
/// that pointed at the names the plan changed.
Future<({int notes, int assets})> _writeAll(
  List<({String path, ArchiveFile file})> entries,
  Map<String, String> plan, {
  required Directory target,
}) async {
  // Bare file names, too: Notion sometimes links a page by name without
  // its folder. Only unique ones — an ambiguous name links nothing.
  final byName = <String, String>{};
  final ambiguous = <String>{};
  plan.forEach((path, rel) {
    final name = p.posix.basename(path).toLowerCase();
    if (byName.containsKey(name)) {
      ambiguous.add(name);
    } else {
      byName[name] = rel;
    }
  });
  ambiguous.forEach(byName.remove);
  var notes = 0;
  var assets = 0;
  for (final entry in entries) {
    final rel = plan[entry.path];
    if (rel == null) continue;
    final bytes = entry.file.readBytes();
    if (bytes == null) continue;
    final file = File(p.joinAll([target.path, ...p.posix.split(rel)]));
    await file.parent.create(recursive: true);
    if (p.posix.extension(entry.path).toLowerCase() == '.md') {
      final text = utf8.decode(bytes, allowMalformed: true);
      final rewritten = _rewriteLinks(
        text,
        sourceDir: p.posix.dirname(entry.path),
        newDir: p.posix.dirname(rel),
        plan: plan,
        byName: byName,
      );
      await file.writeAsString(rewritten);
      notes++;
    } else {
      await file.writeAsBytes(bytes);
      assets++;
    }
  }
  return (notes: notes, assets: assets);
}

/// Rewrites the Markdown links of one note from the archive's names to the
/// names they landed under.
///
/// Links and images alike — an asset with its id stripped is as broken as
/// a page. Only the targets the plan knows: a link out of the export (a
/// URL, a dead path) is left exactly as it was, and the anchor of a link
/// is kept. Fenced code and inline code hold no tokens, so a `](…)` in a
/// sample is not touched.
String _rewriteLinks(
  String text, {
  required String sourceDir,
  required String newDir,
  required Map<String, String> plan,
  required Map<String, String> byName,
}) {
  final edits = <({int start, int end, String value})>[];
  var lineStart = 0;
  for (final line in HighlightDocument.fromText(text).lines) {
    final src = line.text;
    for (final token in line.tokens) {
      if (token.kind != TokenKind.link && token.kind != TokenKind.image) {
        continue;
      }
      final close = src.indexOf(']', token.start);
      if (close < 0 || close + 2 > token.end - 1) continue;
      final href = src.substring(close + 2, token.end - 1).trim();
      final mapped = _mapHref(
        href,
        sourceDir: sourceDir,
        newDir: newDir,
        plan: plan,
        byName: byName,
      );
      if (mapped == null) continue;
      final start = lineStart + token.start;
      final end = lineStart + token.end;
      final raw = text.substring(start, end);
      final open = raw.lastIndexOf('](');
      if (open < 0) continue;
      edits.add((
        start: start,
        end: end,
        value: '${raw.substring(0, open + 2)}$mapped)',
      ));
    }
    lineStart += src.length + 1;
  }
  if (edits.isEmpty) return text;
  // Last to first, so an earlier span's offsets stay valid.
  edits.sort((a, b) => b.start.compareTo(a.start));
  var out = text;
  for (final edit in edits) {
    out = out.substring(0, edit.start) + edit.value + out.substring(edit.end);
  }
  return out;
}

/// The new href for an exported [href], or null when it points at nothing
/// the plan renamed.
String? _mapHref(
  String href, {
  required String sourceDir,
  required String newDir,
  required Map<String, String> plan,
  required Map<String, String> byName,
}) {
  if (href.isEmpty || href.startsWith('#')) return null;
  if (LinkResolver.hasScheme(href)) return null;
  final hash = href.indexOf('#');
  final path = hash < 0 ? href : href.substring(0, hash);
  final anchor = hash < 0 ? '' : href.substring(hash);
  if (path.isEmpty) return null;
  final decoded = percentDecoded(path).replaceAll(r'\', '/');
  final guess = decoded.startsWith('/')
      ? decoded.substring(1)
      : p.posix.normalize(p.posix.join(sourceDir, decoded));
  final newRel = plan[guess] ?? byName[p.posix.basename(decoded).toLowerCase()];
  if (newRel == null) return null;
  final relative = p.posix.relative(newRel, from: newDir);
  final encoded = relative.split('/').map(Uri.encodeComponent).join('/');
  return '$encoded$anchor';
}
