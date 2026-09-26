/// The walk and the pages of a folder export (#24), split from the
/// isolate's orchestration so a page can be built — and tested — without a
/// `TreeExport`.
///
/// Everything here works over the tree: which entries it holds, what a
/// note's page is called, and how a link or a picture inside the subtree
/// resolves. It reads the disk and builds strings; the zip, the isolate and
/// the progress are the caller's.
library;

import 'dart:convert';
import 'dart:io';

import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/links/parser.dart';
import 'package:path/path.dart' as p;

/// One entry of the subtree: its absolute path, its zip name, and whether
/// it is a folder.
typedef ExportTreeEntry = ({String abs, String rel, bool isDir});

/// The walked tree, its root, the lookups links and pictures resolve with,
/// and the page name each note gets inside the export.
typedef ExportTreeWalk = ({
  String root,
  List<ExportTreeEntry> entries,
  Set<String> files,
  Map<String, String> notes,
  Map<String, List<String>> stems,
  Map<String, String> names,
});

/// One subtree, walked once, and the pages built from it.
abstract final class ExportTreePages {
  /// The subtree of [dir] in path order: every file and folder whose name
  /// does not start with a dot (settings, trash and history are not part of
  /// an export).
  static ExportTreeWalk walk(String dir) {
    final entries = <ExportTreeEntry>[];
    void visit(Directory current, String rel) {
      final children = current.listSync()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final child in children) {
        final name = p.basename(child.path);
        if (name.startsWith('.')) continue;
        final childRel = rel.isEmpty ? name : '$rel/$name';
        if (child is Directory) {
          entries.add((abs: child.path, rel: childRel, isDir: true));
          visit(child, childRel);
        } else if (child is File) {
          entries.add((abs: child.path, rel: childRel, isDir: false));
        }
      }
    }

    visit(Directory(dir), '');
    final files = <String>{
      for (final entry in entries)
        if (!entry.isDir) entry.rel,
    };
    final noteFiles = [
      for (final file in files)
        if (isNote(file)) file,
    ];
    final notes = <String, String>{
      for (final file in noteFiles) file.toLowerCase(): file,
    };
    final stems = <String, List<String>>{};
    for (final file in noteFiles) {
      (stems[_stem(file).toLowerCase()] ??= <String>[]).add(file);
    }
    // The page name a note gets inside the export: its stem when that is
    // free, a numbered one when two notes would land on one entry. Names
    // are kept unique case-insensitively: `a.md` and `a.MD` are two notes
    // on Linux and one file name on Windows (E7).
    final names = <String, String>{};
    final used = <String>{};
    for (final file in noteFiles) {
      final wanted = _stem(file);
      var name = wanted;
      for (var n = 2; !used.add(name.toLowerCase()); n++) {
        name = '$wanted-$n';
      }
      names[file] = name;
    }
    return (
      root: dir,
      entries: entries,
      files: files,
      notes: notes,
      stems: stems,
      names: names,
    );
  }

  /// Whether [rel] becomes a page: a Markdown note.
  static bool isNote(String rel) => p.extension(rel).toLowerCase() == '.md';

  /// The note at [abs] as the app reads it: decoded leniently — a note with
  /// a broken byte is still a note (`NoteOps.readNote`) — and without its
  /// BOM. A strict decode would turn one bad byte anywhere in the tree into
  /// a failed export of the whole folder (E9).
  static String readNote(String abs) {
    final bytes = File(abs).readAsBytesSync();
    final text = utf8.decode(bytes, allowMalformed: true);
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  }

  /// The whole page for [text], the note at [rel] of [tree].
  ///
  /// [linkExtension] is what a note link points at — the page the zip
  /// holds, `.html` or `.pdf` — and [embedPictures] is the printed page's
  /// own picture form, a `file:` URL the engine fetches.
  static String page(
    String text,
    String rel,
    ExportTreeWalk tree,
    String language,
    String linkExtension, {
    bool embedPictures = false,
  }) {
    final noteDir = p.dirname(rel);
    final title = pageTitle(text, rel);
    final source = NoteHtmlSource(
      text: text,
      title: title,
      images: embedPictures
          ? imageFileUrls(text, noteDir, tree)
          : imageUrls(text, noteDir, tree),
      links: linkUrls(text, noteDir, tree, linkExtension),
    );
    final html = NoteHtml(source);
    return htmlPage(
      title: title,
      body: html.body(),
      fontFaces: html.fontFaces,
      language: language,
    );
  }

  /// The title a page or a chapter carries: the note's frontmatter title,
  /// or its file's own name.
  static String pageTitle(String text, String rel) =>
      parseFrontmatter(text)?.title ?? p.basenameWithoutExtension(rel);

  /// The pictures [text] shows, by the target as written, as URLs relative
  /// to the page.
  static Map<String, String> imageUrls(
    String text,
    String noteDir,
    ExportTreeWalk tree,
  ) {
    final out = <String, String>{};
    for (final target in ExportSources.pictureTargets(text)) {
      final picture = fileIn(target, noteDir, tree.files);
      if (picture != null) out[target] = url(noteDir, picture);
    }
    return out;
  }

  /// The pictures [text] shows, by the target as written, as `file:` URLs.
  ///
  /// A PDF page is printed from the export's scratch directory, where the
  /// pictures the zip holds are not: left relative, every one of them is a
  /// broken image. A `file:` URL points at the tree itself, and the engine
  /// fetches it — the page stays the note's size, where embedding a
  /// library's photos as base64 built one no phone could hold.
  static Map<String, String> imageFileUrls(
    String text,
    String noteDir,
    ExportTreeWalk tree,
  ) {
    final out = <String, String>{};
    for (final target in ExportSources.pictureTargets(text)) {
      final picture = fileIn(target, noteDir, tree.files);
      if (picture == null) continue;
      out[target] = Uri.file(p.join(tree.root, picture)).toString();
    }
    return out;
  }

  /// The note links [text] writes, by the target as written, as URLs
  /// relative to the page. A target outside the subtree is left out: it
  /// becomes highlighted text on the page. [extension] is what a note link
  /// points at — the page the zip holds, `.html` or `.pdf`.
  static Map<String, String> linkUrls(
    String text,
    String noteDir,
    ExportTreeWalk tree,
    String extension,
  ) {
    final out = <String, String>{};
    for (final link in parseLinks(text)) {
      switch (link) {
        case WikiLink(:final ref):
          final note = noteIn(ref.target, noteDir, tree);
          if (note != null) {
            out[ref.target] = url(noteDir, '${tree.names[note]}$extension');
          }
        case MarkdownLink(:final href):
          if (!href.toLowerCase().endsWith('.md')) continue;
          final note = noteIn(href, noteDir, tree);
          if (note != null) {
            out[href] = url(noteDir, '${tree.names[note]}$extension');
          }
      }
    }
    return out;
  }

  /// The file [target] names inside the tree, from [noteDir]: the subtree
  /// root first, then the note's own folder, then a unique file name — the
  /// read view's own order, over the tree instead of the index. The name
  /// matches case-insensitively when exactly one file answers, as a note
  /// target does (E7).
  static String? fileIn(String target, String noteDir, Set<String> files) {
    var clean = target.trim().replaceAll(r'\', '/');
    while (clean.startsWith('./')) {
      clean = clean.substring(2);
    }
    if (clean.isEmpty) return null;
    if (files.contains(clean)) return clean;
    final beside = p.posix.normalize(p.posix.join(noteDir, clean));
    if (files.contains(beside)) return beside;
    if (clean.contains('%')) {
      try {
        final decoded = Uri.decodeFull(clean);
        if (decoded != clean) return fileIn(decoded, noteDir, files);
      } on FormatException {
        // A stray `%` is taken as written.
      }
    }
    final base = p.posix.basename(clean);
    final matches = [
      for (final file in files)
        if (p.posix.basename(file) == base) file,
    ];
    if (matches.length == 1) return matches.single;
    if (matches.isEmpty) {
      final lower = base.toLowerCase();
      final caseless = [
        for (final file in files)
          if (p.posix.basename(file).toLowerCase() == lower) file,
      ];
      if (caseless.length == 1) return caseless.single;
    }
    return null;
  }

  /// The note [target] names inside the tree: an exact path first (with
  /// `.md`), then the note's own folder, then a unique stem, then the stem
  /// under the target's own folder — the index's own order.
  static String? noteIn(String target, String noteDir, ExportTreeWalk tree) {
    var clean = target.trim().replaceAll(r'\', '/');
    while (clean.startsWith('./')) {
      clean = clean.substring(2);
    }
    if (clean.isEmpty) return null;
    var lower = clean.toLowerCase();
    if (!lower.endsWith('.md')) lower = '$lower.md';
    final atRoot = tree.notes[lower];
    if (atRoot != null) return atRoot;
    final beside = tree.notes[p.posix.join(noteDir, lower)];
    if (beside != null) return beside;
    final stem = p.withoutExtension(p.posix.basename(lower));
    final candidates = tree.stems[stem] ?? const <String>[];
    if (candidates.length == 1) return candidates.single;
    final prefix = p.posix.dirname(lower);
    if (candidates.isEmpty || prefix == '.') return null;
    final filtered = [
      for (final candidate in candidates)
        if (p.posix.dirname(candidate.toLowerCase()) == prefix) candidate,
    ];
    return filtered.length == 1 ? filtered.single : null;
  }

  /// Where [target] sits, from the page in [fromDir] (both tree-relative):
  /// a URL a browser reads, one path segment at a time.
  ///
  /// `Uri.encodeFull` would leave `#` and `?` alone — they are URI
  /// delimiters, not path characters — so a picture named `a#b.png` would
  /// export as a fragment of a path that does not exist.
  static String url(String fromDir, String target) {
    final relative = fromDir.isEmpty || fromDir == '.'
        ? target
        : p.posix.relative(target, from: fromDir);
    return relative.split('/').map(Uri.encodeComponent).join('/');
  }
}

/// [rel] without its Markdown extension: the page beside the note.
String _stem(String rel) => p.withoutExtension(rel);
